//
//  PulseVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/3/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class PulseVC: UIViewController, PulseNavControllerDelegate {
    
    /** Loading Overlay **/
    internal var loadingView : LoadingView!
    
    /** Share content **/
    internal var activityController: UIActivityViewController!
    
    /** Transition Vars **/
    internal var initialFrame = CGRect.zero
    internal var panPresentInteractionController = PanEdgeInteractionController()
    internal var panDismissInteractionController = PanEdgeInteractionController()
    
    /** Collection View Vars **/
    internal let headerReuseIdentifier = "HeaderCell"
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
    public lazy var contentVC = ContentManagerVC(navigationBarClass: PulseNavBar.self, toolbarClass: nil)
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
        headerNav = navigationController as? PulseNavVC
        
        headerNav?.navbarDelegate = self
        headerNav?.updateBackgroundImage(image: nil)
        
        view.backgroundColor = .white
        definesPresentationContext = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
            backButton.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
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
    
    internal func toggleLoading(show: Bool, message: String?, showIcon: Bool = false) {
        if show {
            if loadingView != nil, loadingView.superview == view {
                if showIcon {
                    self.loadingView.addIcon(.medium, _iconColor: .gray, _iconBackgroundColor: UIColor.white)
                }
                
                self.loadingView.addMessage(message, _color: .gray)
                
            } else {
                loadingView = LoadingView(frame: view.bounds, backgroundColor: UIColor.white.withAlphaComponent(0.9))
                
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
    
    internal func createShareRequest(selectedShareItem : Item, selectedChannel: Channel, toUser: User?, toEmail : String? = nil, showAlert : Bool = true, completion: @escaping (_ item : Item?, _ error : Error?) -> Void) {
        let itemKey = databaseRef.child("items").childByAutoId().key
        let parentItemID = selectedShareItem.itemID
        
        selectedShareItem.itemID = itemKey
        selectedShareItem.cID = selectedChannel.cID
        selectedShareItem.cTitle = selectedChannel.cTitle
        
        toggleLoading(show: true, message: "creating invite...", showIcon: true)
        let type : MessageType = selectedShareItem.type == .thread ? .perspectiveInvite : .questionInvite
        Database.createInviteRequest(item: selectedShareItem, type: type, toUser: toUser, toName: nil, toEmail: toEmail,
                                     childItems: [], parentItemID: parentItemID, completion: {(success, error) in
                                        
            if success, showAlert {
                GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Invite Sent", erMessage: "Thanks for your recommendation!", buttonTitle: "okay")
            } else if showAlert {
                GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Error Sending Request", erMessage: "Sorry there was an error sending the invite")
            }
            
            self.toggleLoading(show: false, message: nil)
            completion(selectedShareItem, error)
        })
    }
    
    internal func showShare(selectedItem: Item, type: String, fullShareText: String = "") {
        toggleLoading(show: true, message: "loading share options...", showIcon: true)
        let isInvite = type == "invite" ? true : false
        selectedItem.createShareLink(invite: isInvite, completion: { link in
            guard let link = link else {
                self.toggleLoading(show: false, message: nil)
                return
            }
            self.shareContent(shareType: type, shareText: selectedItem.itemTitle, shareLink: link, fullShareText: fullShareText)
            self.toggleLoading(show: false, message: nil)
        })
    }
    
    internal func shareContent(shareType: String, shareText: String, shareLink: String, fullShareText: String = "") {
        // set up activity view controller
        let textToShare = fullShareText == "" ? "Check out this \(shareType) on Pulse - " + shareText + " " + shareLink : fullShareText + " " + shareLink
        activityController = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
        activityController.popoverPresentationController?.sourceView = view // so that iPads won't crash
        
        // exclude some activity types from the list (optional)
        activityController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFlickr, UIActivityType.saveToCameraRoll, UIActivityType.print, UIActivityType.addToReadingList ]
        toggleLoading(show: false, message: nil)
        // present the view controller
        present(activityController, animated: true, completion: nil)
    }
    
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
}
