//
//  QAManagerVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import MobileCoreServices
import CoreLocation

protocol CameraDelegate : class {
    func doneRecording(_: URL?, image: UIImage?, location: CLLocation?, assetType : CreatedAssetType?)
    func userDismissedCamera()
    func showAlbumPicker()
}

protocol ContentDelegate: class {
    func noItemsToShow(_ : UIViewController)
    func removeIntro()
    func askUserToLogin(_: UIViewController)
    func loginSuccess(_ : UIViewController)
    func doneUploadingAnswer(_: UIViewController)

    func userDismissedRecording(_: UIViewController, recordedItems : [Item])
    func minItemsShown()
    func askUserQuestion()
    func loadMoreFromTag()
    func addMoreItems(_ : UIViewController, recordedItems : [Item])
    func userClickedSeeAll()
    func userClickedProfileDetail()
}

class ContentManagerVC: PulseNavVC, ContentDelegate, CameraDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    //set by delegate - questions or posts
    var selectedChannel : Channel! //all items need a channel - only for adding new posts / answers
    var selectedItem: Item! //the category item - might be the question / tag / post etc.
    var allItems = [Item]()
    
    var itemIndex = 0
    
    var watchedFullPreview = false
    var itemCollection = [Item]()
    
    var openingScreen : OpeningScreenOptions = .item
    enum OpeningScreenOptions { case camera, item }

    fileprivate var recordedItems = [Item]()
    
    /* CHILD VIEW CONTROLLERS */
    fileprivate var loadingVC = LoadingVC()

    fileprivate let contentDetailVC = ContentDetailVC()
    fileprivate var cameraVC : CameraVC!
    fileprivate lazy var recordedVideoVC : RecordedVideoVC = RecordedVideoVC()
    fileprivate var introVC : ContentIntroVC?
    
    fileprivate var hasMoreItems = false
    fileprivate var isCameraLoaded = false
    fileprivate var isAddingMoreItems = false
    fileprivate var isShowingIntro = false
    fileprivate var isLoaded = false
    
    fileprivate var panDismissInteractionController = PanContainerInteractionController()
    
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
            
            if openingScreen == .item {
                showItem()
            } else if openingScreen == .camera {
                showCamera()
            }
            
            isLoaded = true
        }
    }
    
    deinit {
        selectedChannel = nil
        selectedItem = nil //the category item - might be the question / tag / post etc.
        allItems = []
        
        itemCollection = []
        recordedItems = []
        
        contentDetailVC.delegate = nil
        panDismissInteractionController.delegate = nil
        recordedVideoVC.delegate = nil
        
        if cameraVC != nil {
            cameraVC.delegate = nil
            cameraVC = nil
        }
        
        introVC = nil
        cameraVC = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /* QA Specific Methods */
    func showItem() {
        contentDetailVC.delegate = self

        panDismissInteractionController.wireToViewController(contentDetailVC, toViewController: nil, parentViewController: self)
        panDismissInteractionController.delegate = self

        //need to be set first - to determine if first clip should be answer detail or the answer itself
        contentDetailVC.watchedFullPreview = watchedFullPreview
        contentDetailVC.itemDetailCollection = itemCollection
        contentDetailVC.selectedChannel = selectedChannel
        contentDetailVC.itemIndex = itemIndex
        
        isNavigationBarHidden = true
        pushViewController(contentDetailVC, animated: false)
        
        contentDetailVC.allItems = allItems
        contentDetailVC.view.alpha = 1.0 // to make sure view did load fires - push / add controllers does not guarantee view is loaded
        
        contentDetailVC._isShowingIntro = true
        
        showIntro()
    }
    
    func loadMoreFromTag() {
        if let selectedTag = selectedItem.tag, !selectedTag.itemCreated {
            Database.getItemCollection(selectedTag.itemID, completion: { (success, items) in
                self.itemIndex = items.index(of: self.selectedItem) ?? 0
                self.allItems = items
            })
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func userClickedProfileDetail() {
        let userProfileVC = UserProfileVC(collectionViewLayout: GlobalFunctions.getPulseCollectionLayout())
        //popViewController(animated: false)
        isNavigationBarHidden = false
        pushViewController(userProfileVC, animated: true)
        userProfileVC.selectedUser = selectedItem?.user
    }
    
    func userClickedSeeAll() {
        let layout = GlobalFunctions.getPulseCollectionLayout()
        layout.sectionHeadersPinToVisibleBounds = true
        
        let itemCollection = BrowseCollectionVC(collectionViewLayout: layout)
        itemCollection.selectedChannel = selectedChannel
        itemCollection.selectedItem = selectedItem
        
        isNavigationBarHidden = false
        popViewController(animated: false)
        pushViewController(itemCollection, animated: true)
    }
    
    /* user finished recording video or image - send to user recorded answer to add more or post */
    func doneRecording(_ assetURL : URL?, image: UIImage?, location: CLLocation?, assetType : CreatedAssetType?){
        let itemKey = databaseRef.child("items").childByAutoId().key
        let item = Item(itemID: itemKey,
                        itemUserID: User.currentUser!.uID!,
                        itemTitle: selectedItem.type == .question ? selectedItem.itemTitle : "",
                        type: selectedItem.type == .question ? .answer : .post,
                        contentURL: assetURL,
                        content: image,
                        contentType: assetType,
                        tag: selectedItem.tag,
                        cID: selectedChannel.cID)
        
        recordedVideoVC.delegate = self
        recordedItems.append(item)

        recordedVideoVC.selectedChannelID = selectedChannel.cID
        recordedVideoVC.parentItemID = selectedItem.itemID
        recordedVideoVC.isNewEntry = true
        recordedVideoVC.recordedItems = recordedItems
        recordedVideoVC.currentItemIndex += 1
        
        pushViewController(recordedVideoVC, animated: true)
    }
    
    fileprivate func returnToRecordings() {
        //recordedVideoVC.selectedItem = selectedItem
        recordedVideoVC.isNewEntry = false
        recordedVideoVC.recordedItems = recordedItems
        
        pushViewController(recordedVideoVC, animated: true)
    }
    
    /* check if social token available - if yes, then login and post on return, else ask user to login */
    func askUserToLogin(_ currentVC : UIViewController) {
        Database.checkSocialTokens({ result in
            if !result {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let showLoginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginVC {
                    GlobalFunctions.addNewVC(showLoginVC, parentVC: self)
                    showLoginVC.loginVCDelegate = self
                    self.recordedVideoVC = currentVC as! RecordedVideoVC
                }
            } else {
                if let _userAnswerVC = currentVC as? RecordedVideoVC {
                    _userAnswerVC._post()
                }
            }
        })
    }

    
    func doneUploadingAnswer(_ currentVC: UIViewController) {
        recordedItems.removeAll() // empty current answers array
        
        if hasMoreItems {
            returnToAnswers()
            popToViewController(contentDetailVC, animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func askUserQuestion() {
        if User.isLoggedIn(), let selectedTag = selectedItem.tag {
            User.currentUser!.canAnswer(itemID: selectedItem.itemID, tag: selectedTag, completion: { (success, errorTitle, errorDescription) in
                if success {
                    contentDetailVC.view.isHidden = true
                    hasMoreItems = true
                    showCamera()
                } else {
                    returnToAnswers()
                }
            })
        } else {
            contentDetailVC.view.isHidden = true
            hasMoreItems = true
            showCamera()
        }
    }
    
    func noItemsToShow(_ currentVC : UIViewController) {
        if User.isLoggedIn(), selectedItem != nil, let selectedTag = selectedItem.tag {
            User.currentUser!.canAnswer(itemID: selectedItem.itemID, tag: selectedTag, completion: { (success, errorTitle, errorDescription) in
            if success {
                showCamera()
            } else {
                hasMoreItems = false
                dismiss(animated: false, completion: nil)
            }
            })
        } else {
            hasMoreItems = false
            dismiss(animated: false, completion: nil)
        }
    }
    
    func minItemsShown() {
        //NEEDS UPDATE
        if User.isLoggedIn() {
            hasMoreItems = true
            showCamera()
        } else {
            hasMoreItems = true
            showCamera()
        }
    }
    
    func showCamera() {
        if !isCameraLoaded {
            showCamera(true)
            isCameraLoaded = true
        }
    }
    
    func showCamera(_ animated : Bool) {
        cameraVC = CameraVC()
        cameraVC.delegate = self
        cameraVC.screenTitle = selectedItem.type == .question ? selectedItem.itemTitle : selectedItem.tag?.itemTitle ?? ""
        
        panDismissInteractionController.wireToViewController(cameraVC, toViewController: nil, parentViewController: self)
        panDismissInteractionController.delegate = self
        
        isNavigationBarHidden = true
        pushViewController(cameraVC, animated: animated)
    }
    
    func showAlbumPicker() {
        let albumPicker = UIImagePickerController()
        albumPicker.delegate = self
        albumPicker.allowsEditing = false
        albumPicker.sourceType = .photoLibrary
        albumPicker.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
        
        present(albumPicker, animated: true, completion: nil)
    }
    
    func showIntro() {
        introVC = ContentIntroVC()
        if selectedItem != nil {
            switch selectedItem.type {
            case .question, .answer:
                introVC?.itemTitle = selectedItem != nil ? selectedItem.itemTitle ?? allItems[itemIndex].itemTitle : allItems[itemIndex].itemTitle
            case .post:
                introVC?.itemTitle = selectedItem != nil ? selectedItem.tag?.itemTitle : allItems[itemIndex].tag?.itemTitle
            default: break
            }
            
            introVC?.numAnswers = allItems.count
            
            if let image = selectedItem.content as? UIImage {
                introVC?.image = image
            }
            
            isNavigationBarHidden = true
            pushViewController(introVC!, animated: true)
            isShowingIntro = true
        }
    }
    
    func removeIntro() {
        if isShowingIntro {
            popViewController(animated: true)
            isShowingIntro = false
        }
    }
    
    func addMoreItems(_ currentVC : UIViewController, recordedItems : [Item]) {
        recordedVideoVC = currentVC as! RecordedVideoVC
        self.recordedItems = recordedItems
        isAddingMoreItems = true
        
        if !self.viewControllers.contains(cameraVC) {
            popViewController(animated: false)
            pushViewController(cameraVC, animated: false)
        } else {
            popViewController(animated: true)
        }
    }
    
    //case where user closes the 'first' video
    func userDismissedRecording(_ currentVC : UIViewController, recordedItems : [Item]) {
        self.recordedItems = recordedItems
        
        popViewController(animated: true)
        isAddingMoreItems = false
        showCamera()
    }
    
    func userDismissedCamera() {
        if isAddingMoreItems {
            returnToRecordings()
        } else {
            dismiss(animated: false, completion: nil)
        }
    }
    
    func returnToAnswers() {
        contentDetailVC.view.isHidden = false
        contentDetailVC.handleTap()
    }
    
    func loginSuccess (_ currentVC : UIViewController) {
        recordedVideoVC._post()
        popViewController(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        if mediaType.isEqual(to: kUTTypeImage as String) {
            
            let pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage            
            doneRecording(nil, image: pickedImage, location: nil, assetType: .albumImage)
            // Media is an image

        } else if mediaType.isEqual(to: kUTTypeMovie as String) {
            
            let videoURL = info[UIImagePickerControllerMediaURL] as? URL
            doneRecording(videoURL, image: nil, location: nil, assetType: .albumVideo)
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
            } else if fromVC is RecordedVideoVC && toVC is CameraVC {
                let animator = FadeAnimationController()
                animator.transitionType = .dismiss
                return animator
            }
            else if fromVC is ContentIntroVC && toVC is ContentDetailVC {
                let animator = FadeAnimationController()
                animator.transitionType = .dismiss
                return animator
            } else if fromVC is ContentDetailVC {
                let animator = ShrinkDismissController()
                animator.transitionType = .dismiss
                animator.shrinkToView = UIView(frame: CGRect(x: 20,y: 400,width: 40,height: 40))
                
                return animator

            } else {

                return nil
            }
        case .push:
            if toVC is RecordedVideoVC {
                let animator = FadeAnimationController()
                animator.transitionType = .present
                
                return animator
            } else if toVC is CameraVC && fromVC is RecordedVideoVC {
                let animator = FadeAnimationController()
                animator.transitionType = .present
                
                return animator
            }
            else if fromVC is CameraVC && toVC is ContentIntroVC {
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
