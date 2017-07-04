//
//  ContentDetailVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import AVFoundation

class ContentDetailVC: PulseVC, ItemDetailDelegate, UIGestureRecognizerDelegate, ParentDelegate, ItemPreviewDelegate {
    public var selectedChannel : Channel!
    public var selectedItem : Item! //parentItem
    public weak var delegate : ContentDelegate?
    public var _isShowingIntro = false
    
    internal var allItems = [Item]() {
        didSet {
            if isViewLoaded, oldValue == [] {
                removeObserverIfNeeded()
                loadItem(index: itemIndex)
            }
        }
    }
    
    internal var itemIndex = 0
    internal var currentItem : Item? {
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
    internal var nextDetailItem : Item? {
        didSet {
            guard nextDetailItem != nil else { return }
            if nextDetailItem!.itemCreated {
                addNextItem(item: nextDetailItem!, completion: { _ in })
            } else {
                PulseDatabase.getItem(nextDetailItem!.itemID, completion: {[weak self] item, error in
                    guard let `self` = self else { return }
                    if let item = item {
                        self.nextDetailItem = item
                    }
                })
            }
        }
    }
    
    //next item in itemCollection
    internal var nextFullItem : Item? {
        didSet {
            guard let nextFullItem = nextFullItem else { return }
            if nextFullItem.itemCreated {
                PulseDatabase.getItemCollection(nextFullItem.itemID, completion: {[weak self] (success, items) in
                    guard let `self` = self else { return }
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
    
    fileprivate var canAdvanceReady = false
    fileprivate var canAdvanceDetailReady = false
    fileprivate var tapReady = false
    fileprivate var nextItemReady = false
    
    lazy var itemDetail = [Item]()
    lazy var itemDetailIndex = 0
    
    fileprivate var quickBrowse: QuickBrowseVC!
    
    /** Media Player Items **/
    fileprivate var avPlayerLayer: AVPlayerLayer!
    fileprivate var contentOverlay : ContentOverlay?
    fileprivate var qPlayer = AVQueuePlayer()
    fileprivate var nextPlayerItem : AVPlayerItem?
    fileprivate var imageView : UIImageView!
    
    /* bools to make sure can click next video and no errors from unhandled observers */
    fileprivate var isObserving = false
    fileprivate var isMiniProfileShown = false
    fileprivate var isImageViewShown = false
    fileprivate var isQuickBrowseShown = false
    fileprivate var shouldShowExplore = false
    fileprivate var cleanupComplete = false
    
    fileprivate var playedTillEndObserver : Any!
    fileprivate var timeObserver : Any!
    fileprivate var startCountdownObserver : Any!
    
    fileprivate var miniProfile : MiniPreview?
    fileprivate var tap : UITapGestureRecognizer!
    fileprivate var detailTap : UITapGestureRecognizer!
    
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
            
            if (allItems.count > itemIndex) { //to make sure that allItems has been set
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
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
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
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
        guard item.contentURL != nil else {
            completion(false)
            return
            //should not be needed as we always fetch item first but to ensure
        }
        
        guard let itemType = item.contentType else {
            completion(false)
            return
        }
        
        if itemType == .recordedVideo || itemType == .albumVideo {
            //first time a video is added - need to add it to queue first
            addVideoToQueue(itemURL: item.contentURL, completion: { success in
                completion(success)
            })
        } else if itemType == .recordedImage || itemType == .albumImage {
            addImageToQueue(item: item, itemURL: item.contentURL, completion: { success in
                completion(success)
            })
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
    fileprivate func advanceItem(completion: @escaping (_ success : Bool) -> Void) {
        
        guard let item = currentItem, let itemType = item.contentType else {
            completion(false)
            return
        }
        
        if itemType == .recordedVideo || itemType == .albumVideo {
            playItem(completion: { success in
                completion(success)
            })
        } else if itemType == .recordedImage || itemType == .albumImage {
            if let image = item.content as? UIImage {
                showImageView(image)
                if shouldShowExplore {
                    contentOverlay?.highlightExploreDetail()
                }
                completion(true)
            } else {
                completion(false)
            }
            
            hideIntro()
        }
    }
    
    fileprivate func playItem(completion: @escaping (_ success : Bool) -> Void) {
        removeImageView()
        qPlayer.pause()
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
    
    internal func startCountdownTimer() {
        if let currentItem = qPlayer.currentItem {
            let duration = currentItem.duration
            contentOverlay?.startTimer(duration.seconds)
        }
    }
    
    fileprivate func updateOverlayData(_ item : Item, updateUser: Bool = true) {
        contentOverlay?.resetTimer()
        contentOverlay?.setTitle(item.itemTitle)
        contentOverlay?.clearButtons()
        
        if updateUser, let user = item.user {
            contentOverlay?.setUserName(user.name)
            contentOverlay?.setUserSubtitle(user.shortBio)
            
            if let userPic = user.thumbPicImage {
                contentOverlay?.setUserImage(userPic)
            } else if let uPicURL = user.thumbPic {
                DispatchQueue.main.async {
                    let _userImageData = try? Data(contentsOf: URL(string: uPicURL)!)
                    DispatchQueue.main.async(execute: {[weak self] in
                        guard let `self` = self else { return }
                        if _userImageData != nil, item.user?.uID == self.currentItem?.user?.uID {
                            self.currentItem?.user?.thumbPicImage = UIImage(data: _userImageData!)
                            self.contentOverlay?.setUserImage(self.currentItem?.user?.thumbPicImage)
                        }
                    })
                }
            }
        } else if updateUser {
            contentOverlay?.setUserImage(UIImage(named: "default-profile"))
            
            PulseDatabase.getUser(item.itemUserID ?? "", completion: {[weak self] (user, error) in
                if let user = user, let `self` = self, self.currentItem?.itemUserID == user.uID {
                    self.currentItem?.user = user
                    self.contentOverlay?.setUserName(user.name)
                    self.contentOverlay?.setUserSubtitle(user.shortBio)
                    
                    if let _uPic = user.thumbPic {
                        
                        DispatchQueue.main.async {
                            let _userImageData = try? Data(contentsOf: URL(string: _uPic)!)
                            DispatchQueue.main.async(execute: {[weak self] in
                                guard let `self` = self else { return }
                                if _userImageData != nil, item.user?.uID == self.currentItem?.user?.uID {
                                    self.currentItem?.user?.thumbPicImage = UIImage(data: _userImageData!)
                                    self.contentOverlay?.setUserImage(self.currentItem?.user?.thumbPicImage)
                                }
                            })
                        }
                    }
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
        if _isShowingIntro {
            delegate?.removeIntro()
            _isShowingIntro = false
        }
    }
    
    
    fileprivate func canAdvance(_ index: Int) -> Bool{
        return index < allItems.count ? true : false
    }
    
    fileprivate func canAdvanceItemDetail(_ index: Int) -> Bool{
        return index < itemDetail.count ? true : false
    }
    
    //move the controls and filters to top layer
    fileprivate func showImageView(_ image : UIImage) {
        
        if isImageViewShown {
            DispatchQueue.main.async {[weak self] in
                guard let `self` = self else { return }
                self.imageView.image = image
                self.tapReady = true
            }
        } else {
            DispatchQueue.main.async {[weak self] in
                guard let `self` = self else { return }
                self.imageView = UIImageView(frame: self.view.bounds)
                self.imageView.image = image
                self.imageView.backgroundColor = UIColor.black
                self.imageView.contentMode = .scaleAspectFit
                self.view.insertSubview(self.imageView, at: 1)
                self.isImageViewShown = true
                self.tapReady = true
            }
        }
        
    }
    
    fileprivate func removeImageView() {
        if isImageViewShown {
            imageView.image = nil
            imageView.removeFromSuperview()
            isImageViewShown = false
        }
    }
    
    /* DELEGATE METHODS */
    func userClickedSendMessage() {
        guard PulseUser.isLoggedIn(), let selectedUser = currentItem?.user, PulseUser.currentUser.uID != selectedUser.uID else { return }
        
        let messageVC = MiniMessageVC()
        messageVC.selectedUser = selectedUser
        messageVC.delegate = self
        GlobalFunctions.addNewVC(messageVC, parentVC: self)
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
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if qPlayer.currentItem != nil {
            qPlayer.pause()
        }
        
        menu.addAction(UIAlertAction(title: "share \(selectedItem.type.rawValue.capitalized)", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.toggleLoading(show: true, message: "loading share options", showIcon: true)
            self.currentItem?.createShareLink(completion: {[weak self] link in
                guard let link = link, let `self` = self else { return }
                self.shareContent(shareType: "item", shareText: self.currentItem?.itemTitle ?? "", shareLink: link)
                self.toggleLoading(show: false, message: nil)
            })
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            menu.dismiss(animated: true, completion: nil)
            if self.qPlayer.currentItem != nil {
                self.qPlayer.play()
            }
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    func userClickedNextItem() {
        if shouldShowExplore, canAdvanceItemDetail(itemDetailIndex) {
            if let nextFullItem = nextFullItem {
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
        let _profileFrame = CGRect(x: view.bounds.width * (1/5), y: view.bounds.height * (1/4), width: view.bounds.width * (3/5), height: view.bounds.height * (1/2))
        
        /* BLUR BACKGROUND & DISABLE TAP WHEN MINI PROFILE IS SHOWING */
        blurViewBackground()
        
        if let user = currentItem?.user {
            miniProfile = MiniPreview(frame: _profileFrame)
            miniProfile!.delegate = self
            miniProfile!.setTitleLabel(user.name)
            miniProfile!.setMiniDescriptionLabel(user.shortBio)
            
            if let image = currentItem?.user?.thumbPicImage {
                miniProfile!.setBackgroundImage(image)
            }
            
            if !PulseUser.isLoggedIn() || PulseUser.currentUser.uID == user.uID {
                miniProfile?.setActionButton(disabled: true)
            }
            
            view.addSubview(miniProfile!)
            isMiniProfileShown = true
        }
    }
    
    func userClosedPreview(_ _profileView : UIView) {
        _profileView.removeFromSuperview()
        removeBlurBackground()
        isMiniProfileShown = false
    }
    
    //User selected an item
    func userSelected(_ index : IndexPath) {
        userClosedQuickBrowse()
        loadItem(index: (index as NSIndexPath).row)
    }
    
    func userClickedSeeAll(items : [Item]) {
        GlobalFunctions.dismissVC(quickBrowse)
        delegate?.userClickedSeeAll(items: items)
        removeObserverIfNeeded()
        
        isQuickBrowseShown = false
    }
    
    func userClickedBrowseItems() {
        if qPlayer.currentItem != nil {
            qPlayer.pause()
        }
        
        quickBrowse = QuickBrowseVC()
        quickBrowse.view.frame = CGRect(x: 0, y: view.bounds.height * (2/3), width: view.bounds.width, height: view.bounds.height * (1/3))
        
        quickBrowse.delegate = self
        quickBrowse.selectedChannel = selectedChannel
        quickBrowse.allItems = allItems
        
        removeObserverIfNeeded()
        
        GlobalFunctions.addNewVC(quickBrowse, parentVC: self)
        
        isQuickBrowseShown = true
    }
    
    func userClosedQuickBrowse() {
        isQuickBrowseShown = false
        GlobalFunctions.dismissVC(quickBrowse)
    }
    
    func userClickedExpandItem() {
        removeObserverIfNeeded()
    }
    
    func dismissVC(_ viewController: UIViewController) {
        if quickBrowse != nil, viewController == quickBrowse {
            quickBrowse.delegate = nil
        }
        
        GlobalFunctions.dismissVC(viewController)
    }
    
    /** 
     nextItemReady - there is something in the video queue
     tapReady - item is loaded & buffered
     canAdvanceReady - there are more items in collection
     **/
    
    /* MARK : HANDLE GESTURES */
    func handleTap() {
        //ignore tap if mini profile is shown or if quick browse is shown
        guard !isMiniProfileShown, !isQuickBrowseShown else {
            return
        }
        
        if (!tapReady || (!nextItemReady && canAdvanceReady)) {
            //ignore tap
        }
            
        else if canAdvanceReady {
            
            shouldShowExplore = false
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
        
        guard !isMiniProfileShown, !isQuickBrowseShown else {
            return
        }
        
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
            
            if miniProfile != nil {
                miniProfile?.delegate = nil
            }
            
            playedTillEndObserver = nil
            timeObserver = nil
            startCountdownObserver = nil
            
            currentItem = nil
            nextFullItem = nil
            nextDetailItem = nil
            selectedChannel = nil
            selectedItem = nil
            nextPlayerItem = nil
            itemDetail = []
            allItems = []
            
            if quickBrowse != nil {
                quickBrowse.delegate = nil
                quickBrowse = nil
            }
            miniProfile = nil
            
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
