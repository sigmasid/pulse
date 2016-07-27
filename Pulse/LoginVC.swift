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

class LoginVC: UIViewController, UITextFieldDelegate, ParentDelegate {
    weak var loginVCDelegate : childVCDelegate?
    
    @IBOutlet weak var emailLabelButton: UIButton!
    @IBOutlet weak var fbButton: UIButton!
    @IBOutlet weak var emailButton: UIButton!
    @IBOutlet weak var twtrButton: UIButton!
    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var userPassword: UITextField!
    
    @IBOutlet weak var createAccount: UIButton!
    @IBOutlet weak var forgotPassword: UIButton!
    @IBOutlet weak var _emailErrorLabel: UILabel!
    @IBOutlet weak var _passwordErrorLabel: UILabel!
    
    private var _headerView : UIView?
    private var _loginHeader : LoginHeaderView?
    private var _loaded = false

    var currentTWTRSession : TWTRSession?
    
    private var loadingView : LoadingView?
    private var _hasMovedUp = false
    
    private var emailValidated = false {
        didSet {
            if emailValidated && passwordValidated {
                emailButton.setEnabled()
            } else {
                emailButton.setDisabled()
            }
        }
    }
    
    private var passwordValidated = false {
        didSet {
            if emailValidated && passwordValidated {
                emailButton.setEnabled()
            } else {
                emailButton.setDisabled()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated : Bool) {
        super.viewDidAppear(true)
        
        if !_loaded {
            hideKeyboardWhenTappedAround()
            setupView()
            emailButton.setDisabled()
            addHeader()
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.onFBProfileUpdated), name:FBSDKProfileDidChangeNotification, object: nil)
            _loaded = true
        } else {
            view.layoutIfNeeded()
        }
        _loginHeader?.updateStatusMessage("get logged in")

    }
    
    override func viewDidDisappear(animated : Bool) {
        super.viewDidDisappear(true)
        _loginHeader?.updateStatusMessage("")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupView() {
        setDarkBackground()
        
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
        
        fbButton.makeRound()
        twtrButton.makeRound()
        emailLabelButton.makeRound()
        
        emailButton.layer.cornerRadius = buttonCornerRadius
        
        let _footerDividerLine = UIView(frame:CGRectMake(forgotPassword.frame.width - 1, 0 , 1 , forgotPassword.frame.height))
        _footerDividerLine.backgroundColor = UIColor.whiteColor()
        forgotPassword.addSubview(_footerDividerLine)

    }
    
    func addHeader() {
        _headerView = UIView()
        
        if let _headerView = _headerView {
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
                _loginHeader.setScreenTitleLabel("LOGIN")
                _headerView.addSubview(_loginHeader)
            }
        }
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
        sender.setDisabled()
        let _loadingIndicator = sender.addLoadingIndicator()
        dismissKeyboard()
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        FIRAuth.auth()?.signInWithEmail(self.userEmail.text!, password: self.userPassword.text!) { (aUser, error) in
            if let error = error {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                sender.setEnabled()
                sender.removeLoadingIndicator(_loadingIndicator)
                switch error.code {
                case FIRAuthErrorCode.ErrorCodeWrongPassword.rawValue: self._passwordErrorLabel.text = "incorrect password"
                case FIRAuthErrorCode.ErrorCodeInvalidEmail.rawValue: self._emailErrorLabel.text = "invalid email"
                case FIRAuthErrorCode.ErrorCodeUserNotFound.rawValue: self._emailErrorLabel.text = "email not found"

                default: self._loginHeader!.updateStatusMessage("error signing in")
                }
            }
            else {
                sender.setEnabled()
                sender.removeLoadingIndicator(_loadingIndicator)
                self._loginHeader!.updateStatusMessage("welcome!")
                self.view.endEditing(true)
                self._loggedInSuccess()
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        }
    }
    
    @IBAction func createAccount(sender: UIButton) {
        if let CreateAccountVC = storyboard?.instantiateViewControllerWithIdentifier("LoginCreateAccountVC") as? LoginCreateAccountVC {
            CreateAccountVC.returnToParentDelegate = self
            GlobalFunctions.addNewVC(CreateAccountVC, parentVC: self)
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
            } else {
                print("fb login done - success")
                //login sucess - will get handled by FB profile updated notification
            }
        })
        
    }
    
    func onFBProfileUpdated(notification: NSNotification) {
        guard let _accessToken = FBSDKAccessToken.currentAccessToken() else {
            return
        }
        
        let credential = FIRFacebookAuthProvider.credentialWithAccessToken(_accessToken.tokenString)
        FIRAuth.auth()?.signInWithCredential(credential) { (aUser, error) in
            if error != nil {
                self.removeLoading()
                GlobalFunctions.showErrorBlock("Facebook Login Failed", erMessage: error!.localizedDescription)
            }
            else {
                self.removeLoading()
                self._loginHeader!.updateStatusMessage(aUser!.displayName)
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
                        self._loginHeader!.updateStatusMessage(error?.description)
                    } else {
                        self.removeLoading()
                        self._loggedInSuccess()
                    }
                }
            } else {
                self.removeLoading()
                self._loginHeader!.updateStatusMessage("Uh oh! That didn't work: \(error!.localizedDescription)")
            }
        }
    }
    
    func _loggedInSuccess() {
        NSNotificationCenter.defaultCenter().postNotificationName("LoginSuccess", object: self)
        if let _ = loginVCDelegate {
            loginVCDelegate!.loginSuccess(self)
        }
    }
    
    func addLoading() {
        loadingView = LoadingView(frame: view.bounds, backgroundColor: UIColor.whiteColor())
        loadingView?.addIcon(IconSizes.Medium, _iconColor: UIColor.blackColor(), _iconBackgroundColor: nil)
        loadingView?.addMessage("Signing in...")
        view.addSubview(loadingView!)
    }
    
    func returnToParent(currentVC : UIViewController) {
        GlobalFunctions.dismissVC(currentVC)
    }
    
    func removeLoading() {
        if loadingView != nil {
            UIView.animateWithDuration(0.2, animations: { self.loadingView!.alpha = 0.0 } ,
                                       completion: {(value: Bool) in
                                        self.loadingView!.removeFromSuperview()
            })
        }
    }
}
