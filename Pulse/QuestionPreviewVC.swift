//
//  QuestionPreviewVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import AVFoundation

class QuestionPreviewVC: UIViewController {
    
    var currentQuestionID : String? {
        didSet {
            self.loadQuestion()
        }
    }
    
    var aPlayer = AVPlayer()
    var currentQuestion : Question!
    
    @IBOutlet weak var answerPreview: UIView!
    @IBOutlet weak var questionLabel: UILabel!
    weak var qPreviewDelegate : questionPreviewDelegate!
    var pulseIcon = Icon()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        self.view.alpha = 0.7
        
        print(answerPreview.frame)
        let iconColor = UIColor( red: 245/255, green: 44/255, blue:90/255, alpha: 1.0 )
        let iconDimension = min(answerPreview.frame.width, answerPreview.frame.height)
        print("question label dimensions are \(questionLabel.frame.width) and answer preview dimensions are \(answerPreview.frame.width)")
        
        pulseIcon.frame = CGRectMake(0,0,iconDimension,iconDimension)
        
        pulseIcon.frame = CGRectMake(0,(1-iconDimension/answerPreview.frame.height)/2*answerPreview.frame.height,iconDimension,iconDimension) //align icon to middle Y since it's a square
        pulseIcon.drawIcon(iconColor, iconThickness: 4)
        answerPreview.addSubview(pulseIcon)
        pulseIcon.setNeedsDisplay()
        
        let avPlayerLayer = AVPlayerLayer(player: aPlayer)
        avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        answerPreview.layer.insertSublayer(avPlayerLayer, atIndex: 0)
        avPlayerLayer.frame = answerPreview.frame
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "qCreated" {
            displayNewQuestion()
            if currentQuestion.hasAnswers() {
                setupAnswer(currentQuestion.qAnswers!.first!)
            }
            self.currentQuestion.removeObserver(self, forKeyPath: "qCreated")
        } else if keyPath == "status" {
            switch aPlayer.status {
            case AVPlayerStatus.ReadyToPlay:
                aPlayer.prerollAtRate(1, completionHandler: { completed in
                    if completed {
                        self.aPlayer.play()
                    }
                })
                aPlayer.currentItem!.removeObserver(self, forKeyPath: "status")
                break
            default: break
            }
        }
    }
    
    func loadQuestion() {
        if let _currentQuestionID = currentQuestionID {
            let questionsPath = databaseRef.child("questions/\(_currentQuestionID)")
            questionsPath.observeSingleEventOfType(.Value, withBlock: { snapshot in
                self.currentQuestion = Question(qID: snapshot.key, snapshot: snapshot)
                self.currentQuestion.addObserver(self, forKeyPath: "qCreated", options: NSKeyValueObservingOptions.New, context: nil)
            })
        }
    }
    
    func displayNewQuestion() {
        questionLabel.text = self.currentQuestion.qTitle!
        print(self.currentQuestion.qTitle!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func handleSwipe(recognizer:UISwipeGestureRecognizer) {
        print("swipe fired")
        switch recognizer.direction {
        case UISwipeGestureRecognizerDirection.Right:
            qPreviewDelegate.updateQuestion()
        default: print("default case")
        }
    }
    
    func setupAnswer(answerID : String) {
        let downloadRef = storageRef.child("answers/\(answerID)")
        let _ = downloadRef.downloadURLWithCompletion { (URL, error) -> Void in
            if (error != nil) {
                print(error.debugDescription)
            } else {
                self.pulseIcon.removeFromSuperview()
                let aPlayerItem = AVPlayerItem(URL: URL!)
                self.aPlayer.replaceCurrentItemWithPlayerItem(aPlayerItem)
                self.aPlayer.currentItem!.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: nil)
            }
        }
    }
}
