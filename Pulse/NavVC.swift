//
//  navVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/13/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
enum ButtonType { case back, add, remove, close, settings, login, check, search, message, menu, save, blank }
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

    static func getButton(type : ButtonType) -> UIButton {
        let buttonFrame = CGRect(x: 0, y: 0, width: IconSizes.small.rawValue, height: IconSizes.small.rawValue)
        let button = UIButton(frame: buttonFrame)
        button.backgroundColor = pulseBlue
        button.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        button.makeRound()
        
        switch type {
        case .search:
            let tintedTimage = UIImage(named: "search")?.withRenderingMode(.alwaysTemplate)
            button.setImage(tintedTimage, for: UIControlState())
            button.tintColor = .black
            return button
            
        case .back:
            let tintedTimage = UIImage(named: "back")?.withRenderingMode(.alwaysTemplate)
            button.setImage(tintedTimage, for: UIControlState())
            button.tintColor = .black

            return button
            
        case .add:
            let tintedTimage = UIImage(named: "add")?.withRenderingMode(.alwaysTemplate)
            button.setImage(tintedTimage, for: UIControlState())
            button.tintColor = UIColor.black

            return button

        case.remove:
            let tintedTimage = UIImage(named: "remove")?.withRenderingMode(.alwaysTemplate)
            button.setImage(tintedTimage, for: UIControlState())
            button.tintColor = UIColor.black

            return button
            
        case .close:
            let tintedTimage = UIImage(named: "close")?.withRenderingMode(.alwaysTemplate)
            button.setImage(tintedTimage, for: UIControlState())
            button.tintColor = UIColor.black

            return button
            
        case .settings:
            let tintedTimage = UIImage(named: "settings")?.withRenderingMode(.alwaysTemplate)
            button.imageEdgeInsets = UIEdgeInsetsMake(7, 7, 7, 7)
            button.setImage(tintedTimage, for: UIControlState())
            button.tintColor = UIColor.black
            
            return button
            
        case .login:
            let tintedTimage = UIImage(named: "login")?.withRenderingMode(.alwaysTemplate)
            button.setImage(tintedTimage, for: UIControlState())
            button.tintColor = UIColor.black

            return button
            
        case .check:
            let tintedTimage = UIImage(named: "check")?.withRenderingMode(.alwaysTemplate)
            button.setImage(tintedTimage, for: UIControlState())
            button.tintColor = UIColor.black
            button.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)

            return button
            
        case .message:
            let tintedTimage = UIImage(named: "message")?.withRenderingMode(.alwaysTemplate)
            button.setImage(tintedTimage, for: UIControlState())
            button.tintColor = UIColor.black
            
            return button
            
        case .menu:
            let tintedTimage = UIImage(named: "table-list")?.withRenderingMode(.alwaysTemplate)
            button.setImage(tintedTimage, for: UIControlState())
            button.tintColor = UIColor.black
            
            return button
            
        case .save:
            let tintedTimage = UIImage(named: "download-to-disk")?.withRenderingMode(.alwaysTemplate)
            button.setImage(tintedTimage, for: UIControlState())
            button.tintColor = UIColor.black
            
            return button
            
        case . blank:
            return button
        }
    

    }

    override public func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
        if let navBar = self.navigationBar as? PulseNavBar {
            navBar.toggleStatus(show: false)
        }
    }
}
