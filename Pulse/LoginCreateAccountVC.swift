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
    
    fileprivate var isLoaded = false
    
    fileprivate var emailValidated = false {
        didSet {
            if emailValidated && passwordValidated {
                signupButton.setEnabled()
            } else {
                signupButton.setDisabled()
            }
        }
    }
    
    fileprivate var passwordValidated = false {
        didSet {
            if emailValidated && passwordValidated {
                signupButton.setEnabled()
            } else {
                signupButton.setDisabled()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeader()
    }
    
    override func viewDidLayoutSubviews() {
        if !isLoaded {
            hideKeyboardWhenTappedAround()
            
            userEmail.delegate = self
            userPassword.delegate = self
            
            userEmail.tag = 100
            userPassword.tag = 200
            
            userEmail.layer.addSublayer(GlobalFunctions.addBorders(userEmail))
            userPassword.layer.addSublayer(GlobalFunctions.addBorders(userPassword))
            userEmail.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0)
            userPassword.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0)
            
            userEmail.layer.addSublayer(GlobalFunctions.addBorders(self.userEmail, _color: UIColor.black, thickness: IconThickness.thin.rawValue))
            userPassword.layer.addSublayer(GlobalFunctions.addBorders(self.userPassword, _color: UIColor.black, thickness: IconThickness.thin.rawValue))
            userPassword.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
            
            userEmail.attributedPlaceholder = NSAttributedString(string: userEmail.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
            userPassword.attributedPlaceholder = NSAttributedString(string: userPassword.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
            
            signupButton.layer.cornerRadius = buttonCornerRadius.radius(.regular)
            signupButton.setDisabled()
            
            isLoaded = true
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func updateHeader() {
        let backButton = NavVC.getButton(type: .back)
        backButton.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)

        if let nav = navigationController as? NavVC {
            nav.setNav(title: "Create Account", subtitle: nil, statusImage: nil)
        } else {
            title = "Create Account"
        }
    }
    
    @IBAction func createEmailAccount(_ sender: UIButton) {
        sender.setDisabled()
        let _loading = sender.addLoadingIndicator()
        
        Database.createEmailUser(self.userEmail.text!, password: self.userPassword.text!, completion: { (user, error) in
            if let _error = error {
                sender.setEnabled()
                sender.removeLoadingIndicator(_loading)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false

                switch _error.code {
                case FIRAuthErrorCode.errorCodeInvalidEmail.rawValue: self._emailErrorLabel.text = error!.localizedDescription
                case FIRAuthErrorCode.errorCodeEmailAlreadyInUse.rawValue: self._emailErrorLabel.text = "you already have an account! try signing in"
                case FIRAuthErrorCode.errorCodeWeakPassword.rawValue: self._passwordErrorLabel.text = error!.localizedDescription
                default: self._emailErrorLabel.text = "error creating your account. please try again!"
                }
            } else {
                sender.setEnabled()
                sender.removeLoadingIndicator(_loading)

                if let addNameVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginAddNameVC") as? LoginAddNameVC {
                    self.navigationController?.pushViewController(addNameVC, animated: true)
                }
            }
        })
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        _passwordErrorLabel.text = ""
        _emailErrorLabel.text = ""
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == userEmail.tag {
            GlobalFunctions.validateEmail(userEmail.text, completion: {(verified, error) in
                if !verified {
                    self.emailValidated = false
                    DispatchQueue.main.async {
                        self._emailErrorLabel.text = error!.localizedDescription
                    }
                } else {
                    self.emailValidated = true
                    self._emailErrorLabel.text = ""
                }
            })
        }
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        if textField.tag == userPassword.tag {
            GlobalFunctions.validatePassword(userPassword.text, completion: {(verified, error) in
                if !verified {
                    self.passwordValidated = false
                    DispatchQueue.main.async {
                        self._passwordErrorLabel.text = error!.localizedDescription
                    }
                }  else {
                    self.passwordValidated = true
                    self._passwordErrorLabel.text = ""
                }
            })
        }
    }
    
    func goBack() {
        let _ = self.navigationController?.popViewController(animated: true)
    }
}
