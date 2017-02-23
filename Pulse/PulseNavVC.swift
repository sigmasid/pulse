//
//  navVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/13/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

public enum NavBarState { case expanded, collapsed, scrolling }

/**
 The state of the navigation bar
 - collapsed: the navigation bar is fully collapsed
 - expanded: the navigation bar is fully visible
 - scrolling: the navigation bar is transitioning to either `Collapsed` or `Scrolling`
 */

public protocol PulseNavControllerDelegate: NSObjectProtocol {
    /** Called when the state of the navigation bar is about to change */
    func scrollingNavDidSet(_ controller: PulseNavVC, state: NavBarState)
}

public class PulseNavVC: UINavigationController, UIGestureRecognizerDelegate {

    public var navBar : PulseNavBar!

    override public func viewDidLoad() {
        super.viewDidLoad()
        navBar = self.navigationBar as? PulseNavBar
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(false)
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    public func setNav(title: String?) {
        guard navBar != nil else { return }
        navBar.setTitles(title: title)
    }

    public func toggleSearch(show : Bool) {
        guard navBar != nil else { return }
        navBar.toggleSearch(show : show)
    }

    public func updateBackgroundImage(image : UIImage?) {
        guard navBar != nil else { return }
        navBar.setBackgroundImage(image, for: .default)
    }
    
    public func getSearchContainer() -> UIView? {
        guard navBar != nil else { return nil }
        return navBar.getSearchContainer()
    }

    override public func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
    }
}
