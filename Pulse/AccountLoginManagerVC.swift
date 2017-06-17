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
    fileprivate var _currentLoadedView : currentLoadedView?
    fileprivate var initialUserUpdateComplete = false
    
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
        if !initialUserUpdateComplete {
            updateLoginOrAccount()
        }
    }
    
    override init(nibName: String?, bundle: Bundle?) {
        super.init(nibName: nibName, bundle: bundle)
    }
    
    //This is the first notification fired once the user is updated from auth
    func updateLoginOrAccount() {
        if PulseUser.isLoggedIn(), _currentLoadedView != .account, loginVC?._currentLoadedView != .createAccount {
            accountVC.selectedUser = PulseUser.currentUser

            pushViewController(accountVC, animated: false)
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AccountPageLoaded"), object: self)
            NotificationCenter.default.addObserver(self, selector: #selector(logoutSuccess), name: NSNotification.Name(rawValue: "LogoutSuccess"), object: nil)
            _currentLoadedView = .account
            
        } else if !PulseUser.isLoggedIn() {
            pushViewController(loginVC!, animated: false)

            NotificationCenter.default.addObserver(self, selector: #selector(loginSuccess), name: NSNotification.Name(rawValue: "LoginSuccess"), object: nil)
            _currentLoadedView = .login
        }
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UserUpdated"), object: nil)
        initialUserUpdateComplete = true
    }
    
    func loginSuccess() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "LoginSucess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(logoutSuccess), name: NSNotification.Name(rawValue: "LogoutSuccess"), object: nil)
        
        if PulseUser.isLoggedIn(), _currentLoadedView == .login {
            
            accountVC.selectedUser = PulseUser.currentUser
            
            if !self.viewControllers.contains(accountVC) {
                setViewControllers([accountVC], animated: false)
            } else {
                popToViewController(accountVC, animated: false)
            }
            
            _currentLoadedView = .account
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AccountPageLoaded"), object: self)

        }  else if PulseUser.isLoggedIn(), _currentLoadedView == .account {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AccountPageLoaded"), object: self)
        }
    }
    
    func logoutSuccess() {
        if _currentLoadedView == .account {
            if !self.viewControllers.contains(loginVC!) {
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
