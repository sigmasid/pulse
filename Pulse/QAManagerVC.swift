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
    func userDismissedCamera(_: UIViewController)
    func minAnswersShown()
    func showNextQuestion()
    func goBack(_ : UIViewController)
}

class QAManagerVC: UIViewController, childVCDelegate {
    
    // delegate vars
    var selectedTag : Tag!
    var allQuestions = [Question?]()
    var questionCounter = 0
    var currentQuestion = Question!(nil)
    
    private var savedRecordedVideoVC : UserRecordedAnswerVC?
    private let answerVC = ShowAnswerVC()
    weak var returnToParentDelegate : ParentDelegate!
    private var loadingView : LoadingView?
    
    private var _hasMoreAnswers = false
    private var _isShowingCamera = false

    private var panStartingPointX : CGFloat = 0
    private var panStartingPointY : CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        _panGesture.minimumNumberOfTouches = 1
        self.view.addGestureRecognizer(_panGesture)
    }
    
    override func viewDidAppear(animated: Bool) {
        
        loadingView = LoadingView(frame: self.view.bounds, backgroundColor: UIColor.whiteColor())
        loadingView?.addIcon(IconSizes.Medium, _iconColor: UIColor.blackColor(), _iconBackgroundColor: nil)
        loadingView?.addMessage("Loading...")
        self.view.addSubview(loadingView!)
        
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
        answerVC.view.hidden = true
    }
    
    private func loadNextQuestion(completion: (question : Question?, error : NSError?) -> Void) {
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
    
    private func loadPriorQuestion(completion: (question : Question?, error : NSError?) -> Void) {
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
        _isShowingCamera = false

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
                    self.savedRecordedVideoVC = currentVC as? UserRecordedAnswerVC
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
            returnToAnswers()
            GlobalFunctions.dismissVC(currentVC)
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
        } else if User.isLoggedIn() {
            if User.currentUser!.hasAnsweredQuestion(currentQuestion.qID) {
                showNextQuestion()
            } else {
                currentVC.view.hidden = true
                showCamera()
            }
        } else {
            currentVC.view.hidden = true
            showCamera()
        }
    }
    
    func minAnswersShown() {
        if User.isLoggedIn() {
            if User.currentUser!.hasAnsweredQuestion(currentQuestion.qID) {
                returnToAnswers()
                
            } else {
                answerVC.view.hidden = true
                _hasMoreAnswers = true
                showCamera()
            }
        } else {
            answerVC.view.hidden = true
            _hasMoreAnswers = true
            showCamera()
        }
    }
    
    func showCamera() {
        let _cameraVC = CameraVC()
        _cameraVC.childDelegate = self
        _cameraVC.questionToShow = currentQuestion
        _isShowingCamera = true
        GlobalFunctions.addNewVC(_cameraVC, parentVC: self)
    }
    
    func hasAnswersToShow() {
        self.answerVC.view.hidden = false
    }
    
    func userDismissedCamera(currentVC : UIViewController) {
        _isShowingCamera = false

        if _hasMoreAnswers {
            returnToAnswers()
            GlobalFunctions.dismissVC(currentVC, _animationStyle: .VerticalDown)
        } else {
            self.loadNextQuestion({ (question, error) in
                if error != nil {
                    if error?.domain == "ReachedEnd" {
                        self.returnToParentDelegate.returnToParent(self)
                    }
                } else {
                    self.answerVC.currentQuestion = question
                    GlobalFunctions.dismissVC(currentVC, _animationStyle: .VerticalDown)
                }
            })
        }
    }
    
    func returnToAnswers() {
        answerVC.answerIndex += 1
        answerVC.view.hidden = false
        answerVC.handleTap()
    }
    
    func goBack(currentVC : UIViewController) {
        if let _returnToParent = returnToParentDelegate {
            _returnToParent.returnToParent(self)
        }
    }
    
    func loginSuccess (currentVC : UIViewController) {
        if let _userAnswerVC = savedRecordedVideoVC {
            print("login success")
            _userAnswerVC._postVideo()
        }
        GlobalFunctions.dismissVC(currentVC)
    }
    
    func handlePan(pan : UIPanGestureRecognizer) {
        let panCurrentPointX = pan.view!.center.x
        let _ = pan.view!.center.y
        
        if (pan.state == UIGestureRecognizerState.Began) {
            panStartingPointX = pan.view!.center.x
            panStartingPointY = pan.view!.center.y
        }
            
        else if (pan.state == UIGestureRecognizerState.Ended) {
            let translation = pan.translationInView(self.view)
            print("translation values are \(translation), screen bounds are \(self.view.bounds)")
            if _isShowingCamera {
                //cameraVC will handle
            } else {
                switch translation {
                case _ where translation.y < -self.view.bounds.maxY / 3:
                    showNextQuestion()
                    pan.setTranslation(CGPointZero, inView: self.view)
                case _ where translation.y < -20 && translation.y > -self.view.bounds.maxY / 4:
                    print("upvote fired")
                    answerVC.votedAnswer(.Upvote)
                case _ where translation.y > self.view.bounds.maxY / 3:
                    showPriorQuestion()
                    pan.setTranslation(CGPointZero, inView: self.view)
                case _ where translation.y > 20 && translation.y < self.view.bounds.maxY / 4:
                    answerVC.votedAnswer(.Downvote)
                case _ where panCurrentPointX > self.view.bounds.width:
                    goBack(self)
                default:
                    self.view.center = CGPoint(x: self.view.bounds.width / 2, y: pan.view!.center.y)
                    pan.setTranslation(CGPointZero, inView: self.view)
                }
            }
        } else {
            let translation = pan.translationInView(self.view)

            if _isShowingCamera {
                //cameraVC will handle
            } else if (translation.y < -20 || translation.y > 20) {
                //ignore moving the screen if user was trying to move up / down - ha
            }
            else if (translation.x > 0) { //only go back but not go forward - animates as dragging the view off
                self.view.center = CGPoint(x: pan.view!.center.x + translation.x, y: pan.view!.center.y)
                pan.setTranslation(CGPointZero, inView: self.view)
            }
        }
    }
}