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
    var questions = [Question]()
    var selectedTag : Tag!
    private var questionCounter = 0
    private var currentQuestion = Question!(nil)
    var currentUser : User!
    
    var _hasMoreAnswers = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        loadAllQuestionIDsForTag(self.selectedTag)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handleSwipe(recognizer:UISwipeGestureRecognizer) {
        
    }
    
    func displayNewQuestion() {
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
    
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "qCreated" {
            self.displayNewQuestion()
            self.currentQuestion.removeObserver(self, forKeyPath: "qCreated")
        }
    }
    
    func loadNextQuestion() {
        let questionsPath = databaseRef.child("questions/\(self.selectedTag.questions![questionCounter])")
        questionsPath.observeSingleEventOfType(.Value, withBlock: { snapshot in
            self.currentQuestion = Question(qID: snapshot.key, snapshot: snapshot)
            
            self.currentQuestion.addObserver(self, forKeyPath: "qCreated", options: NSKeyValueObservingOptions.New, context: nil)
            self.questionCounter += 1
        })
    }
    
    func loadAllQuestionIDsForTag(currentTag : Tag) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let tagsPath = databaseRef.child("tags/\(self.selectedTag.tagID!)/questions")
        
        tagsPath.observeSingleEventOfType(.Value, withBlock: { snapshot in
            for item in snapshot.children {
                let child = item as! FIRDataSnapshot
                let questionID = child.key
                if self.selectedTag.questions?.append(questionID) == nil {
                    self.selectedTag.questions = [questionID]
                }
            }
            self.loadNextQuestion()
        })
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
                let showLoginVC = (self.storyboard?.instantiateViewControllerWithIdentifier("LoginVC"))! as! LoginVC
                showLoginVC.loginDelegate = self
                
                self.addNewVC(showLoginVC)
                showLoginVC.didMoveToParentViewController(self)
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
