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
    func userSelectedFromExploreQuestions(index : NSIndexPath)
}

class ShowAnswerVC: UIViewController, answerDetailDelegate {
    internal var currentQuestion : Question! {
        didSet {
            if self.isViewLoaded() {
                removeObserverIfNeeded()
                delegate.showQuestionPreviewOverlay()
                answerIndex = 0
                _CameraShown = false
                _loadAnswer(currentQuestion, index: answerIndex)
            }
        }
    }
    
    internal var currentTag : Tag!
    internal var answerIndex = 0
    
    internal var minAnswersToShow = 3
    internal var currentAnswer : Answer?
    private var userForCurrentAnswer : User?
    private var currentUserImage : UIImage?
    
    private var nextAnswer : Answer?
    private var _avPlayerLayer: AVPlayerLayer!
    private var _answerOverlay : AnswerOverlay!
    private var qPlayer = AVQueuePlayer()
    private var currentPlayerItem : AVPlayerItem?
    
    private var _TapReady = false
    private var _NextItemReady = false
    private var _CanAdvanceReady = false
    private var _CameraShown = false
    
    private var isObserving = false
    private var startObserver : AnyObject!
    private var miniProfile : MiniProfile?
    private var _isMiniProfileShown = false
    
    private var exploreAnswers : BrowseAnswersView?
    
    weak var delegate : childVCDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
//        view.addGestureRecognizer(tap)
        
        if (currentQuestion != nil){
            _loadAnswer(currentQuestion, index: answerIndex)
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(_startCountdownTimer), name: "PlaybackStartedNotification", object: currentPlayerItem)

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        _answerOverlay = AnswerOverlay(frame: view.bounds)
        _avPlayerLayer = AVPlayerLayer(player: qPlayer)
        
        view.layer.insertSublayer(_avPlayerLayer, atIndex: 0)
        view.insertSubview(_answerOverlay, atIndex: 1)
        
        _answerOverlay.addIcon(iconColor, backgroundColor: iconBackgroundColor)
        _answerOverlay.addVideoTimerCountdown()
        _answerOverlay.delegate = self
        _avPlayerLayer.frame = view.bounds
        qPlayer.actionAtItemEnd = AVPlayerActionAtItemEnd.None
        
