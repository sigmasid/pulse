//
//  UpdateProfileVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/28/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class UpdateProfileVC: UIViewController {
    
    var _currentSetting : Setting!
    var _loaded = false
    var _headerView = UIView()
    var _loginHeaderView : LoginHeaderView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        
        if !_loaded {
            setDarkBackground()
//            self.view.addHeader(_headerView, appTitle: "PULSE", screenTitle: "UPDATE \(_currentSetting.display!.uppercaseString)")
            _loaded = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
