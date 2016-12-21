//
//  QAManagerVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import MobileCoreServices

protocol cameraDelegate : class {
    func doneRecording(_: URL?, image: UIImage?, currentVC : UIViewController, location: String?, assetType : CreatedAssetType?)
    func userDismissedCamera()
    func showAlbumPicker(_: UIViewController)
}

protocol childVCDelegate: class {
    func noAnswersToShow(_ : UIViewController)
    func removeQuestionPreview()
    func askUserToLogin(_: UIViewController)
    func loginSuccess(_ : UIViewController)
    func doneUploadingAnswer(_: UIViewController)

    func userDismissedRecording(_: UIViewController, _currentAnswers : [Answer])
    func minAnswersShown()
    func askUserQuestion()
    func showNextQuestion()
    //func goBack(_ : UIViewController)
    func showQuestionPreviewOverlay()
    func userClickedAddMoreToAnswer(_ : UIViewController, _currentAnswers : [Answer])
}

class QAManagerVC: UINavigationController, childVCDelegate, cameraDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    // delegate vars
    var selectedTag : Tag!
    var allQuestions = [Question?]()
    var questionCounter = 0
    var currentQuestion : Question!
    var answerIndex = 0
    var watchedFullPreview = false
    
    var openingScreen : OpeningScreenOptions = .question
    enum OpeningScreenOptions { case camera, question }

    fileprivate var currentAnswers = [Answer]()
    
    /* CHILD VIEW CONTROLLERS */
    fileprivate var loadingVC = LoadingVC()

    fileprivate let answerVC = ShowAnswerVC()
    fileprivate var cameraVC : CameraVC!
    fileprivate lazy var savedRecordedVideoVC : UserRecordedAnswerVC = UserRecordedAnswerVC()
    fileprivate var questionPreviewVC : QuestionPreviewVC?
    
    fileprivate var _hasMoreAnswers = false
    fileprivate var _isCameraLoaded = false
    fileprivate var _isAddingMoreAnswers = false
    fileprivate var _isShowingQuestionPreview = false
    
    fileprivate var panDismissInteractionController = PanContainerInteractionController()
    
    fileprivate var isLoaded = false
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init() {
        super.init(nibName:nil, bundle:nil)
        isNavigationBarHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if !isLoaded {
            delegate = self // set the navigation controller delegate
            pushViewController(loadingVC, animated: false)
            
            if openingScreen == .question {
                displayQuestion()
            } else {
                showCamera()
            }
            
            isLoaded = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /* QA Specific Methods */
    func displayQuestion() {
        
        answerVC.currentQuestion = currentQuestion
        answerVC.currentTag = selectedTag
        answerVC.answerIndex = answerIndex
        answerVC.delegate = self
        
        pushViewController(answerVC, animated: false)
        answerVC.view.alpha = 1.0 // to make sure view did load fires - push / add controllers does not guarantee view is loaded
        
        panDismissInteractionController.wireToViewController(answerVC, toViewController: nil, parentViewController: self)
        panDismissInteractionController.delegate = self

        showQuestionPreviewOverlay()
    }
    
    fileprivate func loadNextQuestion(_ completion: @escaping (_ question : Question?, _ error : NSError?) -> Void) {
        questionCounter += 1
        if (questionCounter >= allQuestions.count && selectedTag.totalQuestionsForTag() >  questionCounter) {
            Database.getQuestion(selectedTag.questions[questionCounter]!.qID, completion: { (question, error) in
                if error != nil {
                    completion(nil, error)
                } else {
                    self.allQuestions.append(question)
                    self.currentQuestion = question
                    completion(question, nil)
                }
            })
        } else if (questionCounter >= selectedTag.totalQuestionsForTag()) {
            let userInfo = [ NSLocalizedDescriptionKey : "browsed all questions for tag" ]
            completion(nil, NSError.init(domain: "ReachedEnd", code: 200, userInfo: userInfo))
        } else {
            currentQuestion = allQuestions[questionCounter]
            completion(currentQuestion, nil)
        }
    }
    
    fileprivate func loadPriorQuestion(_ completion: (_ question : Question?, _ error : NSError?) -> Void) {
        questionCounter -= 1
        
        if (questionCounter >= 0) {
            currentQuestion = allQuestions[questionCounter]
            completion(currentQuestion, nil)
        } else if (questionCounter < 0) {
            questionCounter += 1
            let userInfo = [ NSLocalizedDescriptionKey : "reached beginning" ]
            completion(nil, NSError.init(domain: "ReachedBeginning", code: 200, userInfo: userInfo))
        }
    }
    
    /* user finished recording video or image - send to user recorded answer to add more or post */
    func doneRecording(_ assetURL : URL?, image: UIImage?, currentVC : UIViewController, location: String?, assetType : CreatedAssetType?){
        let answerKey = databaseRef.child("answers").childByAutoId().key
        let answer = Answer(aID: answerKey,
                            qID: self.currentQuestion!.qID,
                            uID: User.currentUser!.uID!,
                            aType: assetType!,
                            aLocation: location,
                            aImage: image,
                            aURL: assetURL)
        
        savedRecordedVideoVC.delegate = self
        
        currentAnswers.append(answer)
        savedRecordedVideoVC.currentQuestion = currentQuestion
        savedRecordedVideoVC.isNewEntry = true
        savedRecordedVideoVC.currentAnswers = currentAnswers
        savedRecordedVideoVC.currentAnswerIndex += 1
        
        pushViewController(savedRecordedVideoVC, animated: true)
    }
    
    fileprivate func returnToRecordings() {
        savedRecordedVideoVC.currentQuestion = currentQuestion
        savedRecordedVideoVC.isNewEntry = false
        savedRecordedVideoVC.currentAnswers = currentAnswers
        
        pushViewController(savedRecordedVideoVC, animated: true)
    }
    
    /* check if social token available - if yes, then login and post on return, else ask user to login */
    func askUserToLogin(_ currentVC : UIViewController) {
        Database.checkSocialTokens({ result in
            if !result {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let showLoginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginVC {
                    GlobalFunctions.addNewVC(showLoginVC, parentVC: self)
                    showLoginVC.loginVCDelegate = self
                    self.savedRecordedVideoVC = currentVC as! UserRecordedAnswerVC
                }
            } else {
                if let _userAnswerVC = currentVC as? UserRecordedAnswerVC {
                    _userAnswerVC._post()
                }
            }
        })
    }
    
    func userClickedAddMoreToAnswer(_ currentVC : UIViewController, _currentAnswers : [Answer]) {
        savedRecordedVideoVC = currentVC as! UserRecordedAnswerVC
        currentAnswers = _currentAnswers
        _isAddingMoreAnswers = true
        popViewController(animated: true)
    }
    
    func doneUploadingAnswer(_ currentVC: UIViewController) {
        currentAnswers.removeAll() // empty current answers array
        
        if _hasMoreAnswers {
            returnToAnswers()
            popToViewController(answerVC, animated: true)
        } else {
            self.loadNextQuestion({ (question, error) in
                if error != nil {
                    if error?.domain == "ReachedEnd" {
                        self.dismiss(animated: true, completion: nil)
                    }
                } else {
                    self.answerVC.currentQuestion = question
                    self.popToViewController(self.answerVC, animated: true)
                }
            })
        }
    }
    
    func showNextQuestion() {
        loadNextQuestion({ (question, error) in
            if error != nil {
                if error?.domain == "ReachedEnd" {
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                self.showQuestionPreviewOverlay()
                self.answerVC.currentQuestion = question
            }
        })
    }
    
    func showPriorQuestion() {
        loadPriorQuestion({ (question, error) in
            if error != nil {
                if error?.domain == "ReachedBeginning" {
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                self.showQuestionPreviewOverlay()
                self.answerVC.currentQuestion = question
            }
        })
    }
    
    func askUserQuestion() {
        if User.isLoggedIn() {
            User.currentUser!.canAnswer(qID: currentQuestion.qID, tag: selectedTag, completion: { (success, errorTitle, errorDescription) in
                if success {
                    answerVC.view.isHidden = true
                    _hasMoreAnswers = true
                    showCamera()
                } else {
                    returnToAnswers()
                }
            })
        } else {
            answerVC.view.isHidden = true
            _hasMoreAnswers = true
            showCamera()
        }
    }
    
    func noAnswersToShow(_ currentVC : UIViewController) {
        if User.isLoggedIn() {
            User.currentUser!.canAnswer(qID: currentQuestion.qID, tag: selectedTag, completion: { (success, errorTitle, errorDescription) in
            if success {
                showCamera()
            } else {
                _hasMoreAnswers = false
                dismiss(animated: true, completion: nil)
            }
            })
        }

        /** //old way -- show next question
        if _hasMoreAnswers {
            showNextQuestion()
            _hasMoreAnswers = false
        } else if User.isLoggedIn() {
            User.currentUser!.canAnswer(qID: currentQuestion.qID, tag: selectedTag, completion: { (success, errorTitle, errorDescription) in
                if success {
                    showCamera()
                } else {
                    showNextQuestion()
                    _hasMoreAnswers = false
                }
            })
        } else {
            showNextQuestion()
            _hasMoreAnswers = false
        } 
        **/
    }
    
    func minAnswersShown() {
        if User.isLoggedIn() {
            if User.currentUser!.hasAnsweredQuestion(currentQuestion.qID) {
                returnToAnswers()
            } else {
                _hasMoreAnswers = true
                showCamera()
            }
        } else {
            _hasMoreAnswers = true
            showCamera()
        }
    }
    
    func showCamera() {
        if !_isCameraLoaded {
            showCamera(true)
            _isCameraLoaded = true
        }
    }
    
    func showCamera(_ animated : Bool) {
        cameraVC = CameraVC()
        cameraVC.delegate = self
        cameraVC.screenTitle = currentQuestion.qTitle
                
        panDismissInteractionController.wireToViewController(cameraVC, toViewController: nil, parentViewController: self)
        panDismissInteractionController.delegate = self
        pushViewController(cameraVC, animated: animated)
    }
    
    func showAlbumPicker(_ currentVC : UIViewController) {
        let albumPicker = UIImagePickerController()
        albumPicker.delegate = self
        albumPicker.allowsEditing = false
        albumPicker.sourceType = .photoLibrary
        albumPicker.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
        
        present(albumPicker, animated: true, completion: nil)
    }
    
    func showQuestionPreviewOverlay() {

        questionPreviewVC = QuestionPreviewVC()
        questionPreviewVC?.questionTitle = currentQuestion.qTitle
        questionPreviewVC?.numAnswers =  currentQuestion.totalAnswers()
        
        pushViewController(questionPreviewVC!, animated: true)
        _isShowingQuestionPreview = true
    }
    
    func removeQuestionPreview() {

        if _isShowingQuestionPreview {
            popViewController(animated: true)
            _isShowingQuestionPreview = false
        }
    }
    
    func userDismissedRecording(_ currentVC : UIViewController, _currentAnswers : [Answer]) {
        currentAnswers = _currentAnswers
        
        popViewController(animated: true)
        _isAddingMoreAnswers = false
        showCamera()
    }
    
    func userDismissedCamera() {
        if _isAddingMoreAnswers {
            returnToRecordings()
        } else if _hasMoreAnswers {
            returnToAnswers()
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func returnToAnswers() {
        answerVC.view.isHidden = false
        answerVC.handleTap()
    }
    
    func loginSuccess (_ currentVC : UIViewController) {
        savedRecordedVideoVC._post()
        popViewController(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        if mediaType.isEqual(to: kUTTypeImage as String) {
            
            let pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage            
            doneRecording(nil, image: pickedImage, currentVC: picker, location: nil, assetType: .albumImage)
            // Media is an image

        } else if mediaType.isEqual(to: kUTTypeMovie as String) {
            
            let videoURL = info[UIImagePickerControllerMediaURL] as? URL
            doneRecording(videoURL, image: nil, currentVC: picker, location: nil, assetType: .albumVideo)
            // Media is a video
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        showCamera()
        picker.dismiss(animated: true, completion: nil)
    }
    
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationControllerOperation,
                              from fromVC: UIViewController,
                             to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        switch operation {
        case .pop:
            if fromVC is CameraVC {
                let animator = ShrinkDismissController()
                animator.transitionType = .dismiss
                animator.shrinkToView = UIView(frame: CGRect(x: 20,y: 400,width: 40,height: 40))

                return animator
            } else if fromVC is UserRecordedAnswerVC && toVC is CameraVC {
                let animator = FadeAnimationController()
                animator.transitionType = .dismiss
                return animator
            } else if fromVC is ShowAnswerVC {
                let animator = ShrinkDismissController()
                animator.transitionType = .dismiss
                animator.shrinkToView = UIView(frame: CGRect(x: 20,y: 400,width: 40,height: 40))
                
                return animator

            } else {

                return nil
            }
        case .push:
            if toVC is UserRecordedAnswerVC {
                let animator = FadeAnimationController()
                animator.transitionType = .present
                
                return animator
            } else if toVC is CameraVC && fromVC is UserRecordedAnswerVC {
                let animator = FadeAnimationController()
                animator.transitionType = .present
                
                return animator
            } else if fromVC is CameraVC && toVC is QuestionPreviewVC {
                let animator = ShrinkDismissController()
                animator.transitionType = .dismiss
                animator.shrinkToView = UIView(frame: CGRect(x: 20,y: 400,width: 40,height: 40))

                return animator

            } else {
                return nil
            }
        case .none:
            return nil
        }
    }
    
    func navigationController(_ navigationController: UINavigationController,
                                interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return panDismissInteractionController.interactionInProgress ? panDismissInteractionController : nil
    }
}