        startObserver = qPlayer.addBoundaryTimeObserverForTimes([NSValue(CMTime: CMTimeMake(1, 20))], queue: nil, usingBlock: {
            NSNotificationCenter.defaultCenter().postNotificationName("PlaybackStartedNotification", object: self)
        })
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    private func _loadAnswer(currentQuestion : Question, index: Int) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        if let _answerID = currentQuestion.qAnswers?[index] {
            Database.getAnswer(_answerID, completion: { (answer, error) in
                self.currentAnswer = answer
                self._addVideo(answer.aID)
                self._updateOverlayData(answer)
                self._answerOverlay.addVideoTimerCountdown()
                self.answerIndex = index

                if self._canAdvance(self.answerIndex + 1) {
                    self._addNextVideoToQueue(self.currentQuestion.qAnswers![self.answerIndex + 1])
                    self.answerIndex += 1
                    self._CanAdvanceReady = true
                }
            })
        } else {
            if (delegate != nil) {
                delegate.noAnswersToShow(self)
            }
        }
    }
    
    private func _addVideo(answerID : String) {
        Database.getAnswerURL(answerID, completion: { (URL, error) in
            if error != nil {
                GlobalFunctions.showErrorBlock("Error Getting Answers", erMessage: error!.localizedDescription)
            } else {
                self.currentPlayerItem = AVPlayerItem(URL: URL!)
                if let _currentPlayerItem = self.currentPlayerItem {
                    self.qPlayer.replaceCurrentItemWithPlayerItem(_currentPlayerItem)
                    self.delegate.hasAnswersToShow()
                    self.addObserverForStatusReady()
                }
            }
        })
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
                if let _uPic = user.profilePic {
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
        if let _location = answer.aLocation {
            self._answerOverlay.setUserLocation(_location)
        }
    }
    
    private func _addNextVideoToQueue(nextAnswerID : String) {
        _NextItemReady = false
        
        Database.getAnswer(nextAnswerID, completion: { (answer, error) in
            self.nextAnswer = answer
            Database.getAnswerURL(nextAnswerID, completion: { (URL, error) in
                if (error != nil) {
                    print(error.debugDescription)
                } else {
                    let nextPlayerItem = AVPlayerItem(URL: URL!)
                    if self.qPlayer.canInsertItem(nextPlayerItem, afterItem: nil) {
                        self.qPlayer.insertItem(nextPlayerItem, afterItem: nil)
                        self._NextItemReady = true
                    }
                }
            })
        })
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "status" {
            switch self.qPlayer.status {
            case AVPlayerStatus.ReadyToPlay:
                qPlayer.play()
                if !_TapReady {
                    _TapReady = true
                }
                break
            default: break
            }
        }
    }
    
    func votedAnswer(_vote : AnswerVoteType) {
        _answerOverlay.addVote(_vote)
        
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
        let _profileFrame = CGRectMake(view.bounds.width * (1/6), view.bounds.height * (1/4), view.bounds.width * (2/3), view.bounds.height * (1/2))
        
        if let _userForCurrentAnswer = userForCurrentAnswer {
            miniProfile = MiniProfile(frame: _profileFrame)
            miniProfile!.delegate = self
            miniProfile!.setNameLabel(_userForCurrentAnswer.name)
            miniProfile!.setTagline(_userForCurrentAnswer.bio)
            
            if let currentUserImage = currentUserImage {
                miniProfile!.setProfileImage(currentUserImage)
            }
            view.addSubview(miniProfile!)
            _isMiniProfileShown = true
        }
    }
    
    func userClosedMiniProfile(_profileView : UIView) {
        _profileView.removeFromSuperview()
        _isMiniProfileShown = false
    }
    
    func userClickedExploreAnswers() {
        removeObserverIfNeeded()
        
        let _topHeaderHeight = _answerOverlay.getHeaderHeight()
        let exploreAnswersFrame = CGRectMake(0, _topHeaderHeight, view.bounds.width, view.bounds.height - _topHeaderHeight)
        
        exploreAnswers = BrowseAnswersView(frame: exploreAnswersFrame, _currentQuestion: currentQuestion)
        exploreAnswers!.delegate = self
        view.addSubview(exploreAnswers!)
        //add browse answers view and set question
    }
    
    func userSelectedFromExploreQuestions(index : NSIndexPath) {
        exploreAnswers?.removeFromSuperview()
        _loadAnswer(currentQuestion, index: index.row)
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
        return index < self.currentQuestion.totalAnswers() ? true : false
    }
    
    /* HANDLE GESTURES */
    func handleTap() {
        if _isMiniProfileShown { //ignore tap
            return
        }

        if (answerIndex == minAnswersToShow && !_CameraShown && _CanAdvanceReady) { //ask user to answer the question
            if (delegate != nil) {
                qPlayer.pause()
                _CameraShown = true
                delegate.minAnswersShown()
            }
        }
        else if (!_TapReady || (!_NextItemReady && _CanAdvanceReady)) {
            //ignore swipe
        }
        else if _CanAdvanceReady {
            _TapReady = false
            _answerOverlay.resetTimer()
            qPlayer.pause()
            
            removeObserverIfNeeded()
            _updateOverlayData(nextAnswer!)
            qPlayer.advanceToNextItem()
            addObserverForStatusReady()
            
            currentAnswer = nextAnswer
            answerIndex += 1
            
            if _canAdvance(answerIndex) {
                _addNextVideoToQueue(currentQuestion.qAnswers![answerIndex])
                _CanAdvanceReady = true
//                print("added next item to queue")
            } else {
                _CanAdvanceReady = false
//                print("already added last item to queue")
            }
        } else {
//            print("no more answers")
            if (delegate != nil) {
                delegate.noAnswersToShow(self)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
