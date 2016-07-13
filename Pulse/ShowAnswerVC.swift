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
    var currentQuestion : Question! {
        didSet {
            if self.isViewLoaded() {
                _loadFirstAnswer(currentQuestion)
            }
        }
    }
    
    var nextAnswer : Answer?
    var currentTag : Tag!
    
    var answerIndex = 1
    
    private var _avPlayerLayer: AVPlayerLayer!
    private var _answerOverlay : AnswerOverlay!
    private var allAnswersForQuestion = [Answer]()
    private var qPlayer = AVQueuePlayer()
    
    private var _swipeReady = false
    private var _nextItemReady = false
    
    var delegate : childVCDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
        swipeUp.direction = UISwipeGestureRecognizerDirection.Up
        self.view.addGestureRecognizer(swipeUp)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeRight)
        
        if (currentQuestion != nil){
            _loadFirstAnswer(currentQuestion)
        }
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
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    private func _loadFirstAnswer(currentQuestion : Question) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        if let _firstAnswerID = self.currentQuestion.qAnswers?.first {
            Database.getAnswer(_firstAnswerID, completion: { (answer, error) in
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
    
    private func _updateOverlayData(answer : Answer) {
        Database.getUser(answer.uID!, completion: { (user, error) in
            if let _uName = user.name {
                self._answerOverlay.addUserName(_uName)
            }
            if let _uPic = user.profilePic {
                self._answerOverlay.addUserImage(NSURL(string: _uPic))
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
                self.qPlayer.replaceCurrentItemWithPlayerItem(AVPlayerItem(URL: URL!))
                self.delegate.hasAnswersToShow()

                self.qPlayer.actionAtItemEnd = AVPlayerActionAtItemEnd.None
                self.qPlayer.currentItem!.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: nil)
            }
        })
    }
    
    private func _addNextVideoToQueue(nextAnswerID : String) {
        _nextItemReady = false
        
        Database.getAnswer(nextAnswerID, completion: { (answer, error) in
            self.nextAnswer = answer
            Database.getAnswerURL(nextAnswerID, completion: { (URL, error) in
                if (error != nil) {
                    print(error.debugDescription)
                } else {
                    let nextPlayerItem = AVPlayerItem(URL: URL!)
                    if self.qPlayer.canInsertItem(nextPlayerItem, afterItem: nil) {
                        self.qPlayer.insertItem(nextPlayerItem, afterItem: nil)
                        self._nextItemReady = true
                    }
                }
            })
        })
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "status" {
            switch self.qPlayer.status {
            case AVPlayerStatus.ReadyToPlay:
                let duration = self.qPlayer.currentItem?.duration
                _answerOverlay.startTimer(duration!.seconds)
                qPlayer.play()
                qPlayer.currentItem!.removeObserver(self, forKeyPath: "status")
                if !_swipeReady {
                    _swipeReady = true
                }
                break
            default: break
            }
        }
    }
    
    private func _canAdvance(index: Int) -> Bool{
        return index < self.currentQuestion.totalAnswers() ? true : false
    }
    
    /* HANDLE GESTURES */
    func handleSwipe(recognizer:UISwipeGestureRecognizer) {
        
        switch recognizer.direction {
        case UISwipeGestureRecognizerDirection.Up:
            if (delegate != nil) {
                delegate.showNextQuestion()
            }
            
        case UISwipeGestureRecognizerDirection.Left:
            print("swipe ready: \(_swipeReady) next item ready: \(_nextItemReady) can advance \(_canAdvance(self.answerIndex))")
            if (!_swipeReady || (!_nextItemReady && (_canAdvance(self.answerIndex)))) {
                print("ignore swipe")
            } else if (_canAdvance(self.answerIndex)) {
                qPlayer.pause()
                _swipeReady = false

                _answerOverlay.resetTimer()
                _updateOverlayData(nextAnswer!)
                qPlayer.advanceToNextItem()
                qPlayer.actionAtItemEnd = AVPlayerActionAtItemEnd.None
                
                qPlayer.currentItem!.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: nil)
                answerIndex += 1
                
                if _canAdvance(self.answerIndex) {
                    _addNextVideoToQueue(self.currentQuestion.qAnswers![self.answerIndex])
                }
            } else {
                print("no answers to show")
                if (delegate != nil) {
                    delegate.noAnswersToShow(self)
                }
            }
        case UISwipeGestureRecognizerDirection.Right:
            if (delegate != nil) {
                delegate.goBack(self)
            }
        default: print("unhandled swipe")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
