//
//  ShowAnswerVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import AVFoundation

protocol answerDetailDelegate : class {
    func userClickedProfile()
    func userClosedMiniProfile(_ : UIView)
    func userClickedBrowseAnswers()
    func userClickedAddAnswer()
    func userClickedShowMenu()
    func userSelectedFromExploreQuestions(_ index : IndexPath)
    func userClickedExpandAnswer()
    func votedAnswer(_ _vote : AnswerVoteType)
    func userClickedSendMessage()
}

class ShowAnswerVC: UIViewController, answerDetailDelegate, UIGestureRecognizerDelegate {
    internal var answerIndex = 0
    internal var minAnswersToShow = 4
    
    internal var currentTag : Tag!
    internal var currentAnswer : Answer?
    internal var currentQuestion : Question!
    
    internal var allAnswers = [Answer]() {
        didSet {
            if self.isViewLoaded {
                removeObserverIfNeeded()
                answerIndex = 0
                _hasUserBeenAskedQuestion = false
                watchedFullPreview ? userClickedExpandAnswer() : loadAnswer(index: answerIndex)
            }
        }
    }
    
    //if user has already watched the full preview, go directly to 2nd clip. set by sender - defaults to false
    internal var watchedFullPreview = false
    
    fileprivate var nextAnswer : Answer?
    fileprivate var userForCurrentAnswer : User?
    
    fileprivate var currentUserImage : UIImage?
    fileprivate var avPlayerLayer: AVPlayerLayer!
    fileprivate var answerOverlay : AnswerOverlay!
    fileprivate static var qPlayer = AVQueuePlayer()
    fileprivate var currentPlayerItem : AVPlayerItem?
    fileprivate var imageView : UIImageView!
    
    /* bools to make sure can click next video and no errors from unhandled observers */
    fileprivate var _tapReady = false
    fileprivate var _nextItemReady = false
    fileprivate var _canAdvanceReady = false
    fileprivate var _canAdvanceDetailReady = false
    fileprivate var _returningFromDetail = false
    fileprivate var _hasUserBeenAskedQuestion = false
    fileprivate var _isObserving = false
    fileprivate var _isLoaded = false
    fileprivate var _isMenuShowing = false
    fileprivate var _isMiniProfileShown = false
    fileprivate var _isImageViewShown = false
    
    lazy var currentAnswerCollection = [String]()
    lazy var answerCollectionIndex = 0

    fileprivate var startObserver : AnyObject!
    fileprivate var miniProfile : MiniProfile?
    lazy var blurBackground = UIVisualEffectView()
    
    fileprivate var exploreAnswers : BrowseAnswersView?
    
    weak var delegate : childVCDelegate!
    fileprivate var tap : UITapGestureRecognizer!
    fileprivate var answerDetailTap : UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !_isLoaded {
            view.backgroundColor = UIColor.white
            tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            view.addGestureRecognizer(tap)
            ShowAnswerVC.qPlayer.actionAtItemEnd = AVPlayerActionAtItemEnd.none
            
            if (allAnswers.count > answerIndex) { //make sure we aren't at the end index
                answerOverlay = AnswerOverlay(frame: view.bounds, iconColor: .white, iconBackground: .black)
                answerOverlay.addClipTimerCountdown()
                answerOverlay.delegate = self
                
                watchedFullPreview ? loadWatchedPreviewAnswer() : loadAnswer(index: answerIndex)
                
                avPlayerLayer = AVPlayerLayer(player: ShowAnswerVC.qPlayer)
                view.layer.insertSublayer(avPlayerLayer, at: 0)
                view.insertSubview(answerOverlay, at: 2)
                avPlayerLayer.frame = view.bounds
            }
            
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(startCountdownTimer),
                                                   name: NSNotification.Name(rawValue: "PlaybackStartedNotification"),
                                                   object: currentPlayerItem)
            
            //align the timer to actually when the video starts
            let _ = ShowAnswerVC.qPlayer.addBoundaryTimeObserver(forTimes: [NSValue(time: CMTimeMake(1, 20))],
                                                                 queue: nil,
                                                                 using: {
                                                                    NotificationCenter.default.post(name: Notification.Name(rawValue: "PlaybackStartedNotification"),
                                                                                                    object: self)}) as AnyObject!
            
            _isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if ShowAnswerVC.qPlayer.currentItem != nil {
            ShowAnswerVC.qPlayer.pause()
        }
        
