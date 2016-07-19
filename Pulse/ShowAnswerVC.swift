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

class ShowAnswerVC: UIViewController {
    internal var currentQuestion : Question! {
        didSet {
            if self.isViewLoaded() {
                _loadFirstAnswer(currentQuestion)
            }
        }
    }
    
    internal var currentTag : Tag!
    internal var answerIndex = 1
    internal var minAnswersToShow = 3
    internal var currentAnswer : Answer?
    
    private var nextAnswer : Answer?
    private var allAnswersForQuestion = [Answer]()
    private var _avPlayerLayer: AVPlayerLayer!
    private var _answerOverlay : AnswerOverlay!
    private var qPlayer = AVQueuePlayer()
    private var currentPlayerItem : AVPlayerItem?
    
    private var _TapReady = false
    private var _NextItemReady = false
    private var isObserving = false
    private var startObserver : AnyObject!
    
    weak var delegate : childVCDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap))
        self.view.addGestureRecognizer(tap)
        
        if (currentQuestion != nil){
            _loadFirstAnswer(currentQuestion)
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self._startCountdownTimer), name: "PlaybackStartedNotification", object: self.currentPlayerItem)

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        let _frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
        
        _answerOverlay = AnswerOverlay(frame: _frame)
        _avPlayerLayer = AVPlayerLayer(player: qPlayer)
        
        view.layer.insertSublayer(_avPlayerLayer, atIndex: 0)
        view.insertSubview(_answerOverlay, atIndex: 1)
        
        _answerOverlay.addIcon(iconColor, backgroundColor: iconBackgroundColor)
        _answerOverlay.addVideoTimerCountdown()
        _avPlayerLayer.frame = _frame
        
        startObserver = qPlayer.addBoundaryTimeObserverForTimes([NSValue(CMTime: CMTimeMake(1, 20))], queue: nil, usingBlock: {
            NSNotificationCenter.defaultCenter().postNotificationName("PlaybackStartedNotification", object: self)
        })
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.qPlayer.removeTimeObserver(self.startObserver)
    }
    
    private func _loadFirstAnswer(currentQuestion : Question) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        if let _firstAnswerID = self.currentQuestion.qAnswers?.first {
            Database.getAnswer(_firstAnswerID, completion: { (answer, error) in
                self.currentAnswer = answer
                self.allAnswersForQuestion.append(answer)
                self._addFirstVideo(answer.aID)
                self._updateOverlayData(answer)
                self._answerOverlay.addVideoTimerCountdown()

                if self._canAdvance(self.answerIndex) {
                    self._addNextVideoToQueue(self.currentQuestion.qAnswers![self.answerIndex])
                }
            })
        } else {
            if (delegate != nil) {
                delegate.noAnswersToShow(self)
            }
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
            if let _uName = user.name {
                self._answerOverlay.addUserName(_uName)
            } else {
                self._answerOverlay.addUserName("")
            }
            if let _uPic = user.profilePic {
                self._answerOverlay.addUserImage(NSURL(string: _uPic))
            } else {
                self._answerOverlay.addDefaultUserImage(UIImage(named: "default-profile"))
            }
        })
        if let _aTag = currentTag.tagID {
            self._answerOverlay.updateTag(_aTag)
        }
        if let _qTitle = currentQuestion.qTitle {
            self._answerOverlay.updateQuestion(_qTitle)
        }
        if let _location = answer.aLocation {
            self._answerOverlay.addLocation(_location)
        }
    }
    
    private func _addFirstVideo(answerID : String) {
        Database.getAnswerURL(answerID, completion: { (URL, error) in
            if error != nil {
                print(error.debugDescription)
            } else {
                self.currentPlayerItem = AVPlayerItem(URL: URL!)
                if let _currentPlayerItem = self.currentPlayerItem {
                    self.qPlayer.replaceCurrentItemWithPlayerItem(_currentPlayerItem)
                    self.delegate.hasAnswersToShow()
                    
                    self.qPlayer.actionAtItemEnd = AVPlayerActionAtItemEnd.None
                    self.qPlayer.currentItem!.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: nil)
                    self.isObserving = true
                }
            }
        })
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
                qPlayer.currentItem!.removeObserver(self, forKeyPath: "status")
                isObserving = false
                if !_TapReady {
                    _TapReady = true
                }
                break
            default: break
            }
        }
    }
    
    func upvoteAnswer() {
        _answerOverlay.addUpvote()
        if let _currentAnswer = currentAnswer {
            Database.addAnswerVote(AnswerVoteType.Upvote, aID: _currentAnswer.aID, completion: { (success, error) in
                if success {
                    print("upvote registered")
                } else {
                    print(error!.localizedDescription)
                }
            })
        }
    }
    
    func downvoteAnswer() {
        _answerOverlay.addDownvote()
        if let _currentAnswer = currentAnswer {
            Database.addAnswerVote(AnswerVoteType.Downvote, aID: _currentAnswer.aID, completion: { (success, error) in
                if success {
                    print("downvote registered")
                } else {
                    print(error!.localizedDescription)
                }
            })
        }
    }
    
    deinit {
        if isObserving {
            qPlayer.currentItem!.removeObserver(self, forKeyPath: "status")
        }
    }
    
    private func _canAdvance(index: Int) -> Bool{
        return index < self.currentQuestion.totalAnswers() ? true : false
    }
    
    /* HANDLE GESTURES */
    func handleTap() {
        if (answerIndex == minAnswersToShow && (_canAdvance(self.answerIndex))) { //ask user to answer the question
            if (delegate != nil) {
                qPlayer.pause()
                delegate.minAnswersShown()
            }
        }
        else if (!_TapReady || (!_NextItemReady && (_canAdvance(self.answerIndex)))) {
            //ignore swipe
        } else if (_canAdvance(self.answerIndex)) {
            qPlayer.pause()
            _TapReady = false
            
            _answerOverlay.resetTimer()
            _updateOverlayData(nextAnswer!)
            qPlayer.advanceToNextItem()
            qPlayer.actionAtItemEnd = AVPlayerActionAtItemEnd.None
            currentAnswer = nextAnswer
            
            qPlayer.currentItem!.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: nil)
            answerIndex += 1
            
            if _canAdvance(answerIndex) {
                _addNextVideoToQueue(currentQuestion.qAnswers![answerIndex])
            }
        } else {
            if (delegate != nil) {
                delegate.noAnswersToShow(self)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
