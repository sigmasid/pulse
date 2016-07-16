//
//  QAManagerVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import FirebaseDatabase

protocol childVCDelegate: class {
    func noAnswersToShow(_ : UIViewController)
    func hasAnswersToShow()
    func doneRecording(_: NSURL?, currentVC : UIViewController, qID: String?, location: String?)
    func askUserToLogin(_: UIViewController)
    func loginSuccess(_ : UIViewController)
    func doneUploadingAnswer(_: UIViewController)
    func showNextQuestion()
    func userDismissedCamera(_:UIViewController)
    func goBack(_ : UIViewController)
}

class QAManagerVC: UIViewController, childVCDelegate {
    
    var selectedTag : Tag!
    var allQuestions = [Question?]()
    var questionCounter = 0
    var currentQuestion = Question!(nil)
    var currentUser : User!
    
    let answerVC = ShowAnswerVC()
    var returnToParentDelegate : ParentDelegate!
    
    var _hasMoreAnswers = false //TEMP - UPDATE IMPLEMENTATION
    
    private var panStartingPointX : CGFloat = 0
    private var panStartingPointY : CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        _panGesture.minimumNumberOfTouches = 1
        self.view.addGestureRecognizer(_panGesture)
    }
    
    override func viewDidAppear(animated: Bool) {
        self.view.backgroundColor = UIColor.whiteColor()
        
        let iconSize : CGFloat = 50
        let iconColor = UIColor( red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0 )
        let icon = Icon(frame: CGRectMake(UIScreen.mainScreen().bounds.midX - iconSize / 2, UIScreen.mainScreen().bounds.midY - iconSize / 2, iconSize, iconSize))
        icon.drawIcon(iconColor, iconThickness: 2)
        
        self.view.addSubview(icon)
        displayQuestion()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /* QA Specific Methods */
    
    func displayQuestion() {
        answerVC.currentQuestion = currentQuestion
        answerVC.currentTag = selectedTag
        answerVC.delegate = self
        GlobalFunctions.addNewVC(answerVC, parentVC: self)
    }
    
    func loadNextQuestion(completion: (question : Question?, error : NSError?) -> Void) {
        questionCounter += 1
        
        if (questionCounter >= allQuestions.count && selectedTag.totalQuestionsForTag() >  questionCounter) {
            Database.getQuestion(selectedTag.questions![questionCounter], completion: { (question, error) in
                if error != nil {
                    completion(question: nil, error: error)
                } else {
                    self.allQuestions.append(question)
                    self.currentQuestion = question
                    completion(question: question, error: nil)
                }
            })
        } else if (questionCounter >= selectedTag.totalQuestionsForTag()) {
            let userInfo = [ NSLocalizedDescriptionKey : "browsed all questions for tag" ]
            completion(question: nil, error: NSError.init(domain: "ReachedEnd", code: 200, userInfo: userInfo))
        } else {
            currentQuestion = allQuestions[questionCounter]
            completion(question: currentQuestion, error: nil)
        }
    }
    
    func loadPriorQuestion(completion: (question : Question?, error : NSError?) -> Void) {
        questionCounter -= 1
        
        if (questionCounter >= 0) {
            currentQuestion = allQuestions[questionCounter]
            completion(question: currentQuestion, error: nil)
        } else if (questionCounter < 0) {
            questionCounter += 1
            let userInfo = [ NSLocalizedDescriptionKey : "reached beginning" ]
            completion(question: nil, error: NSError.init(domain: "ReachedBeginning", code: 200, userInfo: userInfo))
        }
    }
    
    func doneRecording(assetURL : NSURL?, currentVC : UIViewController, qID : String?, location: String?){
        let userAnswer = UserRecordedAnswerVC()
        userAnswer.answerDelegate = self
        
        userAnswer.fileURL = assetURL
        userAnswer.currentQuestion = currentQuestion
        userAnswer.aLocation = location
        GlobalFunctions.cycleBetweenVC(currentVC, newVC: userAnswer, parentVC: self)
    }
    
    func askUserToLogin(currentVC : UIViewController) {
        Database.checkSocialTokens({ result in
            if !result {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let showLoginVC = storyboard.instantiateViewControllerWithIdentifier("LoginVC") as? LoginVC {
                    GlobalFunctions.addNewVC(showLoginVC, parentVC: self)
                    showLoginVC.loginVCDelegate = self
                }
            } else {
                if let _userAnswerVC = currentVC as? UserRecordedAnswerVC {
                    _userAnswerVC._postVideo()
                }
            }
        })
    }
    
    func doneUploadingAnswer(currentVC: UIViewController) {
        if _hasMoreAnswers {
            answerVC.currentQuestion = self.currentQuestion
        } else {
            self.loadNextQuestion({ (question, error) in
                if error != nil {
                    if error?.domain == "ReachedEnd" {
                        self.returnToParentDelegate.returnToParent(self)
                    }
                } else {
                    self.answerVC.currentQuestion = question
                    GlobalFunctions.dismissVC(currentVC)
                }
            })
        }
    }
    
    func showNextQuestion() {
        self.loadNextQuestion({ (question, error) in
            if error != nil {
                if error?.domain == "ReachedEnd" {
                    self.returnToParentDelegate.returnToParent(self)
                }
            } else {
                self.answerVC.currentQuestion = question
            }
        })
    }
    
    func showPriorQuestion() {
        self.loadPriorQuestion({ (question, error) in
            if error != nil {
                if error?.domain == "ReachedBeginning" {
                    self.returnToParentDelegate.returnToParent(self)
                }
            } else {
                self.answerVC.currentQuestion = question
            }
        })
    }
    
    func noAnswersToShow(currentVC : UIViewController) {
        if _hasMoreAnswers {
            showNextQuestion()
        } else {
            currentVC.view.hidden = true
            
            let cameraVC = CameraVC()
            cameraVC.camDelegate = self
            cameraVC.questionToShow = currentQuestion
            GlobalFunctions.addNewVC(cameraVC, parentVC: self)
        }
    }
    
    func hasAnswersToShow() {
        self.answerVC.view.hidden = false
    }
    
    func userDismissedCamera(currentVC: UIViewController) {
        if _hasMoreAnswers {
            print("user dismissed camera fired")
        } else {
            self.loadNextQuestion({ (question, error) in
                if error != nil {
                    if error?.domain == "ReachedEnd" {
                        self.returnToParentDelegate.returnToParent(self)
                    }
                } else {
                    self.answerVC.currentQuestion = question
                }
            })
            GlobalFunctions.dismissVC(currentVC)
        }
    }
    
    func goBack(currentVC : UIViewController) {
        if let _returnToParent = returnToParentDelegate {
            _returnToParent.returnToParent(self)
        }
    }
    
    func loginSuccess (currentVC : UIViewController) {
        GlobalFunctions.dismissVC(currentVC)
    }
    
    func handlePan(pan : UIPanGestureRecognizer) {
        let panCurrentPointX = pan.view!.center.x
        let panCurrentPointY = pan.view!.center.y
        
        if (pan.state == UIGestureRecognizerState.Began) {
            panStartingPointX = pan.view!.center.x
            panStartingPointY = pan.view!.center.y

        }
        else if (pan.state == UIGestureRecognizerState.Ended) {
            let translation = pan.translationInView(self.view)

            switch translation {
            case _ where translation.y < -150:
                showNextQuestion()
                pan.setTranslation(CGPointZero, inView: self.view)
            case _ where translation.y > 150:
                showPriorQuestion()
                pan.setTranslation(CGPointZero, inView: self.view)
            case _ where panCurrentPointX > self.view.bounds.width:
                goBack(self)
            default:
                self.view.center = CGPoint(x: self.view.bounds.width / 2, y: pan.view!.center.y)
                pan.setTranslation(CGPointZero, inView: self.view)
            }
        } else {
            let translation = pan.translationInView(self.view)
            if (translation.y < -20 || translation.y > 20) {
                //ignore if user was trying to move up / down
            }
            else if (translation.x > 0) { //only go back but not go forward
                self.view.center = CGPoint(x: pan.view!.center.x + translation.x, y: pan.view!.center.y)
                pan.setTranslation(CGPointZero, inView: self.view)
            }
        }
    }
}

//    func handleSwipe(recognizer:UISwipeGestureRecognizer) {
//
//        switch recognizer.direction {
//        case UISwipeGestureRecognizerDirection.Up:
//            if (delegate != nil) {
//                delegate.showNextQuestion()
//            }
//        default: print("unhandled swipe")
//        }
//    }
//        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
//        swipeUp.direction = UISwipeGestureRecognizerDirection.Up
//        self.view.addGestureRecognizer(swipeUp)
//
//        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
//        swipeDown.direction = UISwipeGestureRecognizerDirection.Down
//        self.view.addGestureRecognizer(swipeDown)
//
//        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
//        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
//        self.view.addGestureRecognizer(swipeRight)