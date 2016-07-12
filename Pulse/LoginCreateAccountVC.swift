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
    
    private var emailValidated = false {
        didSet {
            if emailValidated && passwordValidated {
                self.signupButton.enabled = true
                self.signupButton.alpha = 1.0
            } else {
                self.signupButton.enabled = false
                self.signupButton.alpha = 0.5
            }
        }
    }
    
    private var passwordValidated = false {
        didSet {
            if emailValidated && passwordValidated {
                self.signupButton.enabled = true
                self.signupButton.alpha = 1.0
            } else {
                self.signupButton.enabled = false
                self.signupButton.alpha = 0.5
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        
        self.userEmail.delegate = self
        self.userPassword.delegate = self
        
        self.userEmail.tag = 100
        self.userPassword.tag = 200
        self.userEmail.layer.addSublayer(GlobalFunctions.addBorders(self.userEmail))
        self.userPassword.layer.addSublayer(GlobalFunctions.addBorders(self.userPassword))
        self.userPassword.addTarget(self, action: #selector(self.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)

        self.signupButton.layer.cornerRadius = buttonCornerRadius
        self.signupButton.enabled = false
        self.signupButton.alpha = 0.5
        
        //add icon
        let pulseIcon = Icon(frame: CGRectMake(0,0,self.logoView.frame.width, self.logoView.frame.height))
        pulseIcon.drawIconBackground(iconBackgroundColor)
        pulseIcon.drawIcon(iconColor, iconThickness: 3)
        logoView.addSubview(pulseIcon)
    }
    
    override func viewDidAppear(animated : Bool) {
        super.viewDidAppear(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func createEmailAccount(sender: UIButton) {
        Database.createEmailUser(self.userEmail.text!, password: self.userPassword.text!, completion: { (user, error) in
            if let _error = error {
                switch _error.code {
                case FIRAuthErrorCode.ErrorCodeInvalidEmail.rawValue: self._emailErrorLabel.text = error!.localizedDescription
                case FIRAuthErrorCode.ErrorCodeEmailAlreadyInUse.rawValue: self._emailErrorLabel.text = "you already have an account! try signing in instead"
                case FIRAuthErrorCode.ErrorCodeWeakPassword.rawValue: self._passwordErrorLabel.text = error!.localizedDescription
                default: self._emailErrorLabel.text = "error creating your account. please try again!"
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
            } else {
                self.performSegueWithIdentifier("addNameSegue", sender: self)
            }
        })
    }
    
    ///Validate email
    private func validateEmail(enteredEmail:String?, completion: (verified: Bool, error: NSError?) -> Void) {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        
        if emailPredicate.evaluateWithObject(enteredEmail) {
            completion(verified: true, error: nil)
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "please enter a valid email" ]
            completion(verified: false, error: NSError.init(domain: "Invalid", code: 200, userInfo: userInfo))
        }
    }
    
    ///Validate password returns true if validated, error otherwise
    private func validatePassword(enteredPassword:String?, completion: (verified: Bool, error: NSError?) -> Void) {
        let passwordFormat = "^(?=.*?[a-z]).{8,}$"
        let passwordPredicate = NSPredicate(format:"SELF MATCHES %@", passwordFormat)
        
        if passwordPredicate.evaluateWithObject(enteredPassword) {
            completion(verified: true, error: nil)
            return
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "password must be 8 characters in length" ]
            completion(verified: false, error: NSError.init(domain: "Invalid", code: 200, userInfo: userInfo))
            return
        }
//        let passwordFormat = "^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{8,}$"
//        let passwordPredicate = NSPredicate(format:"SELF MATCHES %@", passwordFormat)
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        _passwordErrorLabel.text = ""
        _emailErrorLabel.text = ""
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField.tag == userEmail.tag {
            validateEmail(userEmail.text, completion: {(verified, error) in
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
            validatePassword(self.userPassword.text, completion: {(verified, error) in
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
