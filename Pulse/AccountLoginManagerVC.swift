//
//  AccountLoginManagerVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/25/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AccountLoginManagerVC: PulseNavVC {
    public weak var tabDelegate : MasterTabDelegate!

    public var showInviteAlert : Bool = false {
        didSet {
            if showInviteAlert, currentLoadedView == .login {
                loginVC!.showInviteAlert = true
            }
        }
    }
    
    fileprivate lazy var loginVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginVC") as? LoginVC
    fileprivate lazy var accountVC = UserProfileVC()
    fileprivate var currentLoadedView : CurrentLoadedView?
    fileprivate var initialUserUpdateComplete = false
    
    enum CurrentLoadedView {
        case login
        case account
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
        isNavigationBarHidden = false
        NotificationCenter.default.addObserver(self, selector: #selector(updateLoginOrAccount), name: NSNotification.Name(rawValue: "UserSummaryUpdated"), object: nil)
        if !initialUserUpdateComplete {
            updateLoginOrAccount()
        }
    }
    
    override init(nibName: String?, bundle: Bundle?) {
        super.init(nibName: nibName, bundle: bundle)
    }
    
    //This is the first notification fired once the user is updated from auth
    func updateLoginOrAccount() {
        if PulseUser.isLoggedIn(), currentLoadedView != .account, loginVC?._currentLoadedView != .createAccount {
            accountVC.selectedUser = PulseUser.currentUser

            pushViewController(accountVC, animated: false)
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AccountPageLoaded"), object: self)
            NotificationCenter.default.addObserver(self, selector: #selector(logoutSuccess), name: NSNotification.Name(rawValue: "LogoutSuccess"), object: nil)
            
            currentLoadedView = .account
            
        } else if !PulseUser.isLoggedIn() {
            pushViewController(loginVC!, animated: false)

            NotificationCenter.default.addObserver(self, selector: #selector(loginSuccess), name: NSNotification.Name(rawValue: "LoginSuccess"), object: nil)
            
            currentLoadedView = .login
        }
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UserSummaryUpdated"), object: nil)
        initialUserUpdateComplete = true
    }
    
    func loginSuccess() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "LoginSucess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(logoutSuccess), name: NSNotification.Name(rawValue: "LogoutSuccess"), object: nil)
        
        if PulseUser.isLoggedIn(), currentLoadedView == .login {
            
            accountVC.selectedUser = PulseUser.currentUser
            
            if !self.viewControllers.contains(accountVC) {
                setViewControllers([accountVC], animated: false)
            } else {
                popToViewController(accountVC, animated: false)
            }
            
            currentLoadedView = .account
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AccountPageLoaded"), object: self)

        }  else if PulseUser.isLoggedIn(), currentLoadedView == .account {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AccountPageLoaded"), object: self)
        }
        
        if tabDelegate != nil, showInviteAlert {
            tabDelegate.userUpdated()
            showInviteAlert = false
        }
    }
    
    func logoutSuccess() {
        if currentLoadedView == .account {
            if !self.viewControllers.contains(loginVC!) {
                pushViewController(loginVC!, animated: true)
            } else {
                popToViewController(loginVC!, animated: false)
            }
            currentLoadedView = .login
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "LogoutSuccess"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(loginSuccess), name: NSNotification.Name(rawValue: "LoginSuccess"), object: nil)
        }
    }
}
