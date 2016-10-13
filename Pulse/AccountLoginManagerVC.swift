//
//  AccountLoginManagerVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/25/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AccountLoginManagerVC: UIViewController {
    
    fileprivate var loginVC : LoginVC?
    fileprivate var accountVC : AccountPageVC?
    let _storyboard = UIStoryboard(name: "Main", bundle: nil)
    fileprivate var _currentLoadedView : currentLoadedView?
    
    enum currentLoadedView {
        case login
        case account
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateLoginOrAccount), name: NSNotification.Name(rawValue: "UserUpdated"), object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func updateLoginOrAccount() {
        if User.isLoggedIn() && accountVC != nil && _currentLoadedView != .account {
            if loginVC?._currentLoadedView != .createAccount {
                GlobalFunctions.addNewVC(accountVC!, parentVC: self)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "AccountPageLoaded"), object: self)
                NotificationCenter.default.addObserver(self, selector: #selector(logoutSuccess), name: NSNotification.Name(rawValue: "LogoutSuccess"), object: nil)
            }
            _currentLoadedView = .account
        } else if User.isLoggedIn() && _currentLoadedView != .account {
            if loginVC?._currentLoadedView != .createAccount {
                accountVC = AccountPageVC()
                GlobalFunctions.addNewVC(accountVC!, parentVC: self)
                NotificationCenter.default.addObserver(self, selector: #selector(logoutSuccess), name: NSNotification.Name(rawValue: "LogoutSuccess"), object: nil)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "AccountPageLoaded"), object: self)
                _currentLoadedView = .account
            }
        } else if !User.isLoggedIn() {
            print("went into not logged in VC")
            loginVC = _storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginVC
            GlobalFunctions.addNewVC(loginVC!, parentVC: self)
            
            NotificationCenter.default.addObserver(self, selector: #selector(loginSuccess), name: NSNotification.Name(rawValue: "LoginSuccess"), object: nil)
            _currentLoadedView = .login
        }
    }
    
    func loginSuccess() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "LoginSucess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(logoutSuccess), name: NSNotification.Name(rawValue: "LogoutSuccess"), object: nil)
        
        if User.isLoggedIn() && accountVC != nil && _currentLoadedView == .login {
            GlobalFunctions.addNewVC(accountVC!, parentVC: self)
            GlobalFunctions.dismissVC(loginVC!)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AccountPageLoaded"), object: self)
        }  else if User.isLoggedIn() && _currentLoadedView == .account {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AccountPageLoaded"), object: self)
        } else if User.isLoggedIn() && _currentLoadedView == .login {
            accountVC = AccountPageVC()
            GlobalFunctions.cycleBetweenVC(loginVC!, newVC: accountVC!, parentVC: self)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AccountPageLoaded"), object: self)
        }
    }
    
    func logoutSuccess() {
        if _currentLoadedView == .account {
            if loginVC != nil  && accountVC != nil {
                GlobalFunctions.addNewVC(loginVC!, parentVC: self)
                GlobalFunctions.dismissVC(accountVC!)
                _currentLoadedView = .login
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "LogoutSuccess"), object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(loginSuccess), name: NSNotification.Name(rawValue: "LoginSuccess"), object: nil)
            } else if accountVC != nil {
                loginVC = _storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginVC
                GlobalFunctions.addNewVC(loginVC!, parentVC: self)
                GlobalFunctions.dismissVC(accountVC!)
                _currentLoadedView = .login
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "LogoutSuccess"), object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(loginSuccess), name: NSNotification.Name(rawValue: "LoginSuccess"), object: nil)
            }
        }
    }
}
