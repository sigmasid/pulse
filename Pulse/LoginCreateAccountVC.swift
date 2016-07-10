//
//  CreateAccountVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/8/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class LoginCreateAccountVC: UIViewController {

    @IBOutlet weak var logoView: UIView!
    @IBOutlet weak var userPassword: UITextField!
    @IBOutlet weak var userEmail: UITextField!
    
    let _errorLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()

    }
    
    override func viewDidAppear(animated : Bool) {
        super.viewDidAppear(true)
        
        let pulseIcon = Icon(frame: CGRectMake(0,0,self.logoView.frame.width, self.logoView.frame.height))
        pulseIcon.drawIcon(iconColor, iconThickness: 3)
        pulseIcon.drawIconBackground(iconBackgroundColor)

        logoView.addSubview(pulseIcon)
        
        self.userEmail.layer.addSublayer(addBorders(self.userEmail))
        self.userPassword.layer.addSublayer(addBorders(self.userPassword))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func createEmailAccount(sender: UIButton) {
        validateEmail(userEmail.text, completion: {(verified, error) in
            if !verified {
                print(error!.localizedDescription)
            } else {
                self.validatePassword(self.userPassword.text, completion: {(verified, error) in
                    if !verified {
                        print(error!.localizedDescription)
                    } else {
                        print("valid email and password")
                    }
                })
            }
        })
        

    }
    
    ///Validate email
    private func validateEmail(enteredEmail:String?, completion: (verified: Bool, error: NSError?) -> Void) {
        completion(verified: true, error: nil)
        
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        
        if emailPredicate.evaluateWithObject(enteredEmail) {
            print("valid email fired")
            completion(verified: true, error: nil)
        } else {
            print("invalid email fired")
            let userInfo = [ NSLocalizedDescriptionKey : "Please enter a valid email" ]
            completion(verified: false, error: NSError.init(domain: "Invalid", code: 0, userInfo: userInfo))
        }
    }
    
    ///Validate password returns true if validated, error otherwise
    private func validatePassword(enteredPassword:String?, completion: (verified: Bool, error: NSError?) -> Void) {
        completion(verified: true, error: nil)
        
        let passwordFormat = "^(?=.*?[a-z]).{8,}$"
        let passwordPredicate = NSPredicate(format:"SELF MATCHES %@", passwordFormat)
        
        if passwordPredicate.evaluateWithObject(enteredPassword) {
            print("valid email fired")
            completion(verified: true, error: nil)
        } else {
            print("invalid password fired")
            let userInfo = [ NSLocalizedDescriptionKey : "Password must be 8 characters in length." ]
            completion(verified: false, error: NSError.init(domain: "Invalid", code: 0, userInfo: userInfo))
        }
//        let passwordFormat = "^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{8,}$"
//        let passwordPredicate = NSPredicate(format:"SELF MATCHES %@", passwordFormat)
    }
    
    private func setupErrorLabel(_relatedLabel : UILabel, error : String) {
        _errorLabel.text = error
        _errorLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        _errorLabel.textColor = UIColor.redColor()
        _errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        _errorLabel.topAnchor.constraintEqualToAnchor(_relatedLabel.bottomAnchor, constant: 0).active = true
        _errorLabel.widthAnchor.constraintEqualToAnchor(_relatedLabel.widthAnchor).active = true
        _errorLabel.centerXAnchor.constraintEqualToAnchor(_relatedLabel.centerXAnchor, constant: 0).active = true
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
