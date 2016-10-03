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
    fileprivate var _headerView : UIView!
    fileprivate var _loginHeader : LoginHeaderView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated : Bool) {
        super.viewDidAppear(true)
        hideKeyboardWhenTappedAround()

        firstName.layer.addSublayer(GlobalFunctions.addBorders(self.firstName, _color: UIColor.black, thickness: IconThickness.thin.rawValue))
        lastName.layer.addSublayer(GlobalFunctions.addBorders(self.lastName, _color: UIColor.black, thickness: IconThickness.thin.rawValue))
        
        firstName.attributedPlaceholder = NSAttributedString(string: firstName.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
        lastName.attributedPlaceholder = NSAttributedString(string: lastName.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
        
        doneButton.layer.cornerRadius = buttonCornerRadius.radius(.regular)
        doneButton.setEnabled()
        addHeader()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    func addHeader() {
        _loginHeader = addHeader(text: "ADD NAME")
        _loginHeader.addEmptyButton(image: UIImage(named: "check")!)
        _loginHeader.updateStatusMessage(_message: "and could we get a name with that?")
    }

    @IBAction func addNameTouchDown(_ sender: UIButton) {
        
    }
    
    @IBAction func addName(_ sender: UIButton) {
        dismissKeyboard()
        sender.setDisabled()
        let _ = sender.addLoadingIndicator()
        
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
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "LoginSuccess"), object: self)
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        _firstNameError.text = ""
        _lastNameError.text = ""
    }
}
