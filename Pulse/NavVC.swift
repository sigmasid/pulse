//
//  navVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/13/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
enum LogoModes { case full, line, none }

class NavVC: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    fileprivate func setupLayout() {
        navigationBar.titleTextAttributes =
            [NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: UIFont.systemFont(ofSize: FontSizes.headline.rawValue, weight: UIFontWeightMedium)]
        self.navigationItem.hidesBackButton = true
    }
    
    public func setAppTitle(appTitle : String, screenTitle : String?) {
        if let navBar = self.navigationBar as? PulseNavBar {
            navBar.setAppTitleLabel(_message: appTitle)
            if let screenTitle = screenTitle {
                navBar.setScreenTitleLabel(_message: screenTitle)
            }
        }
    }
    
    public func setNav(title: String?, subtitle: String?, statusImage : UIImage?) {
        if let navBar = self.navigationBar as? PulseNavBar {

            if let statusImage = statusImage {
                navBar.toggleStatus(show: true)
                navBar.updateStatusImage(_image: statusImage)
            } else if let title = title {
                navBar.toggleStatus(show: true)
                navBar.updateStatusMessage(_message : title) //unhides lable within call
            } else {
                navBar.toggleStatus(show: false)
            }
            
            if let subtitle = subtitle {
                navBar.toggleSubtitle(show: true)
                navBar.setSubtitle(text: subtitle)
            } else {
                navBar.toggleSubtitle(show: false)
            }
        }
    }
    
    public func toggleLogo(mode : LogoModes) {
        if let navBar = self.navigationBar as? PulseNavBar {
            navBar.updateLogo(mode : mode)
        }
    }
    
    public func toggleScopeBar(show : Bool) {
        if let navBar = self.navigationBar as? PulseNavBar {
            navBar.toggleScopeBar(show : show)
        }
    }
    
    public func updateScopeBar(titles : [String], icons : [UIImage]?, selected: Int) {
        if let navBar = self.navigationBar as? PulseNavBar {
            navBar.updateScopeBarTitles(titles : titles, icons : icons, selected: selected)
        }
    }
    
    public func toggleSearch(show : Bool) {
        if let navBar = self.navigationBar as? PulseNavBar {
            navBar.toggleSearch(show : show)
        }
    }
    
    
    fileprivate func updateStatusImage(image : UIImage?) {
        if let navBar = self.navigationBar as? PulseNavBar {
            navBar.toggleStatus(show: false) //hides both status label and image if visible
            navBar.updateStatusImage(_image: image)
        }
    }
    
    fileprivate func updateTitle(title : String?) {
        if let navBar = self.navigationBar as? PulseNavBar {
            navBar.toggleStatus(show: false) //hides both status label and image if visible
            navBar.updateStatusMessage(_message : title) //unhides lable within call
        } else {
            self.title = title
        }
    }
    
    fileprivate func updateSubtitle(title : String?) {
        if let navBar = self.navigationBar as? PulseNavBar {
            if let subtitle = title {
                navBar.toggleSubtitle(show: true)
                navBar.setSubtitle(text: subtitle)
            } else {
                navBar.toggleSubtitle(show: false)
            }
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
        if let navBar = self.navigationBar as? PulseNavBar {
            return navBar.getScopeBar()
        } else {
            return nil
        }
    }

    fileprivate func toggleStatus(show : Bool) {
        if let navBar = self.navigationBar as? PulseNavBar {
            navBar.toggleStatus(show: show)
        }
    }

    override public func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
        if let navBar = self.navigationBar as? PulseNavBar {
            navBar.toggleStatus(show: false)
        }
    }
}
