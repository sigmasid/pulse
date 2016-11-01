//
//  navVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/13/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
public enum LogoModes { case full, line, none }
public enum NavBarSize : CGFloat {
    case expandedScope = 135
    case expanded = 95
    case collapsed = 40
    case none = 0
}

public enum NavBarState { case expanded, collapsed, scrolling }

/**
 The state of the navigation bar
 - collapsed: the navigation bar is fully collapsed
 - expanded: the navigation bar is fully visible
 - scrolling: the navigation bar is transitioning to either `Collapsed` or `Scrolling`
 */

public protocol PulseNavControllerDelegate: NSObjectProtocol {
    /** Called when the state of the navigation bar is about to change */
    func scrollingNavWillSet(_ controller: PulseNavVC, state: NavBarState, size: NavBarSize)
}

public class PulseNavVC: UINavigationController, UIGestureRecognizerDelegate {

    public var navBar : PulseNavBar!
    public var navBarSize : NavBarSize = .expandedScope {
        didSet {
            setNavSize(size: navBarSize)
        }
    }
    
    public var shouldShowScope : Bool = false {
        didSet {
            navBarSize = shouldShowScope ? .expandedScope : .expanded
            toggleScopeBar(show: shouldShowScope)
        }
    }
    
    public var logoMode : LogoModes = .full {
        didSet {
            navBar.updateLogo(mode : logoMode)
        }
    }
    override public func viewDidLoad() {
        super.viewDidLoad()
        navBar = self.navigationBar as? PulseNavBar
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navBarState = .expanded
        
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func setNavSize(size : NavBarSize) {
        guard navBar != nil else { return }
        
        switch size {
        case .expandedScope: navBar.navBarSize =  CGSize(width: UIScreen.main.bounds.width, height: NavBarSize.expandedScope.rawValue)
        case .expanded: navBar.navBarSize =  CGSize(width: UIScreen.main.bounds.width, height: NavBarSize.expanded.rawValue)
        case .collapsed: navBar.navBarSize =  CGSize(width: UIScreen.main.bounds.width, height: NavBarSize.collapsed.rawValue)
        case .none: navBar.navBarSize =  CGSize(width: UIScreen.main.bounds.width, height: NavBarSize.none.rawValue)
        }
    }
    
    /** SCROLLING NAV IMPLEMENTATION **/

    
    /** Returns the `NavigationBarState` of the navigation bar */
    open fileprivate(set) var navBarState: NavBarState = .expanded {
        willSet {
            if newValue != navBarState {
                scrollingNavbarDelegate?.scrollingNavWillSet(self, state: newValue, size: navBarSize)
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
        guard let _ = self.scrollableView, let visibleViewController = self.visibleViewController else { return }
        
        if navBarState == .expanded {
            self.navBarState = .scrolling
            UIView.animate(withDuration: animated ? 0.1 : 0, animations: { () -> Void in
                self.scrollWithDelta(self.navBarSize.rawValue)
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
        guard let _ = self.scrollableView, let visibleViewController = self.visibleViewController else {
            return
        }
        
        if navBarState == .collapsed {
            gestureRecognizer?.isEnabled = false
            self.navBarState = .scrolling
            UIView.animate(withDuration: animated ? 0.1 : 0, animations: {
                self.lastContentOffset = 0;
                self.delayDistance =  self.navBarSize.rawValue
                self.scrollWithDelta(-self.navBarSize.rawValue)
                visibleViewController.view.setNeedsLayout()
                if self.navigationBar.isTranslucent {
                    let currentOffset = self.contentOffset
                    self.scrollView()?.contentOffset = CGPoint(x: currentOffset.x, y: currentOffset.y - self.navBarSize.rawValue)
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
        print("stop following scroll view fired")
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

        guard let pulseNavBar = navigationBar as? PulseNavBar else { return }
        pulseNavBar.collapsedTitleLabel.alpha = 0.0

    }
    
    // MARK: - Gesture recognizer
    func handlePan(_ gesture: UIPanGestureRecognizer) {
        if gesture.state != .failed {
            if let superview = scrollableView?.superview {
                let translation = gesture.translation(in: superview)
                let delta = lastContentOffset - translation.y
                lastContentOffset = translation.y
                
                if shouldScrollWithDelta(delta) {
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
        guard let pulseNavBar = navigationBar as? PulseNavBar else { return }

        let frame = pulseNavBar.frame
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
            if navBarState == .collapsed {
                return
            }
            
            // Compute the bar position
            if frame.origin.y - scrollDelta < -deltaLimit {
                scrollDelta = frame.origin.y + deltaLimit
            }
            
            // Detect when the bar is completely collapsed
            if frame.origin.y <= -deltaLimit {
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
            if navBarState == .expanded {
                return
            }
            
            // Compute the bar position
            if frame.origin.y - scrollDelta > statusBarHeight {
                scrollDelta = frame.origin.y - statusBarHeight
            }
            
            // Detect when the bar is completely expanded
            if frame.origin.y >= statusBarHeight {
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
        guard let topViewController = self.topViewController else { return }
        guard let pulseNavBar = navigationBar as? PulseNavBar else { return }
        
        var frame = pulseNavBar.frame
        
        // Move the navigation bar
        frame.origin = CGPoint(x: frame.origin.x, y: min(frame.origin.y - delta, statusBarHeight))
        pulseNavBar.frame = frame
        
        // Resize the view if the navigation bar is not translucent
        if !pulseNavBar.isTranslucent {
            let navBarY = pulseNavBar.frame.origin.y + pulseNavBar.frame.size.height
            frame = topViewController.view.frame
            frame.origin = CGPoint(x: frame.origin.x, y: navBarY)
            frame.size = CGSize(width: frame.size.width, height: view.frame.size.height - (navBarY) - tabBarOffset)
            topViewController.view.frame = frame
            topViewController.view.setNeedsLayout()
        } else {
            adjustContentInsets()
        }
    }
    
    private func updateNavbarAlpha() {
        if let pulseNavBar = navigationBar as? PulseNavBar {
            let frame = pulseNavBar.frame
            let alpha = (frame.origin.y + deltaLimit) / deltaLimit
            pulseNavBar.expandedContainer.alpha = alpha
            pulseNavBar.getScopeBar()?.alpha = alpha
            pulseNavBar.collapsedTitleLabel.alpha = 1 - alpha
            print("collapsed title label alpha is \(pulseNavBar.collapsedTitleLabel.alpha)")
        }
    }
    
    private func adjustContentInsets() {
        if let view = scrollView() as? UICollectionView {
            view.contentInset.top = navigationBar.frame.origin.y + navigationBar.frame.size.height
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
        
        let frame = navBar.frame
        var duration = TimeInterval(0)
        var delta = CGFloat(0.0)
        let distance = delta / (frame.size.height / 2)
        
        // Scroll back down
        let threshold = statusBarHeight - (frame.size.height / 2)
        if navBar.frame.origin.y >= threshold {
            delta = frame.origin.y - statusBarHeight
            duration = TimeInterval(abs(distance * 0.2))
            navBarState = .expanded
        } else {
            // Scroll up
            delta = frame.origin.y + deltaLimit
            duration = TimeInterval(abs(distance * 0.2))
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
    
    
    public func setNav(title: String?, subtitle: String?, statusImage : UIImage?) {
        guard navBar != nil else { return }
        
        if let statusImage = statusImage {
            navBar.toggleStatus(show: true)
            navBar.setExpandedTitleImage(_image: statusImage)
            navBar.setExpandedTitles(_title: nil, _subtitle: subtitle)
        } else {
            navBar.setExpandedTitles(_title: title, _subtitle: subtitle)
        }
    }
    
    public func toggleScopeBar(show : Bool) {
        guard navBar != nil else { return }
        navBar.toggleScopeBar(show : show)
    }
    
    public func updateScopeBar(titles : [String], icons : [UIImage]?, selected: Int) {
        guard navBar != nil else { return }
        navBar.updateScopeBarTitles(titles : titles, icons : icons, selected: selected)
    }
    
    public func toggleSearch(show : Bool) {
        guard navBar != nil else { return }
        navBar.toggleSearch(show : show)
    }
    
    public func toggleLogo(mode : LogoModes) {
        if let navBar = self.navigationBar as? PulseNavBar {
            navBar.updateLogo(mode : mode)
        }
    }
    
    fileprivate func setStatusImage(image : UIImage?) {
        guard navBar != nil else { return }
        
        navBar.toggleStatus(show: false) //hides both status label and image if visible
        navBar.setExpandedTitleImage(_image: image)
    }
    
    public func setTitle(title : String?) {
        guard navBar != nil else { return }

        if navBarState == .expanded {
            navBar.toggleStatus(show: false) //hides both status label and image if visible
            navBar.setExpandedTitles(_title : title, _subtitle: nil) //unhides lable within call
        }
    }

    fileprivate func updateBackgroundImage(image : UIImage?) {
        if let navBar = self.navigationBar as? PulseNavBar, let image = image {
            navBar.setBackgroundImage(image, for: .default)
        }
    }
    
    public func getSearchContainer() -> UIView? {
        if let navBar = self.navigationBar as? PulseNavBar {
            return navBar.getSearchContainer()
        } else {
            return nil
        }
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
        return self.navBarSize.rawValue - NavBarSize.collapsed.rawValue
    }
}
