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
    var currentQuestion : Question!
    var currentAnswer : Answer!
    var answerIndex = 1
    
    var avPlayerLayer: AVPlayerLayer!
    var allAnswersIDForQuestion = [String]()
    var qPlayer = AVQueuePlayer()
    
    let loadingLabel = UILabel(frame: CGRectMake(0, UIScreen.mainScreen().bounds.height / 2, UIScreen.mainScreen().bounds.width, 20))
    weak var delegate : childVCDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("show answers loaded")

        
        loadingLabel.text = "Loading..."
        loadingLabel.textColor = UIColor.redColor()
        self.view.addSubview(loadingLabel)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
        swipeUp.direction = UISwipeGestureRecognizerDirection.Up
        self.view.addGestureRecognizer(swipeUp)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeRight)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        avPlayerLayer = AVPlayerLayer(player: qPlayer)
        view.layer.insertSublayer(self.avPlayerLayer, atIndex: 0)
        self.avPlayerLayer.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
        
        if (self.currentQuestion != nil){
            loadAnswerIDForCurrentQuestion(self.currentQuestion)
        }
    }
    
    func _addNextVideoToQueue(fileID : String) {
        let downloadRef = storageRef.child("answers/\(fileID)")
        let _ = downloadRef.downloadURLWithCompletion { (URL, error) -> Void in
            if (error != nil) {
                print(error.debugDescription)
            } else {
                let nextPlayerItem = AVPlayerItem(URL: URL!)
                if self.qPlayer.canInsertItem(nextPlayerItem, afterItem: nil) {
                    print("adding next video to queue")
                    self.qPlayer.insertItem(nextPlayerItem, afterItem: nil)
                }
            }
        }
    }
    
    private func _addFirstVideo(fileID : String) {
        let downloadRef = storageRef.child("answers/\(fileID)")
        let _ = downloadRef.downloadURLWithCompletion { (URL, error) -> Void in
            if (error != nil) {
                print(error.debugDescription)
            } else {
                self.qPlayer.replaceCurrentItemWithPlayerItem(AVPlayerItem(URL: URL!))
                self.qPlayer.actionAtItemEnd = AVPlayerActionAtItemEnd.None
                self.qPlayer.currentItem!.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: nil)
            }
        }
    }
    
    private func loadAnswerIDForCurrentQuestion(currentQuestion : Question) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        if let _ = self.currentQuestion.qAnswers {
            let answerIDPath =  databaseRef.child("questions/\(self.currentQuestion.qID)/answers")
            answerIDPath.observeSingleEventOfType(.Value, withBlock: { snapshot in
                for aAnswer in snapshot.children {
                    let answerKey = aAnswer.key as String
                    //  let answerURL = NSURL(fileURLWithPath: String(snapshot.value![answerKey]))
                    self.allAnswersIDForQuestion.append(answerKey)
                }
                self._addFirstVideo(self.allAnswersIDForQuestion.first!)
                if self._canAdvance(self.answerIndex) {
                    self._addNextVideoToQueue(self.allAnswersIDForQuestion[self.answerIndex])
                }
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            })
        }
        else {
            print("no answers to show fired")
            if (self.delegate != nil) {
                self.delegate.noAnswersToShow(self)
            }
        }
    }
    
//    deinit {
//        //        self.qPlayer.currentItem!.removeObserver(self, forKeyPath: "status", context: nil)
//    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        print("player item status is \(qPlayer.currentItem?.status.rawValue)")
        print("key path is \(keyPath)")
        
        if keyPath == "status" {
            switch self.qPlayer.status {
            case AVPlayerStatus.ReadyToPlay:
                self.loadingLabel.hidden = true
                self.qPlayer.prerollAtRate(1, completionHandler: { completed in
                    if completed {
                        self.qPlayer.play()
                        let duration = self.qPlayer.currentItem?.duration
                        let newLayer = self.addVideoTimerCountdown(duration!)
                        self.avPlayerLayer.addSublayer(newLayer)
                    }
                })
                self.qPlayer.currentItem!.removeObserver(self, forKeyPath: "status")
                break
            default: break
            }
        }
    }
    
    func _canAdvance(index: Int) -> Bool{
        return index < self.allAnswersIDForQuestion.count ? true : false
    }
    
    /* HANDLE GESTURES */
    func handleSwipe(recognizer:UISwipeGestureRecognizer) {
        //        self.qPlayer.currentItem!.removeObserver(self, forKeyPath: "playerItemDidReachEnd")
        
        switch recognizer.direction {
        case UISwipeGestureRecognizerDirection.Up:
            
            if (self.delegate != nil) {
                self.delegate.showNextQuestion(self)
            }
        case UISwipeGestureRecognizerDirection.Left:
            if (_canAdvance(self.answerIndex)) {
                self.qPlayer.advanceToNextItem()
                self.qPlayer.actionAtItemEnd = AVPlayerActionAtItemEnd.None
                self.qPlayer.currentItem!.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: nil)
                
                self.answerIndex += 1
                
                if _canAdvance(self.answerIndex) {
                    _addNextVideoToQueue(self.allAnswersIDForQuestion[self.answerIndex])
                }
            } else {
                if (self.delegate != nil) {
                    self.delegate.noAnswersToShow(self)
                }
            }
        case UISwipeGestureRecognizerDirection.Right:
            if (self.delegate != nil) {
                self.delegate.goBack()
            }
        default: print("unhandled swipe")
        }
    }
    
    // Add video countdown
    func addVideoTimerCountdown(videoDuration : CMTime) -> CALayer {
        print(videoDuration.seconds)
        let cameraOverlay = CALayer()
        
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        cameraOverlay.frame = CGRectMake(screenSize.maxX - 40, screenSize.maxY - 40, 40, 40)
        
        // draw the countdown
        let bgShapeLayer = drawBgShape()
        let timeLeftShapeLayer = drawTimeLeftShape()
        
        cameraOverlay.addSublayer(bgShapeLayer)
        cameraOverlay.addSublayer(timeLeftShapeLayer)
        
        // basic animation object to animate the strokeEnd
        let strokeIt = CABasicAnimation(keyPath: "strokeEnd")
        strokeIt.fromValue = 0.0
        strokeIt.toValue = 1.0
        strokeIt.duration = videoDuration.seconds
        
        timeLeftShapeLayer.addAnimation(strokeIt, forKey: nil)
        return cameraOverlay
    }
    
    func drawBgShape() -> CAShapeLayer {
        let bgShapeLayer = CAShapeLayer()
        bgShapeLayer.path = UIBezierPath(arcCenter: CGPoint(x: 0 , y: 0), radius:
            15, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).CGPath
        bgShapeLayer.strokeColor = UIColor.whiteColor().CGColor
        bgShapeLayer.fillColor = UIColor.clearColor().CGColor
        bgShapeLayer.opacity = 0.7
        bgShapeLayer.lineWidth = 5
        
        return bgShapeLayer
    }
    
    func drawTimeLeftShape() -> CAShapeLayer {
        let timeLeftShapeLayer = CAShapeLayer()
        timeLeftShapeLayer.path = UIBezierPath(arcCenter: CGPoint(x: 0, y: 0), radius:
            15, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).CGPath
        timeLeftShapeLayer.strokeColor = UIColor.darkGrayColor().CGColor
        timeLeftShapeLayer.fillColor = UIColor.clearColor().CGColor
        timeLeftShapeLayer.lineWidth = 5
        timeLeftShapeLayer.opacity = 0.7
        
        return timeLeftShapeLayer
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
