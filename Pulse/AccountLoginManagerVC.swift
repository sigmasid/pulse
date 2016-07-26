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
    let _storyboard = UIStoryboard(name: "Main", bundle: nil)

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        setupInitialView()
    }
    
    func setupInitialView() {
        if User.isLoggedIn() {
            accountVC = _storyboard.instantiateViewControllerWithIdentifier("AccountPageVC") as? AccountPageVC
            GlobalFunctions.addNewVC(accountVC!, parentVC: self)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateLoginOrAccount), name: "UserUpdated", object: nil)
            NSNotificationCenter.defaultCenter().postNotificationName("AccountPageLoaded", object: self)
        } else {
            loginVC = _storyboard.instantiateViewControllerWithIdentifier("LoginVC") as? LoginVC
            GlobalFunctions.addNewVC(loginVC!, parentVC: self)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateLoginOrAccount), name: "UserUpdated", object: nil)
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
}
