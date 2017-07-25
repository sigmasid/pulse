//
//  ContentDetailVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import AVFoundation

class ContentDetailVC: PulseVC, ItemDetailDelegate, UIGestureRecognizerDelegate, ModalDelegate {
    public var selectedChannel : Channel!
    public var selectedItem : Item! //parentItem
    public weak var delegate : ContentDelegate?
    public var isShowingIntro = false
    
    public var allItems = [Item]() {
        didSet {
            if isViewLoaded, oldValue == [], !firstItemLoaded {
                firstItemLoaded = true
                removeObserverIfNeeded()
                loadItem(index: itemIndex)
            }
        }
    }
    public lazy var itemDetail = [Item]()
    public var itemIndex = 0
    
    private var currentItem : Item? {
        didSet {
            guard let currentItem = currentItem else { return }
            
            guard nextItemReady else {
                addNextItem(item: currentItem, completion: {[weak self] success in
                    guard let `self` = self else { return }
                    if success {
                        let _currentItem = self.currentItem
                        self.currentItem = _currentItem
                    } else {
                        self.handleTap()
                    }
                })
                return
            }
            
            tapReady = false
            
            //whenever this is set - advance with this item
            advanceItem(completion: { [weak self] success in
                guard let `self` = self else { return }
                if currentItem.itemCollection.count > 1 {
                    //set the next detail item from fullItem which adds the next item to queue
                    self.updateOverlayData(currentItem, updateUser: true)
                    self.itemDetail = currentItem.itemCollection
                    self.itemDetailIndex = 0
                    self.showItemDetail(show: true)
                    self.contentOverlay?.updateSelectedPager(num: self.itemDetailIndex)
                    self.shouldShowExplore = true
                } else if self.shouldShowExplore {
                    //is a detail item so just update the overlay
                    currentItem.user = oldValue?.user
                    self.updateOverlayData(currentItem, updateUser: false)
                    self.contentOverlay?.updateSelectedPager(num: self.itemDetailIndex)
                } else {
                    //not a detail item and does not have any item detail
                    self.showItemDetail(show: false)
                    self.updateOverlayData(currentItem, updateUser: true)
                    self.shouldShowExplore = false
                }
                
                if self.shouldShowExplore {
                    self.checkNextItem(detail: true, completion: {[weak self] success in
                        guard let `self` = self else { return }
                        if success {
                            //this will also add as next item in queue
                            self.nextDetailItem = self.itemDetail[self.itemDetailIndex]
                        } else if self.canAdvanceReady, let nextFullItem = self.nextFullItem {
                            //no more detail items - so check if can move to fullItems
                            self.addNextItem(item: nextFullItem, completion: { _ in })
                        }
                    })
                } else if self.canAdvanceReady, let nextFullItem = self.nextFullItem {
                    self.addNextItem(item: nextFullItem, completion: { _ in })
                }
            })
        }
    }
    
    //next item in itemDetail - so add it to the queue right away
    //on detail tap - checks to get next item
    private var nextDetailItem : Item? {
        didSet {
            guard let nextDetailItem = nextDetailItem else { return }
            
            if nextDetailItem.itemCreated {
                addNextItem(item: nextDetailItem, completion: { _ in })
            } else {
                PulseDatabase.getItem(nextDetailItem.itemID, completion: {[weak self] item, error in
                    guard let `self` = self else { return }
                    if let item = item {
                        self.nextDetailItem = item
                    }
                })
            }
        }
    }
    
    //next item in itemCollection
    private var nextFullItem : Item? {
        didSet {
            guard let nextFullItem = nextFullItem else { return }
            
            if nextFullItem.itemCreated {
                let itemID = nextFullItem.itemID
                PulseDatabase.getItemCollection(nextFullItem.itemID, completion: {[weak self] (success, items) in
                    guard let `self` = self, nextFullItem.itemID == itemID else { return }
                    nextFullItem.itemCollection = self.reorderItemDetail(parentItem: nextFullItem, itemCollection: items)
                })
            } else {
                PulseDatabase.getItem(nextFullItem.itemID, completion: {[weak self] item, error in
                    guard let `self` = self else { return }
                    if let item = item {
                        self.nextFullItem = item
                    }
                })
            }
        }
    }
    
