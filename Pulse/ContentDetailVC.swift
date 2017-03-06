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

private let minItemsToShow = 4

protocol ItemDetailDelegate : class {
    func userClickedProfile()
    func userClickedProfileDetail()
    func userClosedProfile(_ : UIView)
    func userClickedBrowseItems()
    func userSelected(_ index : IndexPath)
    func userClickedExpandItem()
    func votedItem(_ _vote : VoteType)
    func userClickedSendMessage()
    func userClosedQuickBrowse()
    func userClickedSeeAll(items : [Item])
}

class ContentDetailVC: UIViewController, ItemDetailDelegate, UIGestureRecognizerDelegate, ParentDelegate {
    internal var itemIndex = 0
    internal var currentItem : Item?
    internal var nextItem : Item?

    public var selectedChannel : Channel!
    internal var allItems = [Item]() {
        didSet {
            if self.isViewLoaded {
                removeObserverIfNeeded()
                _hasUserBeenAskedQuestion = false
                watchedFullPreview ? loadWatchedPreviewItem() : loadItem(index: itemIndex)
            }
        }
    }
    lazy var itemDetailCollection = [Item]()
    lazy var itemCollectionIndex = 0

    fileprivate var quickBrowse: QuickBrowseVC!
    
    //if user has already watched the full preview, go directly to 2nd clip. set by sender - defaults to false
    internal var watchedFullPreview = false
    
    /** Media Player Items **/
    fileprivate var avPlayerLayer: AVPlayerLayer!
    fileprivate var contentOverlay : ContentOverlay!
    fileprivate static var qPlayer = AVQueuePlayer()
    fileprivate var currentPlayerItem : AVPlayerItem?
    fileprivate var imageView : UIImageView!
    
    /* bools to make sure can click next video and no errors from unhandled observers */
    fileprivate var _tapReady = false
    fileprivate var _nextItemReady = false
    fileprivate var _canAdvanceReady = false
    fileprivate var _canAdvanceDetailReady = false
    fileprivate var _hasUserBeenAskedQuestion = false
    fileprivate var _isObserving = false
    fileprivate var _isLoaded = false
    fileprivate var _isMenuShowing = false
    fileprivate var _isMiniProfileShown = false
    fileprivate var _isImageViewShown = false
    fileprivate var _isQuickBrowseShown = false
    fileprivate var _isExploring = false
    public var _isShowingIntro = false
    
    fileprivate var startObserver : AnyObject!
    fileprivate var playedTillEndObserver : Any!
    
    fileprivate var miniProfile : MiniProfile?
    lazy var blurBackground = UIVisualEffectView()
    
    weak var delegate : ContentDelegate!
    fileprivate var tap : UITapGestureRecognizer!
    fileprivate var detailTap : UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !_isLoaded {
            view.backgroundColor = UIColor.white
            
            tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            tap.cancelsTouchesInView = false
            tap.delegate = self
            view.addGestureRecognizer(tap)
            
            ContentDetailVC.qPlayer.actionAtItemEnd = AVPlayerActionAtItemEnd.none
            contentOverlay = ContentOverlay(frame: view.bounds, iconColor: .white, iconBackground: .black)
            contentOverlay.addClipTimerCountdown()
            contentOverlay.delegate = self
            
            avPlayerLayer = AVPlayerLayer(player: ContentDetailVC.qPlayer)
            view.layer.insertSublayer(avPlayerLayer, at: 0)
            view.insertSubview(contentOverlay, at: 2)
            avPlayerLayer.frame = view.bounds
            
            if (allItems.count > itemIndex) { //to make sure that allItems has been set
                watchedFullPreview ? loadWatchedPreviewItem() : loadItem(index: itemIndex)
            }
            
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(startCountdownTimer),
                                                   name: NSNotification.Name(rawValue: "PlaybackStartedNotification"),
                                                   object: currentPlayerItem)
            
            //align the timer to actually when the video starts
            let _ = ContentDetailVC.qPlayer.addBoundaryTimeObserver(forTimes: [NSValue(time: CMTimeMake(1, 20))],
                                                                 queue: nil,
                                                                 using: {
                                                                    NotificationCenter.default.post(name: Notification.Name(rawValue: "PlaybackStartedNotification"),
                                                                                                    object: self)}) as AnyObject!
            
