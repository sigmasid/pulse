//
//  QAManagerVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import MobileCoreServices

protocol childVCDelegate: class {
    func noAnswersToShow(_ : UIViewController)
    func hasAnswersToShow()
    func doneRecording(_: NSURL?, currentVC : UIViewController, location: String?, assetType : AssetType?)
    func askUserToLogin(_: UIViewController)
    func loginSuccess(_ : UIViewController)
    func doneUploadingAnswer(_: UIViewController)
    func userDismissedCamera(_: UIViewController)
    func userDismissedRecording(_: UIViewController)
    func showAlbumPicker(_: UIViewController)
    func minAnswersShown()
    func askUserQuestion()
    func showNextQuestion()
    func goBack(_ : UIViewController)
    func showQuestionPreviewOverlay()
}

class QAManagerVC: UIViewController, childVCDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    // delegate vars
    var selectedTag : Tag!
    var allQuestions = [Question?]()
    var questionCounter = 0
    var currentQuestion = Question!(nil)
    
    private var savedRecordedVideoVC : UserRecordedAnswerVC?
    private var questionPreviewOverlay : QuestionPreviewOverlay?
    private let answerVC = ShowAnswerVC()
    weak var returnToParentDelegate : ParentDelegate!
    private var loadingView : LoadingView?
    
    private var _hasMoreAnswers = false
    private var _isShowingCamera = false
    private var _isShowingUserRecordedVideo = false

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
        showQuestionPreviewOverlay()
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
    
    func doneRecording(assetURL : NSURL?, currentVC : UIViewController, location: String?, assetType : AssetType?){
        _isShowingCamera = false

        let userAnswer = UserRecordedAnswerVC()
        userAnswer.answerDelegate = self
        
        userAnswer.fileURL = assetURL
        userAnswer.currentQuestion = currentQuestion
        userAnswer.aLocation = location
        userAnswer.currentAssetType = assetType
        
        _isShowingUserRecordedVideo = true
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
        _isShowingUserRecordedVideo = false
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
        loadNextQuestion({ (question, error) in
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
        loadPriorQuestion({ (question, error) in
            if error != nil {
                if error?.domain == "ReachedBeginning" {
                    self.returnToParentDelegate.returnToParent(self)
                }
            } else {
                self.answerVC.currentQuestion = question
            }
        })
    }
    
    func askUserQuestion() {
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
    
    func noAnswersToShow(currentVC : UIViewController) {
        if _hasMoreAnswers {
            showNextQuestion()
            _hasMoreAnswers = false
        } else if User.isLoggedIn() {
            if User.currentUser!.hasAnsweredQuestion(currentQuestion.qID) {
                showNextQuestion()
                _hasMoreAnswers = false
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
        _cameraVC.view.alpha = 0
        
        UIView.animateWithDuration(1, animations: { _cameraVC.view.alpha = 1.0; self.questionPreviewOverlay?.alpha = 0 } , completion: {(value: Bool) in
            GlobalFunctions.addNewVC(_cameraVC, parentVC: self)
            self.removeQuestionPreviewOverlay()
        })
    }
    
    func showAlbumPicker(currentVC : UIViewController) {
        let albumPicker = UIImagePickerController()
        albumPicker.delegate = self
        albumPicker.allowsEditing = false
        albumPicker.sourceType = .PhotoLibrary
        albumPicker.mediaTypes = [kUTTypeMovie as String]
        
        GlobalFunctions.cycleBetweenVC(currentVC, newVC: albumPicker, parentVC: self)
    }
    
    func showQuestionPreviewOverlay() {
//        print("adding question preview overlay")
        questionPreviewOverlay = QuestionPreviewOverlay(frame: view.frame)
        questionPreviewOverlay!.setQuestionLabel(currentQuestion.qTitle)
        questionPreviewOverlay!.setNumAnswersLabel(currentQuestion.totalAnswers())
        view.addSubview(questionPreviewOverlay!)
    }
    
    private func removeQuestionPreviewOverlay() {
//        print("removing question preview overlay")
        UIView.animateWithDuration(1, animations: { self.questionPreviewOverlay?.alpha = 0 } , completion: {(value: Bool) in
            self.questionPreviewOverlay?.removeFromSuperview()
        })
    }
    
    func hasAnswersToShow() {
        answerVC.view.hidden = false
        removeQuestionPreviewOverlay()
    }
    
    func userDismissedRecording(currentVC : UIViewController) {
        _isShowingUserRecordedVideo = false
        GlobalFunctions.dismissVC(currentVC, _animationStyle: .VerticalDown)
        showCamera()
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
            if _isShowingCamera {
                //cameraVC will handle
            } else if _isShowingUserRecordedVideo {
                //userRecordedVC will handle
            } else {
                switch translation {
                case _ where translation.y < -self.view.bounds.maxY / 3:
                    showNextQuestion()
                    pan.setTranslation(CGPointZero, inView: self.view)
                    self.view.center = CGPoint(x: self.view.bounds.width / 2, y: pan.view!.center.y) /*ADDED*/
                case _ where translation.y < -20 && translation.y > -self.view.bounds.maxY / 4:
                    answerVC.votedAnswer(.Upvote)
                case _ where translation.y > self.view.bounds.maxY / 3:
                    showPriorQuestion()
                    pan.setTranslation(CGPointZero, inView: self.view)
                    self.view.center = CGPoint(x: self.view.bounds.width / 2, y: pan.view!.center.y) /*ADDED*/

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
            } else if _isShowingUserRecordedVideo {
                //userRecordedVC will handle
            }else if (translation.y < -20 || translation.y > 20) {
                self.view.center = CGPoint(x: self.view.bounds.width / 2, y: pan.view!.center.y) /*ADDED*/
                //ignore moving the screen if user was trying to move up / down - ha
            }
            else if (translation.x > 0) { //only go back but not go forward - animates as dragging the view off
                self.view.center = CGPoint(x: pan.view!.center.x + translation.x, y: pan.view!.center.y)
                pan.setTranslation(CGPointZero, inView: self.view)
            }
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        if mediaType.isEqualToString(kUTTypeImage as String) {
            
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            // Media is an image
//            doneRecording(videoURL, currentVC: picker, location: nil, assetType: .albumVideo)

            
        } else if mediaType.isEqualToString(kUTTypeMovie as String) {
            
            let videoURL = info[UIImagePickerControllerMediaURL] as? NSURL
            doneRecording(videoURL, currentVC: picker, location: nil, assetType: .albumVideo)
            // Media is a video
            
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        showCamera()
        GlobalFunctions.dismissVC(picker)
    }
}