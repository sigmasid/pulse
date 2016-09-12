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
    func userClickedExploreAnswers()
    func userClickedAddAnswer()
    func userClickedShowMenu()
    func userSelectedFromExploreQuestions(index : NSIndexPath)
    func userClickedExpandAnswer()
    func votedAnswer(_vote : AnswerVoteType)
}

class ShowAnswerVC: UIViewController, answerDetailDelegate, UIGestureRecognizerDelegate {
    internal var currentQuestion : Question! {
        didSet {
            if self.isViewLoaded() {
                removeObserverIfNeeded()
                answerIndex = 0
                _hasUserBeenAskedQuestion = false
                _loadAnswer(currentQuestion, index: answerIndex)
            }
        }
    }
    
    internal var answerIndex = 0
    internal var minAnswersToShow = 3
    
    internal var currentTag : Tag!
    internal var currentAnswer : Answer?
    private var nextAnswer : Answer?
    private var userForCurrentAnswer : User?
    
    private var currentUserImage : UIImage?
    private var _avPlayerLayer: AVPlayerLayer!
    private var _answerOverlay : AnswerOverlay!
    private var qPlayer = AVQueuePlayer()
    private var currentPlayerItem : AVPlayerItem?
    private var imageView : UIImageView!
    
    /* bools to make sure can click next video and no errors from unhandled observers */
    private var _tapReady = false
    private var _nextItemReady = false
    private var _canAdvanceReady = false
    private var _canAdvanceDetailReady = false
    private var _hasUserBeenAskedQuestion = false
    private var isObserving = false
    private var isLoaded = false
    private var _isMenuShowing = false
    private var _isMiniProfileShown = false
    private var _isImageViewShown = false
    
    lazy var currentAnswerCollection = [String]()
    lazy var answerCollectionIndex = 0

    private var startObserver : AnyObject!
    private var miniProfile : MiniProfile?
    lazy var _blurBackground = UIVisualEffectView()
    
    private var exploreAnswers : BrowseAnswersView?
    
    weak var delegate : childVCDelegate!
    private var tap : UITapGestureRecognizer!
    private var answerDetailTap : UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            print("went into view will appear")
            view.backgroundColor = UIColor.whiteColor()
            tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            view.addGestureRecognizer(tap)
            