    private var canAdvanceReady = false
    private var canAdvanceDetailReady = false
    private var tapReady = false
    private var nextItemReady = false
    
    private lazy var itemDetailIndex = 0
    private var quickBrowse: QuickBrowseVC!
    private var messageVC : MiniMessageVC!
    
    /** Media Player Items **/
    private var avPlayerLayer: AVPlayerLayer!
    private var contentOverlay : ContentOverlay?
    private var qPlayer = AVQueuePlayer()
    private var nextPlayerItem : AVPlayerItem?
    private var imageView : UIImageView!
    private var textBox: RecordedTextView!
    
    /* bools to make sure can click next video and no errors from unhandled observers */
    private var isObserving = false
    private var shouldShowExplore = false
    private var cleanupComplete = false
    private var firstItemLoaded = false
    
    private var playedTillEndObserver : Any!
    private var timeObserver : Any!
    private var startCountdownObserver : Any!
    
    private var tap : UITapGestureRecognizer!
    private var detailTap : UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            tabBarHidden = true
            statusBarHidden = true
            
            view.backgroundColor = UIColor.black
            
            tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            tap.cancelsTouchesInView = false
            tap.delegate = self
            view.addGestureRecognizer(tap)
            
            qPlayer.actionAtItemEnd = AVPlayerActionAtItemEnd.none
            contentOverlay = ContentOverlay(frame: view.bounds, iconColor: .white, iconBackground: .black)
            contentOverlay?.addClipTimerCountdown()
            contentOverlay?.delegate = self
            
            avPlayerLayer = AVPlayerLayer(player: qPlayer)
            avPlayerLayer.backgroundColor = UIColor.black.cgColor
            view.layer.insertSublayer(avPlayerLayer, at: 0)
            view.insertSubview(contentOverlay!, at: 2)
            avPlayerLayer.frame = view.bounds
            
            if allItems.count > itemIndex && !firstItemLoaded { //to make sure that allItems has been set
                firstItemLoaded = true
                loadItem(index: itemIndex)
            }
            
            startCountdownObserver = NotificationCenter.default.addObserver(self,
                                                   selector: #selector(startCountdownTimer),
                                                   name: NSNotification.Name(rawValue: "PlaybackStartedNotification"),
                                                   object: nextPlayerItem)
            
            //align the timer to actually when the video starts
            timeObserver = qPlayer.addBoundaryTimeObserver(forTimes: [NSValue(time: CMTimeMake(1, 20))],
                                                        queue: nil,
                                                        using: { NotificationCenter.default.post(name: Notification.Name(rawValue: "PlaybackStartedNotification"), object: self)}) as AnyObject!
            
