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


class MasterTabVC: UITabBarController, UITabBarControllerDelegate {
    fileprivate var initialLoadComplete = false

    var accountNavVC : PulseNavVC!
    var exploreNavVC : PulseNavVC!

    var accountVC : AccountLoginManagerVC = AccountLoginManagerVC()
    var exploreVC : ExploreVC = ExploreVC()
    lazy var homeVC : HomeVC = HomeVC()
    
    fileprivate var panInteractionController = PanHorizonInteractionController()
    
    fileprivate var initialFrame : CGRect!
    fileprivate var rectToRight : CGRect!
    fileprivate var rectToLeft : CGRect!
    
    fileprivate var isLoaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            Database.checkCurrentUser { success in
            // get feed and show initial view controller
            if success && !self.initialLoadComplete {
                self.setupControllers(1)
                self.initialLoadComplete = true
            } else if !success && !self.initialLoadComplete {
                self.setupControllers(1)
                self.initialLoadComplete = true
            }
            self.isLoaded = true
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupControllers(_ initialIndex : Int) {
        accountNavVC = PulseNavVC(navigationBarClass: PulseNavBar.self, toolbarClass: nil)
        accountNavVC.navBarSize = .expanded
        accountNavVC.viewControllers = [accountVC]

        exploreNavVC = PulseNavVC(navigationBarClass: PulseNavBar.self, toolbarClass: nil)
        exploreNavVC.navigationBar.barTintColor = UIColor(red:0.91, green:0.3, blue:0.24, alpha:1)
        exploreNavVC.viewControllers = [exploreVC]

        let homeNavVC = UINavigationController(rootViewController: homeVC)
        homeNavVC.isNavigationBarHidden = true
        viewControllers = [accountNavVC, exploreNavVC, homeNavVC]
        
        let tabAccount = UITabBarItem(title: "Account", image: UIImage(named: "settings"), selectedImage: UIImage(named: "profile"))
        let tabExplore = UITabBarItem(title: "Explore", image: UIImage(named: "search"), selectedImage: UIImage(named: "search"))
        let tabHome = UITabBarItem(title: "Home", image: UIImage(named: "browse"), selectedImage: UIImage(named: "explore"))
        
        accountVC.tabBarItem = tabAccount
        exploreVC.tabBarItem = tabExplore
        homeVC.tabBarItem = tabHome
        
        selectedIndex = initialIndex
        
        rectToLeft = view.frame
        rectToLeft.origin.x = view.frame.minX - view.frame.size.width
        rectToRight = view.frame
        rectToRight.origin.x = view.frame.maxX
        
        delegate = self
        tabBar.tintColor = UIColor.white.withAlphaComponent(0.5)
        tabBar.backgroundImage = GlobalFunctions.imageWithColor(UIColor.clear)
        tabBar.isHidden = true
        
        panInteractionController.wireToViewController(self)
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        print("Selected \(viewController.title!)")
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
