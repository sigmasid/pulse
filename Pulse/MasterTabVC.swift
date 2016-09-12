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
    lazy var feedVC : FeedVC = FeedVC()
    lazy var accountVC : AccountLoginManagerVC = AccountLoginManagerVC()
    
    private var panInteractionController = PanHorizonInteractionController()
    
    private var initialFrame : CGRect!
    private var rectToRight : CGRect!
    private var rectToLeft : CGRect!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Database.checkCurrentUser { success in
            // get feed and show initial view controller
            if success && !self.initialLoadComplete {
                self.feedVC.pageType = .Home
                self.feedVC.feedItemType = .Question
                self.setupControllers()
                self.initialLoadComplete = true
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupControllers() {
        viewControllers = [accountVC, searchVC, feedVC]

        let tabAccount = UITabBarItem(title: "Account", image: UIImage(named: "settings"), selectedImage: UIImage(named: "settings"))
        let tabSearch = UITabBarItem(title: "Search", image: UIImage(named: "search"), selectedImage: UIImage(named: "search"))
        let tabFeed = UITabBarItem(title: "Home", image: UIImage(named: "browse"), selectedImage: UIImage(named: "browse"))
        
        accountVC.tabBarItem = tabAccount
        searchVC.tabBarItem = tabSearch
        feedVC.tabBarItem = tabFeed
        
        selectedIndex = 2
        
        rectToLeft = view.frame
        rectToLeft.origin.x = view.frame.minX - view.frame.size.width
        
        rectToRight = view.frame
        rectToRight.origin.x = view.frame.maxX
        
        delegate = self
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
