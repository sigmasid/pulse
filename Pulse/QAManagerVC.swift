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
    func removeQuestionPreview()
    func doneRecording(_: NSURL?, image: UIImage?, currentVC : UIViewController, location: String?, assetType : CreatedAssetType?)
    func askUserToLogin(_: UIViewController)
    func loginSuccess(_ : UIViewController)
    func doneUploadingAnswer(_: UIViewController)
//    func userDismissedCamera(_: UIViewController)

    func userDismissedCamera()
    func userDismissedRecording(_: UIViewController, _currentAnswers : [Answer])
    func showAlbumPicker(_: UIViewController)
    func minAnswersShown()
    func askUserQuestion()
    func showNextQuestion()
    func goBack(_ : UIViewController)
    func showQuestionPreviewOverlay()
    func userClickedAddMoreToAnswer(_ : UIViewController, _currentAnswers : [Answer])
}

class QAManagerVC: UINavigationController, childVCDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    // delegate vars
    var selectedTag : Tag!
    var allQuestions = [Question?]()
    var questionCounter = 0
    var currentQuestion = Question!(nil)
    private var currentAnswers = [Answer]()
    
    /* CHILD VIEW CONTROLLERS */
    private var loadingView : LoadingView?

    private let answerVC = ShowAnswerVC()
    private var cameraVC : CameraVC!
    private lazy var savedRecordedVideoVC : UserRecordedAnswerVC = UserRecordedAnswerVC()
    private var questionPreviewVC : QuestionPreviewVC?
    
    private var _hasMoreAnswers = false