            isLoaded = true
        }
    }
    
    deinit {
        performCleanup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let view = touch.view, view.isKind(of: PulseButton.self) {
            return false
        }
        
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeObserverIfNeeded()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    internal func didPlayTillEnd() {
        if shouldShowExplore {
            contentOverlay?.highlightExploreDetail()
        }
        
        if let currentItem = currentItem {
            PulseDatabase.updateItemViewCount(itemID: currentItem.itemID)
        }
        
        if playedTillEndObserver != nil {
            NotificationCenter.default.removeObserver(playedTillEndObserver)
        }
    }
    
    fileprivate func loadItem(index: Int) {
        canAdvanceReady = false
        
        guard index < allItems.count else {
            delegate?.noItemsToShow(self)
            return
        }
        
        guard allItems[index].itemCreated else {
            PulseDatabase.getItem( allItems[index].itemID, completion: {[weak self] item, error in
                if let item = item, let `self` = self {
                    self.allItems[index] = item
                    self.loadItem(index: index)
                }
            })
            return
        }
        
        let item = allItems[index]
                
        addNextItem(item: item, completion: {[weak self] success in
            guard let `self` = self else { return }
            if success {
                
                PulseDatabase.getItemCollection(item.itemID, completion: {[weak self] (_ success : Bool, _ items : [Item]) in
                    guard let `self` = self else { return }
                    
                    item.itemCollection = self.reorderItemDetail(parentItem: item, itemCollection: items)
                    
                    self.checkNextItem(detail: false, completion: {[weak self] success in
                        guard let `self` = self else { return }
                        if success {
                            PulseDatabase.getItem(self.allItems[self.itemIndex].itemID, completion: {[weak self] nextItem, error in
                                guard let `self` = self else { return }
                                
                                self.nextFullItem = nextItem
                                self.currentItem = item
                            })
                        } else {
                            self.currentItem = item
                        }
                    })
                })
            }
        })
    }
    
    fileprivate func reorderItemDetail(parentItem: Item, itemCollection: [Item]) -> [Item] {
        guard itemCollection.count > 1 else {
            return []
        }
        
        if parentItem.needsCover() {
            let _items = itemCollection.reversed()
            
            if let lastItem = _items.last {
                let sessionSlice = _items.dropLast()
                var arrangedItems = Array(sessionSlice)
                arrangedItems.insert(lastItem, at: 0)
                
                return arrangedItems
            }
        }
        
        return itemCollection.reversed()
    }
    
    fileprivate func addDetailTap() {
        tap.isEnabled = false
        
        if detailTap == nil {
            detailTap = UITapGestureRecognizer(target: self, action: #selector(handleDetailTap))
            detailTap.cancelsTouchesInView = false
            detailTap.delegate = self
            view.addGestureRecognizer(detailTap)
        } else {
            detailTap.isEnabled = true
        }
    }
    
    fileprivate func removeDetailTap() {
        if detailTap != nil {
            detailTap.isEnabled = false
        }
        
        tap.isEnabled = true
    }
    
    fileprivate func showItemDetail(show: Bool) {
        if show {
            addDetailTap()
            contentOverlay?.addPagers(num: itemDetail.count)
            contentOverlay?.dimExploreDetail()
        } else {
            removeDetailTap()
            contentOverlay?.hideExploreDetail()
            contentOverlay?.clearPagers()
        }
    }
    
    fileprivate func checkNextItem(detail : Bool, completion: @escaping (_ success : Bool) -> Void) {
        let success = detail ? canAdvanceItemDetail(itemDetailIndex + 1) : canAdvance(itemIndex + 1)
        
        if success, detail {
            itemDetailIndex += 1
            canAdvanceDetailReady = true
        } else if success {
            itemIndex += 1
            canAdvanceReady = true
        } else if detail {
            itemDetailIndex += 1
            canAdvanceDetailReady = false
        } else {
            itemIndex += 1
            canAdvanceReady = false
        }
        
        completion(success)
    }
    
    fileprivate func addNextItem(item: Item, completion: @escaping (_ success : Bool) -> Void) {
        guard let itemType = item.contentType else {
            completion(false)
            return
        }
        
        switch itemType {
        case .recordedVideo, .albumVideo:
            guard item.contentURL != nil else {
                completion(false)
                return
            }
            
            addVideoToQueue(itemURL: item.contentURL, completion: { success in
                completion(success)
            })
        case .recordedImage, .albumImage:
            guard item.contentURL != nil else {
                completion(false)
                return
            }
            
            addImageToQueue(item: item, itemURL: item.contentURL, completion: { success in
                completion(success)
            })
        case .postcard:
            
            nextItemReady = true
            completion(true)
        }
    }
    
    fileprivate func addVideoToQueue(itemURL: URL?, completion:  @escaping (_ success : Bool) -> Void) {
        guard let itemURL = itemURL else {
            completion(false)
            return
        }
        
        nextPlayerItem = AVPlayerItem(url: itemURL)
        
        //without changing names the avqueueplayer doesn't add the item i.e. currentitem never gets set
        guard let _nextPlayerItem = nextPlayerItem else {
            completion(false)
            return
        }
        
        if qPlayer.currentItem != nil, qPlayer.canInsert(_nextPlayerItem, after: qPlayer.currentItem) {
            qPlayer.insert(_nextPlayerItem, after: qPlayer.currentItem)
            nextPlayerItem = _nextPlayerItem
            nextItemReady = true
            completion(true)
        } else if qPlayer.canInsert(_nextPlayerItem, after: nil) {
            qPlayer.insert(_nextPlayerItem, after: nil)
            nextItemReady = true
            nextPlayerItem = _nextPlayerItem
            completion(true)
        } else {
            nextPlayerItem = nil
            nextItemReady = false
            completion(false)
        }
    }
    
    fileprivate func addImageToQueue(item: Item, itemURL: URL?, completion: @escaping (_ success : Bool) -> Void) {
        guard let itemURL = itemURL else {
            completion(false)
            return
        }
        
        DispatchQueue.global(qos: .background).async {[weak self] in
            guard let `self` = self else { return }
            if let _imageData = try? Data(contentsOf: itemURL), let image = UIImage(data: _imageData) {
                item.content = image
                self.nextItemReady = true
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    //adds the first clip to the Items
    private func advanceItem(completion: @escaping (_ success : Bool) -> Void) {
        
        guard let item = currentItem, let itemType = item.contentType else {
            completion(false)
            return
        }
        
        switch itemType {
        case .recordedVideo, .albumVideo:
            showMode(mode: .video)
            playItem(completion: { success in
                completion(success)
            })
            
        case .recordedImage, .albumImage:
            guard let image = item.content else {
                completion(false)
                hideIntro()
                return
            }
            
            showMode(mode: .image)
            imageView.image = image
            
            if shouldShowExplore {
                contentOverlay?.highlightExploreDetail()
            }
            completion(true)
            hideIntro()
            
        case .postcard:
            showMode(mode: .text)
            textBox.textToShow = item.itemTitle
            
            if shouldShowExplore {
                contentOverlay?.highlightExploreDetail()
            }
            completion(true)
            hideIntro()
        }
    }
    
    private func playItem(completion: @escaping (_ success : Bool) -> Void) {
        pausePlayer()
        contentOverlay?.resetTimer()
        
        if qPlayer.items().count > 1 {
            qPlayer.advanceToNextItem()
            addObserverForStatusReady { success in
                completion(success)
            }
        } else {
            addObserverForStatusReady {[weak self] success in
                guard let `self` = self else { return }
                
                self.qPlayer.play()
                completion(success)
            }
        }
    }
    
    private func pausePlayer() {
        if qPlayer.currentItem != nil {
            qPlayer.pause()
        }
    }
    
    private func restartPlayer() {
        if qPlayer.currentItem != nil {
            qPlayer.play()
        }
    }
    
    internal func startCountdownTimer() {
        if let currentItem = qPlayer.currentItem {
            let duration = currentItem.duration
            contentOverlay?.startTimer(duration.seconds)
        }
    }
    
    fileprivate func updateOverlayData(_ item : Item, updateUser: Bool = true) {
        contentOverlay?.resetTimer()
        contentOverlay?.setTitle(currentItem?.contentType != .postcard ? item.itemTitle : "")
        contentOverlay?.updateButtons(color: currentItem?.contentType != .postcard ? .white : .black )
        
        guard updateUser else { return }
        
        PulseDatabase.getCachedUserPic(uid: item.itemUserID, completion: {[weak self] image in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                self.contentOverlay?.setUserImage(image)
            }
        })
        
        if let user = item.user {
            contentOverlay?.setUserName(user.name)
            contentOverlay?.setUserSubtitle(user.shortBio)
        } else if updateUser {
            contentOverlay?.setUserImage(UIImage(named: "default-profile"))
            
            PulseDatabase.getUser(item.itemUserID ?? "", completion: {[weak self] (user, error) in
                if let user = user, let `self` = self, self.currentItem?.itemUserID == user.uID {
                    self.currentItem?.user = user
                    self.contentOverlay?.setUserName(user.name)
                    self.contentOverlay?.setUserSubtitle(user.shortBio)
                }
            })
        }
    }
    
    fileprivate func addObserverForStatusReady(completion: @escaping (_ success : Bool) -> Void) {
        if qPlayer.currentItem != nil {
            qPlayer.currentItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
            
            playedTillEndObserver = NotificationCenter.default.addObserver(self, selector: #selector(didPlayTillEnd),
                                                                           name: .AVPlayerItemDidPlayToEndTime,
                                                                           object: nextPlayerItem)
            
            isObserving = true
            completion(true)
        } else {
            completion(false)
        }
        
    }
    
    fileprivate func removeObserverIfNeeded() {
        if isObserving, qPlayer.currentItem != nil {
            qPlayer.currentItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
            
            if playedTillEndObserver != nil {
                NotificationCenter.default.removeObserver(playedTillEndObserver)
            }
            
            if startCountdownObserver != nil {
                NotificationCenter.default.removeObserver(startCountdownObserver)
            }
            
            isObserving = false
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "loadedTimeRanges" {
            switch qPlayer.status {
            case AVPlayerStatus.readyToPlay:
                readyToPlay()
                break
            default: break
            }
        }
    }
    
    fileprivate func readyToPlay() {
        DispatchQueue.main.async(execute: {[weak self] in
            guard let `self` = self else { return }
            self.qPlayer.play()
        })
        
        if !tapReady {
            tapReady = true
        }
        
        hideIntro()
        removeObserverIfNeeded()
    }
    
    fileprivate func hideIntro() {
        if isShowingIntro {
            delegate?.removeIntro()
            isShowingIntro = false
        }
    }
    
    
    fileprivate func canAdvance(_ index: Int) -> Bool{
        return index < allItems.count ? true : false
    }
    
    fileprivate func canAdvanceItemDetail(_ index: Int) -> Bool{
        return index < itemDetail.count ? true : false
    }
    
    private func addImageView() {
        imageView = UIImageView(frame: view.bounds)
        imageView.backgroundColor = UIColor.black
        imageView.contentMode = .scaleAspectFill
        view.insertSubview(imageView, at: 1)
    }
    
    private func addTextView() {
        textBox = RecordedTextView(frame: view.bounds)
        textBox.isEditable = false
        textBox.isExclusiveTouch = false
        view.insertSubview(textBox, at: 1)
    }
    
    private func showMode(mode: ContentMode) {
        switch mode {
        case .image:
            pausePlayer()
            if imageView == nil { addImageView() }
            avPlayerLayer.isHidden = true
            imageView.image = nil
            imageView.isHidden = false
            if textBox != nil { textBox.isHidden = true }
            tapReady = true
            
        case .video:
            avPlayerLayer.isHidden = false
            if imageView != nil { imageView.isHidden = true }
            if textBox != nil { textBox.isHidden = true }
            tapReady = false
            
        case .text:
            pausePlayer()
            if textBox == nil { addTextView() }
            textBox.textToShow = nil
            textBox.isHidden = false
            avPlayerLayer.isHidden = true
            if imageView != nil { imageView.isHidden = true }
            tapReady = true
            
        }
    }
    
    /* DELEGATE METHODS */
    func userClickedSendMessage() {
        guard PulseUser.isLoggedIn(), let selectedUser = currentItem?.user, PulseUser.currentUser.uID != selectedUser.uID else { return }
        
        pausePlayer()
        
        if messageVC == nil {
            messageVC = MiniMessageVC()
            messageVC.selectedUser = selectedUser
            messageVC.delegate = self
        }
        
        present(messageVC, animated: true, completion: nil)
        blurViewBackground()
    }
    
    func votedItem(_ vote : VoteType) {
        if let _currentItem = currentItem {
            if vote == .favorite {
                PulseDatabase.saveItem(item: _currentItem, completion: {[weak self] success, error in
                    if success, let `self` = self {
                        self.contentOverlay?.itemSaved(type: vote)
                    }
                })
            } else {
                PulseDatabase.addVote( vote, itemID: _currentItem.itemID, completion: {[weak self] (success, error) in
                    if let `self` = self, success {
                        self.contentOverlay?.itemSaved(type: vote)
                    }
                })
            }
        }
    }
    
    func userClickedButton() {
        delegate?.userClickedProfileDetail()
    }
    
    func userClickedHeaderMenu() {
        guard let currentItem = currentItem else { return }
        
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        pausePlayer()
        
        menu.addAction(UIAlertAction(title: "share \(selectedItem.type.rawValue.capitalized)", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.toggleLoading(show: true, message: "loading share options", showIcon: true)
            let shareItem = Item.shareItemType(parentType: self.selectedItem.type, childType: currentItem.type) == self.selectedItem.type ?
                self.selectedItem : currentItem
            shareItem?.createShareLink(completion: {[weak self] link in
                guard let link = link, let `self` = self else { return }
                self.shareContent(shareType: shareItem!.type.rawValue, shareText: shareItem!.shareText(), shareLink: link)
                self.toggleLoading(show: false, message: nil)
            })
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            menu.dismiss(animated: true, completion: nil)
            self.restartPlayer()
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    func userClickedNextItem() {
        if shouldShowExplore, canAdvanceItemDetail(itemDetailIndex) {
            if let nextFullItem = nextFullItem {
                qPlayer.removeAllItems()
                addNextItem(item: nextFullItem, completion: {[unowned self] success in
                    if success {
                        self.handleTap()
                    }
                })
            } else {
                handleTap()
            }
        } else {
            handleTap()
        }
    }
    
    func userClickedProfile() {
        blurViewBackground()
        pausePlayer()
        
        if let user = currentItem?.user {
            
            PulseDatabase.getCachedUserPic(uid: user.uID!, completion: {[weak self] image in
                guard let `self` = self else { return }
                
                DispatchQueue.main.async {
                    let miniProfile = PMAlertController(title: user.name ?? "Pulse User", description: user.shortBio ?? "", image: image, style: .alert)
                    
                    miniProfile.dismissWithBackgroudTouch = true
                    miniProfile.modalDelegate = self
                    
                    miniProfile.addAction(PMAlertAction(title: "View Profile", style: .cancel, action: {[weak self] () -> Void in
                        guard let `self` = self else { return }
                        self.delegate?.userClickedProfileDetail()
                        self.removeBlurBackground()
                    }))
                    
                    self.present(miniProfile, animated: true, completion: nil)
                }
            })
        }
    }
    
    func userClosedModal(_ viewController: UIViewController) {
        dismiss(animated: true, completion: nil)
        removeBlurBackground()
        restartPlayer()
    }
    
    /** Quick Browse Delegate **/
    func userSelected(_ index : IndexPath) {
        userClosedQuickBrowse()
        clearAllItems()
        itemIndex = index.row
        loadItem(index: (index as NSIndexPath).row)
        removeBlurBackground()
    }
    
    func userClickedSeeAll(items : [Item]) {
        userClosedQuickBrowse()
        delegate?.userClickedSeeAll(items: items)
        removeObserverIfNeeded()
    }
    
    func userClickedBrowseItems() {
        pausePlayer()
        
        quickBrowse = QuickBrowseVC()
        quickBrowse.delegate = self
        quickBrowse.selectedChannel = selectedChannel
        quickBrowse.allItems = allItems
        
        removeObserverIfNeeded()
        blurViewBackground()
        
        present(quickBrowse, animated: true, completion: nil)
    }
    
    func userClosedQuickBrowse() {
        removeBlurBackground()
        restartPlayer()
        dismiss(animated: true, completion: nil)
    }
    
    /** 
     nextItemReady - there is something in the video queue
     tapReady - item is loaded & buffered
     canAdvanceReady - there are more items in collection
     **/
    
    /* MARK : HANDLE GESTURES */
    func handleTap() {
        //ignore tap if mini profile is shown or if quick browse is shown
        if (!tapReady || (!nextItemReady && canAdvanceReady)) {
            //ignore tap
        }
            
        else if canAdvanceReady {
            
            shouldShowExplore = false
            canAdvanceDetailReady = false
            showItemDetail(show: false)
            
            self.checkNextItem(detail: false, completion: {[weak self] success in
                guard let `self` = self else { return }
                let _nextItem = self.nextFullItem
                if success {
                    PulseDatabase.getItem(self.allItems[self.itemIndex].itemID, completion: {[weak self] item, error in
                        guard let `self` = self else { return }
                        if let item = item {
                            self.nextFullItem = item
                        }
                        self.removeObserverIfNeeded()
                        self.currentItem = _nextItem
                    })
                } else {
                    self.currentItem = _nextItem
                }
            })
        }
            
        else {
            if (delegate != nil) {
                removeObserverIfNeeded()
                delegate?.noItemsToShow(self)
                performCleanup()
            }
        }
    }
    
    func handleDetailTap() {
        if (!tapReady || (!nextItemReady && canAdvanceDetailReady)) {
            //ignore tap
        }
        else if canAdvanceDetailReady {
            
            removeObserverIfNeeded()
            currentItem = nextDetailItem
            
        } else {
            // reset Item detail count and go to next Item
            itemDetailIndex = 0
            
            detailTap.isEnabled = false
            tap.isEnabled = true

            handleTap()
        }
    }
    
    private func clearAllItems() {
        removeObserverIfNeeded()
        qPlayer.removeAllItems()
        nextPlayerItem = nil
        currentItem = nil
        nextDetailItem = nil
        nextFullItem = nil
        canAdvanceReady = false
        canAdvanceDetailReady = false
        shouldShowExplore = false
        tapReady = false
        nextItemReady = false
        itemDetailIndex = 0
        contentOverlay?.clearPagers()
    }
    
    public func performCleanup() {        
        if !cleanupComplete {
            
            if timeObserver != nil {
                qPlayer.removeTimeObserver(timeObserver)
            }
            
            if tap != nil {
                view.removeGestureRecognizer(tap)
                tap.delegate = nil
                tap = nil
            }
            
            if detailTap != nil {
                view.removeGestureRecognizer(detailTap)
                detailTap.delegate = nil
                detailTap = nil
            }
            
            delegate = nil
            
            playedTillEndObserver = nil
            timeObserver = nil
            startCountdownObserver = nil
            
            currentItem = nil
            nextFullItem = nil
            nextDetailItem = nil
            nextPlayerItem = nil
            
            selectedChannel = nil
            selectedItem = nil
            itemDetail = []
            allItems = []
            
            if quickBrowse != nil {
                quickBrowse.delegate = nil
                quickBrowse = nil
            }
            
            if messageVC != nil {
                messageVC.delegate = nil
                messageVC = nil
            }
            
            if contentOverlay != nil {
                contentOverlay?.delegate = nil
                contentOverlay = nil
            }
            
            if imageView != nil {
                imageView.image = nil
                imageView = nil
            }
            
            qPlayer.removeAllItems()
            cleanupComplete = true
        }
    }
}
