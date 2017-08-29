//
//  PulseVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/3/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit
import Firebase

class PulseVC: UIViewController, PulseNavControllerDelegate, ModalDelegate, SelectionDelegate, ParentTextViewDelegate {
    
    /** Loading Overlay **/
    internal var loadingView : LoadingView!
    
    /** Share content **/
    internal var activityController: UIActivityViewController!
    internal var selectedShareItem : Any?
    
    /** Transition Vars **/
    internal var initialFrame = CGRect.zero
    
    /** Collection View Vars **/
    internal let headerReuseIdentifier = "HeaderCell"
    internal let footerReuseIdentifier = "FooterCell"
    internal let sectionReuseIdentifier = "SectionHeaderCell"
    internal let emptyReuseIdentifier = "EmptyCell"
    internal let reuseIdentifier = "ItemCell"
    internal let skinnyHeaderHeight : CGFloat = 40
    internal let headerSectionHeight : CGFloat = 100
    
    /** Close Button - Only Needed If Presented Modally **/
    internal lazy var closeButton = PulseButton(size: .medium, type: .close, isRound : true, background: .white, tint: .black)
    internal lazy var backButton = PulseButton(size: .small, type: .back, isRound : true, background: .white, tint: .black)
    
    /** Adds a popup text view **/
    internal var addText : AddText!

    /** General Setup Var **/
    internal var isLoaded : Bool = false
    
    /** Blurs the background if there is a popup **/
    lazy var blurBackground = UIVisualEffectView()
    
    public var headerNav : PulseNavVC?
    public var statusBarHidden : Bool = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    public var currentNavState : NavigationBarState = .expanded
    public var statusBarStyle : UIStatusBarStyle = .default {
        didSet {
            headerNav?.navBar.barStyle = statusBarStyle == .default ? .default : .black
        }
    }
    public var contentVC : ContentManagerVC!
    public lazy var browseContentVC = BrowseContentVC()
    
    open var tabBarHidden : Bool = false {
        didSet {
            if tabBarHidden {
                tabBarController?.tabBar.isHidden = true
                edgesForExtendedLayout = .bottom
                extendedLayoutIncludesOpaqueBars = true
            } else {
                tabBarController?.tabBar.isHidden = false
                edgesForExtendedLayout = .all
                extendedLayoutIncludesOpaqueBars = false
                automaticallyAdjustsScrollViewInsets = true
            }
        }
    }
    
    init() {
        super.init(nibName:nil, bundle:nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        headerNav = navigationController as? PulseNavVC
        
        headerNav?.navbarDelegate = self
        //headerNav?.updateBackgroundImage(image: nil)
        
        view.backgroundColor = .white
        definesPresentationContext = true
        
        currentNavState = .expanded
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        headerNav?.stopFollowingScrollView()
    }
    
    override public var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }
    
