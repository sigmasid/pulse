//
//  AccountLoginManagerVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/25/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AccountLoginManagerVC: PulseNavVC {
    
    fileprivate lazy var loginVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginVC") as? LoginVC
    fileprivate lazy var accountVC = UserProfileVC()
    let _storyboard = UIStoryboard(name: "Main", bundle: nil)
    fileprivate var _currentLoadedView : currentLoadedView?
    
    enum currentLoadedView {
        case login
        case account
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
        isNavigationBarHidden = false
        NotificationCenter.default.addObserver(self, selector: #selector(updateLoginOrAccount), name: NSNotification.Name(rawValue: "UserUpdated"), object: nil)
    }
    
    override init(nibName: String?, bundle: Bundle?) {
        super.init(nibName: nibName, bundle: bundle)
    }
    
    //This is the first notification fired once the user is updated from auth
    func updateLoginOrAccount() {
        if User.isLoggedIn(), _currentLoadedView != .account, loginVC?._currentLoadedView != .createAccount {
            accountVC.selectedUser = User.currentUser!

            if !viewControllers.contains(accountVC) {
                pushViewController(accountVC, animated: false)
            } else {
                popToViewController(accountVC, animated: false)
            }
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AccountPageLoaded"), object: self)
            NotificationCenter.default.addObserver(self, selector: #selector(logoutSuccess), name: NSNotification.Name(rawValue: "LogoutSuccess"), object: nil)
            _currentLoadedView = .account
        } else if !User.isLoggedIn() {
            if !viewControllers.contains(loginVC!) {
                pushViewController(loginVC!, animated: false)
            } else {
                popToViewController(loginVC!, animated: false)
            }
            NotificationCenter.default.addObserver(self, selector: #selector(loginSuccess), name: NSNotification.Name(rawValue: "LoginSuccess"), object: nil)
            _currentLoadedView = .login
        }
    }
    
    func loginSuccess() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "LoginSucess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(logoutSuccess), name: NSNotification.Name(rawValue: "LogoutSuccess"), object: nil)
        
        if User.isLoggedIn(), _currentLoadedView == .login {
            
            accountVC.selectedUser = User.currentUser!
            
            if !self.viewControllers.contains(accountVC) {
                popToRootViewController(animated: false)
                pushViewController(accountVC, animated: true)
            } else {
                popToViewController(accountVC, animated: false)
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AccountPageLoaded"), object: self)

        }  else if User.isLoggedIn(), _currentLoadedView == .account {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AccountPageLoaded"), object: self)
        }
    }
    
    func logoutSuccess() {
        if _currentLoadedView == .account {
            if !self.viewControllers.contains(loginVC!) {
                popToRootViewController(animated: false)
                pushViewController(loginVC!, animated: true)
            } else {
                popToViewController(loginVC!, animated: false)
            }
            _currentLoadedView = .login
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "LogoutSuccess"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(loginSuccess), name: NSNotification.Name(rawValue: "LoginSuccess"), object: nil)
        }
    }
}
