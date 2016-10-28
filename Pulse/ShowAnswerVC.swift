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
    func userSelectedFromExploreQuestions(_ index : IndexPath)
    func userClickedExpandAnswer()
    func votedAnswer(_ _vote : AnswerVoteType)
    func userClickedSendMessage()
}

class ShowAnswerVC: UIViewController, answerDetailDelegate, UIGestureRecognizerDelegate {
    internal var currentQuestion : Question! {
        didSet {
            if self.isViewLoaded {
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
    fileprivate var nextAnswer : Answer?
    fileprivate var userForCurrentAnswer : User?
    
    fileprivate var currentUserImage : UIImage?
    fileprivate var _avPlayerLayer: AVPlayerLayer!
    fileprivate var _answerOverlay : AnswerOverlay!
    fileprivate var qPlayer = AVQueuePlayer()
    fileprivate var currentPlayerItem : AVPlayerItem?
    fileprivate var imageView : UIImageView!
    
    /* bools to make sure can click next video and no errors from unhandled observers */
    fileprivate var _tapReady = false
    fileprivate var _nextItemReady = false
    fileprivate var _canAdvanceReady = false
    fileprivate var _canAdvanceDetailReady = false
    fileprivate var _hasUserBeenAskedQuestion = false
    fileprivate var isObserving = false
    fileprivate var isLoaded = false
    fileprivate var _isMenuShowing = false
    fileprivate var _isMiniProfileShown = false
    fileprivate var _isImageViewShown = false
    
    lazy var currentAnswerCollection = [String]()
    lazy var answerCollectionIndex = 0

    fileprivate var startObserver : AnyObject!
    fileprivate var miniProfile : MiniProfile?
    lazy var _blurBackground = UIVisualEffectView()
    
    fileprivate var exploreAnswers : BrowseAnswersView?
    
    weak var delegate : childVCDelegate!
    fileprivate var tap : UITapGestureRecognizer!
    fileprivate var answerDetailTap : UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            view.backgroundColor = UIColor.white
            tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            view.addGestureRecognizer(tap)
            
            if (currentQuestion != nil){
                _loadAnswer(currentQuestion, index: answerIndex)
                _answerOverlay = AnswerOverlay(frame: view.bounds, iconColor: UIColor.black, iconBackground: UIColor.white)
                _answerOverlay.addClipTimerCountdown()
                _answerOverlay.delegate = self
                
                _avPlayerLayer = AVPlayerLayer(player: qPlayer)
                view.layer.insertSublayer(_avPlayerLayer, at: 0)
                view.insertSubview(_answerOverlay, at: 2)
                _avPlayerLayer.frame = view.bounds
                qPlayer.actionAtItemEnd = AVPlayerActionAtItemEnd.none
            }
            
            NotificationCenter.default.addObserver(self, selector: #selector(_startCountdownTimer), name: NSNotification.Name(rawValue: "PlaybackStartedNotification"), object: currentPlayerItem)
            
            startObserver = qPlayer.addBoundaryTimeObserver(forTimes: [NSValue(time: CMTimeMake(1, 20))], queue: nil, using: {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "PlaybackStartedNotification"), object: self)
            }) as AnyObject!
            isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if _isMiniProfileShown {
            return true
        } else {
            return false
        }
    }
    
    fileprivate func _loadAnswer(_ currentQuestion : Question, index: Int) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
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
                UIApplication.shared.isNetworkActivityIndicatorVisible = false

            })
        } else {
            if (delegate != nil) {
                delegate.noAnswersToShow(self)
            }
        }
    }
    
    fileprivate func _loadAnswerCollections(_ index : Int) {
        tap.isEnabled = false
        
        answerDetailTap = UITapGestureRecognizer(target: self, action: #selector(handleAnswerDetailTap))
        view.addGestureRecognizer(answerDetailTap)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        _canAdvanceDetailReady = false
        answerCollectionIndex = index

        _addClip(currentAnswerCollection[answerCollectionIndex])
        _answerOverlay.addClipTimerCountdown()
        
        if _canAdvanceAnswerDetail(answerCollectionIndex + 1) {
            _addNextClipToQueue(currentAnswerCollection[answerCollectionIndex + 1])
            answerCollectionIndex += 1
            _canAdvanceDetailReady = true
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    fileprivate func _addExploreAnswerDetail(_ _answerID : String) {
        
        Database.getAnswerCollection(_answerID, completion: {(hasDetail, answerCollection) in
            if hasDetail {
                self._answerOverlay.showExploreAnswerDetail()
                self.currentAnswerCollection = answerCollection!
            } else {
                self._answerOverlay.hideExploreAnswerDetail()
            }
        })
    }
    
    fileprivate func _addClip(_ answerID : String) {
        Database.getAnswer(answerID, completion: { (answer, error) in
            error == nil ? self._addClip(answer) : GlobalFunctions.showErrorBlock("Error", erMessage: "Sorry there was an error getting this question")
        })
    }
    
    //adds the first clip to the answers
    fileprivate func _addClip(_ answer : Answer) {
        guard let _answerType = answer.aType else {
            return
        }
        
        if _answerType == .recordedVideo || _answerType == .albumVideo {
            Database.getAnswerURL(answer.aID, completion: { (URL, error) in
                if (error != nil) {
                    GlobalFunctions.showErrorBlock("error getting video", erMessage: "Sorry there was an error! Please go to next answer")
                    self.delegate.removeQuestionPreview()
                    self.handleTap()
                } else {
                    self.currentPlayerItem = AVPlayerItem(url: URL!)
                    self.removeImageView()
                    if let _currentPlayerItem = self.currentPlayerItem {
                        self.qPlayer.replaceCurrentItem(with: _currentPlayerItem)
                        self.addObserverForStatusReady()
                    }
                }
            })
        } else if _answerType == .recordedImage || _answerType == .albumImage {
            Database.getImage(.Answers, fileID: answer.aID, maxImgSize: maxImgSize, completion: {(data, error) in
                if error != nil {
                    print("error getting image")
                    self.delegate.removeQuestionPreview()
                    self.handleTap()
                } else {
                    if let _image = GlobalFunctions.createImageFromData(data!) {
                        self.showImageView(_image)
                    } else {
                        print("error creating image from data")
                        self.delegate.removeQuestionPreview()
                        self.handleTap()
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
    
    fileprivate func _updateOverlayData(_ answer : Answer) {
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
                    self.currentUserImage = nil
                    self._answerOverlay.setUserImage(self.currentUserImage)
                    
                    DispatchQueue.main.async {
                        let _userImageData = try? Data(contentsOf: URL(string: _uPic)!)
                        DispatchQueue.main.async(execute: {
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
    
    fileprivate func _addNextClipToQueue(_ nextAnswerID : String) {
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
                            self.handleTap()
                        } else {
                            let nextPlayerItem = AVPlayerItem(url: URL!)
                            if self.qPlayer.canInsert(nextPlayerItem, after: nil) {
                                self.qPlayer.insert(nextPlayerItem, after: nil)
                                self._nextItemReady = true
                            }
                        }
                    })
                } else if self.nextAnswer!.aType == .recordedImage || self.nextAnswer!.aType == .albumImage {
                    Database.getImage(.Answers, fileID: nextAnswerID, maxImgSize: maxImgSize, completion: {(data, error) in
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
        })
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            switch self.qPlayer.status {
            case AVPlayerStatus.readyToPlay:
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
    
    fileprivate func removeObserverIfNeeded() {
        if isObserving {
            qPlayer.currentItem!.removeObserver(self, forKeyPath: "status")
            isObserving = false
        }
    }
    
    fileprivate func addObserverForStatusReady() {
        if qPlayer.currentItem != nil {
            qPlayer.currentItem!.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
            isObserving = true
        }
    }
    
    fileprivate func _canAdvance(_ index: Int) -> Bool{
        return index < currentQuestion.totalAnswers() ? true : false
    }
    
    fileprivate func _canAdvanceAnswerDetail(_ index: Int) -> Bool{
        print("checking if can can advance with index \(index) and total count \(currentAnswerCollection.count)")
        return index < currentAnswerCollection.count ? true : false
    }
    
    //move the controls and filters to top layer
    fileprivate func showImageView(_ image : UIImage) {
        if _isImageViewShown {
            imageView.image = image
        } else {
            imageView = UIImageView(frame: view.bounds)
            imageView.image = image
            imageView.contentMode = .scaleAspectFill
            view.insertSubview(imageView, at: 1)
            _isImageViewShown = true
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
        _blurBackground = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        _blurBackground.frame = view.bounds
        view.addSubview(_blurBackground)
        tap.isEnabled = false
        
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
            
            if !User.isLoggedIn() || User.currentUser?.uID == _userForCurrentAnswer.uID {
                miniProfile?.setMessageButton(disabled: true)
            }
            
            view.addSubview(miniProfile!)
            _isMiniProfileShown = true
        }
    }
    
    func userClosedMiniProfile(_ _profileView : UIView) {
        _profileView.removeFromSuperview()
        _blurBackground.removeFromSuperview()
        _isMiniProfileShown = false
        tap.isEnabled = true
    }
    
    func userClickedAddAnswer() {
        tap.isEnabled = true
        exploreAnswers?.removeFromSuperview()
        delegate.askUserQuestion()
    }
    
    func userClickedExploreAnswers() {
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
        _loadAnswer(currentQuestion, index: (index as NSIndexPath).row)
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
