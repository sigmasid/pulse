//
//  CreateAccountVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/8/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase

class LoginCreateAccountVC: PulseVC, UITextFieldDelegate {

    @IBOutlet weak var logoView: UIView!
    @IBOutlet weak var userPassword: UITextField!
    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var _emailErrorLabel: UILabel!
    @IBOutlet weak var _passwordErrorLabel: UILabel!
    @IBOutlet weak var signupButton: UIButton!
        
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
            
            userPassword.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
            
            userEmail.placeholder = userEmail.placeholder
            userPassword.placeholder = userPassword.placeholder
            
            signupButton.makeRound()
            signupButton.setDisabled()
            
            isLoaded = true
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func updateHeader() {
        addBackButton()
        headerNav?.setNav(title: "Create Account")
    }
    
    @IBAction func createEmailAccount(_ sender: UIButton) {
        sender.setDisabled()
        let _loading = sender.addLoadingIndicator()
        
        PulseDatabase.createEmailUser(self.userEmail.text!, password: self.userPassword.text!, completion: {[weak self] (user, error) in
            guard let `self` = self else { return }
            if let error = error, let errorCode = AuthErrorCode(rawValue: error.code) {
                sender.setEnabled()
                sender.removeLoadingIndicator(_loading)

                switch errorCode {
                case AuthErrorCode.invalidEmail: self._emailErrorLabel.text = error.localizedDescription
                case AuthErrorCode.emailAlreadyInUse: self._emailErrorLabel.text = "you already have an account! try signing in"
                case AuthErrorCode.weakPassword: self._passwordErrorLabel.text = error.localizedDescription
                default: self._emailErrorLabel.text = "error creating your account. please try again!"
                }
            } else {
                sender.setEnabled()
                sender.removeLoadingIndicator(_loading)
                Analytics.logEvent(AnalyticsEventSignUp, parameters: [AnalyticsParameterSignUpMethod: "email" as NSObject])
                
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
        if textField == userEmail {
            GlobalFunctions.validateEmail(userEmail.text, completion: {[weak self] (verified, error) in
                guard let `self` = self else { return }
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
        if textField == userPassword {
            GlobalFunctions.validatePassword(userPassword.text, completion: {[weak self](verified, error) in
                guard let `self` = self else { return }
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
}
