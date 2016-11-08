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
    
    public var shouldShowScope : Bool = false {
        didSet {
            guard navBar != nil else { return }
            navBar.shouldShowScope = shouldShowScope
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        navBar = self.navigationBar as? PulseNavBar
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /** SCROLLING NAV IMPLEMENTATION **/
    /** Returns the `NavigationBarState` of the navigation bar */
    open fileprivate(set) var navBarState: NavBarState = .expanded {
        didSet {
            if navBarState != oldValue {
                scrollingNavbarDelegate?.scrollingNavDidSet(self, state: navBarState)
            }
        }
    }
    
    /** Determines whether the navbar should scroll when the content inside the scrollview fits the view's size.
     Defaults to `true' - UICollectionView scrollview doesn't work with autolayout */
    open var shouldScrollWhenContentFits = true
    
    /** Determines if the navbar should expand once the application becomes active after entering backgroun
     Defaults to `true` */
    open var expandOnActive = true
    
    /**
     Determines if the navbar scrolling is enabled.
     Defaults to `true` */
    open var scrollingEnabled = true
    
    /** The delegate for the scrolling navbar controller */
    var scrollingNavbarDelegate: PulseNavControllerDelegate?
    
    open fileprivate(set) var gestureRecognizer: UIPanGestureRecognizer?
    var delayDistance: CGFloat = 0
    var maxDelay: CGFloat = 0
    var scrollableView: UIView?
    var lastContentOffset = CGFloat(0.0)
    
    /**
     Start scrolling
     Enables the scrolling by observing a view
     - parameter scrollableView: The view with the scrolling content that will be observed
     - parameter delay: The delay expressed in points that determines the scrolling resistance. Defaults to `0`
     */
    open func followScrollView(_ scrollableView: UIView, delay: Double = 0) {
        self.scrollableView = scrollableView
        
        gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        gestureRecognizer?.maximumNumberOfTouches = 1
        gestureRecognizer?.delegate = self
        scrollableView.addGestureRecognizer(gestureRecognizer!)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        maxDelay = CGFloat(delay)
        delayDistance = CGFloat(delay)
        scrollingEnabled = true
    }
    
    /**
     Hide the navigation bar
     - parameter animated: If true the scrolling is animated. Defaults to `true`
     */
    public func hideNavbar(animated: Bool = true) {
        guard let _ = self.scrollableView, let visibleViewController = self.visibleViewController, let navBar = navigationBar as? PulseNavBar else { return }
        
        if navBarState == .expanded {
            self.navBarState = .scrolling
            UIView.animate(withDuration: animated ? 0.1 : 0, animations: { () -> Void in
                self.scrollWithDelta(navBar.navBarSize.height)
                visibleViewController.view.setNeedsLayout()
            }) { _ in
                self.navBarState = .collapsed
            }
        } else {
            updateNavbarAlpha()
        }
    }
    
    /**
     Show the navigation bar
     - parameter animated: If true the scrolling is animated. Defaults to `true`
     */
    public func showNavbar(animated: Bool = true) {
        guard let _ = self.scrollableView, let visibleViewController = self.visibleViewController, let navBar = navigationBar as? PulseNavBar else {
            return
        }
        if navBarState == .collapsed {
            gestureRecognizer?.isEnabled = false
            self.navBarState = .scrolling
            UIView.animate(withDuration: animated ? 0.1 : 0, animations: {
                self.lastContentOffset = 0;
                self.delayDistance = -navBar.navBarSize.height
                self.scrollWithDelta(-navBar.navBarSize.height)
                visibleViewController.view.setNeedsLayout()
                if self.navigationBar.isTranslucent {
                    let currentOffset = self.contentOffset
                    self.scrollView()?.contentOffset = CGPoint(x: currentOffset.x, y: currentOffset.y - navBar.navBarSize.height)
                }
            }) { _ in
                self.navBarState = .expanded
                self.gestureRecognizer?.isEnabled = true
            }
        } else {
            updateNavbarAlpha()
        }
    }
    
    /**
     Stop observing the view and reset the navigation bar
     */
    public func stopFollowingScrollView() {
        showNavbar(animated: false)
        if let gesture = gestureRecognizer {
            scrollableView?.removeGestureRecognizer(gesture)
        }
        scrollableView = .none
        gestureRecognizer = .none
        scrollingNavbarDelegate = .none
        scrollingEnabled = false
        
        let center = NotificationCenter.default
        center.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        center.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    // MARK: - Gesture recognizer
    func handlePan(_ gesture: UIPanGestureRecognizer) {
        if gesture.state != .failed {
            if let superview = scrollableView?.superview {
                let translation = gesture.translation(in: superview)
                let delta = lastContentOffset - translation.y
                lastContentOffset = translation.y
                
                if shouldScrollWithDelta(delta) && shouldShowScope {
                    scrollWithDelta(delta)
                }
            }
        }
        
        if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
            checkForPartialScroll()
            lastContentOffset = 0
        }
    }
    
    /**
     UIContentContainer protocol method.
     Will show the navigation bar upon rotation or changes in the trait sizes.
     */
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        showNavbar()
    }
    
    // MARK: - Notification handler
    func didBecomeActive(_ notification: Notification) {
        if expandOnActive {
            showNavbar(animated: false)
        }
    }
    
    /// Handles when the status bar changes
    func willChangeStatusBar() {
        showNavbar(animated: true)
    }
    
    // MARK: - Scrolling functions
    private func shouldScrollWithDelta(_ delta: CGFloat) -> Bool {
        // Check for rubberbanding
        if delta < 0 {
            if let scrollableView = scrollableView , contentOffset.y + scrollableView.frame.size.height > contentSize.height && scrollableView.frame.size.height < contentSize.height {
                // Only if the content is big enough
                return false
            }
        } else {
            if contentOffset.y < 0 {
                return false
            }
        }
        return true
    }
    
    private func scrollWithDelta(_ delta: CGFloat) {
        var scrollDelta = delta
        guard let navBar = navigationBar as? PulseNavBar else { return }

        let frame = navBar.screenOptions.frame
        // View scrolling up, hide the navbar
        if scrollDelta > 0 {
            // Update the delay
            delayDistance -= scrollDelta
            
            // Skip if the delay is not over yet
            if delayDistance > 0 {
                return
            }
            
            // No need to scroll if the content fits
            if !shouldScrollWhenContentFits && navBarState != .collapsed &&
                (scrollableView?.frame.size.height)! >= contentSize.height {
                return
            }
            
            // Skip if scrolling down and already collapsed
            if navBarState == .collapsed && frame.origin.y <= navBar.fullNavHeight - deltaLimit {
                return
            }
            
            // Compute the bar position - not using delta limit because it includes statusbar height
            if frame.origin.y - scrollDelta < navBar.fullNavHeight - deltaLimit {
                scrollDelta = frame.origin.y - (navBar.fullNavHeight - deltaLimit)
            }
            
            // Detect when the bar is completely collapsed
            if frame.origin.y <= navBar.fullNavHeight - deltaLimit {
                navBarState = .collapsed
                delayDistance = maxDelay
            } else {
                navBarState = .scrolling
            }
        }
        
        if scrollDelta < 0 {
            
            // Update the delay
            delayDistance += scrollDelta
            
            // Skip if the delay is not over yet
            if delayDistance > 0 && maxDelay < contentOffset.y {
                return
            }
            
            // Skip if scrolling up and already expanded
            if navBarState == .expanded && frame.origin.y >= navBar.fullNavHeight {
                return
            }
            
            // Compute the bar position
            if frame.origin.y - scrollDelta > navBar.fullNavHeight {
                scrollDelta = frame.origin.y - navBar.fullNavHeight
            }
            
            // Detect when the bar is completely expanded
            if frame.origin.y >= navBar.fullNavHeight {
                navBarState = .expanded
                delayDistance = maxDelay
            } else {
                navBarState = .scrolling
            }
        }
        
        if navBarState == .scrolling {
            updateSizing(scrollDelta)
            updateNavbarAlpha()
            restoreContentOffset(scrollDelta)
        }
    }
    
    private func updateSizing(_ delta: CGFloat) {
        guard let topViewController = self.topViewController, let navBar = navigationBar as? PulseNavBar else { return }
        
        var screenOptionsFrame = navBar.screenOptions.frame
        
        // Move the navigation bar
        screenOptionsFrame.origin = CGPoint(x: screenOptionsFrame.origin.x,
                                            y: max(screenOptionsFrame.origin.y - delta, navBar.fullNavHeight - navBar.scopeBarHeight))
        navBar.screenOptions.frame = screenOptionsFrame
        
        navBar.navBarSize = CGSize(width: navBar.navBarSize.width,
                                   height: min(max(navBar.navBarSize.height - delta, navBar.fullNavHeight),
                                               navBar.fullNavHeight + navBar.scopeBarHeight))

        let navBarHeight = min(max(navBar.fullNavHeight, navBar.navBarSize.height - delta), navBar.fullNavHeight + navBar.scopeBarHeight) //maintain min frame size once status bar is hidden

        // Resize the view if the navigation bar is not translucent
        if !navBar.isTranslucent {
            var frame = topViewController.view.frame
            frame.origin = CGPoint(x: frame.origin.x, y: navBarHeight)
            frame.size = CGSize(width: frame.size.width, height: view.frame.size.height - (navBarHeight) - tabBarOffset)
            topViewController.view.frame = frame
        } else {
            adjustContentInsets()
        }
    }
    
    private func updateNavbarAlpha() {
        guard navBar != nil else { return }

        let frame = navBar.screenOptions.frame
        let alpha = (frame.origin.y - deltaLimit) / deltaLimit
        navBar.screenOptions.alpha = alpha
    }
    
    private func adjustContentInsets() {
        guard navBar != nil else { return }

        if let view = scrollView() as? UICollectionView {
            view.contentInset.top = navBar.frame.origin.y + navBar.frame.size.height
            // When this is called by `hideNavbar(_:)` or `showNavbar(_:)`, the sticky header reamins still
            // even if the content inset changed. This triggers a fake scroll, fixing the header's position
            view.setContentOffset(CGPoint(x: contentOffset.x, y: contentOffset.y - 0.1), animated: false)
        }
    }
    
    private func restoreContentOffset(_ delta: CGFloat) {
        if navigationBar.isTranslucent || delta == 0 {
            return
        }
        
        // Hold the scroll steady until the navbar appears/disappears
        if let scrollView = scrollView() {
            scrollView.setContentOffset(CGPoint(x: contentOffset.x, y: contentOffset.y - delta), animated: false)
        }
    }
    
    private func checkForPartialScroll() {
        guard navBar != nil else { return }
        
        let frame = navBar.screenOptions.frame
        var duration = TimeInterval(0)
        var delta = CGFloat(0.0)
        let distance = delta / (frame.size.height / 2)
        // Scroll back down
        let threshold = navBar.fullNavHeight - (navBar.scopeBarHeight / 2)
        if frame.origin.y >= threshold {
            delta = frame.origin.y - navBar.fullNavHeight
            duration = TimeInterval(abs(distance * 0.1))
            navBarState = .expanded

        } else {
            // Scroll up

            delta = navBar.fullNavHeight - frame.origin.y
            duration = TimeInterval(abs(distance * 0.1))
            navBarState = .collapsed
        }
        
        delayDistance = maxDelay
        
        UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions.beginFromCurrentState, animations: {
            self.updateSizing(delta)
            self.updateNavbarAlpha()
        }, completion: nil)
    }
    
    // MARK: - UIGestureRecognizerDelegate
    /**
     UIGestureRecognizerDelegate function. Enables the scrolling of both the content and the navigation bar
     */
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    /** UIGestureRecognizerDelegate function. Only scrolls the navigation bar with the content when `scrollingEnabled` is true */
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return scrollingEnabled
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    public func setNav(navTitle: String?, screenTitle: String?, screenImage : UIImage?) {
        guard navBar != nil else { return }
        navBar.setTitles(_navTitle: navTitle, _screenTitle: screenTitle, _navImage: screenImage)
    }
    
    public func updateScopeBar(titles : [String], icons : [UIImage]?, selected: Int) {
        guard navBar != nil else { return }
        navBar.updateScopeBarTitles(titles : titles, icons : icons, selected: selected)
    }
    
    public func toggleSearch(show : Bool) {
        guard navBar != nil else { return }
        navBar.toggleSearch(show : show)
    }

    fileprivate func updateBackgroundImage(image : UIImage?) {
        guard navBar != nil, let image = image else { return }
        navBar.setBackgroundImage(image, for: .default)
    }
    
    public func getSearchContainer() -> UIView? {
        guard navBar != nil else { return nil }
        return navBar.getSearchContainer()
    }
    
    public func getScopeBar() -> XMSegmentedControl? {
        guard navBar != nil else { return nil }
        return navBar.getScopeBar()
    }

    override public func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
    }
}

extension PulseNavVC {
    // MARK: - View sizing
    var tabBarOffset: CGFloat {
        // Only account for the tab bar if a tab bar controller is present and the bar is not translucent
        if let tabBarController = tabBarController {
            return tabBarController.tabBar.isTranslucent ? 0 : tabBarController.tabBar.frame.height
        }
        return 0
    }
    
    func scrollView() -> UIScrollView? {
        if let webView = scrollableView as? UIWebView {
            return webView.scrollView
        } else {
            return scrollableView as? UIScrollView
        }
    }
    
    var contentOffset: CGPoint {
        return scrollView()?.contentOffset ?? CGPoint.zero
    }
    
    var contentSize: CGSize {
        return scrollView()?.contentSize ?? CGSize.zero
    }
    
    var deltaLimit: CGFloat {
        guard navBar != nil else { return 0 }
        return navBar.scopeBarHeight
    }
}
