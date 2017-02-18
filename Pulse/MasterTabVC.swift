//
//  MasterTabVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/12/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

protocol tabVCDelegate: class {
    func cancelledTransition()
    func removeLoading()
}


class MasterTabVC: UITabBarController, UITabBarControllerDelegate, tabVCDelegate, LoadingDelegate {
    
    var reachability: Reachability? = Reachability.networkReachabilityForInternetConnection()

    fileprivate var initialLoadComplete = false
    fileprivate var loadingView : LoadingView!

    var accountVC : AccountLoginManagerVC = AccountLoginManagerVC()
    var exploreVC : ExploreVC!
    var homeVC : HomeVC!
    fileprivate var deselectedIndex : Int!
    
    fileprivate var tabIcons = UIStackView()
    fileprivate var profileStack = UIStackView()
    fileprivate var exploreStack = UIStackView()
    fileprivate var feedStack = UIStackView()
    
    fileprivate var profileButton = PulseButton(size: .small, type: .tabProfile, isRound: true, hasBackground: false)
    fileprivate var exploreButton = PulseButton(size: .small, type: .tabExplore, isRound: true, hasBackground: false)
    fileprivate var feedButton = PulseButton(size: .small, type: .tabHome, isRound: true, hasBackground: false)
    
    fileprivate var profileLabel = UILabel()
    fileprivate var exploreLabel = UILabel()
    fileprivate var feedLabel = UILabel()
    
    fileprivate var pulseAppButton = UIButton(frame: CGRect(x: 0, y: 0, width: IconSizes.small.rawValue, height: IconSizes.small.rawValue))
    fileprivate var pulseAppButtonTap = UITapGestureRecognizer()

    fileprivate var panInteractionController = PanHorizonInteractionController()
    
    fileprivate var initialFrame : CGRect!
    fileprivate var rectToRight : CGRect!
    fileprivate var rectToLeft : CGRect!
    
    fileprivate var isLoaded = false
    fileprivate var universalLink : URL?
    
    override open var selectedIndex: Int {
        didSet {
            self.setSelectedIcon(index: selectedIndex)
        }
        willSet {
            self.deselectedIndex = selectedIndex
            self.setDeselectIcon(index: selectedIndex)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoading()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityDidChange(_:)), name: NSNotification.Name(rawValue: ReachabilityDidChangeNotificationName), object: nil)

