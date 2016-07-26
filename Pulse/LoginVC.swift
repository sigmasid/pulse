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
    
    @IBOutlet weak var emailLabelButton: UIButton!
    @IBOutlet weak var fbButton: UIButton!
    @IBOutlet weak var emailButton: UIButton!
    @IBOutlet weak var twtrButton: UIButton!
    @IBOutlet weak var logoView: UIView!
    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var userPassword: UITextField!
    private var showStatus = UILabel()
    
    @IBOutlet weak var createAccount: UIButton!
    @IBOutlet weak var forgotPassword: UIButton!
    @IBOutlet weak var _emailErrorLabel: UILabel!
    @IBOutlet weak var _passwordErrorLabel: UILabel!
    
    var currentTWTRSession : TWTRSession?
    
    private var loadingView : LoadingView?
    private var _hasMovedUp = false
    
    private var emailValidated = false {
        didSet {
            if emailValidated && passwordValidated {
                emailButton.enabled = true
                emailButton.backgroundColor = UIColor(red: 245/255, green: 44/255, blue: 90/255, alpha: 1.0 )
            } else {
                emailButton.enabled = false
                emailButton.backgroundColor = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 0.5 )
            }
        }
    }
    
    private var passwordValidated = false {
        didSet {
            if emailValidated && passwordValidated {
                emailButton.enabled = true
                emailButton.backgroundColor = UIColor(red: 245/255, green: 44/255, blue: 90/255, alpha: 1.0 )
            } else {
                emailButton.enabled = false
                emailButton.backgroundColor = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 0.5 )
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.onFBProfileUpdated), name:FBSDKProfileDidChangeNotification, object: nil)
    }
    
    override func viewDidAppear(animated : Bool) {
        super.viewDidAppear(true)
        setupView()

        emailButton.enabled = false
        emailButton.alpha = 0.5

        if (!User.isLoggedIn()) {
            showStatus.text = "please log in to post"
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupView() {
        self.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.95)
        
        let pulseIcon = Icon(frame: CGRectMake(0,0,logoView.frame.width, logoView.frame.height))
        pulseIcon.drawLongIcon(UIColor.whiteColor(), iconThickness: 2)
        logoView.addSubview(pulseIcon)
        
        userEmail.delegate = self
        userPassword.delegate = self
        userPassword.addTarget(self, action: #selector(self.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)

        userEmail.layer.addSublayer(GlobalFunctions.addBorders(userEmail))
        userPassword.layer.addSublayer(GlobalFunctions.addBorders(userPassword))
        userEmail.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0)
        userPassword.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0)
        userEmail.attributedPlaceholder = NSAttributedString(string: "email", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])
        userPassword.attributedPlaceholder = NSAttributedString(string: "password", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])

        userEmail.tag = 100
        userPassword.tag = 200
        
        fbButton.layer.cornerRadius = fbButton.frame.width / 2
        twtrButton.layer.cornerRadius = twtrButton.frame.width / 2
        emailLabelButton.layer.cornerRadius = emailLabelButton.frame.width / 2
        emailButton.layer.cornerRadius = buttonCornerRadius
        
        self.view.addSubview(showStatus)

        showStatus.translatesAutoresizingMaskIntoConstraints = false
        
        showStatus.centerYAnchor.constraintEqualToAnchor(logoView.centerYAnchor).active = true
        showStatus.widthAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue).active = true
        showStatus.heightAnchor.constraintEqualToAnchor(showStatus.widthAnchor).active = true
        showStatus.centerXAnchor.constraintEqualToAnchor(self.view.centerXAnchor).active = true
        
        showStatus.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
        showStatus.backgroundColor = UIColor.whiteColor()
        showStatus.textColor = UIColor.blackColor()
        showStatus.lineBreakMode = .ByWordWrapping
        showStatus.numberOfLines = 0
        showStatus.layer.cornerRadius = showStatus.frame.width / 2
        showStatus.textAlignment = .Center
        showStatus.layer.masksToBounds = true
        
        let _footerDividerLine = UIView(frame:CGRectMake(forgotPassword.frame.width - 1, 0 , 1 , forgotPassword.frame.height))
        _footerDividerLine.backgroundColor = UIColor.whiteColor()
        forgotPassword.addSubview(_footerDividerLine)

    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if !_hasMovedUp {
            UIView.animateWithDuration(0.25) {
                self.view.frame.origin.y -= 100
            }
            _hasMovedUp = true
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if _hasMovedUp {
            UIView.animateWithDuration(0.25) {
                self.view.frame.origin.y += 100
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
        Database.signOut{ (success) in
            if success {
                self.showStatus.text = "signed off successfully"
            }
            else {
                self.showStatus.text = "error signing out"
            }
        }
    }
    
    @IBAction func fbLogin(sender: UIButton) {
        addLoading()
        let facebookReadPermissions = ["public_profile", "email", "user_friends"]
        let loginButton = FBSDKLoginManager()
        loginButton.logInWithReadPermissions(facebookReadPermissions, fromViewController: self, handler: { (result:FBSDKLoginManagerLoginResult!, error:NSError!) -> Void in
            if error != nil {
                self.removeLoading()
                GlobalFunctions.showErrorBlock("Facebook Login Failed", erMessage: error.localizedDescription)
            } else if result.isCancelled {
                self.removeLoading()
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
                self.removeLoading()
                GlobalFunctions.showErrorBlock("Facebook Login Failed", erMessage: error!.localizedDescription)
            }
            else {
                self.removeLoading()
                self.showStatus.text = aUser!.displayName
                self._loggedInSuccess()
            }
        }
         NSNotificationCenter.defaultCenter().removeObserver(self, name: FBSDKProfileDidChangeNotification, object: nil)
    }
    
    @IBAction func twtrLogin(sender: UIButton) {
        addLoading()
        Twitter.sharedInstance().logInWithCompletion { session, error in
            if (session != nil) {
                self.currentTWTRSession = session
                let credential = FIRTwitterAuthProvider.credentialWithToken(session!.authToken, secret: session!.authTokenSecret)
                FIRAuth.auth()?.signInWithCredential(credential) { (aUser, error) in
                    if error != nil {
                        self.removeLoading()
                        self.showStatus.text =  error?.description
                    } else {
                        self.removeLoading()
                        self._loggedInSuccess()
                    }
                }
            } else {
                self.removeLoading()
                self.showStatus.text = "Uh oh! That didn't work: \(error!.localizedDescription)"
            }
        }
    }
    
    func _loggedInSuccess() {
        if let _ = self.loginVCDelegate {
            self.loginVCDelegate!.loginSuccess(self)
        }
    }
    
    func addLoading() {
        loadingView = LoadingView(frame: view.bounds, backgroundColor: UIColor.whiteColor())
        loadingView?.addIcon(IconSizes.Medium, _iconColor: UIColor.blackColor(), _iconBackgroundColor: nil)
        loadingView?.addMessage("Signing in...")
        self.view.addSubview(loadingView!)
    }
    
    func removeLoading() {
        UIView.animateWithDuration(0.2, animations: { self.loadingView!.alpha = 0.0 } ,
                                   completion: {(value: Bool) in
                                    self.loadingView!.removeFromSuperview()
        })
    }
    
    @IBAction func unwindFromCreateAccount(segue: UIStoryboardSegue) {
        print("unwould segue success")
    }
    
    @IBAction func unwindFromLoggedInSuccess(segue: UIStoryboardSegue) {
        _loggedInSuccess()
    }
}