            _isLoaded = true
        }
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
        
        if ContentDetailVC.qPlayer.currentItem != nil {
            ContentDetailVC.qPlayer.pause()
        }
        
        if ContentDetailVC.qPlayer.items().count > 0 {
            ContentDetailVC.qPlayer.removeAllItems()
        }
        
        itemIndex = 0
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    //so you cannot tap to next Item when miniprofile is shown - cancels all other gestures
    /**func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return _isMiniProfileShown ? true : false
    }**/
    
    fileprivate func loadWatchedPreviewItem() {
        Database.updateItemViewCount(itemID: allItems[itemIndex].itemID)
        currentItem = allItems[itemIndex]
        updateOverlayData(allItems[itemIndex])
        contentOverlay.addClipTimerCountdown()
        addExploreItemDetail(allItems[itemIndex].itemID)
                
        userClickedExpandItem()
    }
    
    fileprivate func loadItem(index: Int) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        _canAdvanceReady = false
        
        if index < allItems.count  {
            let _itemID = allItems[index].itemID
            addExploreItemDetail(_itemID)
            
            if !allItems[index].itemCreated {

                //fetch Item from DB first
                Database.getItem(_itemID, completion: { (item, error) in
                    if let item = item {
                        self.currentItem = item
                        self.addClip(item, completion: { success in
                            self.itemIndex = index
                            if self._canAdvance(self.itemIndex + 1) {
                                self.addNextClipToQueue(self.allItems[self.itemIndex + 1])
                                self._canAdvanceReady = true
                            } else {
                                self._canAdvanceReady = false
                            }
                        })
                        self.contentOverlay.addClipTimerCountdown()
                        self.updateOverlayData(item)
                    }
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                })
            } else {
                //Item is created so no need to fetch again
                currentItem = allItems[index]

                addClip(allItems[index], completion: { success in
                    if success {
                        self.itemIndex = index
                        
                        if self._canAdvance(self.itemIndex + 1) {
                            self.addNextClipToQueue(self.allItems[self.itemIndex + 1])
                            self._canAdvanceReady = true
                        } else {
                            self._canAdvanceReady = false
                        }
                    }
                })
                
                updateOverlayData(allItems[index])
                contentOverlay.addClipTimerCountdown()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        } else {
            if (delegate != nil) {
                delegate.noItemsToShow(self)
            }
        }
    }
    
    fileprivate func loadItemCollections(_ index : Int) {
        tap.isEnabled = false
        
        detailTap = UITapGestureRecognizer(target: self, action: #selector(handledetailTap))
        detailTap.cancelsTouchesInView = false
        detailTap.delegate = self
        view.addGestureRecognizer(detailTap)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        _canAdvanceDetailReady = false
        itemCollectionIndex = index

        addClip(itemDetailCollection[itemCollectionIndex], completion: { success in
            if self._canAdvanceItemDetail(self.itemCollectionIndex + 1) {
                
                self.addNextClipToQueue(self.itemDetailCollection[self.itemCollectionIndex + 1].itemID)
                self.itemCollectionIndex += 1
                self._canAdvanceDetailReady = true
            } else {
                self._canAdvanceDetailReady = false
                
                // done w/ Item detail - queue up next Item (outside of collection) if it exists
                if self._canAdvance(self.itemIndex + 1) {
                    self.addNextClipToQueue(self.allItems[self.itemIndex + 1])
                    self._canAdvanceReady = true
                } else {
                    self._canAdvanceReady = false
                }
            }
        
        })
        contentOverlay.addClipTimerCountdown()
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    fileprivate func addExploreItemDetail(_ _itemID : String) {
        if itemDetailCollection.count > 1 {
            contentOverlay.showExploreDetail()
        } else {
            Database.getItemCollection(_itemID, completion: {(hasDetail, itemCollection) in
                if hasDetail {
                    self.contentOverlay.showExploreDetail()
                    self.itemDetailCollection = itemCollection
                } else {
                    self.contentOverlay.hideExploreDetail()
                }
            })
        }
    }
    
    fileprivate func addClip(_ itemID : String, completion: @escaping (_ success : Bool) -> Void) {
        Database.getItem(itemID, completion: { (item, error) in
            if let item = item {
                self.addClip(item, completion: { success in
                    completion(success)
                })
            } else {
                GlobalFunctions.showErrorBlock("Error", erMessage: "Sorry there was an error getting this item")
                completion(false)
            }
        })
    }
    
    //adds the first clip to the Items
    fileprivate func addClip(_ item : Item, completion: @escaping (_ success : Bool) -> Void) {
        
        if !item.itemCreated {
            
            addClip(item.itemID, completion: { _ in })
            
        } else {
            guard let itemType = item.contentType else { return }
            
            currentItem = item //needed so we vote for the correct Item and update views for correct Item
            let itemURL = currentItem?.contentURL
            
            if itemType == .recordedVideo || itemType == .albumVideo {
                ContentDetailVC.qPlayer.pause()
                
                if let itemURL = itemURL  {
                    currentPlayerItem = AVPlayerItem(url: itemURL)

                    removeImageView()
                    
                    if let _currentPlayerItem = currentPlayerItem {
                        if ContentDetailVC.qPlayer.currentItem != nil {
                            ContentDetailVC.qPlayer.insert(_currentPlayerItem, after: ContentDetailVC.qPlayer.currentItem)
                            ContentDetailVC.qPlayer.advanceToNextItem()
                            addObserverForStatusReady()
                            completion(true)
                        } else {
                            ContentDetailVC.qPlayer.insert(_currentPlayerItem, after: nil)
                            addObserverForStatusReady()
                            completion(true)
                        }
                    }
                }
            } else if itemType == .recordedImage || itemType == .albumImage {
                DispatchQueue.global(qos: .background).async {
                    if let imageURL = itemURL, let _imageData = try? Data(contentsOf: imageURL), let image = UIImage(data: _imageData) {
                        self.showImageView(image)
                        if self._isShowingIntro {
                            self.delegate.removeIntro()
                            self._isShowingIntro = false
                        }
                    } else {
                        if self._isShowingIntro {
                            self.delegate.removeIntro()
                            self._isShowingIntro = false
                        }
                        self.handleTap()
                    }
                }
            }
        }
    }
    
    internal func startCountdownTimer() {
        if let currentItem = ContentDetailVC.qPlayer.currentItem {
            let duration = currentItem.duration
            contentOverlay.startTimer(duration.seconds)
        }
    }
    
    fileprivate func updateOverlayData(_ item : Item) {
        contentOverlay.setTitle(item.itemTitle ?? "")
        contentOverlay.setTagName(item.tag?.itemTitle)
        contentOverlay.clearButtons()
        
        if let user = item.user {
            contentOverlay.setUserName(user.name)
            contentOverlay.setUserSubtitle(user.shortBio)
            
            if let userPic = user.thumbPicImage {
                contentOverlay.setUserImage(userPic)
            } else if let uPicURL = user.thumbPic {
                DispatchQueue.main.async {
                    let _userImageData = try? Data(contentsOf: URL(string: uPicURL)!)
                    DispatchQueue.main.async(execute: {
                        if _userImageData != nil, item.user?.uID == self.currentItem?.user?.uID {
                            self.currentItem?.user?.thumbPicImage = UIImage(data: _userImageData!)
                            self.contentOverlay.setUserImage(self.currentItem?.user?.thumbPicImage)
                        }
                    })
                }
            }
        } else {
            contentOverlay.setUserImage(UIImage(named: "default-profile"))
            
            
            Database.getUser(item.itemUserID ?? "", completion: { (user, error) in
                if let user = user, self.currentItem?.itemUserID == user.uID {
                    self.currentItem?.user = user
                    self.contentOverlay.setUserName(user.name)
                    self.contentOverlay.setUserSubtitle(user.shortBio)
                    
                    if let _uPic = user.thumbPic {
                        
                        DispatchQueue.main.async {
                            let _userImageData = try? Data(contentsOf: URL(string: _uPic)!)
                            DispatchQueue.main.async(execute: {
                                if _userImageData != nil, item.user?.uID == self.currentItem?.user?.uID {
                                    self.currentItem?.user?.thumbPicImage = UIImage(data: _userImageData!)
                                    self.contentOverlay.setUserImage(self.currentItem?.user?.thumbPicImage)
                                }
                            })
                        }
                    }
                }
            })
        }
        
    }
    
    fileprivate func addNextClipToQueue(_ _nextItem : Item) {
        _nextItemReady = false
        
        if !_nextItem.itemCreated {
            addNextClipToQueue(_nextItem.itemID)
        } else {
            nextItem = _nextItem
            let itemURL = _nextItem.contentURL
            
            if nextItem!.contentType == .recordedVideo || self.nextItem!.contentType == .albumVideo {
                if let itemURL = itemURL  {
                    let nextPlayerItem = AVPlayerItem(url: itemURL)
                    if ContentDetailVC.qPlayer.currentItem != nil, ContentDetailVC.qPlayer.canInsert(nextPlayerItem, after: ContentDetailVC.qPlayer.currentItem) {
                        self.currentPlayerItem = nextPlayerItem
                        ContentDetailVC.qPlayer.insert(nextPlayerItem, after: ContentDetailVC.qPlayer.currentItem)
                        self._nextItemReady = true
                    } else if ContentDetailVC.qPlayer.canInsert(nextPlayerItem, after: nil) {
                        self.currentPlayerItem = nextPlayerItem
                        ContentDetailVC.qPlayer.insert(nextPlayerItem, after: nil)
                        self._nextItemReady = true
                    }
                }
            } else if nextItem!.contentType == .recordedImage || nextItem!.contentType == .albumImage {
                DispatchQueue.global(qos: .background).async {
                    if let imageURL = itemURL, let _imageData = try? Data(contentsOf: imageURL) {
                        self._nextItemReady = true
                        self.nextItem?.content = UIImage(data: _imageData)
                    }
                }
            }
        }
    }
    
    //used if we need to get the next Item from database - otherwise just get the URL
    fileprivate func addNextClipToQueue(_ nextItemID : String) {
        Database.getItem(nextItemID, completion: { (item, error) in
            if let item = item {
                self.addNextClipToQueue(item)
            } else {
                self.handleTap()
            }
        })
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "loadedTimeRanges" {
            switch ContentDetailVC.qPlayer.status {
            case AVPlayerStatus.readyToPlay:
                readyToPlay()
                break
            default: break
            }
        }
    }
    
    deinit {
        removeObserverIfNeeded()
    }
    
    fileprivate func readyToPlay() {
        DispatchQueue.main.async(execute: {
            ContentDetailVC.qPlayer.play()
        })
        
        if !_tapReady {
            _tapReady = true
        }
        
        if self._isShowingIntro {
            self.delegate.removeIntro()
            self._isShowingIntro = false
        }
    }
    
    fileprivate func addObserverForStatusReady() {
        if ContentDetailVC.qPlayer.currentItem != nil {
            ContentDetailVC.qPlayer.currentItem?.addObserver(self,
                                                          forKeyPath: "loadedTimeRanges",
                                                          options: NSKeyValueObservingOptions.new,
                                                          context: nil)
            
            playedTillEndObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                   object: ContentDetailVC.qPlayer.currentItem,
                                                   queue: nil, using: { (_) in
                if let currentItem = self.currentItem {
                    Database.updateItemViewCount(itemID: currentItem.itemID)
                }
            })
            
            _isObserving = true
        }
    }
    
    fileprivate func removeObserverIfNeeded() {
        if _isObserving, ContentDetailVC.qPlayer.currentItem != nil {
            ContentDetailVC.qPlayer.currentItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
            
            if playedTillEndObserver != nil {
                NotificationCenter.default.removeObserver(playedTillEndObserver)
            }
            
            _isObserving = false
        }
    }
    
    fileprivate func _canAdvance(_ index: Int) -> Bool{
        return index < allItems.count ? true : false
    }
    
    fileprivate func _canAdvanceItemDetail(_ index: Int) -> Bool{
        return index < itemDetailCollection.count ? true : false
    }
    
    //move the controls and filters to top layer
    fileprivate func showImageView(_ image : UIImage) {
        
        if _isImageViewShown {
            DispatchQueue.main.async {
                self.imageView.image = image
                self._tapReady = true
            }
        } else {
            DispatchQueue.main.async {
                self.imageView = UIImageView(frame: self.view.bounds)
                self.imageView.image = image
                self.imageView.contentMode = .scaleAspectFill
                self.view.insertSubview(self.imageView, at: 1)
                self._isImageViewShown = true
                self._tapReady = true
            }
        }
    }
    
    fileprivate func removeImageView() {
        if _isImageViewShown {
            imageView.image = nil
            imageView.removeFromSuperview()
            _isImageViewShown = false
        }
    }
    
    /* DELEGATE METHODS */
    func userClickedSendMessage() {
        guard let selectedUser = currentItem?.user, User.currentUser!.uID != selectedUser.uID else { return }

        let messageVC = MiniMessageVC()
        messageVC.selectedUser = selectedUser
        messageVC.delegate = self
        GlobalFunctions.addNewVC(messageVC, parentVC: self)
    }
    
    func votedItem(_ vote : VoteType) {
        if let _currentItem = currentItem {
            if vote == .favorite {
                Database.saveItem(_currentItem.itemID, completion: { success, error in
                    if success {
                        self.contentOverlay.itemSaved(type: vote)
                    }
                })
            } else {
                Database.addVote( vote, itemID: _currentItem.itemID, completion: { (success, error) in
                    if success {
                        self.contentOverlay.itemSaved(type: vote)
                    }
                })
            }
        }
    }
    
    func userClickedProfileDetail() {
        delegate.userClickedProfileDetail()
    }
    
    func userClickedProfile() {
        let _profileFrame = CGRect(x: view.bounds.width * (1/5), y: view.bounds.height * (1/4), width: view.bounds.width * (3/5), height: view.bounds.height * (1/2))
        
        /* BLUR BACKGROUND & DISABLE TAP WHEN MINI PROFILE IS SHOWING */
        blurBackground = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurBackground.frame = view.bounds
        view.addSubview(blurBackground)
        
        if let user = currentItem?.user {
            miniProfile = MiniProfile(frame: _profileFrame)
            miniProfile!.delegate = self
            miniProfile!.setNameLabel(user.name)
            miniProfile!.setTagLabel(user.shortBio)
            
            if let image = currentItem?.user?.thumbPicImage {
                miniProfile!.setProfileImage(image)
            }
            
            if !User.isLoggedIn() || User.currentUser?.uID == user.uID {
                miniProfile?.setProfileButton(disabled: true)
            }
            
            view.addSubview(miniProfile!)
            _isMiniProfileShown = true
        }
    }
    
    func userClosedProfile(_ _profileView : UIView) {
        _profileView.removeFromSuperview()
        blurBackground.removeFromSuperview()
        _isMiniProfileShown = false
    }
    
    func userClickedAddItem() {
        tap.isEnabled = true
        delegate.askUserQuestion()
    }
    
    //User selected an item
    func userSelected(_ index : IndexPath) {
        userClosedQuickBrowse()
        loadItem(index: (index as NSIndexPath).row)
    }
    
    func userClickedSeeAll(items : [Item]) {
        GlobalFunctions.dismissVC(quickBrowse)
        delegate.userClickedSeeAll(items: items)
        removeObserverIfNeeded()
    }
    
    func userClickedBrowseItems() {
        if ContentDetailVC.qPlayer.currentItem != nil {
            ContentDetailVC.qPlayer.pause()
        }
        
        quickBrowse = QuickBrowseVC()
        quickBrowse.view.frame = CGRect(x: 0, y: view.bounds.height * (2/3), width: view.bounds.width, height: view.bounds.height * (1/3))
        
        quickBrowse.delegate = self
        quickBrowse.selectedChannel = selectedChannel
        quickBrowse.allItems = allItems
        
        removeObserverIfNeeded()
        
        GlobalFunctions.addNewVC(quickBrowse, parentVC: self)
        
        _isQuickBrowseShown = true        
    }
    
    func userClosedQuickBrowse() {
        _isQuickBrowseShown = false
        GlobalFunctions.dismissVC(quickBrowse)
    }
    
    func userClickedExpandItem() {
        removeObserverIfNeeded()
        contentOverlay.updateExploreDetail()
        loadItemCollections(1)
        _isExploring = true
    }
    
    func dismiss(_ viewController: UIViewController) {
        GlobalFunctions.dismissVC(viewController)
    }
    
    /* MARK : HANDLE GESTURES */
    func handleTap() {
        //ignore tap if mini profile is shown or if quick browse is shown
        guard !_isMiniProfileShown, !_isQuickBrowseShown else {
            return
        }
        
        if (itemIndex == minItemsToShow && !_hasUserBeenAskedQuestion && _canAdvanceReady) { //ask user to Item the question
            if (delegate != nil) {
                ContentDetailVC.qPlayer.pause()
                _hasUserBeenAskedQuestion = true
                delegate.minItemsShown()
            }
        }
            
        else if (!_tapReady || (!_nextItemReady && _canAdvanceReady)) {
            //ignore tap
        }
        
        else if _canAdvanceReady {
            guard let _nextItem = nextItem else {
                return
            }
            
            itemDetailCollection.removeAll()
            contentOverlay.resetTimer()
            updateOverlayData(_nextItem)
            addExploreItemDetail(_nextItem.itemID)
            
            currentItem = _nextItem
            itemIndex += 1
            
            if _nextItem.contentType == .recordedImage || _nextItem.contentType == .albumImage {
                if let _image = _nextItem.content as? UIImage {
                    showImageView(_image)
                } else {
                    
                }
            } else if _nextItem.contentType == .recordedVideo || _nextItem.contentType == .albumVideo  {
                removeImageView()
                _tapReady = false
                ContentDetailVC.qPlayer.pause()
                removeObserverIfNeeded()
                
                if ContentDetailVC.qPlayer.items().count > 0 {
                    ContentDetailVC.qPlayer.advanceToNextItem()
                    addObserverForStatusReady()
                }
            }
            
            if _canAdvance(itemIndex + 1) {
                addNextClipToQueue(allItems[itemIndex + 1])
                _canAdvanceReady = true
            } else {
                _canAdvanceReady = false
            }
        }
        
        else {
            if (delegate != nil) {
                removeObserverIfNeeded()
                delegate.noItemsToShow(self)
            }
        }
    }

    func handledetailTap() {
        guard !_isMiniProfileShown, !_isQuickBrowseShown else {
            return
        }
        
        if (!_tapReady || (!_nextItemReady && _canAdvanceDetailReady)) {
            //ignore tap
        }
        else if _canAdvanceDetailReady {
            
            currentItem = nextItem
            itemCollectionIndex += 1

            if nextItem?.contentType == .recordedImage || nextItem?.contentType == .albumImage {
                if let _image = nextItem!.content as? UIImage {
                    showImageView(_image)
                }
            } else if nextItem?.contentType == .recordedVideo || nextItem?.contentType == .albumVideo  {
                removeImageView()
                _tapReady = false
                contentOverlay.resetTimer()
                ContentDetailVC.qPlayer.pause()
                removeObserverIfNeeded()
                
                if ContentDetailVC.qPlayer.items().count > 1 {
                    ContentDetailVC.qPlayer.advanceToNextItem()
                    addObserverForStatusReady()
                }
            }
            
            if _canAdvanceItemDetail(itemCollectionIndex) {
                addNextClipToQueue(itemDetailCollection[itemCollectionIndex])
                _canAdvanceDetailReady = true
            } else {
                _canAdvanceDetailReady = false
                
                // done w/ Item detail - queue up next Item if it exists
                if _canAdvance(itemIndex) {
                    addNextClipToQueue(allItems[itemIndex])
                    _canAdvanceReady = true
                } else {
                    _canAdvanceReady = false
                }
            }
        } else {
            // reset Item detail count and go to next Item
            itemCollectionIndex = 0
            handleTap()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
