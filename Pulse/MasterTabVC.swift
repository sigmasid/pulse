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

class MasterTabVC: UITabBarController, UITabBarControllerDelegate, LoadingDelegate, FirstLaunchDelegate {
    
    public var reachability: Reachability? = Reachability.networkReachabilityForInternetConnection()
    public var showAppIntro = false
    public var introDelegate : FirstLaunchDelegate!

    fileprivate var introTab : IntroType = .other
    fileprivate var initialLoadComplete = false
    fileprivate var loadingView : LoadingView!

    var accountVC : AccountLoginManagerVC!
    var exploreChannelsVC : ExploreChannelsVC!
    var inboxVC : InboxVC!
    var homeVC : HomeVC!

    fileprivate var panInteractionController = PanHorizonInteractionController()
    fileprivate var initialFrame : CGRect!
    fileprivate var rectToRight : CGRect!
    fileprivate var rectToLeft : CGRect!
    
    fileprivate var isLoaded = false
    fileprivate var universalLink : URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoading()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityDidChange(_:)), name: NSNotification.Name(rawValue: ReachabilityDidChangeNotificationName), object: nil)
        checkReachability()
        
        _ = reachability?.startNotifier()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if showAppIntro {
            let appIntro = FirstLoadVC()
            appIntro.introDelegate = self
            appIntro.transitioningDelegate = self
            present(appIntro, animated: true, completion: {})
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        reachability?.stopNotifier()
    }
    
    internal func checkReachability() {
        guard let r = reachability else { return }
        if r.isReachable, !isLoaded {
            setupControllers()
            
            PulseDatabase.checkCurrentUser {[weak self] success in
                guard let `self` = self else { return }
                
                if let link = self.universalLink {
                    self.selectedIndex = 1
                    self.exploreChannelsVC.universalLink = link
                    self.initialLoadComplete = true
                    
                } else if self.introTab == .login {
                    self.selectedIndex = 0
                    self.initialLoadComplete = true
                }
                    // get feed and show initial view controller
                else if success && !self.initialLoadComplete {
                    self.selectedIndex = 3
                    self.initialLoadComplete = true
                    
                } else if !success && !self.initialLoadComplete {
                    self.selectedIndex = 1
                    self.initialLoadComplete = true
                }
                
                self.isLoaded = true
                self.removeLoading()
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
    
    internal func reachabilityDidChange(_ notification: Notification) {
        checkReachability()
    }
    
    internal func doneWithIntro(mode: IntroType) {
        showAppIntro = false //update in userdefaults
        introTab = mode

        if !isLoaded {
            checkReachability()
        } else {
            if mode == .login {
                selectedIndex = 0
            }
        }
        
        if introDelegate != nil {
            introDelegate.doneWithIntro(mode: mode)
        }
    }
    
    //DELEGATE METHOD TO REMOVE INITIAL LOADING SCREEN WHEN THE FEED IS LOADED
    internal func removeLoading() {
        UIView.animate(withDuration: 1, animations: { self.loadingView.alpha = 0 } , completion: {(value: Bool) in
            self.loadingView.isHidden = true
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    internal func setupControllers() {
        accountVC = AccountLoginManagerVC(navigationBarClass: PulseNavBar.self, toolbarClass: nil)
        
        exploreChannelsVC = ExploreChannelsVC()
        let exploreNavVC = PulseNavVC(navigationBarClass: PulseNavBar.self, toolbarClass: nil)
        exploreNavVC.viewControllers = [exploreChannelsVC]
        
        inboxVC = InboxVC()
        let inboxNavVC = PulseNavVC(navigationBarClass: PulseNavBar.self, toolbarClass: nil)
        inboxNavVC.viewControllers = [inboxVC]
        
        homeVC = HomeVC()
        let homeNavVC = PulseNavVC(navigationBarClass: PulseNavBar.self, toolbarClass: nil)
        homeNavVC.viewControllers = [homeVC]

        viewControllers = [accountVC, exploreNavVC, inboxNavVC, homeNavVC]
        
        let tabAccount = UITabBarItem(title: nil, image: UIImage(named: "tab-profile"), tag: 10)
        let tabExplore = UITabBarItem(title: nil, image: UIImage(named: "tab-explore"), tag: 20)
        let tabInbox = UITabBarItem(title: nil, image: UIImage(named: "tab-messages"), tag: 30)
        let tabHome = UITabBarItem(title: nil, image: UIImage(named: "tab-home"), tag: 40)
        
        UITabBar.appearance().tintColor = .pulseBlue
        
        accountVC.tabBarItem = tabAccount
        exploreChannelsVC.tabBarItem = tabExplore
        inboxVC.tabBarItem = tabInbox
        homeVC.tabBarItem = tabHome
        
        rectToLeft = view.frame
        rectToLeft.origin.x = view.frame.minX - view.frame.size.width
        rectToRight = view.frame
        rectToRight.origin.x = view.frame.maxX
        
        delegate = self
        tabBar.backgroundImage = GlobalFunctions.imageWithColor(UIColor.white)
        
        panInteractionController.wireToViewController(self)
    }
    
    fileprivate func setupLoading() {
        loadingView = LoadingView(frame: view.bounds, backgroundColor: .white)
        view.addSubview(loadingView!)
        
        loadingView?.addLongIcon(IconSizes.medium, _iconColor: UIColor.black, _iconBackgroundColor: nil)
        loadingView?.addTextLogo()
        loadingView?.loadingDelegate = self
    }
    
    internal func clickedRefresh() {
        loadingView?.addMessage("Loading...", _color: .black)
        checkReachability()
    }
    
    internal func handleLink(link: URL) {
        if isLoaded {
            exploreChannelsVC.universalLink = link
            selectedIndex = 1
        } else {
            universalLink = link
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController,
                                animationControllerForTransitionFrom
                                fromVC: UIViewController,
                                to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        let fromVCIndex = tabBarController.viewControllers?.index(of: fromVC)
        let toVCIndex = tabBarController.viewControllers?.index(of: toVC)
        
        let animator = PanAnimationController()
        
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

extension MasterTabVC: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if presented is FirstLoadVC {
            let animator = FadeAnimationController()
            animator.transitionType = .present
            
            return animator            
        } else {
            return nil
        }
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is FirstLoadVC {

            let animator = FadeAnimationController()
            animator.transitionType = .dismiss
            
            return animator
        } else {
            return nil
        }
    }
}
