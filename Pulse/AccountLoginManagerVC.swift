//
//  AccountLoginManagerVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/25/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AccountLoginManagerVC: UIViewController {
    
    private var loginVC : LoginVC?
    private var accountVC : AccountPageVC?
    static private var _loaded = false
    let _storyboard = UIStoryboard(name: "Main", bundle: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
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
            AccountLoginManagerVC._loaded = true
            NSNotificationCenter.defaultCenter().postNotificationName("AccountPageLoaded", object: self)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(logoutSuccess), name: "LogoutSuccess", object: nil)
        } else {
            loginVC = _storyboard.instantiateViewControllerWithIdentifier("LoginVC") as? LoginVC
            GlobalFunctions.addNewVC(loginVC!, parentVC: self)
            AccountLoginManagerVC._loaded = true

            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(loginSuccess), name: "LoginSuccess", object: nil)

        }
    }
    
    func updateLoginOrAccount() {
        if User.isLoggedIn() {
            accountVC = _storyboard.instantiateViewControllerWithIdentifier("AccountPageVC") as? AccountPageVC
            GlobalFunctions.addNewVC(accountVC!, parentVC: self)
            NSNotificationCenter.defaultCenter().postNotificationName("AccountPageLoaded", object: self)
        } else {
            loginVC = _storyboard.instantiateViewControllerWithIdentifier("LoginVC") as? LoginVC
            GlobalFunctions.addNewVC(loginVC!, parentVC: self)
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
//            GlobalFunctions.addNewVC(accountVC!, parentVC: self)
            NSNotificationCenter.defaultCenter().postNotificationName("AccountPageLoaded", object: self)
        }
    }
    
    func logoutSuccess() {
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
