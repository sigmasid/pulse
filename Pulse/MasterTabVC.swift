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

class MasterTabVC: UITabBarController, UITabBarControllerDelegate, LoadingDelegate {
    
    var reachability: Reachability? = Reachability.networkReachabilityForInternetConnection()

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
            
            Database.checkCurrentUser { success in
                if let link = self.universalLink {
                    self.selectedIndex = 1
                    self.exploreChannelsVC.universalLink = link
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
    
    func reachabilityDidChange(_ notification: Notification) {
        checkReachability()
    }
    
    //DELEGATE METHOD TO REMOVE INITIAL LOADING SCREEN WHEN THE FEED IS LOADED
    func removeLoading() {
        UIView.animate(withDuration: 0.25, animations: { self.loadingView.alpha = 0 } , completion: {(value: Bool) in
            self.loadingView.isHidden = true
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupControllers() {
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
        loadingView?.addMessage("P U L S E", _color: .black)
        loadingView?.loadingDelegate = self
    }
    
    func clickedRefresh() {
        loadingView?.addMessage("Loading...", _color: .black)
        checkReachability()
    }
    
    func handleLink(link: URL) {
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
