//
//  CreateAccountVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/8/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import FirebaseAuth

class LoginCreateAccountVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var logoView: UIView!
    @IBOutlet weak var userPassword: UITextField!
    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var _emailErrorLabel: UILabel!
    @IBOutlet weak var _passwordErrorLabel: UILabel!
    @IBOutlet weak var signupButton: UIButton!
    weak var returnToParentDelegate : ParentDelegate!
    
    private var _headerView : UIView!
    private var _loginHeader : LoginHeaderView?

    private var emailValidated = false {
        didSet {
            if emailValidated && passwordValidated {
                signupButton.setEnabled()
            } else {
                signupButton.setDisabled()
            }
        }
    }
    
    private var passwordValidated = false {
        didSet {
            if emailValidated && passwordValidated {
                signupButton.setEnabled()
            } else {
                signupButton.setDisabled()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        setDarkBackground()

        userEmail.delegate = self
        userPassword.delegate = self
        
        userEmail.tag = 100
        userPassword.tag = 200
        userEmail.layer.addSublayer(GlobalFunctions.addBorders(self.userEmail, _color: UIColor.whiteColor()))
        userPassword.layer.addSublayer(GlobalFunctions.addBorders(self.userPassword, _color: UIColor.whiteColor()))
        userPassword.addTarget(self, action: #selector(self.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        
        userEmail.attributedPlaceholder = NSAttributedString(string: userEmail.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])
        userPassword.attributedPlaceholder = NSAttributedString(string: userPassword.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])

        signupButton.layer.cornerRadius = buttonCornerRadius.radius(.regular)
        signupButton.setDisabled()
        

    }
    
    override func viewDidAppear(animated : Bool) {
        super.viewDidAppear(true)
        addHeader()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func addHeader() {
        _headerView = UIView()
        view.addSubview(_headerView)

        _headerView.translatesAutoresizingMaskIntoConstraints = false
        _headerView.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: Spacing.xs.rawValue).active = true
        _headerView.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        _headerView.heightAnchor.constraintEqualToAnchor(view.heightAnchor, multiplier: 1/13).active = true
        _headerView.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 1 - (Spacing.m.rawValue/view.frame.width)).active = true
        
        _headerView.layoutIfNeeded()
        
        _loginHeader = LoginHeaderView(frame: _headerView.frame)
        if let _loginHeader = _loginHeader {
            _loginHeader.setAppTitleLabel("PULSE")
            _loginHeader.setScreenTitleLabel("CREATE ACCOUNT")
            _loginHeader.addGoBack()
            _loginHeader._goBack.addTarget(self, action: #selector(goBack), forControlEvents: UIControlEvents.TouchUpInside)
            _headerView.addSubview(_loginHeader)
        }
    }
    
    @IBAction func createEmailAccount(sender: UIButton) {
        sender.setDisabled()
        let _loading = sender.addLoadingIndicator()
        
        Database.createEmailUser(self.userEmail.text!, password: self.userPassword.text!, completion: { (user, error) in
            if let _error = error {
                sender.setEnabled()
                sender.removeLoadingIndicator(_loading)
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false

                switch _error.code {
                case FIRAuthErrorCode.ErrorCodeInvalidEmail.rawValue: self._emailErrorLabel.text = error!.localizedDescription
                case FIRAuthErrorCode.ErrorCodeEmailAlreadyInUse.rawValue: self._emailErrorLabel.text = "you already have an account! try signing in"
                case FIRAuthErrorCode.ErrorCodeWeakPassword.rawValue: self._passwordErrorLabel.text = error!.localizedDescription
                default: self._emailErrorLabel.text = "error creating your account. please try again!"
                }
            } else {
                sender.setEnabled()
                sender.removeLoadingIndicator(_loading)

                if let AddNameVC = self.storyboard?.instantiateViewControllerWithIdentifier("LoginAddNameVC") as? LoginAddNameVC {
                    GlobalFunctions.addNewVC(AddNameVC, parentVC: self)
                }
            }
        })
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        _passwordErrorLabel.text = ""
        _emailErrorLabel.text = ""
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField.tag == userEmail.tag {
            GlobalFunctions.validateEmail(userEmail.text, completion: {(verified, error) in
                if !verified {
                    self.emailValidated = false
                    dispatch_async(dispatch_get_main_queue()) {
                        self._emailErrorLabel.text = error!.localizedDescription
                    }
                } else {
                    self.emailValidated = true
                    self._emailErrorLabel.text = ""
                }
            })
        }
    }
    
    func textFieldDidChange(textField: UITextField) {
        if textField.tag == userPassword.tag {
            GlobalFunctions.validatePassword(userPassword.text, completion: {(verified, error) in
                if !verified {
                    self.passwordValidated = false
                    dispatch_async(dispatch_get_main_queue()) {
                        self._passwordErrorLabel.text = error!.localizedDescription
                    }
                }  else {
                    self.passwordValidated = true
                    self._passwordErrorLabel.text = ""
                }
            })
        }
    }
    
    func goBack(sender: UIButton) {
        if returnToParentDelegate != nil {
            returnToParentDelegate.returnToParent(self)
        }
    }
}
