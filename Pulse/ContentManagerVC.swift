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

class ContentManagerVC: PulseNavVC, ContentDelegate, CameraDelegate, BrowseContentDelegate, ModalDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    //set by delegate - questions or posts
    var selectedChannel : Channel! //all items need a channel - only for adding new posts / answers
    var selectedItem: Item! //the category item - might be the question / tag / post etc.
    var allItems = [Item]()
    var itemIndex = 0
    var watchedFullPreview = false
    var itemCollection = [Item]()
    var createdItemKey : String?
    
    var openingScreen : OpeningScreenOptions = .item
    enum OpeningScreenOptions { case camera, item }
    public weak var completedRecordingDelegate : CompletedRecordingDelegate!

    fileprivate var recordedItems = [Item]()
    
    /* CHILD VIEW CONTROLLERS */
    fileprivate var loadingVC : LoadingVC?

    fileprivate let contentDetailVC = ContentDetailVC()
    fileprivate var cameraVC : CameraVC!
    fileprivate lazy var recordedVideoVC : RecordedVideoVC = RecordedVideoVC()
    fileprivate var introVC : ContentIntroVC?
    
    fileprivate var hasMoreItems = false
    fileprivate var isCameraLoaded = false
    fileprivate var isAddingMoreItems = false
    fileprivate var isAddingCover = false
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
    
    override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
        isNavigationBarHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if !isLoaded {
            delegate = self // set the navigation controller delegate
            
            loadingVC = LoadingVC()
            pushViewController(loadingVC!, animated: false)
            
            if openingScreen == .item {
                showItemDetail(shouldShowIntro: true)
            } else if openingScreen == .camera {
                showCamera()
            }
            
            isLoaded = true
        }
    }
    
    deinit {
        print("content manager deinit fired")
        selectedChannel = nil
        selectedItem = nil //the category item - might be the question / tag / post etc.
        allItems = []
        
        itemCollection = []
        recordedItems = []
        
        contentDetailVC.delegate = nil
        panDismissInteractionController.delegate = nil
        recordedVideoVC.delegate = nil
        completedRecordingDelegate = nil
        
        if cameraVC != nil {
            cameraVC.delegate = nil
            cameraVC = nil
        }
        
        introVC = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /* Item Specific Methods */
    func showItemDetail(shouldShowIntro: Bool) {
        isNavigationBarHidden = true
        contentDetailVC.delegate = self
        panDismissInteractionController.wireToViewController(contentDetailVC, toViewController: nil, parentViewController: self)
        panDismissInteractionController.delegate = self

        //need to be set first - to determine if first clip should be answer detail or the answer itself
        contentDetailVC.watchedFullPreview = watchedFullPreview
        contentDetailVC.itemDetail = itemCollection
        contentDetailVC.selectedChannel = selectedChannel != nil ? selectedChannel : Channel(cID: selectedItem.cID, title: selectedItem.cTitle ?? "")
        contentDetailVC.selectedItem = selectedItem
        contentDetailVC.itemIndex = itemIndex
        
        if shouldShowIntro {
            pushViewController(contentDetailVC, animated: false)
            
            contentDetailVC.allItems = allItems
            contentDetailVC.view.alpha = 1.0 // to make sure view did load fires - push / add controllers does not guarantee view is loaded
            
            contentDetailVC._isShowingIntro = true
        
            showIntro()
        } else {
            //case where user is returning form quick browse
            
            contentDetailVC.allItems = allItems
            contentDetailVC.view.alpha = 1.0 // to make sure view did load fires - push / add controllers does not guarantee view is loaded
            
            dismiss(animated: true, completion: { _ in }) //dismisses the quick browse
        }
    }
    
    /** Browse Content Delegate **/
    internal func showItemDetail(allItems: [Item], index: Int, itemCollection: [Item], selectedItem : Item, watchedPreview : Bool) {
        self.allItems = allItems
        self.itemIndex = index
        self.itemCollection = itemCollection
        self.watchedFullPreview = watchedPreview

        showItemDetail(shouldShowIntro: false)
    }
    
    internal func addNewItem(selectedItem: Item) {
        dismiss(animated: true, completion: { _ in
            self.isNavigationBarHidden = true
            self.showCamera(animated: true)
        })
    }
    /** End Browse Content Delegate **/

    func loadMoreFromTag() {
        if let selectedTag = selectedItem.tag, !selectedTag.itemCreated {
            PulseDatabase.getItemCollection(selectedTag.itemID, completion: {[weak self] (success, items) in
                guard let `self` = self else {
                    return
                }
                self.itemIndex = items.index(of: self.selectedItem) ?? 0
                self.allItems = items
            })
        } else {
            dismiss(animated: true, completion: {
                self.transitioningDelegate = nil
            })
        }
    }
    
    func userClickedProfileDetail() {
        
        let userProfileVC = UserProfileVC()        
        userProfileVC.selectedUser = selectedItem?.user
        userProfileVC.modalDelegate = self

        present(userProfileVC, animated: true)
        
    }
    
    func userClosedModal(_ viewController : UIViewController) {
        dismiss(animated: true, completion: { _ in
            self.isNavigationBarHidden = true
        })
    }
    
    func userClickedSeeAll(items : [Item]) {
        let itemCollection = BrowseContentVC()
        itemCollection.selectedChannel = selectedChannel
        itemCollection.allItems = items
        itemCollection.selectedItem = selectedItem
        itemCollection.contentDelegate = self
        itemCollection.modalDelegate = self
                
        present(itemCollection, animated: true)
    }
    
    /* user finished recording video or image - send to user recorded answer to add more or post */
    func doneRecording(isCapturing: Bool, url assetURL : URL?, image: UIImage?, location: CLLocation?, assetType : CreatedAssetType?){
        if isAddingCover {
            recordedItems.first?.content = image
        } else {
            //in case parent provides key for first item use that (interview case) else create a new key. After creation marks the createdItemKey as nil
            let itemKey = createdItemKey != nil ? createdItemKey! : databaseRef.child("items").childByAutoId().key
            createdItemKey = nil
            
            let item = Item(itemID: itemKey,
                            itemUserID: PulseUser.currentUser.uID!,
                            itemTitle: getRecordedItemTitle(),
                            type: selectedItem.childItemType(),
                            contentURL: assetURL,
                            content: image,
                            contentType: assetType,
                            tag: selectedItem.tag ?? selectedItem, //if its a post / feedback thread, the series item is the selected item, don't need one level up look back
                            cID: selectedChannel.cID ?? selectedItem.cID)
            recordedItems.append(item)
        }
        
        recordedVideoVC.delegate = self
        
        recordedVideoVC.selectedChannelID = selectedChannel.cID
        recordedVideoVC.parentItem = selectedItem
        recordedVideoVC.isNewEntry = true
        recordedVideoVC.recordedItems = recordedItems
        
        if isAddingCover {
            recordedVideoVC.coverAdded = true
            isAddingCover = false
            recordedVideoVC.isNewEntry = false
        } else {
            recordedVideoVC.isNewEntry = true
            recordedVideoVC.currentItemIndex += 1
        }
        
        pushViewController(recordedVideoVC, animated: true)
    }
    
    fileprivate func getRecordedItemTitle() -> String {
        switch selectedItem.type {
        case .question, .thread, .interview, .session:
            return selectedItem.itemTitle
        default:
            return ""
        }
    }
    
    fileprivate func returnToRecordings() {
        //recordedVideoVC.selectedItem = selectedItem
        recordedVideoVC.isNewEntry = false
        recordedVideoVC.recordedItems = recordedItems
        recordedVideoVC.currentItemIndex = recordedVideoVC.currentItemIndex
        
        pushViewController(recordedVideoVC, animated: true)
    }
    
    /* check if social token available - if yes, then login and post on return, else ask user to login */
    func askUserToLogin(_ currentVC : UIViewController) {
        PulseDatabase.checkSocialTokens({ [weak self] result in
            guard let `self` = self else {
                return
            }
            
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

    
    func doneUploadingItem(_ currentVC: UIViewController, success: Bool) {
        recordedItems.removeAll() // empty current answers array
        
        if hasMoreItems { //currently always false - if we add ability to add new answer from actual video item can use this var
            returnToAnswers()
            popToViewController(contentDetailVC, animated: true)
        } else {
            let doneRecordingMenu = UIAlertController(title: "Success!",
                                                    message: "You are all done. Thanks for your post!",
                                                    preferredStyle: .actionSheet)
            
            doneRecordingMenu.addAction(UIAlertAction(title: "done", style: .destructive, handler: { (action: UIAlertAction!) in
                self.dismiss(animated: true, completion: nil)
                
                if self.completedRecordingDelegate != nil {
                    self.completedRecordingDelegate.doneRecording(success: success)
                }
            }))
            
            present(doneRecordingMenu, animated: true, completion: nil)
        }
    }
    
    func noItemsToShow(_ currentVC : UIViewController) {
        if selectedItem != nil {
            selectedItem.checkVerifiedInput(completion: {[weak self] success, error in
                guard let `self` = self else {
                    return
                }
                
                if success {
                    self.showCamera()
                } else {
                    self.hasMoreItems = false
                    self.dismiss(animated: true, completion: {
                        self.transitioningDelegate = nil
                    })
                }
            })
        } else {
            dismiss(animated: true, completion: {
                self.transitioningDelegate = nil
            })
        }
    }
    
    func showCamera(animated : Bool = true, mode: CameraOutputMode = .videoWithMic) {
        cameraVC = CameraVC()
        cameraVC.cameraMode = mode
        cameraVC.delegate = self
        cameraVC.screenTitle = selectedItem.itemTitle
        
        panDismissInteractionController.wireToViewController(cameraVC, toViewController: nil, parentViewController: self)
        panDismissInteractionController.delegate = self
        
        isNavigationBarHidden = true
        isCameraLoaded = true
        
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
            introVC?.item = selectedItem
            
            isNavigationBarHidden = true
            pushViewController(introVC!, animated: true)
            isShowingIntro = true
        }
    }
    
    func removeIntro() {
        if isShowingIntro {
            DispatchQueue.main.async {
                self.popViewController(animated: true)
                self.isShowingIntro = false
            }
        }
    }
    
    //NOT USED
    func addCover(_ currentVC : UIViewController, _recordedItems : [Item]) {
        recordedVideoVC = currentVC as! RecordedVideoVC
        recordedItems = _recordedItems
        isAddingCover = true
        
        if !self.viewControllers.contains(cameraVC) {
            popViewController(animated: false)
            pushViewController(cameraVC, animated: false)
        } else {
            popViewController(animated: true)
        }
    }
    
    func addMoreItems(_ currentVC : UIViewController, recordedItems : [Item], isCover : Bool) {
        recordedVideoVC = currentVC as! RecordedVideoVC
        self.recordedItems = recordedItems
        
        if isCover {
            isAddingCover = true
            cameraVC.updateOverlayTitle(title: "take or choose a cover image")
            cameraVC.cameraMode = .stillImage
        } else {
            isAddingMoreItems = true
        }
        
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
        if cameraVC != nil {
            cameraVC.delegate = nil
        }
        
        if isAddingMoreItems || isAddingCover {
            returnToRecordings()
        } else {
            dismiss(animated: true, completion: {
                self.transitioningDelegate = nil
            })
            //dismiss(animated: false, completion: nil)
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
            doneRecording(isCapturing: false, url: nil, image: pickedImage, location: nil, assetType: .albumImage)
            // Media is an image

        } else if mediaType.isEqual(to: kUTTypeMovie as String) {
            
            let videoURL = info[UIImagePickerControllerMediaURL] as? URL
            doneRecording(isCapturing: false, url: videoURL, image: nil, location: nil, assetType: .albumVideo)
            // Media is a video
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
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