    override public var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }
    
    internal func addBackButton() {
        if let headerNav = headerNav, headerNav.viewControllers.count > 1 {
            DispatchQueue.main.async {
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: self.backButton)
            }
            backButton.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
        }
    }
    
    internal func updateChannelImage(channel: Channel) {

        if let image = channel.cNavImage {
            headerNav?.updateBackgroundImage(image: image)
        } else {
            headerNav?.setBackgroundColor(color: UIColor.pulseDarkGrey, updateDarkNav: true)
            
            PulseDatabase.getCachedChannelNavImage(channelID: channel.cID, completion: {[weak self] image in
                guard let `self` = self else { return }
                DispatchQueue.main.async {
                    self.headerNav?.updateBackgroundImage(image: image)
                    channel.cNavImage = image
                }
            })
        }
    }
    
    internal func addRightButton(type: ButtonType) -> PulseButton {
        if headerNav != nil {
            let rightButton = PulseButton(size: .small, type: type, isRound : true, background: .white, tint: .black)
            DispatchQueue.main.async {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
            }
            return rightButton
        }
        return PulseButton(size: .small, type: .blank, isRound : true, background: .white, tint: .black)
    }
    
    internal func blurViewBackground() {
        /* BLUR BACKGROUND & DISABLE TAP WHEN MINI PROFILE IS SHOWING */
        blurBackground = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurBackground.frame = view.bounds
        view.addSubview(blurBackground)
    }
    
    internal func removeBlurBackground() {
        if blurBackground.superview == view {
            blurBackground.removeFromSuperview()
        }
    }
    
    internal func isRootController() -> Bool {
        guard let headerNav = headerNav else {
            return false
        }
        return headerNav.viewControllers.count == 1
    }
    
    internal func addScreenButton(button : PulseButton) {
        view.addSubview(button)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Spacing.s.rawValue).isActive = true
        button.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        button.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        button.layoutIfNeeded()
    }
    
    internal func toggleLoading(show: Bool, message: String?, showIcon: Bool = false, backgroundOpacity : CGFloat = 0.9) {
        if show {
            if loadingView != nil, loadingView.superview == view {
                if showIcon {
                    loadingView.addIcon(.medium, _iconColor: .gray, _iconBackgroundColor: UIColor.white)
                }
                
                loadingView.addMessage(message, _color: .gray)
                
            } else {
                loadingView = LoadingView(frame: view.bounds, backgroundColor: UIColor.white.withAlphaComponent(backgroundOpacity))
                
                DispatchQueue.main.async {
                    self.view.addSubview(self.loadingView)
                    
                    if showIcon {
                        self.loadingView.addIcon(.medium, _iconColor: .gray, _iconBackgroundColor: UIColor.white)
                    }
                    
                    self.loadingView.addMessage(message, _color: .gray)
                }
            }
            
        } else {
            if loadingView != nil {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.2, animations: { self.loadingView!.alpha = 0.0 } ,
                                   completion: {(value: Bool) in
                                    self.loadingView.removeFromSuperview()
                    })
                }
            }
        }
    }
    
    /** Menu Options **/
    internal func showInviteMenu(currentItem : Any?, inviteTitle: String, inviteMessage: String, inviteType: MessageType) {
        let menu = UIAlertController(title: inviteTitle, message: inviteMessage, preferredStyle: .actionSheet)
        var selectedChannel : Channel!
        
        if let currentChannel = currentItem as? Channel {
            selectedChannel = currentChannel
        } else if let currentItem = currentItem as? Item {
            selectedChannel = Channel(cID: currentItem.cID, title: currentItem.cTitle)
        }
        
        menu.addAction(UIAlertAction(title: "invite Pulse Users", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.selectedShareItem = currentItem
            
            let browseUsers = MiniUserSearchVC()
            browseUsers.modalPresentationStyle = .overCurrentContext
            browseUsers.modalTransitionStyle = .crossDissolve
            
            browseUsers.modalDelegate = self
            browseUsers.selectionDelegate = self
            browseUsers.selectedChannel = selectedChannel
            self.tabBarHidden = true

            self.navigationController?.present(browseUsers, animated: true, completion: nil)
        }))
        
        menu.addAction(UIAlertAction(title: "invite via Email", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.selectedShareItem = currentItem
            self.showAddText(buttonText: "Send", bodyText: nil, defaultBodyText: "enter email", tabBarHeightAdjustment: self.tabBarHidden ? 0 : self.tabBarController?.tabBar.frame.height ?? 0)
        }))
        
        menu.addAction(UIAlertAction(title: "more invite Options", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            switch inviteType {
            case .perspectiveInvite, .questionInvite, .showcaseInvite, .feedbackInvite:
                if let currentItem = currentItem as? Item {
                    self.createShareRequest(selectedShareItem: currentItem, shareType: inviteType, selectedChannel: selectedChannel, toUser: nil, showAlert: false, completion: {[unowned self] selectedShareItem , error in
                        //using the share item returned from the request
                        if error == nil, let selectedShareItem = selectedShareItem {
                            let shareText = "Can you \(currentItem.childActionType())\(currentItem.childType()) on \(currentItem.itemTitle)"
                            self.showShare(selectedItem: selectedShareItem, type: "invite", fullShareText: shareText, inviteItemID: currentItem.itemID)
                        }
                    })
                    
                }
            case .contributorInvite:
                if let shareChannel = currentItem as? Channel {
                    self.toggleLoading(show: true, message: "loading share options...", showIcon: true)
                    
                    self.createContributorInvite(selectedChannel: shareChannel, toUser: nil, toEmail: nil, showAlert: true, completion: {[unowned self] inviteID , error in
                        
                        if error == nil, let inviteID = inviteID {
                            let channelTitle = shareChannel.cTitle ?? "a Pulse channel"
                            let shareText = "You are invited to be a contributor on \(channelTitle)"
                            
                            PulseDatabase.createShareLink(item: shareChannel, linkString: "invites/"+inviteID, completion: {[unowned self] link in
                                guard let link = link else {
                                    self.toggleLoading(show: false, message: nil)
                                    return
                                }
                                
                                self.toggleLoading(show: false, message: nil)
                                self.shareContent(shareType: "", shareText: "", shareLink: link, fullShareText: shareText)
                            })
                        }
                        
                    })
                }
            case .channelInvite:
                if let shareChannel = currentItem as? Channel {
                    self.toggleLoading(show: true, message: "loading share options...", showIcon: true)
                    
                    let shareItem = Item(itemID: "")
                    shareItem.itemTitle = "Check out \(shareChannel.cTitle ?? " this channel")" //send blank item since we are inviting users to come to channel
                    
                    self.createShareRequest(selectedShareItem: shareItem, shareType: .channelInvite, selectedChannel: shareChannel, toUser: nil, completion: { [unowned self] item, error in
                        
                        if error == nil, let inviteID = item?.itemID {
                            let channelTitle = shareChannel.cTitle ?? "a Pulse channel"
                            let shareText = "\(PulseUser.currentUser.name ?? "Your friend") invited you to \(channelTitle)"
                            
                            PulseDatabase.createShareLink(item: shareChannel, linkString: "invites/"+inviteID, completion: {[unowned self] link in
                                guard let link = link else {
                                    self.toggleLoading(show: false, message: nil)
                                    return
                                }
                                
                                self.toggleLoading(show: false, message: nil)
                                self.shareContent(shareType: "", shareText: "", shareLink: link, fullShareText: shareText)
                            })
                        }
                    })
                }
            default: break
            }
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    
    internal func createContributorInvite(selectedChannel: Channel, toUser: PulseUser?, toEmail: String?  = nil, showAlert: Bool = true,
                                          completion: @escaping (String?, Error?) -> Void) {
        
        toggleLoading(show: true, message: "creating invite...", showIcon: true)
        PulseDatabase.createContributorInvite(channel: selectedChannel, type: .contributorInvite, toUser: toUser, toName: toUser?.name,
                                              toEmail: toEmail, completion: {[unowned self] (inviteID, error) in
                                                
                                                self.toggleLoading(show: false, message: nil)
                                                
                                                if error == nil, showAlert {
                                                    GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Invite Sent", erMessage: "Thanks for your recommendation!", buttonTitle: "okay")
                                                    completion(inviteID, nil)
                                                } else if showAlert {
                                                    GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Error Sending Request", erMessage: "Sorry there was an error sending the invite")
                                                    completion(nil, error)
                                                }
        })
    }
    
    internal func showAddText(buttonText: String = "Done", bodyText: String?, defaultBodyText: String = "type here", keyboardType: UIKeyboardType = .emailAddress, tabBarHeightAdjustment: CGFloat = 0) {
        if addText == nil {
            addText = AddText(frame: view.bounds, buttonText: buttonText, bodyText: bodyText,
                              defaultBodyText: defaultBodyText, keyboardType: keyboardType, tabBarHeightAdjustment: tabBarHeightAdjustment)
        } else {
            addText.setText(bodyText: bodyText, keyboardType: keyboardType)
        }
        
        addText.delegate = self
        view.addSubview(addText)
    }
    
    //Used for creating invites
    internal func createShareRequest(selectedShareItem : Item, shareType: MessageType?, selectedChannel: Channel, toUser: PulseUser?, toEmail : String? = nil, showAlert : Bool = true,
                                     completion: @escaping (_ item : Item?, _ error : Error?) -> Void) {
        guard let shareType = shareType else {
            let userInfo = [ NSLocalizedDescriptionKey : "please login to share content" ]
            completion(nil, NSError(domain: "NotLoggedIn", code: 200, userInfo: userInfo))
            return
        }
        
        toggleLoading(show: true, message: "creating invite...", showIcon: true)
        
        let itemKey = databaseRef.child("items").childByAutoId().key        
        let newShareItem = Item(itemID: itemKey)
        newShareItem.itemID = itemKey
        newShareItem.cID = selectedChannel.cID
        newShareItem.cTitle = selectedChannel.cTitle
        newShareItem.tag = selectedShareItem.tag
        newShareItem.itemTitle = selectedShareItem.itemTitle
        
        PulseDatabase.createInviteRequest(item: newShareItem, type: shareType, toUser: toUser, toName: nil, toEmail: toEmail,
                                     childItems: [], parentItemID: selectedShareItem.itemID, completion: {[weak self] (success, error) in
            guard let `self` = self else { return }
                                        
            if success, showAlert {
                self.toggleLoading(show: false, message: nil)
                GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Invite Sent", erMessage: "Thanks for your recommendation!", buttonTitle: "okay")
            } else if showAlert {
                self.toggleLoading(show: false, message: nil)
                GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Error Sending Request", erMessage: "Sorry there was an error sending the invite")
            }
            
            completion(newShareItem, error)
        })
    }
    
    //creates the short link based on the item type (invite vs. just sharing content)
    internal func showShare(selectedItem: Item, type: String, fullShareText: String = "", inviteItemID: String? = nil) {
        toggleLoading(show: true, message: "loading share options...", showIcon: true)
        let isInvite = type == "invite" ? true : false
        
        selectedItem.createShareLink(invite: isInvite, inviteItemID: inviteItemID, completion: {[weak self] link in
            guard let `self` = self else { return }
            
            guard let link = link else {
                self.toggleLoading(show: false, message: nil)
                return
            }
            self.shareContent(shareType: type, shareText: selectedItem.shareText(), shareLink: link, fullShareText: fullShareText)
            Analytics.logEvent(AnalyticsEventShare, parameters: [AnalyticsParameterContentType: type as NSObject,
                                                                 AnalyticsParameterItemID: "\(selectedItem.itemID)" as NSObject])
        })
    }
    
    //Actually displays the share screen
    internal func shareContent(shareType: String, shareText: String, shareLink: URL, fullShareText: String = "") {
        // set up activity view controller
        let textToShare = fullShareText == "" ? "Check out this \(shareType) on Pulse: " + shareText : fullShareText
        let shareItems = [textToShare, shareLink] as [Any]
        activityController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        activityController.popoverPresentationController?.sourceView = view // so that iPads won't crash

        // exclude some activity types from the list (optional)
        activityController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFlickr, UIActivityType.saveToCameraRoll, UIActivityType.print, UIActivityType.addToReadingList ]
        
        // present the view controller
        present(activityController, animated: true, completion: { _ in
            self.toggleLoading(show: false, message: nil)
        })
    }
    
    internal func reportContent(item: Item) {
        let detailReport = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        detailReport.addAction(UIAlertAction(title: "it's Spam", style: .destructive, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            PulseDatabase.reportContent(item: item, reason: "spam", completion: { success, error in
                if success {
                    GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Thanks for reporting!", erMessage: "Our moderation team will review your complaint and remove the post promptly if it is found to be inappropriate", buttonTitle: "done")
                } else {
                    GlobalFunctions.showAlertBlock("Error filing complaint!", erMessage: error?.localizedDescription)
                }
                detailReport.dismiss(animated: true, completion: nil)
            })
        }))
        
        detailReport.addAction(UIAlertAction(title: "it's Inappropriate", style: .destructive, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            PulseDatabase.reportContent(item: item, reason: "inappropriate", completion: { success, error in
                if success {
                    GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Thanks for reporting!", erMessage: "Our moderation team will review your complaint and remove the post promptly if it is found to be inappropriate", buttonTitle: "done")
                } else {
                    GlobalFunctions.showAlertBlock("Error filing complaint!", erMessage: error?.localizedDescription)
                }
                detailReport.dismiss(animated: true, completion: nil)
            })
        }))
        
        detailReport.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: {(action: UIAlertAction!) in
            detailReport.dismiss(animated: true, completion: nil)
        }))
        
        DispatchQueue.main.async {
            self.present(detailReport, animated: true, completion: nil)
        }
    }
    
    /** Delegate Functions **/
    
    /**
     Called when the state of the navigation bar changes
     */
    func scrollingNavigationController(_ controller: PulseNavVC, didChangeState state: NavigationBarState) {

    }
    
    /**
     Called when the state of the navigation bar is about to change
     */
    func scrollingNavigationController(_ controller: PulseNavVC, willChangeState state: NavigationBarState) {

    }
    
    //Must be implemented by the child inheriting controllers
    internal func userClosedModal(_ viewController : UIViewController) {
        NSException(name:NSExceptionName.internalInconsistencyException, reason:"\(#function) must be overridden in a subclass/category", userInfo:nil).raise()
    }
    
    internal func userSelected(item : Any) {
        NSException(name:NSExceptionName.internalInconsistencyException, reason:"\(#function) must be overridden in a subclass/category", userInfo:nil).raise()
    }
    
    internal func dismiss(_ view : UIView) {
        NSException(name:NSExceptionName.internalInconsistencyException, reason:"\(#function) must be overridden in a subclass/category", userInfo:nil).raise()
    }
    
    internal func buttonClicked(_ text: String, sender: UIView) {
        NSException(name:NSExceptionName.internalInconsistencyException, reason:"\(#function) must be overridden in a subclass/category", userInfo:nil).raise()
    }
}

extension PulseVC: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if presented is ContentManagerVC {
            
            let animator = ExpandAnimationController()
            animator.initialFrame = initialFrame
            animator.exitFrame = getRectToLeft()
            return animator
            
        } else if presented is InputVC || presented is RecordedVideoVC || presented is VideoTrimmerVC {
            
            let animator = FadeAnimationController()
            animator.transitionType = .present
            return animator
            
        } else {
            return nil
        }
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is InputVC || dismissed is ImageCropperVC || dismissed is VideoTrimmerVC {
            let animator = FadeAnimationController()
            animator.transitionType = .dismiss
            
            return animator
            
        } else {
            return nil
        }
    }
}
