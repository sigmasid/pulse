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

    @IBOutlet weak var logoView: UIView!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    
    @IBOutlet weak var _firstNameError: UILabel!
    @IBOutlet weak var _lastNameError: UILabel!
    
    weak var loginVCDelegate : childVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewDidAppear(animated : Bool) {
        super.viewDidAppear(true)
        
        let pulseIcon = Icon(frame: CGRectMake(0,0,self.logoView.frame.width, self.logoView.frame.height))
        pulseIcon.drawIconBackground(iconBackgroundColor)
        pulseIcon.drawIcon(iconColor, iconThickness: 2)
        
        logoView.addSubview(pulseIcon)
        
        self.firstName.layer.addSublayer(GlobalFunctions.addBorders(self.firstName))
        self.lastName.layer.addSublayer(GlobalFunctions.addBorders(self.lastName))
        self.doneButton.layer.cornerRadius = buttonCornerRadius

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    @IBAction func addName(sender: UIButton) {
        GlobalFunctions.validateName(firstName.text, completion: {(verified, error) in
            if !verified {
                self._firstNameError.text = error!.localizedDescription
            } else {
                GlobalFunctions.validateName(self.lastName.text, completion: {(verified, error) in
                    if !verified {
                        self._lastNameError.text = error!.localizedDescription
                    } else {
                        let fullName = self.firstName.text! + " " + self.lastName.text!
                        Database.updateUserDisplayName(fullName, completion: { (success, error) in
                            if !success {
                                self._firstNameError.text = error!.localizedDescription
                            }
                            else {
                                self.performSegueWithIdentifier("unwindFromLoggedInSuccess", sender: self)
                            }
                        })
                    }
                })
            }
        })
    }
    
    func _loggedInSuccess() {
        self.loginVCDelegate!.loginSuccess(self)
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        _firstNameError.text = ""
        _lastNameError.text = ""
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
