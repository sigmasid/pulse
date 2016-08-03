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
                removeObserverIfNeeded()
                delegate.showQuestionPreviewOverlay()
                answerIndex = 0
                _CameraShown = false
                _loadFirstAnswer(currentQuestion)
            }
        }
    }
    
    internal var currentTag : Tag!
    internal var answerIndex = 0
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
    private var _CanAdvanceReady = false
    private var _CameraShown = false
    
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
        qPlayer.actionAtItemEnd = AVPlayerActionAtItemEnd.None
        
        startObserver = qPlayer.addBoundaryTimeObserverForTimes([NSValue(CMTime: CMTimeMake(1, 20))], queue: nil, usingBlock: {
            NSNotificationCenter.defaultCenter().postNotificationName("PlaybackStartedNotification", object: self)
        })
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
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
    
    private func _addFirstVideo(answerID : String) {
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
            if let _uName = user.name {
                self._answerOverlay.addUserName(_uName)
            } else {
                self._answerOverlay.addUserName("")
            }
            if let _uPic = user.profilePic {
                self._answerOverlay.addUserImage(NSURL(string: _uPic), _userImageData: nil)
            } else {
                self._answerOverlay.addUserImage(nil, _userImageData: UIImage(named: "default-profile"))
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
//        print("current index is \(answerIndex)")
//        print("tap ready \(_TapReady), next item ready \(_NextItemReady), can advance \(_CanAdvanceReady)")
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
//            print("trying to advance to next answer")
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
