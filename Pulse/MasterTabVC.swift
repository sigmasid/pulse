//
//  MasterTabVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/12/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class MasterTabVC: UITabBarController, UITabBarControllerDelegate {
    private var initialLoadComplete = false

    lazy var searchVC : SearchVC = SearchVC()
    lazy var homeVC : HomeVC = HomeVC()
    lazy var accountVC : AccountLoginManagerVC = AccountLoginManagerVC()
    
    private var panInteractionController = PanHorizonInteractionController()
    
    private var initialFrame : CGRect!
    private var rectToRight : CGRect!
    private var rectToLeft : CGRect!
    
    private var isLoaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            Database.checkCurrentUser { success in
                
            // get feed and show initial view controller
            if success && !self.initialLoadComplete {
                self.setupControllers(2)
                self.initialLoadComplete = true
            }
            self.isLoaded = true
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupControllers(initialIndex : Int) {
        viewControllers = [accountVC, searchVC, homeVC]

        let tabAccount = UITabBarItem(title: "Account", image: UIImage(named: "settings"), selectedImage: UIImage(named: "settings"))
        let tabSearch = UITabBarItem(title: "Search", image: UIImage(named: "search"), selectedImage: UIImage(named: "search"))
        let tabHome = UITabBarItem(title: "Home", image: UIImage(named: "browse"), selectedImage: UIImage(named: "browse"))
        
        accountVC.tabBarItem = tabAccount
        searchVC.tabBarItem = tabSearch
        homeVC.tabBarItem = tabHome
        
        selectedIndex = initialIndex
        
        rectToLeft = view.frame
        rectToLeft.origin.x = view.frame.minX - view.frame.size.width
        rectToRight = view.frame
        rectToRight.origin.x = view.frame.maxX
        
        delegate = self
        tabBar.tintColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)
        tabBar.backgroundImage = GlobalFunctions.imageWithColor(UIColor.clearColor())
        
        panInteractionController.wireToViewController(self)

    }
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        print("Selected \(viewController.title!)")
    }
    
    func tabBarController(tabBarController: UITabBarController,
                                animationControllerForTransitionFromViewController
                                fromVC: UIViewController,
                                toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        let fromVCIndex = tabBarController.viewControllers?.indexOf(fromVC)
        let toVCIndex = tabBarController.viewControllers?.indexOf(toVC)
        
        let animator = PanAnimationController()
        
        if fromVCIndex < toVCIndex {
            animator.initialFrame = rectToRight
            animator.exitFrame = rectToLeft
            animator.transitionType = .Present
        } else {
            animator.initialFrame = rectToLeft
            animator.exitFrame = rectToRight
            animator.transitionType = .Dismiss
        }
        
        return animator
        
    }
    
    func tabBarController(tabBarController: UITabBarController,
                            interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return panInteractionController.interactionInProgress ? panInteractionController : nil
    }


}
