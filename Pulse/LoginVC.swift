//
//  LoginVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import TwitterKit
import FBSDKLoginKit

class LoginVC: UIViewController, UITextFieldDelegate {
    weak var loginVCDelegate : childVCDelegate?
    
    @IBOutlet weak var fbButton: UIButton!
    @IBOutlet weak var emailButton: UIButton!
    @IBOutlet weak var twtrButton: UIButton!
    @IBOutlet weak var logoView: UIView!
    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var userPassword: UITextField!
    private var showStatus = UILabel()
    
    @IBOutlet weak var _emailErrorLabel: UILabel!
    @IBOutlet weak var _passwordErrorLabel: UILabel!
    
    var currentTWTRSession : TWTRSession?
    
    private var _hasMovedUp = false
    private var emailValidated = false {
        didSet {
            if emailValidated && passwordValidated {
                self.emailButton.enabled = true
                self.emailButton.alpha = 1.0
            } else {
                self.emailButton.enabled = false
                self.emailButton.alpha = 0.5
            }
        }
    }
    
    private var passwordValidated = false {
        didSet {
            if emailValidated && passwordValidated {
                self.emailButton.enabled = true
                self.emailButton.alpha = 1.0
            } else {
                self.emailButton.enabled = false
                self.emailButton.alpha = 0.5
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.onFBProfileUpdated), name:FBSDKProfileDidChangeNotification, object: nil)
        
        setupView()
    }
    
    override func viewDidAppear(animated : Bool) {
        super.viewDidAppear(true)
        
        emailButton.enabled = false
        emailButton.alpha = 0.5

        if (!User.isLoggedIn()) {
            showStatus.text = "please log in to post"
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupView() {
        let pulseIcon = Icon(frame: CGRectMake(0,0,logoView.frame.width, logoView.frame.height))
        pulseIcon.drawIcon(iconBackgroundColor, iconThickness: 2)
        logoView.addSubview(pulseIcon)
        
        userEmail.delegate = self
        userPassword.delegate = self
        userPassword.addTarget(self, action: #selector(self.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)

        userEmail.layer.addSublayer(GlobalFunctions.addBorders(userEmail))
        userPassword.layer.addSublayer(GlobalFunctions.addBorders(userPassword))
        userEmail.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0)
        userPassword.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0)
        userEmail.tag = 100
        userPassword.tag = 200
        
        fbButton.layer.cornerRadius = buttonCornerRadius
        twtrButton.layer.cornerRadius = buttonCornerRadius
        emailButton.layer.cornerRadius = buttonCornerRadius
        
        self.view.addSubview(showStatus)

        showStatus.translatesAutoresizingMaskIntoConstraints = false
        
        showStatus.topAnchor.constraintEqualToAnchor(self.view.topAnchor).active = true
        showStatus.widthAnchor.constraintEqualToAnchor(self.view.widthAnchor).active = true
        showStatus.heightAnchor.constraintEqualToConstant(30).active = true
        showStatus.centerXAnchor.constraintEqualToAnchor(self.view.centerXAnchor).active = true
        
        showStatus.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
        showStatus.backgroundColor = UIColor.grayColor()
        showStatus.textColor = UIColor.whiteColor()
        showStatus.textAlignment = .Center

    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if !_hasMovedUp {
            UIView.animateWithDuration(0.25) {
                self.view.frame.origin.y -= 200
            }
            _hasMovedUp = true
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if _hasMovedUp {
            UIView.animateWithDuration(0.25) {
                self.view.frame.origin.y += 200
            }
            _hasMovedUp = false
        }
        
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
    
    @IBAction func emailLogin(sender: UIButton) {

        self.dismissKeyboard()

        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        FIRAuth.auth()?.signInWithEmail(self.userEmail.text!, password: self.userPassword.text!) { (aUser, error) in
            if let error = error {
                switch error.code {
                case FIRAuthErrorCode.ErrorCodeWrongPassword.rawValue: self._passwordErrorLabel.text = "incorrect password"
                case FIRAuthErrorCode.ErrorCodeInvalidEmail.rawValue: self._emailErrorLabel.text = "invalid email"
                case FIRAuthErrorCode.ErrorCodeUserNotFound.rawValue: self._emailErrorLabel.text = "email not found"

                default: self.showStatus.text = "error signing in"
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
            }
            else {
                self.showStatus.text = "welcome!"
                self.view.endEditing(true)
                self._loggedInSuccess()
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        }
    }
    
    @IBAction func signOut(sender: UIButton) {
        do {
            try FIRAuth.auth()!.signOut()
            let store = Twitter.sharedInstance().sessionStore
            
            if let userID = currentTWTRSession?.userID {
                store.logOutUserID(userID)
                if let _ = Twitter.sharedInstance().sessionStore.sessionForUserID(userID) {
                    // print(currentTWTRSession?.userID)
                } else {
                    Database.signOut{ (success) in
                        if success {
                            self.showStatus.text = "signed off successfully"
                        }
                        else {
                            self.showStatus.text = "error signing out"
                        }
                    }
                }
            }
        }
        catch {
            self.showStatus.text = "there was an error signing out"
        }
    }
    
    @IBAction func fbLogin(sender: UIButton) {
        let facebookReadPermissions = ["public_profile", "email", "user_friends"]
        let loginButton = FBSDKLoginManager()
        loginButton.logInWithReadPermissions(facebookReadPermissions, fromViewController: self, handler: { (result:FBSDKLoginManagerLoginResult!, error:NSError!) -> Void in
            if error != nil {
                print(error.localizedDescription)
            } else if result.isCancelled {
                FBSDKLoginManager().logOut()
            } else {
                print("fb login done - success")
                //login sucess - will get handled by FB profile updated notification
            }
        })
        
    }
    
    func onFBProfileUpdated(notification: NSNotification) {
        let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
        FIRAuth.auth()?.signInWithCredential(credential) { (aUser, error) in
            if error != nil {
                print(error?.localizedDescription)
            }
            else {
                self.showStatus.text = aUser!.displayName
                self._loggedInSuccess()
            }
        }
    }
    
    @IBAction func twtrLogin(sender: UIButton) {
    
        Twitter.sharedInstance().logInWithCompletion { session, error in
            if (session != nil) {
                self.currentTWTRSession = session
                let credential = FIRTwitterAuthProvider.credentialWithToken(session!.authToken, secret: session!.authTokenSecret)
                FIRAuth.auth()?.signInWithCredential(credential) { (aUser, error) in
                    if error != nil {
                        self.showStatus.text =  error?.description
                    } else {
                        self._loggedInSuccess()
                    }
                }
            } else {
                self.showStatus.text = "Uh oh! That didn't work: \(error!.localizedDescription)"
            }
        }
    }
    
    func _loggedInSuccess() {
        if let _ = self.loginVCDelegate {
            self.loginVCDelegate!.loginSuccess(self)
        }
    }
    
    @IBAction func unwindFromCreateAccount(segue: UIStoryboardSegue) {
        print("unwould segue success")
    }
    
    @IBAction func unwindFromLoggedInSuccess(segue: UIStoryboardSegue) {
        _loggedInSuccess()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
    }

}
