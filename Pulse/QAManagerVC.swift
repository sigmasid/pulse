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
//    func dismissVC(_ : UIViewController)
    func noAnswersToShow(_ : UIViewController)
    func doneRecording(_: NSURL?, currentVC : UIViewController, qID: String?, location: String?)
    func askUserToLogin(_: UIViewController)
    func loginSuccess(_ : UIViewController)
    func doneUploadingAnswer(_: UIViewController)
    func showNextQuestion(_: UIViewController)
    func userDismissedCamera(_:UIViewController)
    func goBack()
}

class QAManagerVC: UIViewController, childVCDelegate {
    
    var selectedTag : Tag!
    var allQuestions = [Question?]()
    var questionCounter = 0
    var currentQuestion = Question!(nil)
    var currentUser : User!
    
    let answerVC = ShowAnswerVC()
    var _hasMoreAnswers = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.view.backgroundColor = UIColor.yellowColor()
        
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
    
    func handleSwipe(recognizer:UISwipeGestureRecognizer) {
        
    }
    
    /* General VC related methods */
    func dismissVC(currentVC : UIViewController) {
        currentVC.willMoveToParentViewController(nil)
        currentVC.view.removeFromSuperview()
        currentVC.removeFromParentViewController()
    }
    
    func addNewVC(newVC: UIViewController) {
        self.addChildViewController(newVC)
        newVC.view.frame = self.view.frame
        self.view.addSubview(newVC.view)
        newVC.didMoveToParentViewController(self)
    }
    
    func cycleBetweenVC(oldVC: UIViewController, newVC: UIViewController) {
        self.transitionFromViewController(oldVC, toViewController: newVC, duration: 0.25, options: UIViewAnimationOptions.CurveEaseIn, animations: nil, completion: { (finished) in
            oldVC.removeFromParentViewController()
            newVC.didMoveToParentViewController(self)
        })
    }
    
    /* QA Specific Methods */
    
    func loadNextQuestion(completion: (question : Question, error : NSError?) -> Void) {
        questionCounter += 1
        
        if (questionCounter >= allQuestions.count && selectedTag.totalQuestionsForTag() >  questionCounter) {
            Database.getQuestion(selectedTag.questions![questionCounter], completion: { (question, error) in
                if error != nil {
                    print(error.debugDescription)
                } else {
                    self.allQuestions.append(question)
                    self.currentQuestion = question
                    completion(question: question, error: nil)
                }
            })
        } else {
            currentQuestion = allQuestions[questionCounter]
            completion(question: currentQuestion, error: nil)
        }
    }
    
    func displayQuestion() {
        answerVC.currentQuestion = self.currentQuestion
        answerVC.delegate = self
        self.addNewVC(answerVC)
    }
    
    func noAnswersToShow(currentVC : UIViewController) {
        if currentQuestion.hasAnswers() && User.currentUser.askedToAnswerCurrentQuestion {
            print("question has answers \(currentQuestion.totalAnswers())")
//            self.loadNextQuestion()
        } else {
            print("going to show camera")
            let cameraVC = CameraVC()
            cameraVC.camDelegate = self
            cameraVC.questionToShow = currentQuestion
            addNewVC(cameraVC)
//          cycleBetweenVC(currentVC, newVC: cameraVC)
        }
    }
    
    func doneRecording(assetURL : NSURL?, currentVC : UIViewController, qID : String?, location: String?){
        let userAnswer = UserRecordedAnswerVC()
        userAnswer.fileURL = assetURL
        userAnswer.answerDelegate = self
        userAnswer.currentQuestion = currentQuestion
        userAnswer.aLocation = location
        addNewVC(userAnswer)
        cycleBetweenVC(currentVC, newVC: userAnswer)
    }
    
    func askUserToLogin(currentVC : UIViewController) {
        AuthHelper.checkSocialTokens({ result in
            if !result {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let showLoginVC = storyboard.instantiateViewControllerWithIdentifier("LoginVC") as? LoginVC {
                    self.addNewVC(showLoginVC)
                    showLoginVC.loginDelegate = self
                }
            }
        })
    }
    
    func loginSuccess (currentVC : UIViewController) {
        self.dismissVC(currentVC)
    }
    
    func loginFailed (currentVC : UIViewController) {
        
    }
    
    func doneUploadingAnswer(currentVC: UIViewController) {
        if _hasMoreAnswers {
            answerVC.currentQuestion = self.currentQuestion
        } else {
            self.loadNextQuestion({ (question, error) in
                if error == nil {
                    self.answerVC.currentQuestion = question
                }
            })
            self.dismissVC(currentVC)
        }
    }
    
    func showNextQuestion(currentVC: UIViewController) {
        self.loadNextQuestion({ (question, error) in
            if error != nil {
                print("error getting question")
            } else {
                self.answerVC.currentQuestion = question
            }
        })
    }
    
    func askUserQuestion() {
        
    }
    
    func userDismissedCamera(currentVC: UIViewController) {
        
        if _hasMoreAnswers {
            print("user dismissed camera fired")
            
        } else {
            self.loadNextQuestion({ (question, error) in
                if error == nil {
                    self.answerVC.currentQuestion = question
                }
            })
            self.dismissVC(currentVC)
        }
    }
    
    func goBack() {
        self.performSegueWithIdentifier("unwindToExplore", sender: self)
    }
    
}
