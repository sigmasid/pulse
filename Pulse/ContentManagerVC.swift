//
//  QAManagerVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import UIKit
import MobileCoreServices
import CoreLocation
import AVFoundation
import Firebase

class ContentManagerVC: PulseNavVC, ContentDelegate, InputMasterDelegate, BrowseContentDelegate, ModalDelegate, UINavigationControllerDelegate, PanAnimationDelegate  {
    //set by delegate - questions or posts
    var selectedChannel : Channel! //all items need a channel - only for adding new posts / answers
    var selectedItem: Item! //the category item - might be the question / tag / post etc.
    var allItems = [Item]()
    var itemIndex = 0
    var itemCollection = [Item]()
    var createdItemKey : String?
    var selectedChoice: Item? //for new items (threads) - if user has selected an option then show in title & with final upload
    
    var openingScreen : OpeningScreenOptions = .item
    enum OpeningScreenOptions { case camera, item }
    public weak var completedRecordingDelegate : CompletedRecordingDelegate!

    fileprivate var recordedItems = [Item]()
    
    /* CHILD VIEW CONTROLLERS */
    fileprivate var loadingVC : LoadingVC?

    fileprivate var contentDetailVC : ContentDetailVC!
    fileprivate var inputVC : InputVC!
    fileprivate lazy var recordedVideoVC : RecordedVideoVC! = RecordedVideoVC()
    fileprivate var introVC : ContentIntroVC?
    
    fileprivate var isAddingMoreItems = false
    fileprivate var isShowingIntro = false
    fileprivate var isLoaded = false
    fileprivate var cleanupComplete = false
    
