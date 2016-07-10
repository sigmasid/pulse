//
//  CreateAccountVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/8/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class LoginCreateAccountVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var logoView: UIView!
    @IBOutlet weak var userPassword: UITextField!
    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var _emailErrorLabel: UILabel!
    @IBOutlet weak var _passwordErrorLabel: UILabel!
    @IBOutlet weak var signupButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        
        self.userEmail.delegate = self
        self.userPassword.delegate = self
    }
    
    override func viewDidAppear(animated : Bool) {
        super.viewDidAppear(true)
        
        let pulseIcon = Icon(frame: CGRectMake(0,0,self.logoView.frame.width, self.logoView.frame.height))
        pulseIcon.drawIconBackground(iconBackgroundColor)
        pulseIcon.drawIcon(iconColor, iconThickness: 3)

        logoView.addSubview(pulseIcon)
        
        self.userEmail.layer.addSublayer(addBorders(self.userEmail))
        self.userPassword.layer.addSublayer(addBorders(self.userPassword))
        
        self.signupButton.layer.cornerRadius = 20
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func createEmailAccount(sender: UIButton) {
        validateEmail(userEmail.text, completion: {(verified, error) in
            if !verified {
                self._emailErrorLabel.text = error!.localizedDescription
            } else {
                self.validatePassword(self.userPassword.text, completion: {(verified, error) in
                    if !verified {
                        self._passwordErrorLabel.text = error!.localizedDescription
                    } else {
                        self.performSegueWithIdentifier("addNameSegue", sender: self)
                    }
                })
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
            let userInfo = [ NSLocalizedDescriptionKey : "Please enter a valid email" ]
            completion(verified: false, error: NSError.init(domain: "Invalid", code: 0, userInfo: userInfo))
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
            let userInfo = [ NSLocalizedDescriptionKey : "Password must be 8 characters in length" ]
            completion(verified: false, error: NSError.init(domain: "Invalid", code: 0, userInfo: userInfo))
            return
        }
//        let passwordFormat = "^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{8,}$"
//        let passwordPredicate = NSPredicate(format:"SELF MATCHES %@", passwordFormat)
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        _passwordErrorLabel.text = ""
        _emailErrorLabel.text = ""
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
