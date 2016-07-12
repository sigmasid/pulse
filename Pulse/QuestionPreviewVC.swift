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
    var pulseIcon : Icon!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        let avPlayerLayer = AVPlayerLayer(player: aPlayer)
        answerPreview.layer.insertSublayer(avPlayerLayer, atIndex: 0)
        avPlayerLayer.frame = answerPreview.bounds
        avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "status" {
            switch aPlayer.status {
            case AVPlayerStatus.ReadyToPlay:
                self.aPlayer.play()
                aPlayer.currentItem!.removeObserver(self, forKeyPath: "status")
                break
            default: break
            }
        }
    }
    
    func loadQuestion() {
        Database.getQuestion(currentQuestionID!, completion: {(question, error) in
            self.currentQuestion = question
            self.questionLabel.text = question.qTitle!
            if self.currentQuestion.hasAnswers() {
                self.setupAnswer(self.currentQuestion.qAnswers!.first!)
            }
        })
    }
    
    func setupAnswer(answerID : String) {
        Database.getAnswerURL(answerID, completion: {(URL, error) in
            if (error != nil) {
                print(error.debugDescription)
            } else {
                self.pulseIcon.removeFromSuperview()
                let aPlayerItem = AVPlayerItem(URL: URL!)
                self.aPlayer.replaceCurrentItemWithPlayerItem(aPlayerItem)
                self.aPlayer.currentItem!.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: nil)
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func handleSwipe(recognizer:UISwipeGestureRecognizer) {
        switch recognizer.direction {
        case UISwipeGestureRecognizerDirection.Right:
            qPreviewDelegate.updateContainerQuestion()
        default: print("default case")
        }
    }

}