    fileprivate var panDismissInteractionController : PanContainerInteractionController!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        performCleanup()
    }
    
    init() {
        super.init(navigationBarClass: PulseNavBar.self, toolbarClass: nil)
    }
    
    
    override init(nibName: String?, bundle: Bundle?) {
        super.init(nibName: nibName, bundle: bundle)
    }
    
    override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    

    fileprivate func performCleanup() {
        if !cleanupComplete {
            selectedChannel = nil
            selectedItem = nil
            
            allItems = []
            itemCollection = []
            recordedItems = []
            
            if contentDetailVC != nil {
                contentDetailVC.performCleanup()
                contentDetailVC.delegate = nil
                contentDetailVC = nil
            }
            
            if panDismissInteractionController != nil {
                panDismissInteractionController.delegate = nil
                panDismissInteractionController = nil
            }
            
            recordedVideoVC.performCleanup()
            recordedVideoVC.delegate = nil
            recordedVideoVC = nil
            
            completedRecordingDelegate = nil
            loadingVC = nil
            
            if inputVC != nil {
                inputVC.performCleanup()
                inputVC.delegate = nil
                inputVC = nil
            }
            
            if introVC != nil {
                introVC?.performCleanup()
                introVC = nil
            }
            
            transitioningDelegate = nil
            setViewControllers([], animated: false)
            cleanupComplete = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /* Item Specific Methods */
    func showItemDetail(shouldShowIntro: Bool) {
        isNavigationBarHidden = true
        
        if contentDetailVC == nil {
            contentDetailVC = ContentDetailVC()
            contentDetailVC.delegate = self
            panDismissInteractionController = PanContainerInteractionController()
            panDismissInteractionController.wireToViewController(contentDetailVC, toViewController: nil, parentViewController: self)
            panDismissInteractionController.delegate = self
        }
        
        //need to be set first - to determine if first clip should be answer detail or the answer itself
        contentDetailVC.itemDetail = itemCollection
        contentDetailVC.selectedChannel = selectedChannel != nil ? selectedChannel : Channel(cID: selectedItem.cID, title: selectedItem.cTitle ?? "")
        contentDetailVC.selectedItem = selectedItem
        contentDetailVC.itemIndex = itemIndex //set first - if not 0 then DetailVC uses this as the index
        
        if shouldShowIntro {
            pushViewController(contentDetailVC, animated: false)
            
            contentDetailVC.allItems = allItems
            contentDetailVC.view.alpha = 1.0 // to make sure view did load fires - push / add controllers does not guarantee view is loaded
            
            contentDetailVC.isShowingIntro = true
        
            showIntro()
        } else {
            //case where user is returning form quick browse
            
            contentDetailVC.allItems = allItems
            contentDetailVC.view.alpha = 1.0 // to make sure view did load fires - push / add controllers does not guarantee view is loaded
            
            dismiss(animated: true, completion: { _ in }) //dismisses the quick browse
        }
    }
    
    /** Browse Content Delegate **/
    internal func showItemDetail(allItems: [Item], index: Int, itemCollection: [Item], selectedItem : Item) {
        self.allItems = allItems
        self.itemIndex = index
        self.itemCollection = itemCollection
        
        showItemDetail(shouldShowIntro: false)
    }
    
    internal func addNewItem(selectedItem: Item) {
        dismiss(animated: true, completion: {[weak self] _ in
            guard let `self` = self else { return }
            self.isNavigationBarHidden = true
            self.showCamera(animated: true)
        })
    }
    /** End Browse Content Delegate **/

    func loadMoreFromTag() {
        if let selectedTag = selectedItem.tag, !selectedTag.itemCreated {
            PulseDatabase.getItemCollection(selectedTag.itemID, completion: {[weak self] (success, items) in
                guard let `self` = self else { return }
                
                self.itemIndex = items.index(of: self.selectedItem) ?? 0
                self.allItems = items
            })
        } else {
            dismiss(animated: true, completion: {[weak self] in
                guard let `self` = self else { return }
                self.transitioningDelegate = nil
            })
        }
    }
    
    func userClickedProfileDetail() {
        
        let userProfileVC = UserProfileVC()
        userProfileVC.isModal = true
        userProfileVC.selectedUser = selectedItem?.user
        userProfileVC.modalDelegate = self

        present(userProfileVC, animated: true)
        
    }
    
    func userClosedModal(_ viewController : UIViewController) {
        dismiss(animated: true, completion: {[weak self] _ in
            guard let `self` = self else { return }
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
    func capturedItem(item newItem: Any?, location: CLLocation?, assetType: CreatedAssetType) {
        guard let newItem = newItem else {
            GlobalFunctions.showAlertBlock("Error retreiving Item", erMessage: "Sorry there was an error! Please try again")
            return
        }
        
        //in case parent provides key for first item use that (interview case) else create a new key. After creation marks the createdItemKey as nil
        let itemKey = createdItemKey != nil ? createdItemKey! :  PulseDatabase.getKey(forPath: "items")

        createdItemKey = nil
        
        let item = Item(itemID: itemKey,
                        itemUserID: PulseUser.currentUser.uID!,
                        itemTitle: getRecordedItemTitle(),
                        type: selectedItem.childItemType(),
                        tag: selectedItem.tag ?? selectedItem, //if its a post / feedback thread, the series item is the selected item, don't need to look back
                        cID: selectedChannel.cID ?? selectedItem.cID)
        
        item.contentType = assetType
        switch assetType {
        case .albumImage, .recordedImage:
            item.content = newItem as? UIImage
        case .albumVideo, .recordedVideo:
            item.contentURL = newItem as? URL
        case .postcard:
            item.itemTitle = newItem as? String ?? ""
        }
        
        if let selectedChoice = selectedChoice {
            item.choices.append(selectedChoice)
        }
        
        recordedItems.append(item)
        recordedVideoVC.delegate = self
        
        recordedVideoVC.selectedChannelID = selectedChannel.cID
        recordedVideoVC.parentItem = selectedItem
        recordedVideoVC.recordedItems = recordedItems
        recordedVideoVC.isNewEntry = true
        recordedVideoVC.currentItemIndex = recordedItems.count - 1
        
        pushViewController(recordedVideoVC, animated: true)
    }
    
    fileprivate func getRecordedItemTitle() -> String {
        switch selectedItem.type {
        case .question, .interview, .session:
            //only add the title to the first item in the series
            return recordedItems.count == 0 ? selectedItem.itemTitle : ""            
        case .thread:
            //only add the title to the first item in the series - for threads if there is a choice & add the selected choice in there
            let choiceTitle = selectedChoice?.itemTitle ?? ""
            return recordedItems.count == 0 ? "\(selectedItem.itemTitle) \(choiceTitle)" : ""
        default:
            return ""
        }
    }
    
    fileprivate func returnToRecordings() {
        recordedVideoVC.isNewEntry = false
        recordedVideoVC.recordedItems = recordedItems
        recordedVideoVC.currentItemIndex = recordedVideoVC.currentItemIndex
        
        pushViewController(recordedVideoVC, animated: true)
    }
    
    func doneUploadingItem(_ currentVC: UIViewController, item: Item, success: Bool) {
        
        guard completedRecordingDelegate == nil else {
            completedRecordingDelegate.doneRecording(success: success)
            performCleanup()
            dismiss(animated: true, completion: nil)
            return
        }
        
        let doneRecordingMenu = UIAlertController(title: "Success!",
                                                message: "You are all done. Thanks for contributing!",
                                                preferredStyle: .actionSheet)
        
        doneRecordingMenu.addAction(UIAlertAction(title: "share This", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            
            if self.loadingVC != nil {
                self.popToViewController(self.loadingVC!, animated: false)
            } else {
                self.pushViewController(self.loadingVC!, animated: false)
            }
            
            let shareItem = Item.shareItemType(parentType: self.selectedItem.type, childType: item.type) == self.selectedItem.type ?
                self.selectedItem : item
            
            shareItem!.createShareLink(invite: false, completion: {[weak self] link in
                guard let `self` = self else { return }
                
                guard let link = link else {
                    return
                }
                
                self.shareContent(item: shareItem!, shareLink: link)
                Analytics.logEvent(AnalyticsEventShare, parameters: [AnalyticsParameterContentType: item.type.rawValue as NSObject,
                                                                     AnalyticsParameterItemID: "\(item.itemID)" as NSObject])
            })
        }))
        
        doneRecordingMenu.addAction(UIAlertAction(title: "done", style: .destructive, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            
            self.performCleanup()
            self.dismiss(animated: true, completion: nil)
            
        }))
        
        present(doneRecordingMenu, animated: true, completion: nil)
    }
    
    
    //Actually displays the share screen
    internal func shareContent(item: Item, shareLink: URL) {
        // set up activity view controller
        let textToShare = "Check out this \(item.type.rawValue) on Pulse: " + item.itemTitle
        let shareItems = [textToShare, shareLink] as [Any]
        let activityController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        activityController.popoverPresentationController?.sourceView = view // so that iPads won't crash
        activityController.completionWithItemsHandler = {[weak self] _, _, _, _ in
            guard let `self` = self else { return }
            self.performCleanup()
            self.dismiss(animated: true, completion: nil)
        }
        
        // exclude some activity types from the list (optional)
        activityController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFlickr, UIActivityType.saveToCameraRoll, UIActivityType.print, UIActivityType.addToReadingList ]
        
        // present the view controller
        present(activityController, animated: true, completion: { _ in })
    }
    
    func noItemsToShow(_ currentVC : UIViewController) {
        if selectedItem != nil {
            selectedItem.checkVerifiedInput(completion: {[weak self] success, error in
                guard let `self` = self else { return }
                
                if success {
                    self.showCamera()
                } else {
                    self.dismiss(animated: true, completion: {[unowned self] in
                        self.performCleanup()
                    })
                }
            })
        } else {
            self.dismiss(animated: true, completion: {[unowned self] in
                self.performCleanup()
            })
        }
    }
    
    func showCamera(animated : Bool = true, mode: CameraOutputMode = .videoWithMic) {
        if inputVC == nil {
            inputVC = InputVC(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
            inputVC.cameraMode = mode
            inputVC.showTextInput = true
            inputVC.captureSize = .fullScreen
            inputVC.inputDelegate = self
            inputVC.updateAlpha()
        }
        
        let screenTitle = selectedChoice != nil ? "\(selectedItem.itemTitle) - \(selectedChoice!.itemTitle)" : selectedItem.itemTitle
        inputVC.cameraTitle = screenTitle
        
        isNavigationBarHidden = true
        
        pushViewController(inputVC, animated: animated)
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
            DispatchQueue.main.async {[weak self] in
                guard let `self` = self else { return }
                self.popViewController(animated: true)
                self.isShowingIntro = false
            }
        }
    }
    
    func addMoreItems(_ currentVC : UIViewController, recordedItems : [Item]) {
        recordedVideoVC = currentVC as! RecordedVideoVC
        self.recordedItems = recordedItems
        inputVC.captureSize = .fullScreen
        inputVC.updateAlpha()
        isAddingMoreItems = true
        
        if !viewControllers.contains(inputVC) {
            popViewController(animated: false)
            pushViewController(inputVC, animated: false)
        } else {
            popViewController(animated: true)
        }
    }
    
    //case where user closes the 'first' video
    func userDismissedRecording(_ currentVC : UIViewController, recordedItems : [Item]) {
        self.recordedItems = recordedItems
        inputVC.updateAlpha()
        popViewController(animated: true)
        isAddingMoreItems = false
        //showCamera(animated: false)
    }
    
    func dismissInput() {
        if isAddingMoreItems  {
            returnToRecordings()
        } else {
            dismiss(animated: true, completion: {[weak self] in
                guard let `self` = self else { return }
                self.performCleanup()
            })
        }
    }
    
    func panCompleted(success: Bool, fromVC: UIViewController?) {
        if success {
            if inputVC != nil, fromVC is InputVC {
                dismissInput()
            } else if fromVC is ContentDetailVC {
                dismiss(animated: false, completion: {[weak self] in
                    guard let `self` = self else { return }
                    self.performCleanup()
                })
            }
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
    
    /** ANIMATION CONTROLLERS **/
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationControllerOperation,
                              from fromVC: UIViewController,
                             to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        switch operation {
        case .pop:
            if fromVC is InputVC {
                let animator = ShrinkDismissController()
                animator.transitionType = .dismiss
                animator.shrinkToView = UIView(frame: CGRect(x: 20,y: 400,width: 40,height: 40))
                
                return animator
            } else if fromVC is RecordedVideoVC && toVC is InputVC {
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
            } else if toVC is InputVC && fromVC is RecordedVideoVC {
                let animator = FadeAnimationController()
                animator.transitionType = .present
                
                return animator
            }
            else if fromVC is InputVC && toVC is ContentIntroVC {
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
        guard panDismissInteractionController != nil else { return nil } 
        return panDismissInteractionController.interactionInProgress ? panDismissInteractionController : nil
    }
}
