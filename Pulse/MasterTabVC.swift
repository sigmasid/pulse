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
    func setTabIcons()
    func cancelSettingIcons()
}


class MasterTabVC: UITabBarController, UITabBarControllerDelegate, tabVCDelegate {
    public var currentSelectedIndex : Int = 0
    public var currentDeselectedIndex : Int = 0

    fileprivate var initialLoadComplete = false
    
    var accountVC : AccountLoginManagerVC = AccountLoginManagerVC()
    var exploreVC : ExploreVC = ExploreVC()
    var homeVC : HomeVC = HomeVC()
    
    fileprivate var tabIcons = UIStackView()
    
    fileprivate var profileButton = PulseButton(size: .small, type: .profile, isRound: true, hasBackground: false)
    fileprivate var exploreButton = PulseButton(size: .small, type: .search, isRound: true, hasBackground: false)
    fileprivate var feedButton = PulseButton(size: .small, type: .browse, isRound: true, hasBackground: false)
    
    fileprivate var pulseAppButton = IconContainer(frame: CGRect(x: 0,y: 0,
                                                                width: IconSizes.medium.rawValue,
                                                                height: IconSizes.small.rawValue + Spacing.s.rawValue))

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
                    self.currentSelectedIndex = 2
                    self.setupControllers()
                    self.setupIcons()
                    
                    self.initialLoadComplete = true
                    
                } else if !success && !self.initialLoadComplete {
                    self.currentSelectedIndex = 1
                    self.setupControllers()
                    self.setupIcons()
                    self.initialLoadComplete = true
                }
                
                self.selectedIndex = self.currentSelectedIndex
                self.isLoaded = true
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupControllers() {
        let accountNavVC = PulseNavVC(navigationBarClass: PulseNavBar.self, toolbarClass: nil)
        accountNavVC.setNav(navTitle: "Account", screenTitle: nil, screenImage: nil)
        accountNavVC.viewControllers = [accountVC]

        let exploreNavVC = PulseNavVC(navigationBarClass: PulseNavBar.self, toolbarClass: nil)
        accountNavVC.setNav(navTitle: nil, screenTitle: "Explore", screenImage: nil)
        exploreNavVC.viewControllers = [exploreVC]
        
        let homeNavVC = PulseNavVC(navigationBarClass: PulseNavBar.self, toolbarClass: nil)
        homeNavVC.isNavigationBarHidden = true
        homeNavVC.viewControllers = [homeVC]
        
        viewControllers = [accountNavVC, exploreNavVC, homeNavVC]
        
        let tabAccount = UITabBarItem(title: "Account", image: UIImage(named: "settings"), selectedImage: UIImage(named: "profile"))
        let tabExplore = UITabBarItem(title: "Explore", image: UIImage(named: "search"), selectedImage: UIImage(named: "search"))
        let tabHome = UITabBarItem(title: "Home", image: UIImage(named: "browse"), selectedImage: UIImage(named: "explore"))
        
        accountVC.tabBarItem = tabAccount
        exploreVC.tabBarItem = tabExplore
        homeVC.tabBarItem = tabHome
        
        rectToLeft = view.frame
        rectToLeft.origin.x = view.frame.minX - view.frame.size.width
        rectToRight = view.frame
        rectToRight.origin.x = view.frame.maxX
        
        delegate = self
        tabBar.backgroundImage = GlobalFunctions.imageWithColor(UIColor.clear)
        tabBar.isHidden = true
        
        panInteractionController.wireToViewController(self)
    }
    
    fileprivate func setupIcons() {
        view.addSubview(tabIcons)
        view.addSubview(pulseAppButton)
        
        tabIcons.translatesAutoresizingMaskIntoConstraints = false
        tabIcons.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Spacing.s.rawValue).isActive = true
        tabIcons.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.s.rawValue).isActive = true
        //tabIcons.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4).isActive = true

        pulseAppButton.translatesAutoresizingMaskIntoConstraints = false
        pulseAppButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Spacing.xs.rawValue).isActive = true
        pulseAppButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        pulseAppButton.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        pulseAppButton.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true

        tabIcons.addArrangedSubview(profileButton)
        tabIcons.addArrangedSubview(exploreButton)
        tabIcons.addArrangedSubview(feedButton)

        profileButton.setVerticalTitle("Profile", for: UIControlState())
        exploreButton.setVerticalTitle("Explore", for: UIControlState())
        feedButton.setVerticalTitle("Feed", for: UIControlState())

        tabIcons.axis = .horizontal
        tabIcons.alignment = .lastBaseline
        tabIcons.distribution = .fillEqually
        tabIcons.spacing = Spacing.xs.rawValue
        
        tabIcons.alpha = 0.5
        
        DispatchQueue.main.async { self.setSelectedIcon(index: self.currentSelectedIndex) }
    }
    
    func setTabIcons() { //animated transition
        setDeselectIcon(index: currentDeselectedIndex)
        setSelectedIcon(index: currentSelectedIndex)
    }
    
    func cancelSettingIcons() {
        print("should cancel animation")
    }
    
    fileprivate func setDeselectIcon(index: Int) {
        switch index {
        case 0:
            profileButton.isHighlighted = false
            profileButton.frame.origin.y += Spacing.xs.rawValue

        case 1:
            exploreButton.isHighlighted = false
            exploreButton.frame.origin.y += Spacing.xs.rawValue

        case 2:
            feedButton.isHighlighted = false
            feedButton.frame.origin.y += Spacing.xs.rawValue
            
        default: break
        }
    }
    
    fileprivate func setSelectedIcon(index : Int) {
        print("setting selected icon to \(index)")
        switch index {
        case 0:
            profileButton.isHighlighted = true
            profileButton.frame.origin.y -= Spacing.xs.rawValue
            pulseAppButton.setViewTitle("Profile")
        case 1:
            print("explore button frame is \(feedButton.frame)")
            exploreButton.isHighlighted = true
            exploreButton.frame.origin.y -= Spacing.xs.rawValue
            pulseAppButton.setViewTitle("Explore")
            print("explore button new frame is \(feedButton.frame)")

        case 2:
            print("feed button frame is \(feedButton.frame)")
            feedButton.isHighlighted = true
            feedButton.frame.origin.y -= Spacing.xs.rawValue
            print("feed button new frame is \(feedButton.frame)")

            pulseAppButton.setViewTitle("Feed")

        default: break
        }
    }
    
    fileprivate func addLogoIcon(text : String) -> IconContainer {
        let iconContainer = IconContainer(frame: CGRect(x: 0,y: 0, width: IconSizes.medium.rawValue, height: IconSizes.medium.rawValue + Spacing.m.rawValue))
        iconContainer.setViewTitle(text)
        
        return iconContainer
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let indexOfTab = tabBarController.viewControllers?.index(of: viewController) {
            currentSelectedIndex = indexOfTab
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController,
                                animationControllerForTransitionFrom
                                fromVC: UIViewController,
                                to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        let fromVCIndex = tabBarController.viewControllers?.index(of: fromVC)
        let toVCIndex = tabBarController.viewControllers?.index(of: toVC)
        
        let animator = PanAnimationController()
        
        currentDeselectedIndex = currentSelectedIndex
        currentSelectedIndex = toVCIndex ?? (currentSelectedIndex)
        
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
