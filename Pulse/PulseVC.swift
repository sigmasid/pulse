//
//  PulseVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/3/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class PulseVC: UIViewController, PulseNavControllerDelegate {
    
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

    open var tabBarHidden : Bool = false {
        didSet {
            if tabBarHidden {
                tabBarController?.tabBar.isHidden = true
                edgesForExtendedLayout = .bottom
                extendedLayoutIncludesOpaqueBars = true
            } else {
                tabBarController?.tabBar.isHidden = false
                edgesForExtendedLayout = []
                extendedLayoutIncludesOpaqueBars = false
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
    
    /**
     Called when the state of the navigation bar changes
     */
    func scrollingNavigationController(_ controller: PulseNavVC, didChangeState state: NavigationBarState) {
        if state != currentNavState {
            if state == .collapsed {
                //statusBarHidden = true
                //currentNavState = .collapsed
                statusBarStyle = .lightContent

            } else if state == .expanded {
                //statusBarHidden = false
                //currentNavState = .expanded
                statusBarStyle = .default
            }
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    /**
     Called when the state of the navigation bar is about to change
     */
    func scrollingNavigationController(_ controller: PulseNavVC, willChangeState state: NavigationBarState) {

    }
}