            if (currentQuestion != nil){
                _loadAnswer(currentQuestion, index: answerIndex)
                _answerOverlay = AnswerOverlay(frame: view.bounds, iconColor: UIColor.blackColor(), iconBackground: UIColor.whiteColor())
                _answerOverlay.addClipTimerCountdown()
                _answerOverlay.delegate = self
                
                _avPlayerLayer = AVPlayerLayer(player: qPlayer)
                view.layer.insertSublayer(_avPlayerLayer, atIndex: 0)
                view.insertSubview(_answerOverlay, atIndex: 2)
                _avPlayerLayer.frame = view.bounds
                qPlayer.actionAtItemEnd = AVPlayerActionAtItemEnd.None
            }
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(_startCountdownTimer), name: "PlaybackStartedNotification", object: currentPlayerItem)
            
            startObserver = qPlayer.addBoundaryTimeObserverForTimes([NSValue(CMTime: CMTimeMake(1, 20))], queue: nil, usingBlock: {
                NSNotificationCenter.defaultCenter().postNotificationName("PlaybackStartedNotification", object: self)
            })
            isLoaded = true
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if _isMiniProfileShown {
            return true
        } else {
            return false
        }
    }
    
    private func _loadAnswer(currentQuestion : Question, index: Int) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        _canAdvanceReady = false
        
        if let _answerID = currentQuestion.qAnswers?[index] {
            _addExploreAnswerDetail(_answerID)
            
            Database.getAnswer(_answerID, completion: { (answer, error) in
                self.currentAnswer = answer
                self._addClip(answer)
                self._updateOverlayData(answer)
                self._answerOverlay.addClipTimerCountdown()
                self.answerIndex = index

                if self._canAdvance(self.answerIndex + 1) {
                    self._addNextClipToQueue(self.currentQuestion.qAnswers![self.answerIndex + 1])
                    self.answerIndex += 1
                    self._canAdvanceReady = true
                } else {
                    self.answerIndex += 1
                    self._canAdvanceReady = false
                }
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false

            })
        } else {
            if (delegate != nil) {
                delegate.noAnswersToShow(self)
            }
        }
    }
    
    private func _loadAnswerCollections(index : Int) {
        tap.enabled = false
        
        answerDetailTap = UITapGestureRecognizer(target: self, action: #selector(handleAnswerDetailTap))
        view.addGestureRecognizer(answerDetailTap)
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        _canAdvanceDetailReady = false
        answerCollectionIndex = index

        _addClip(currentAnswerCollection[answerCollectionIndex])
        _answerOverlay.addClipTimerCountdown()
        
        if _canAdvanceAnswerDetail(answerCollectionIndex + 1) {
            _addNextClipToQueue(currentAnswerCollection[answerCollectionIndex + 1])
            answerCollectionIndex += 1
            _canAdvanceDetailReady = true
        }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    private func _addExploreAnswerDetail(_answerID : String) {
        
        Database.getAnswerCollection(_answerID, completion: {(hasDetail, answerCollection) in
            if hasDetail {
                self._answerOverlay.showExploreAnswerDetail()
                self.currentAnswerCollection = answerCollection!
            } else {
                self._answerOverlay.hideExploreAnswerDetail()
            }
        })
    }
    
    private func _addClip(answerID : String) {
        Database.getAnswer(answerID, completion: { (answer, error) in
            if error != nil {
                print("error getting question")
            } else {
                self._addClip(answer)
            }
        })
    }
    
    private func _addClip(answer : Answer) {
        guard let _answerType = answer.aType else {
            return
        }
        
        if _answerType == .recordedVideo || _answerType == .albumVideo {
            Database.getAnswerURL(answer.aID, completion: { (URL, error) in
                if (error != nil) {
                    GlobalFunctions.showErrorBlock("error getting video", erMessage: "Sorry there was an error! Please go to next answer")
                } else {
                    self.currentPlayerItem = AVPlayerItem(URL: URL!)
                    self.removeImageView()
                    if let _currentPlayerItem = self.currentPlayerItem {
                        self.qPlayer.replaceCurrentItemWithPlayerItem(_currentPlayerItem)
                        self.addObserverForStatusReady()
                    }
                }
            })
        } else if _answerType == .recordedImage || _answerType == .albumImage {
            Database.getImage(.Answers, fileID: answer.aID, maxImgSize: maxImgSize, completion: {(data, error) in
                if error != nil {
                    print("error getting image")
                } else {
                    if let _image = GlobalFunctions.createImageFromData(data!) {
                        self.showImageView(_image)
                    }
                }
            })
        }
    }
    
    internal func _startCountdownTimer() {
        if let _currentItem = qPlayer.currentItem {
            let duration = _currentItem.duration
            _answerOverlay.startTimer(duration.seconds)
        }
    }
    
    private func _updateOverlayData(answer : Answer) {
        Database.getUser(answer.uID!, completion: { (user, error) in
            if error == nil {
                self.userForCurrentAnswer = user
                
                if let _uName = user.name {
                    self._answerOverlay.setUserName(_uName)
                }
                
                if let _uBio = user.shortBio {
                    self._answerOverlay.setUserSubtitle(_uBio)
                } else if let _location = answer.aLocation {
                    self._answerOverlay.setUserSubtitle(_location)
                }
                
                if let _uPic = user.thumbPic {
                    self.currentUserImage = UIImage(named: "default-profile")
                    self._answerOverlay.setUserImage(self.currentUserImage)
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                        let _userImageData = NSData(contentsOfURL: NSURL(string: _uPic)!)
                        dispatch_async(dispatch_get_main_queue(), {
                            if _userImageData != nil {
                                self.currentUserImage = UIImage(data: _userImageData!)
                                self._answerOverlay.setUserImage(self.currentUserImage)
                            }
                        })
                    }
                } else {
                    self.currentUserImage = UIImage(named: "default-profile")
                    self._answerOverlay.setUserImage(self.currentUserImage)
                }
            }
        })
        
        if let _aTag = currentTag.tagID {
            self._answerOverlay.setTagName(_aTag)
        }
        if let _qTitle = currentQuestion.qTitle {
            self._answerOverlay.setQuestion(_qTitle)
        }
    }
    
    private func _addNextClipToQueue(nextAnswerID : String) {
        _nextItemReady = false
        
        Database.getAnswer(nextAnswerID, completion: { (answer, error) in
            if error != nil {
                print("error getting answer")
            } else {
                self.nextAnswer = answer
                
                if self.nextAnswer!.aType == .recordedVideo || self.nextAnswer!.aType == .albumVideo {
                    Database.getAnswerURL(nextAnswerID, completion: { (URL, error) in
                        if (error != nil) {
                            GlobalFunctions.showErrorBlock("Download Error", erMessage: "Sorry! Mind tapping to next answer?")
                        } else {
                            let nextPlayerItem = AVPlayerItem(URL: URL!)
                            if self.qPlayer.canInsertItem(nextPlayerItem, afterItem: nil) {
                                self.qPlayer.insertItem(nextPlayerItem, afterItem: nil)
                                self._nextItemReady = true
                            }
                        }
                    })
                } else if self.nextAnswer!.aType == .recordedImage || self.nextAnswer!.aType == .albumImage {
                    Database.getImage(.Answers, fileID: nextAnswerID, maxImgSize: maxImgSize, completion: {(data, error) in
                        if error != nil {
                            GlobalFunctions.showErrorBlock("Download Error", erMessage: "Sorry! Mind tapping to next answer?")
                        } else {
                            self._nextItemReady = true
                            self.nextAnswer?.aImage = UIImage(data: data!)
                        }
                    })
                }
            }
        })
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "status" {
            switch self.qPlayer.status {
            case AVPlayerStatus.ReadyToPlay:
                qPlayer.play()
                if !_tapReady {
                    _tapReady = true
                }
                
                delegate.removeQuestionPreview()
                break
            default: break
            }
        }
    }
    
    deinit {
        removeObserverIfNeeded()
    }
    
    private func removeObserverIfNeeded() {
        if isObserving {
            qPlayer.currentItem!.removeObserver(self, forKeyPath: "status")
            isObserving = false
        }
    }
    
    private func addObserverForStatusReady() {
        if qPlayer.currentItem != nil {
            qPlayer.currentItem!.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: nil)
            isObserving = true
        }
    }
    
    private func _canAdvance(index: Int) -> Bool{
        return index < currentQuestion.totalAnswers() ? true : false
    }
    
    private func _canAdvanceAnswerDetail(index: Int) -> Bool{
        print("checking if can can advance with index \(index) and total count \(currentAnswerCollection.count)")
        return index < currentAnswerCollection.count ? true : false
    }
    
    //move the controls and filters to top layer
    private func showImageView(image : UIImage) {
        if _isImageViewShown {
            imageView.image = image
        } else {
            imageView = UIImageView(frame: view.bounds)
            imageView.image = image
            imageView.contentMode = .ScaleAspectFill
            view.insertSubview(imageView, atIndex: 1)
            _isImageViewShown = true
        }
    }
    
    private func removeImageView() {
        if _isImageViewShown {
            imageView.image = nil
            imageView.removeFromSuperview()
            _isImageViewShown = false
        }
    }
    
    /* DELEGATE METHODS */
    func votedAnswer(_vote : AnswerVoteType) {        
        if let _currentAnswer = currentAnswer {
            Database.addAnswerVote( _vote, aID: _currentAnswer.aID, completion: { (success, error) in
                if success {
                    print("vote registered")
                } else {
                    print(error!.localizedDescription)
                }
            })
        }
    }
    
    func userClickedProfile() {
        let _profileFrame = CGRectMake(view.bounds.width * (1/5), view.bounds.height * (1/4), view.bounds.width * (3/5), view.bounds.height * (1/2))
        
        /* BLUR BACKGROUND & DISABLE TAP WHEN MINI PROFILE IS SHOWING */
        _blurBackground = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        _blurBackground.frame = view.bounds
        view.addSubview(_blurBackground)
        tap.enabled = false
        
        if let _userForCurrentAnswer = userForCurrentAnswer {
            miniProfile = MiniProfile(frame: _profileFrame)
            miniProfile!.delegate = self
            miniProfile!.setNameLabel(_userForCurrentAnswer.name)
            
            if _userForCurrentAnswer.bio != nil {
                miniProfile!.setBioLabel(_userForCurrentAnswer.bio)
            } else {
                Database.getUserProperty(_userForCurrentAnswer.uID!, property: "bio", completion: {(bio) in
                    self.miniProfile!.setBioLabel(bio)
                })
            }
            
            miniProfile!.setTagLabel(_userForCurrentAnswer.shortBio)
            
            if let currentUserImage = currentUserImage {
                miniProfile!.setProfileImage(currentUserImage)
            }
            view.addSubview(miniProfile!)
            _isMiniProfileShown = true
        }
    }
    
    func userClosedMiniProfile(_profileView : UIView) {
        _profileView.removeFromSuperview()
        _blurBackground.removeFromSuperview()
        _isMiniProfileShown = false
        tap.enabled = true
    }
    
    func userClickedAddAnswer() {
        tap.enabled = true
        exploreAnswers?.removeFromSuperview()
        delegate.askUserQuestion()
    }
    
    func userClickedExploreAnswers() {
        removeObserverIfNeeded()
        tap.enabled = false
        
        exploreAnswers = BrowseAnswersView(frame: view.bounds, _currentQuestion: currentQuestion, _currentTag: currentTag)
        exploreAnswers!.delegate = self
        view.addSubview(exploreAnswers!)
        //add browse answers view and set question
    }
    
    func userSelectedFromExploreQuestions(index : NSIndexPath) {
        tap.enabled = true
        exploreAnswers?.removeFromSuperview()
        _loadAnswer(currentQuestion, index: index.row)
    }
    
    func userClickedShowMenu() {
        _answerOverlay.toggleMenu()
    }
    
    func userClickedExpandAnswer() {
        removeObserverIfNeeded()
        _answerOverlay.updateExploreAnswerDetail()
        _loadAnswerCollections(1)
    }
    
    /* MARK : HANDLE GESTURES */
    func handleTap() {
        if _isMiniProfileShown { //ignore tap
            return
        }
        
        print("answer index is \(answerIndex), can advance \(_canAdvanceReady), tap ready \(_tapReady), next item ready \(_nextItemReady)")
        if (answerIndex == minAnswersToShow && !_hasUserBeenAskedQuestion && _canAdvanceReady) { //ask user to answer the question
            if (delegate != nil) {
                qPlayer.pause()
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
            
            _answerOverlay.resetTimer()
            _updateOverlayData(_nextAnswer)
            _addExploreAnswerDetail(_nextAnswer.aID)
            
            if _nextAnswer.aType == .recordedImage || _nextAnswer.aType == .albumImage {
                if let _image = _nextAnswer.aImage {
                    showImageView(_image)
                }
            } else if _nextAnswer.aType == .recordedVideo || _nextAnswer.aType == .albumVideo  {

                removeImageView()
                _tapReady = false
                qPlayer.pause()
                removeObserverIfNeeded()
                qPlayer.advanceToNextItem()
                addObserverForStatusReady()
            }
        
            currentAnswer = _nextAnswer
            answerIndex += 1
            
            if _canAdvance(answerIndex) {
                _addNextClipToQueue(currentQuestion.qAnswers![answerIndex])
                _canAdvanceReady = true
            } else {
                _canAdvanceReady = false
            }
        }
        
        else {
            if (delegate != nil) {
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
                _answerOverlay.resetTimer()
                qPlayer.pause()
                
                removeObserverIfNeeded()
                qPlayer.advanceToNextItem()
                addObserverForStatusReady()
            }
            
            currentAnswer = nextAnswer
            answerCollectionIndex += 1
            
            if _canAdvanceAnswerDetail(answerCollectionIndex) {
                _addNextClipToQueue(currentAnswerCollection[answerCollectionIndex])
                _canAdvanceDetailReady = true
            } else {
                _canAdvanceDetailReady = false
                
                // done w/ answer detail - queue up next answer if it exists
                if _canAdvance(answerIndex) {
                    _addNextClipToQueue(currentQuestion.qAnswers![answerIndex])
                    _canAdvanceReady = true
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
