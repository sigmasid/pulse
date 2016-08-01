//
//  AccountLoginManagerVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/25/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AccountLoginManagerVC: UIViewController {
    
    private weak var loginVC : LoginVC?
    private weak var accountVC : AccountPageVC?
    let _storyboard = UIStoryboard(name: "Main", bundle: nil)
    private var _currentLoadedView : currentLoadedView!
    
    enum currentLoadedView {
        case login
        case account
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateLoginOrAccount), name: "UserUpdated", object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setupInitialView() {
        if User.isLoggedIn() {
            accountVC = _storyboard.instantiateViewControllerWithIdentifier("AccountPageVC") as? AccountPageVC
            GlobalFunctions.addNewVC(accountVC!, parentVC: self)
            
            NSNotificationCenter.defaultCenter().postNotificationName("AccountPageLoaded", object: self)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(logoutSuccess), name: "LogoutSuccess", object: nil)
            
            _currentLoadedView = .account
        } else {
            loginVC = _storyboard.instantiateViewControllerWithIdentifier("LoginVC") as? LoginVC
            GlobalFunctions.addNewVC(loginVC!, parentVC: self)

            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(loginSuccess), name: "LoginSuccess", object: nil)
            _currentLoadedView = .login

        }
    }
    
    func updateLoginOrAccount() {
        if User.isLoggedIn() && accountVC != nil && _currentLoadedView != .account {
            GlobalFunctions.addNewVC(accountVC!, parentVC: self)
            NSNotificationCenter.defaultCenter().postNotificationName("AccountPageLoaded", object: self)
            _currentLoadedView = .account
        } else if User.isLoggedIn() && _currentLoadedView != .account {
            accountVC = _storyboard.instantiateViewControllerWithIdentifier("AccountPageVC") as? AccountPageVC
            GlobalFunctions.addNewVC(accountVC!, parentVC: self)
            NSNotificationCenter.defaultCenter().postNotificationName("AccountPageLoaded", object: self)
            _currentLoadedView = .account

        }
    }
    
    func loginSuccess() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(logoutSuccess), name: "LogoutSuccess", object: nil)

        if User.isLoggedIn() && accountVC != nil && loginVC != nil {
            GlobalFunctions.cycleBetweenVC(loginVC!, newVC: accountVC!, parentVC: self)
            NSNotificationCenter.defaultCenter().postNotificationName("AccountPageLoaded", object: self)
        }  else if User.isLoggedIn() && accountVC != nil{
            NSNotificationCenter.defaultCenter().postNotificationName("AccountPageLoaded", object: self)
        } else if User.isLoggedIn() && loginVC != nil {
            accountVC = _storyboard.instantiateViewControllerWithIdentifier("AccountPageVC") as? AccountPageVC
            GlobalFunctions.cycleBetweenVC(loginVC!, newVC: accountVC!, parentVC: self)
            NSNotificationCenter.defaultCenter().postNotificationName("AccountPageLoaded", object: self)
        }
    }
    
    func logoutSuccess() {
        print("received logout notification")
        if loginVC != nil  && accountVC != nil {
            GlobalFunctions.cycleBetweenVC(accountVC!, newVC: loginVC!, parentVC: self)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(loginSuccess), name: "LoginSuccess", object: nil)
        } else if accountVC != nil {
            GlobalFunctions.dismissVC(accountVC!)
            loginVC = _storyboard.instantiateViewControllerWithIdentifier("LoginVC") as? LoginVC
            GlobalFunctions.addNewVC(loginVC!, parentVC: self)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(loginSuccess), name: "LoginSuccess", object: nil)
        }
    }
}