//    private var _isShowingUserRecordedVideo = false
    private var _isAddingMoreAnswers = false
    private var _isShowingQuestionPreview = false
    
    private var panDismissInteractionController = PanContainerInteractionController()
    private var panStartingPointX : CGFloat = 0
    private var panStartingPointY : CGFloat = 0
    
    private var rectToRight : CGRect!
    private var rectToLeft : CGRect!
    private var isLoaded = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init() {
        super.init(nibName:nil, bundle:nil)
        navigationBarHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        panGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
//        panGestureRecognizer.edges = .Left
//        view.addGestureRecognizer(panGestureRecognizer)
        
        if !isLoaded {
            delegate = self // set the navigation controller delegate
            displayQuestion()
            
            rectToLeft = view.frame
            rectToLeft.origin.x = view.frame.minX - view.frame.size.width
            
            rectToRight = view.frame
            rectToRight.origin.x = view.frame.maxX
            

            loadingView = LoadingView(frame: self.view.bounds, backgroundColor: UIColor.whiteColor())
            loadingView?.addIcon(IconSizes.Medium, _iconColor: UIColor.blackColor(), _iconBackgroundColor: nil)
            loadingView?.addMessage("Loading...")
            
//            view.addSubview(loadingView!)
        
            isLoaded = true
        }
    }
    
    override func viewDidAppear(animated: Bool) {
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
        
        pushViewController(answerVC, animated: false)
        answerVC.view.alpha = 1.0 // to make sure view did load fires - push / add controllers does not guarantee view is loaded
        
        showQuestionPreviewOverlay()
    }
    
    private func loadNextQuestion(completion: (question : Question?, error : NSError?) -> Void) {
        questionCounter += 1
        
        if (questionCounter >= allQuestions.count && selectedTag.totalQuestionsForTag() >  questionCounter) {
            Database.getQuestion(selectedTag.questions![questionCounter].qID, completion: { (question, error) in
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
    
    /* user finished recording video or image - send to user recorded answer to add more or post */
    func doneRecording(assetURL : NSURL?, image: UIImage?, currentVC : UIViewController, location: String?, assetType : CreatedAssetType?){
        let answerKey = databaseRef.child("answers").childByAutoId().key
        let answer = Answer(aID: answerKey, qID: self.currentQuestion!.qID, uID: User.currentUser!.uID!, aType: assetType!, aLocation: location, aImage: image, aURL: assetURL)
        
        savedRecordedVideoVC.delegate = self
        
        currentAnswers.append(answer)
        savedRecordedVideoVC.currentQuestion = currentQuestion
        savedRecordedVideoVC.isNewEntry = true
        savedRecordedVideoVC.currentAnswers = currentAnswers
        savedRecordedVideoVC.currentAnswerIndex += 1
        
        pushViewController(savedRecordedVideoVC, animated: true)
    }
    
    private func returnToRecordings() {
        savedRecordedVideoVC.currentQuestion = currentQuestion
        savedRecordedVideoVC.isNewEntry = false
        savedRecordedVideoVC.currentAnswers = currentAnswers
        
        pushViewController(savedRecordedVideoVC, animated: true)
    }
    
    /* check if social token available - if yes, then login and post on return, else ask user to login */
    func askUserToLogin(currentVC : UIViewController) {
        Database.checkSocialTokens({ result in
            if !result {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let showLoginVC = storyboard.instantiateViewControllerWithIdentifier("LoginVC") as? LoginVC {
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
    
    func userClickedAddMoreToAnswer(currentVC : UIViewController, _currentAnswers : [Answer]) {
        savedRecordedVideoVC = currentVC as! UserRecordedAnswerVC
        currentAnswers = _currentAnswers
        _isAddingMoreAnswers = true
        popViewControllerAnimated(true)
    }
    
    func doneUploadingAnswer(currentVC: UIViewController) {
        currentAnswers.removeAll() // empty current answers array
        
        if _hasMoreAnswers {
            returnToAnswers()
            popToViewController(answerVC, animated: true)
        } else {
            self.loadNextQuestion({ (question, error) in
                if error != nil {
                    if error?.domain == "ReachedEnd" {
                        self.dismissViewControllerAnimated(true, completion: nil)
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
                    self.dismissViewControllerAnimated(true, completion: nil)
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
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            } else {
                self.showQuestionPreviewOverlay()
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
                showCamera()
            }
        } else {
            showCamera()
        }
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
        showCamera(true)
    }
    
    func showCamera(animated : Bool) {
        cameraVC = CameraVC()
        cameraVC.childDelegate = self
        cameraVC.questionToShow = currentQuestion
        
        cameraVC.transitioningDelegate = self
        
        panDismissInteractionController.wireToViewController(cameraVC, toViewController: nil, parentViewController: self)
        panDismissInteractionController.delegate = self
        pushViewController(cameraVC, animated: animated)
    }
    
    func showAlbumPicker(currentVC : UIViewController) {
        let albumPicker = UIImagePickerController()
        albumPicker.delegate = self
        albumPicker.allowsEditing = false
        albumPicker.sourceType = .PhotoLibrary
        albumPicker.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
        
        presentViewController(albumPicker, animated: true, completion: nil)
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
            popViewControllerAnimated(true)
            _isShowingQuestionPreview = false
        }
    }
    
    func userDismissedRecording(currentVC : UIViewController, _currentAnswers : [Answer]) {
        currentAnswers = _currentAnswers
        
        popViewControllerAnimated(false)
        _isAddingMoreAnswers = false
        showCamera()
    }
    
    func userDismissedCamera() {
        if _isAddingMoreAnswers {
            returnToRecordings()
        } else if _hasMoreAnswers {
            returnToAnswers()
        } else {
            self.loadNextQuestion({ (question, error) in
                if error != nil {
                    if error?.domain == "ReachedEnd" {
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                } else {
                    self.popViewControllerAnimated(false)
                    self.showQuestionPreviewOverlay()
                    self.currentQuestion = question
                    self.answerVC.currentQuestion = question
                }
            })
        }
    }
    
    func returnToAnswers() {
        answerVC.view.hidden = false
        answerVC.handleTap()
    }
    
    func goBack(currentVC : UIViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func loginSuccess (currentVC : UIViewController) {
        savedRecordedVideoVC._post()
        popViewControllerAnimated(true)
//        GlobalFunctions.dismissVC(currentVC)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        if mediaType.isEqualToString(kUTTypeImage as String) {
            
            let pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage            
            doneRecording(nil, image: pickedImage, currentVC: picker, location: nil, assetType: .albumImage)
            // Media is an image

        } else if mediaType.isEqualToString(kUTTypeMovie as String) {
            
            let videoURL = info[UIImagePickerControllerMediaURL] as? NSURL
            doneRecording(videoURL, image: nil, currentVC: picker, location: nil, assetType: .albumVideo)
            // Media is a video
        }
        picker.dismissViewControllerAnimated(true, completion: nil)
//        GlobalFunctions.dismissVC(picker)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
//        showCamera()
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func navigationController(navigationController: UINavigationController,
                              animationControllerForOperation operation: UINavigationControllerOperation,
                              fromViewController fromVC: UIViewController,
                             toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .Pop:
            if fromVC is CameraVC {
                let animator = ShrinkDismissController()
                animator.transitionType = .Dismiss
                animator.shrinkToView = UIView(frame: CGRectMake(20,400,40,40))

                return animator
            } else {
                return nil
            }
        case .Push:
            print("is push operation")
            return nil
        case .None:
            print("is no operation")

            return nil
        }
    }
    
    func navigationController(navigationController: UINavigationController,
                                interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if panDismissInteractionController.interactionInProgress{
            print("pan is in progress, returning panDismissController")
        }
        
        return panDismissInteractionController.interactionInProgress ? panDismissInteractionController : nil
    }
}





/** OLD **/
extension QAManagerVC: UIViewControllerTransitioningDelegate {
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        print("animation for presented controller fired")

        if presented is CameraVC {
            let animator = FadeAnimationController()
            animator.transitionType = .Present
            
            return animator
        } else {
            return nil
        }
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is CameraVC {
            let animator = ShrinkDismissController()
            animator.transitionType = .Dismiss
            animator.shrinkToView = UIView(frame: CGRectMake(20,400,40,40))
            
            return animator
        } else {
            return nil
        }
    }
    
    func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return panDismissInteractionController.interactionInProgress ? panDismissInteractionController : nil
    }
}

/* PAN GESTURE HANDLER */
//    func handlePan(pan : UIPanGestureRecognizer) {
//        let panCurrentPointX = pan.view!.center.x
//        let _ = pan.view!.center.y
//
//        if (pan.state == UIGestureRecognizerState.Began) {
//            panStartingPointX = pan.view!.center.x
//            panStartingPointY = pan.view!.center.y
//        }
//
//        else if (pan.state == UIGestureRecognizerState.Ended) {
//            let translation = pan.translationInView(self.view)
//            if _isShowingUserRecordedVideo {
//                //userRecordedVC will handle
//            } else {
//                switch translation {
//                case _ where translation.y < -self.view.bounds.maxY / 3:
//                    showNextQuestion()
//                    pan.setTranslation(CGPointZero, inView: self.view)
//                    self.view.center = CGPoint(x: view.bounds.width / 2, y: pan.view!.center.y)
//                case _ where translation.y < -20 && translation.y > -self.view.bounds.maxY / 4:
//                    return
////                    answerVC.votedAnswer(.Upvote)
//                case _ where translation.y > view.bounds.maxY / 3:
//                    showPriorQuestion()
//                    pan.setTranslation(CGPointZero, inView: view)
//                    self.view.center = CGPoint(x: view.bounds.width / 2, y: pan.view!.center.y)
//
//                case _ where translation.y > 20 && translation.y < self.view.bounds.maxY / 4:
//                    return
////                    answerVC.votedAnswer(.Downvote)
//                default:
//                    self.view.center = CGPoint(x: view.bounds.width / 2, y: pan.view!.center.y)
//                    pan.setTranslation(CGPointZero, inView: view)
//                }
//            }
//        } else {
//            let translation = pan.translationInView(view)
//
//            if _isShowingUserRecordedVideo {
//                //userRecordedVC will handle
//            }else if (translation.y < -20 || translation.y > 20) {
//                self.view.center = CGPoint(x: self.view.bounds.width / 2, y: pan.view!.center.y)
//                //ignore moving the screen if user was trying to move up / down
//            }
//            else if (translation.x > 0) { //only go back but not go forward - animates as dragging the view off
//                self.view.center = CGPoint(x: pan.view!.center.x + translation.x, y: pan.view!.center.y)
//                pan.setTranslation(CGPointZero, inView: view)
//            }
//        }
//    }