        if ShowAnswerVC.qPlayer.items().count > 0 {
            ShowAnswerVC.qPlayer.removeAllItems()
        }
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    //so you cannot tap to next answer when miniprofile is shown - cancels all other gestures
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if _isMiniProfileShown {
            return true
        } else {
            return false
        }
    }
    
    fileprivate func loadWatchedPreviewAnswer() {
        currentAnswer = allAnswers[answerIndex]
        updateOverlayData(allAnswers[answerIndex])
        answerOverlay.addClipTimerCountdown()
        addExploreAnswerDetail(allAnswers[answerIndex].aID)
        
        userClickedExpandAnswer()
    }
    
    fileprivate func loadAnswer(index: Int) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        _canAdvanceReady = false
        
        if index < allAnswers.count  {
            let _answerID = allAnswers[index].aID
            addExploreAnswerDetail(_answerID)
            
            if !allAnswers[index].aCreated {
                //answer is created so no need to fetch again
                Database.getAnswer(_answerID, completion: { (answer, error) in
                    self.currentAnswer = answer
                    self.addClip(answer, completion: { success in
                        self.answerIndex = index
                        if self._canAdvance(self.answerIndex + 1) {
                            self.addNextClipToQueue(self.allAnswers[self.answerIndex + 1])
                            self._canAdvanceReady = true
                        } else {
                            self._canAdvanceReady = false
                        }
                    })
                    self.answerOverlay.addClipTimerCountdown()
                    self.updateOverlayData(answer)
                    
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false

                })
            } else {
                //answer is created so no need to fetch again
                currentAnswer = allAnswers[index]
                addClip(allAnswers[index], completion: { success in
                    self.answerIndex = index
                    
                    if self._canAdvance(self.answerIndex + 1) {
                        self.addNextClipToQueue(self.allAnswers[self.answerIndex + 1])
                        self._canAdvanceReady = true
                    } else {
                        self._canAdvanceReady = false
                    }
                })
                
                updateOverlayData(allAnswers[index])
                answerOverlay.addClipTimerCountdown()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        } else {
            if (delegate != nil) {
                delegate.noAnswersToShow(self)
            }
        }
    }
    
    fileprivate func loadAnswerCollections(_ index : Int) {
        tap.isEnabled = false
        
        answerDetailTap = UITapGestureRecognizer(target: self, action: #selector(handleAnswerDetailTap))
        view.addGestureRecognizer(answerDetailTap)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        _canAdvanceDetailReady = false
        answerCollectionIndex = index

        addClip(currentAnswerCollection[answerCollectionIndex], completion: { success in
            if self._canAdvanceAnswerDetail(self.answerCollectionIndex + 1) {
                
                self.addNextClipToQueue(self.currentAnswerCollection[self.answerCollectionIndex + 1])
                self.answerCollectionIndex += 1
                self._canAdvanceDetailReady = true
            } else {
                self._canAdvanceDetailReady = false
                
                // done w/ answer detail - queue up next answer if it exists
                if self._canAdvance(self.answerIndex + 1) {
                    self.addNextClipToQueue(self.allAnswers[self.answerIndex + 1])
                    self._canAdvanceReady = true
                    self._returningFromDetail = true
                } else {
                    self._canAdvanceReady = false
                }
            }
        
        })
        answerOverlay.addClipTimerCountdown()
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    fileprivate func addExploreAnswerDetail(_ _answerID : String) {
        if currentAnswerCollection.count > 1 {
            self.answerOverlay.showExploreAnswerDetail()
        } else {
            Database.getAnswerCollection(_answerID, completion: {(hasDetail, answerCollection) in
                if hasDetail {
                    self.answerOverlay.showExploreAnswerDetail()
                    self.currentAnswerCollection = answerCollection!
                } else {
                    self.answerOverlay.hideExploreAnswerDetail()
                }
            })
        }
    }
    
    fileprivate func addClip(_ answerID : String, completion: @escaping (_ success : Bool) -> Void) {
        Database.getAnswer(answerID, completion: { (answer, error) in
            if error == nil {
                self.addClip(answer, completion: { success in
                    completion(success)
                })
            } else {
                GlobalFunctions.showErrorBlock("Error", erMessage: "Sorry there was an error getting this question")
                completion(false)
            }
        })
    }
    
    //adds the first clip to the answers
    fileprivate func addClip(_ answer : Answer, completion: @escaping (_ success : Bool) -> Void) {
        guard let answerType = answer.aType else {
            return
        }
        
        if answerType == .recordedVideo || answerType == .albumVideo {
            ShowAnswerVC.qPlayer.pause()
            
            Database.getAnswerURL(qID: answer.qID, fileID: answer.aID, completion: { (URL, error) in
                if (error != nil) {
                    GlobalFunctions.showErrorBlock("error getting video", erMessage: "Sorry there was an error! Please go to next answer")
                    self.delegate.removeQuestionPreview()
                    self.handleTap()
                } else {
                    self.currentPlayerItem = AVPlayerItem(url: URL!)
                    self.removeImageView()
                    if let _currentPlayerItem = self.currentPlayerItem {
                        
                        if ShowAnswerVC.qPlayer.currentItem != nil {
                            ShowAnswerVC.qPlayer.insert(_currentPlayerItem, after: ShowAnswerVC.qPlayer.currentItem)
                            ShowAnswerVC.qPlayer.advanceToNextItem()
                            self.addObserverForStatusReady()
                            completion(true)
                        } else {
                            ShowAnswerVC.qPlayer.insert(_currentPlayerItem, after: nil)
                            self.addObserverForStatusReady()
                            completion(true)
                        }
                        
                    }
                    
                }
            })
        } else if answerType == .recordedImage || answerType == .albumImage {
            Database.getAnswerImage(qID: answer.qID, fileID: answer.aID, maxImgSize: maxImgSize, completion: {(data, error) in
                if error != nil {
                    self.delegate.removeQuestionPreview()
                    self.handleTap()
                } else {
                    if let _image = GlobalFunctions.createImageFromData(data!) {
                        self.showImageView(_image)
                        self.delegate.removeQuestionPreview()
                    } else {
                        self.delegate.removeQuestionPreview()
                        self.handleTap()
                    }
                }
            })
        }
    }
    
    internal func startCountdownTimer() {
        if let currentItem = ShowAnswerVC.qPlayer.currentItem {
            let duration = currentItem.duration
            answerOverlay.startTimer(duration.seconds)
        }
    }
    
    fileprivate func updateOverlayData(_ answer : Answer) {
        Database.getUser(answer.uID!, completion: { (user, error) in
            if error == nil {
                self.userForCurrentAnswer = user
                
                if let _uName = user.name {
                    self.answerOverlay.setUserName(_uName.capitalized)
                }
                
                if let _uBio = user.shortBio {
                    self.answerOverlay.setUserSubtitle(_uBio.capitalized)
                } else if let _location = answer.aLocation {
                    self.answerOverlay.setUserSubtitle(_location.capitalized)
                }
                
                if let _uPic = user.thumbPic {
                    self.currentUserImage = nil
                    self.answerOverlay.setUserImage(self.currentUserImage)
                    
                    DispatchQueue.main.async {
                        let _userImageData = try? Data(contentsOf: URL(string: _uPic)!)
                        DispatchQueue.main.async(execute: {
                            if _userImageData != nil {
                                self.currentUserImage = UIImage(data: _userImageData!)
                                self.answerOverlay.setUserImage(self.currentUserImage)
                            }
                        })
                    }
                } else {
                    self.currentUserImage = UIImage(named: "default-profile")
                    self.answerOverlay.setUserImage(self.currentUserImage)
                }
            }
        })
        
        if let _aTag = currentTag.tagID {
            self.answerOverlay.setTagName(_aTag)
        }
        if let _qTitle = currentQuestion.qTitle {
            self.answerOverlay.setQuestion(_qTitle)
        }
    }
    
    fileprivate func addNextClipToQueue(_ _nextAnswer : Answer) {
        _nextItemReady = false
        
        nextAnswer = _nextAnswer
        
        if self.nextAnswer!.aType == .recordedVideo || self.nextAnswer!.aType == .albumVideo {

            Database.getAnswerURL(qID: _nextAnswer.qID, fileID : _nextAnswer.aID, completion: { (URL, error) in
                if (error != nil) {
                    GlobalFunctions.showErrorBlock("Download Error", erMessage: "Sorry! Mind tapping to next answer?")
                    self.handleTap()
                } else {
                    let nextPlayerItem = AVPlayerItem(url: URL!)
                    if ShowAnswerVC.qPlayer.currentItem != nil, ShowAnswerVC.qPlayer.canInsert(nextPlayerItem, after: ShowAnswerVC.qPlayer.currentItem) {
                        
                        self.currentPlayerItem = nextPlayerItem
                        ShowAnswerVC.qPlayer.insert(nextPlayerItem, after: ShowAnswerVC.qPlayer.currentItem)

                        self._nextItemReady = true
                    } else if ShowAnswerVC.qPlayer.canInsert(nextPlayerItem, after: nil) {

                        self.currentPlayerItem = nextPlayerItem
                        ShowAnswerVC.qPlayer.insert(nextPlayerItem, after: nil)

                        self._nextItemReady = true
                    }
                }
            })
        } else if nextAnswer!.aType == .recordedImage || nextAnswer!.aType == .albumImage {
            Database.getAnswerImage(qID: _nextAnswer.qID, fileID: _nextAnswer.aID, maxImgSize: maxImgSize, completion: {(data, error) in
                if error != nil {
                    GlobalFunctions.showErrorBlock("Download Error", erMessage: "Sorry! Mind tapping to next answer?")
                    self.handleTap()
                } else {
                    self._nextItemReady = true
                    self.nextAnswer?.aImage = UIImage(data: data!)
                }
            })
        }
    }
    
    //used if we need to get the next answer from database - otherwise just get the URL
    fileprivate func addNextClipToQueue(_ nextAnswerID : String) {
        Database.getAnswer(nextAnswerID, completion: { (answer, error) in
            if error != nil {
                self.handleTap()
            } else {
                self.addNextClipToQueue(answer)
            }
        })
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            switch ShowAnswerVC.qPlayer.status {
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
            ShowAnswerVC.qPlayer.play()
        })
        
        if !_tapReady {
            _tapReady = true
        }
        
        delegate.removeQuestionPreview()
    }
    
    fileprivate func addObserverForStatusReady() {
        if ShowAnswerVC.qPlayer.currentItem != nil {
            ShowAnswerVC.qPlayer.currentItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
            _isObserving = true
        }
    }
    
    fileprivate func removeObserverIfNeeded() {
        if _isObserving, ShowAnswerVC.qPlayer.currentItem != nil {
            ShowAnswerVC.qPlayer.currentItem?.removeObserver(self, forKeyPath: "status")
            _isObserving = false
        }
    }
    
    fileprivate func _canAdvance(_ index: Int) -> Bool{
        return index < allAnswers.count ? true : false
    }
    
    fileprivate func _canAdvanceAnswerDetail(_ index: Int) -> Bool{
        return index < currentAnswerCollection.count ? true : false
    }
    
    //move the controls and filters to top layer
    fileprivate func showImageView(_ image : UIImage) {
        if _isImageViewShown {
            imageView.image = image
            _tapReady = true

        } else {
            imageView = UIImageView(frame: view.bounds)
            imageView.image = image
            imageView.contentMode = .scaleAspectFill
            view.insertSubview(imageView, at: 1)
            _isImageViewShown = true
            _tapReady = true

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
        let messageVC = MessageVC()
        messageVC.toUser = userForCurrentAnswer
        
        if let currentUserImage = currentUserImage {
            messageVC.toUserImage = currentUserImage
        }
        
        navigationController?.pushViewController(messageVC, animated: true)
    }
    
    func votedAnswer(_ _vote : AnswerVoteType) {        
        if let _currentAnswer = currentAnswer {
            Database.addAnswerVote( _vote, aID: _currentAnswer.aID, completion: { (success, error) in })
        }
    }
    
    func userClickedProfile() {
        let _profileFrame = CGRect(x: view.bounds.width * (1/5), y: view.bounds.height * (1/4), width: view.bounds.width * (3/5), height: view.bounds.height * (1/2))
        
        /* BLUR BACKGROUND & DISABLE TAP WHEN MINI PROFILE IS SHOWING */
        blurBackground = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurBackground.frame = view.bounds
        view.addSubview(blurBackground)
        tap.isEnabled = false
        
        if let _userForCurrentAnswer = userForCurrentAnswer {
            miniProfile = MiniProfile(frame: _profileFrame)
            miniProfile!.delegate = self
            miniProfile!.setNameLabel(_userForCurrentAnswer.name)
            
            if _userForCurrentAnswer.bio != nil {
                miniProfile!.setBioLabel(_userForCurrentAnswer.bio)
            } else {
                Database.getUserPublicProperty(_userForCurrentAnswer.uID!, property: "bio", completion: {(bio) in
                    self.miniProfile!.setBioLabel(bio)
                })
            }
            
            miniProfile!.setTagLabel(_userForCurrentAnswer.shortBio)
            
            if let currentUserImage = currentUserImage {
                miniProfile!.setProfileImage(currentUserImage)
            }
            
            if !User.isLoggedIn() || User.currentUser?.uID == _userForCurrentAnswer.uID {
                miniProfile?.setMessageButton(disabled: true)
            }
            
            view.addSubview(miniProfile!)
            _isMiniProfileShown = true
        }
    }
    
    func userClosedMiniProfile(_ _profileView : UIView) {
        _profileView.removeFromSuperview()
        blurBackground.removeFromSuperview()
        _isMiniProfileShown = false
        tap.isEnabled = true
    }
    
    func userClickedAddAnswer() {
        tap.isEnabled = true
        exploreAnswers?.removeFromSuperview()
        delegate.askUserQuestion()
    }
    
    func userClickedBrowseAnswers() {
        removeObserverIfNeeded()
        tap.isEnabled = false
        
        exploreAnswers = BrowseAnswersView(frame: view.bounds, _currentQuestion: currentQuestion, _currentTag: currentTag)
        exploreAnswers!.delegate = self
        view.addSubview(exploreAnswers!)
        //add browse answers view and set question
    }
    
    func userSelectedFromExploreQuestions(_ index : IndexPath) {
        tap.isEnabled = true
        exploreAnswers?.removeFromSuperview()
        loadAnswer(index: (index as NSIndexPath).row)
    }
    
    func userClickedShowMenu() {
        answerOverlay.toggleMenu(show: _isMenuShowing ? false : true)
        _isMenuShowing = _isMenuShowing ? false : true
    }
    
    func userClickedExpandAnswer() {
        removeObserverIfNeeded()
        answerOverlay.updateExploreAnswerDetail()
        loadAnswerCollections(1)
    }
    
    /* MARK : HANDLE GESTURES */
    func handleTap() {
        if _isMiniProfileShown { //ignore tap
            return
        }
        
        if (answerIndex == minAnswersToShow && !_hasUserBeenAskedQuestion && _canAdvanceReady) { //ask user to answer the question
            if (delegate != nil) {
                ShowAnswerVC.qPlayer.pause()
                _hasUserBeenAskedQuestion = true
                delegate.minAnswersShown()
            }
        }
            
        else if (!_tapReady || (!_nextItemReady && _canAdvanceReady)) {
            //ignore tap
        }
        
        else if _canAdvanceReady {
            guard let _nextAnswer = nextAnswer else {
                return
            }
            
            currentAnswerCollection.removeAll()
            answerOverlay.resetTimer()
            updateOverlayData(_nextAnswer)
            addExploreAnswerDetail(_nextAnswer.aID)
            
            if _nextAnswer.aType == .recordedImage || _nextAnswer.aType == .albumImage {
                if let _image = _nextAnswer.aImage {
                    showImageView(_image)
                }
            } else if _nextAnswer.aType == .recordedVideo || _nextAnswer.aType == .albumVideo  {
                removeImageView()
                _tapReady = false
                ShowAnswerVC.qPlayer.pause()
                removeObserverIfNeeded()
                
                if ShowAnswerVC.qPlayer.items().count > 0 {
                    ShowAnswerVC.qPlayer.advanceToNextItem()
                    addObserverForStatusReady()
                }
            }
            
            currentAnswer = _nextAnswer
            answerIndex += 1
            
            if _canAdvance(answerIndex + 1) {
                addNextClipToQueue(allAnswers[answerIndex + 1])
                _canAdvanceReady = true
            } else {
                _canAdvanceReady = false
            }
        }
        
        else {
            if (delegate != nil) {
                removeObserverIfNeeded()
                delegate.noAnswersToShow(self)
            }
        }
    }

    func handleAnswerDetailTap() {
        if _isMiniProfileShown {
            return
        }
        
        if (!_tapReady || (!_nextItemReady && _canAdvanceDetailReady)) {
            //ignore tap
        }
        else if _canAdvanceDetailReady {
            
            if nextAnswer?.aType == .recordedImage || nextAnswer?.aType == .albumImage {
                if let _image = nextAnswer!.aImage {
                    showImageView(_image)
                }
            } else if nextAnswer?.aType == .recordedVideo || nextAnswer?.aType == .albumVideo  {
                removeImageView()
                _tapReady = false
                answerOverlay.resetTimer()
                ShowAnswerVC.qPlayer.pause()
                removeObserverIfNeeded()
                
                if ShowAnswerVC.qPlayer.items().count > 1 {
                    ShowAnswerVC.qPlayer.advanceToNextItem()
                    addObserverForStatusReady()
                }
            }
            
            currentAnswer = nextAnswer
            answerCollectionIndex += 1
            
            if _canAdvanceAnswerDetail(answerCollectionIndex) {
                addNextClipToQueue(currentAnswerCollection[answerCollectionIndex])
                _canAdvanceDetailReady = true
            } else {
                _canAdvanceDetailReady = false
                
                // done w/ answer detail - queue up next answer if it exists
                if _canAdvance(answerIndex) {
                    addNextClipToQueue(allAnswers[answerIndex])
                    _canAdvanceReady = true
                    _returningFromDetail = true
                } else {
                    _canAdvanceReady = false
                }
            }
        } else {
            // reset answer detail count and go to next answer
            answerCollectionIndex = 0
            handleTap()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
