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
    func dismissVC(_ : UIViewController)
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
    var questions = [Question?]()
//    var selectedTag : Tag!
    var questionCounter = 0
    var currentQuestion = Question!(nil)
    var currentUser : User!
    
    var _hasMoreAnswers = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        print("QA Manager frame is \(self.view.frame)")
        self.view.backgroundColor = UIColor.yellowColor()   
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
    
    func displayQuestion() {
        print("display questions fired, current question \(self.currentQuestion)")
        let newVC = ShowAnswerVC()
        newVC.currentQuestion = self.currentQuestion
        newVC.delegate = self
        self.addNewVC(newVC)
    }
    
    func cycleBetweenVC(oldVC: UIViewController, newVC: UIViewController) {
        
        self.transitionFromViewController(oldVC, toViewController: newVC, duration: 0.25, options: UIViewAnimationOptions.CurveEaseIn, animations: nil, completion: { (finished) in
            oldVC.removeFromParentViewController()
            newVC.didMoveToParentViewController(self)
        })
    }
    
    func loadNextQuestion() {
        questionCounter += 1
        currentQuestion = questions[questionCounter]
    }
    
    /* IMPLEMENT CHILD DISMISSED PROTOCOL */
    func dismissVC(currentVC : UIViewController) {
        currentVC.willMoveToParentViewController(nil)
        currentVC.view.removeFromSuperview()
        currentVC.removeFromParentViewController()
    }
    
    func addNewVC(newVC: UIViewController) {
        self.addChildViewController(newVC)
        newVC.view.frame = self.view.frame
        self.view.addSubview(newVC.view)
    }
    
    func noAnswersToShow(currentVC : UIViewController) {
        if currentQuestion.hasAnswers() && User.currentUser.askedToAnswerCurrentQuestion {
            self.loadNextQuestion()
        } else {
            print("camera VC fired")
            let cameraVC = CameraVC()
            cameraVC.camDelegate = self
            cameraVC.questionToShow = currentQuestion
            addNewVC(cameraVC)
            cycleBetweenVC(currentVC, newVC: cameraVC)
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
                    showLoginVC.didMoveToParentViewController(self)
                } else {
                    print("could not instantiate")
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
            let aAnswer = ShowAnswerVC()
            aAnswer.currentQuestion = self.currentQuestion
        } else {
            self.loadNextQuestion()
            self.dismissVC(currentVC)
        }
    }
    
    func showNextQuestion(currentVC: UIViewController) {
        self.loadNextQuestion()
        self.dismissVC(currentVC)
    }
    
    func askUserQuestion() {
        
    }
    
    func userDismissedCamera(currentVC: UIViewController) {
        
        if _hasMoreAnswers {
            print("user dismissed camera fired")
            
        } else {
            self.loadNextQuestion()
            self.dismissVC(currentVC)
        }
    }
    
    func goBack() {
        self.performSegueWithIdentifier("unwindToExplore", sender: self)
    }
    
}
