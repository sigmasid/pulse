//
//  LoginAddNameVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/8/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import FirebaseAuth

class LoginAddNameVC: UIViewController {

    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    
    @IBOutlet weak var _firstNameError: UILabel!
    @IBOutlet weak var _lastNameError: UILabel!
    
    weak var loginVCDelegate : childVCDelegate?
    private var _headerView : UIView!
    private var _loginHeader : LoginHeaderView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated : Bool) {
        super.viewDidAppear(true)
        hideKeyboardWhenTappedAround()
        setDarkBackground()

        firstName.layer.addSublayer(GlobalFunctions.addBorders(self.firstName, _color: UIColor.whiteColor()))
        lastName.layer.addSublayer(GlobalFunctions.addBorders(self.lastName, _color: UIColor.whiteColor()))
        
        firstName.attributedPlaceholder = NSAttributedString(string: firstName.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])
        lastName.attributedPlaceholder = NSAttributedString(string: lastName.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])
        
        doneButton.layer.cornerRadius = buttonCornerRadius
        doneButton.setEnabled()
        addHeader()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    func addHeader() {
        _headerView = UIView()
        view.addSubview(_headerView)
        
        _headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraint(NSLayoutConstraint(item: _headerView, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .TopMargin , multiplier: 2, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: _headerView, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX , multiplier: 1, constant: 0))
        _headerView.heightAnchor.constraintEqualToAnchor(view.heightAnchor, multiplier: 1/13).active = true
        _headerView.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 1 - (Spacing.m.rawValue/view.frame.width)).active = true
        _headerView.layoutIfNeeded()
        
        _loginHeader = LoginHeaderView(frame: _headerView.frame)
        if let _loginHeader = _loginHeader {
            _loginHeader.setAppTitleLabel("PULSE")
            _loginHeader.setScreenTitleLabel("ADD NAME")
            _loginHeader.updateStatusMessage("could we get a name with that?")
            _headerView.addSubview(_loginHeader)
        }
    }

    @IBAction func addNameTouchDown(sender: UIButton) {
        
    }
    
    @IBAction func addName(sender: UIButton) {
        dismissKeyboard()
        sender.setDisabled()
        sender.addLoadingIndicator()
        
        GlobalFunctions.validateName(firstName.text, completion: {(verified, error) in
            if !verified {
                self._firstNameError.text = error!.localizedDescription
                sender.setEnabled()
            } else {
                GlobalFunctions.validateName(self.lastName.text, completion: {(verified, error) in
                    if !verified {
                        self._lastNameError.text = error!.localizedDescription
                        sender.setEnabled()
                    } else {
                        let fullName = self.firstName.text! + " " + self.lastName.text!
                        Database.updateUserData(UserProfileUpdateType.displayName, value: fullName, completion: { (success, error) in
                            if !success {
                                self._firstNameError.text = error!.localizedDescription
                                sender.setEnabled()
                            }
                            else {
                                NSNotificationCenter.defaultCenter().postNotificationName("LoginSuccess", object: self)
                                sender.setEnabled()
                                self._loggedInSuccess()
                            }
                        })
                    }
                })
            }
        })
    }
    
    func _loggedInSuccess() {
        if loginVCDelegate != nil {
            self.loginVCDelegate!.loginSuccess(self)
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        _firstNameError.text = ""
        _lastNameError.text = ""
    }
}