        _ = reachability?.startNotifier()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkReachability()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        reachability?.stopNotifier()
    }
    
    func checkReachability() {
        guard let r = reachability else { return }
        if r.isReachable, !isLoaded {
            self.setupControllers()
            self.setupPulseButton()
            
            Database.checkCurrentUser { success in
                if let link = self.universalLink {
                    self.setupIcons(_selectedIndex: 1)
                    self.exploreVC.universalLink = link
                    self.setSelected(self.exploreButton)
                    self.initialLoadComplete = true
                }
                    // get feed and show initial view controller
                else if success && !self.initialLoadComplete {
                    self.setupIcons(_selectedIndex: 2)
                    self.initialLoadComplete = true
                    
                } else if !success && !self.initialLoadComplete {
                    self.setupIcons(_selectedIndex: 1)
                    self.initialLoadComplete = true
                }
                
                self.isLoaded = true
            }
        } else if r.isReachable, isLoaded {
            removeLoading()
        } else {
            loadingView.isHidden = false
            loadingView.alpha = 1.0
            loadingView?.addMessage("Sorry! No Internet Connection", _color: .black)
            loadingView?.addRefreshButton()
            view.bringSubview(toFront: loadingView)
        }
    }
    
    func reachabilityDidChange(_ notification: Notification) {
        checkReachability()
    }
    
    //DELEGATE METHOD TO REMOVE INITIAL LOADING SCREEN WHEN THE FEED IS LOADED
    func removeLoading() {
        UIView.animate(withDuration: 0.25, animations: { self.loadingView.alpha = 0 } , completion: {(value: Bool) in
            self.loadingView.isHidden = true
        })
    }
    
    //DELEGATE METHOD TO RESET ICONS IF THE TRANSITION IS CANCELLED HALF WAY
    func cancelledTransition() {
        if deselectedIndex != nil {
            setSelectedIcon(index: deselectedIndex)
            setDeselectIcon(index: selectedIndex)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupControllers() {
        let accountNavVC = PulseNavVC(navigationBarClass: PulseNavBar.self, toolbarClass: nil)
        accountNavVC.setNav(title: "Account", image: nil)
        accountNavVC.viewControllers = [accountVC]

        exploreVC = ExploreVC()
        let exploreNavVC = PulseNavVC(navigationBarClass: PulseNavBar.self, toolbarClass: nil)
        exploreNavVC.setNav(title: "Explore", image: nil)
        exploreNavVC.viewControllers = [exploreVC]
        exploreVC.tabDelegate = self
        
        homeVC = HomeVC()
        let homeNavVC = PulseNavVC(navigationBarClass: PulseNavBar.self, toolbarClass: nil)
        homeNavVC.isNavigationBarHidden = true
        homeNavVC.viewControllers = [homeVC]
        homeVC.tabDelegate = self

        viewControllers = [accountNavVC, exploreNavVC, homeNavVC]
        
        let tabAccount = UITabBarItem(title: nil, image: UIImage(named: "tab-profile"), tag: 10)
        let tabExplore = UITabBarItem(title: nil, image: UIImage(named: "tab-explore"), tag: 20)
        let tabHome = UITabBarItem(title: nil, image: UIImage(named: "tab-home"), tag: 30)
        
        UITabBar.appearance().tintColor = pulseBlue
        
        accountVC.tabBarItem = tabAccount
        exploreVC.tabBarItem = tabExplore
        homeVC.tabBarItem = tabHome
        
        rectToLeft = view.frame
        rectToLeft.origin.x = view.frame.minX - view.frame.size.width
        rectToRight = view.frame
        rectToRight.origin.x = view.frame.maxX
        
        delegate = self
        tabBar.backgroundImage = GlobalFunctions.imageWithColor(UIColor.white)
        //tabBar.isHidden = true
        
        panInteractionController.wireToViewController(self)
    }
    
    fileprivate func setupPulseButton() {
        view.addSubview(pulseAppButton)

        pulseAppButton.translatesAutoresizingMaskIntoConstraints = false
        pulseAppButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Spacing.xs.rawValue).isActive = true
        pulseAppButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        pulseAppButton.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        pulseAppButton.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        pulseAppButton.isUserInteractionEnabled = true
        
        pulseAppButtonTap = UITapGestureRecognizer(target: self, action: #selector(handleAppButtonTap))
        pulseAppButton.addGestureRecognizer(pulseAppButtonTap)
        
        //pulseAppButton.setImage(UIImage(named: "pulse-logo"), for: .normal)
        //pulseAppButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
    }
    
    func handleAppButtonTap() {
        switch selectedIndex  {
        case 0:
            break
        case 1:
            exploreVC.appButtonTapped()
        case 2:
            homeVC.appButtonTapped()
        default: break
        }
    }
    
    fileprivate func setupIcons(_selectedIndex: Int) {
        /**
        view.addSubview(tabIcons)
        
        tabIcons.translatesAutoresizingMaskIntoConstraints = false
        tabIcons.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Spacing.s.rawValue).isActive = true
        tabIcons.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.s.rawValue).isActive = true
        tabIcons.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4).isActive = true
        **/
        
        profileButton.addTarget(self, action: #selector(setSelected(_:)), for: .touchUpInside)
        exploreButton.addTarget(self, action: #selector(setSelected(_:)), for: .touchUpInside)
        feedButton.addTarget(self, action: #selector(setSelected(_:)), for: .touchUpInside)
        
        tabIcons.axis = .horizontal
        tabIcons.alignment = .lastBaseline
        tabIcons.distribution = .fillProportionally
        tabIcons.spacing = Spacing.xs.rawValue
        
        profileLabel.text = "Profile"
        exploreLabel.text = "Explore"
        feedLabel.text = "Feed"
    
        profileLabel.setFont(FontSizes.caption2.rawValue, weight: UIFontWeightRegular, color: .white, alignment: .center)
        exploreLabel.setFont(FontSizes.caption2.rawValue, weight: UIFontWeightRegular, color: .white, alignment: .center)
        feedLabel.setFont(FontSizes.caption2.rawValue, weight: UIFontWeightRegular, color: .white, alignment: .center)
        
        profileLabel.setBlurredBackground()
        exploreLabel.setBlurredBackground()
        feedLabel.setBlurredBackground()
        
        /** INDIVIDUAL STACK VIEWS WITH BUTTON + LABEL **/
        profileStack.addArrangedSubview(profileButton)
        profileStack.addArrangedSubview(profileLabel)
        
        profileStack.axis = .vertical
        profileStack.alignment = .center
        profileStack.distribution = .fillProportionally

        exploreStack.axis = .vertical
        exploreStack.alignment = .center
        exploreStack.distribution = .fillProportionally
        
        exploreStack.addArrangedSubview(exploreButton)
        exploreStack.addArrangedSubview(exploreLabel)

        feedStack.axis = .vertical
        feedStack.alignment = .center
        feedStack.distribution = .fillProportionally
        
        feedStack.addArrangedSubview(feedButton)
        feedStack.addArrangedSubview(feedLabel)
        
        /** ADD TO MASTER STACK **/
        tabIcons.addArrangedSubview(profileStack)
        tabIcons.addArrangedSubview(exploreStack)
        tabIcons.addArrangedSubview(feedStack)
        
        tabIcons.alpha = 0.5
        selectedIndex = _selectedIndex
    }
    
    fileprivate func setupLoading() {
        loadingView = LoadingView(frame: view.bounds, backgroundColor: .white)
        view.addSubview(loadingView!)
        
        loadingView?.addLongIcon(IconSizes.medium, _iconColor: UIColor.black, _iconBackgroundColor: nil)
        loadingView?.addMessage("P U L S E", _color: .black)
        loadingView?.loadingDelegate = self
    }
    
    func clickedRefresh() {
        loadingView?.addMessage("Loading...", _color: .black)
        checkReachability()
    }
    
    func handleLink(link: URL) {
        if isLoaded {
            exploreVC.universalLink = link
            setSelected(exploreButton)
        } else {
            universalLink = link
        }
    }
    
    func setSelected(_ sender: UIButton) {

        switch sender {
        case profileButton:
            selectedIndex = 0

        case exploreButton:
            selectedIndex = 1

        case feedButton:
            selectedIndex = 2
            
        default: break
        }
    }
    
    fileprivate func setDeselectIcon(index: Int) {

        switch index {
        case 0:
            profileButton.isHighlighted = false
            DispatchQueue.main.async {
                self.profileLabel.textColor = .white
                self.profileButton.transform = CGAffineTransform.identity
            }

        case 1:
            exploreButton.isHighlighted = false
            DispatchQueue.main.async {
                self.exploreLabel.textColor = .white
                self.exploreButton.transform = CGAffineTransform.identity
            }

        case 2:
            feedButton.isHighlighted = false
            DispatchQueue.main.async {
                self.feedLabel.textColor = .white
                self.feedButton.transform = CGAffineTransform.identity
            }

        default: break
        }
    }
    
    fileprivate func setSelectedIcon(index : Int) {

        let xScaleUp = CGAffineTransform(scaleX: 1.2, y: 1.2)

        switch index {
        case 0:
            profileButton.isHighlighted = true
            DispatchQueue.main.async {
                self.profileLabel.textColor = pulseBlue
                self.profileButton.transform = xScaleUp
            }
        case 1:
            exploreButton.isHighlighted = true
            DispatchQueue.main.async {
                self.exploreLabel.textColor = pulseBlue
                self.exploreButton.transform = xScaleUp
            }
        case 2:
            feedButton.isHighlighted = true
            DispatchQueue.main.async {
                self.feedLabel.textColor = pulseBlue
                self.feedButton.transform = xScaleUp
            }
        default: break
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController,
                                animationControllerForTransitionFrom
                                fromVC: UIViewController,
                                to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        let fromVCIndex = tabBarController.viewControllers?.index(of: fromVC)
        let toVCIndex = tabBarController.viewControllers?.index(of: toVC)
        
        let animator = PanAnimationController()
        animator.delegate = self
        
        animator.tabIcons = self.tabIcons
        if fromVCIndex < toVCIndex {
            animator.initialFrame = rectToRight
            animator.exitFrame = rectToLeft
            animator.transitionType = .present
        } else {
            animator.initialFrame = rectToLeft
            animator.exitFrame = rectToRight
            animator.transitionType = .dismiss
        }
        
        return animator
    }
    
    func tabBarController(_ tabBarController: UITabBarController,
                            interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return panInteractionController.interactionInProgress ? panInteractionController : nil
    }
}
