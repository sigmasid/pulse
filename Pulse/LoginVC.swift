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
import SafariServices

class LoginVC: PulseVC, UITextFieldDelegate, ItemPreviewDelegate {
    public weak var loginVCDelegate : ContentDelegate?
    
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
    @IBOutlet weak var termsDescription: UILabel!
    @IBOutlet weak var showTermsButton: UIButton!
    @IBOutlet weak var showPrivacyButton: UIButton!
    
    public var _currentLoadedView : currentLoadedView?
    public var showInviteAlert : Bool = false
    
    fileprivate var agreeTermsButton = PulseButton(size: .xxSmall, type: .check, isRound: false, background: .pulseGrey, tint: .black)
    
    enum currentLoadedView {
        case login
        case createAccount
    }
    
    var currentTWTRSession : TWTRSession?
    
    fileprivate var _hasMovedUp = false
    fileprivate var termsChecked = true
    
    fileprivate var emailValidated = false {
        didSet {
            if emailValidated && passwordValidated {
                emailButton.setEnabled()
            } else {
                emailButton.setDisabled()
            }
        }
    }
    
    fileprivate var passwordValidated = false {
        didSet {
            if emailValidated && passwordValidated {
                emailButton.setEnabled()
            } else {
                emailButton.setDisabled()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        if !isLoaded {
            hideKeyboardWhenTappedAround()
            setupView()
            addTermsButton()
            
            emailButton.setDisabled()
            _currentLoadedView = .login
            
            NotificationCenter.default.addObserver(self, selector: #selector(onFBProfileUpdated), name:NSNotification.Name.FBSDKAccessTokenDidChange, object: nil)
            
            isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeader()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if showInviteAlert {
            presentInviteAlert()
        }
    }
    
    fileprivate func updateHeader() {
        let loginButton = PulseButton(size: .small, type: .login, isRound : true, background: .white, tint: .black)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: loginButton)
        headerNav?.setNav(title: "Login")
    }
    
    fileprivate func presentInviteAlert() {
        if showInviteAlert {
            GlobalFunctions.showAlertBlock(viewController: self,
                                           erTitle: "Please login to see invite",
                                           erMessage: "You need to be logged in to view and respond to the invite",
                                           buttonTitle: "okay")
            showInviteAlert = false
        }
    }
    
    fileprivate func setupView() {
        userEmail.delegate = self
        userPassword.delegate = self
        userPassword.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)

        userEmail.addBottomBorder()
        userPassword.addBottomBorder()
        
        userEmail.attributedPlaceholder = NSAttributedString(string: "email", attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
        userPassword.attributedPlaceholder = NSAttributedString(string: "password", attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
        userEmail.tag = 100
        userPassword.tag = 200
        
        fbButton.makeRound()
        twtrButton.makeRound()
        emailLabelButton.makeRound()
        
        emailButton.layer.cornerRadius = buttonCornerRadius.radius(.regular)
        
        let _footerDividerLine = UIView(frame:CGRect(x: forgotPassword.frame.width - 1, y: 0 , width: 1 , height: forgotPassword.frame.height))
        _footerDividerLine.backgroundColor = UIColor.black
        forgotPassword.addSubview(_footerDividerLine)
    }
    
    fileprivate func addTermsButton() {
        view.addSubview(agreeTermsButton)
        
        agreeTermsButton.translatesAutoresizingMaskIntoConstraints = false
        agreeTermsButton.centerYAnchor.constraint(equalTo: termsDescription.centerYAnchor).isActive = true
        agreeTermsButton.leadingAnchor.constraint(equalTo: forgotPassword.leadingAnchor).isActive = true
        agreeTermsButton.widthAnchor.constraint(equalToConstant: IconSizes.xxSmall.rawValue).isActive = true
        agreeTermsButton.heightAnchor.constraint(equalTo: agreeTermsButton.widthAnchor).isActive = true
        
        agreeTermsButton.layoutIfNeeded()
        agreeTermsButton.removeShadow()
        
        agreeTermsButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        agreeTermsButton.setImage(UIImage(named: "check"), for: .selected)
        agreeTermsButton.setImage(nil, for: .normal)
        
        agreeTermsButton.isSelected = true
        agreeTermsButton.addTarget(self, action: #selector(handleAgreeTerms), for: .touchUpInside)
    }
    
    internal func handleAgreeTerms(_ sender: UIButton) {
        termsChecked = !sender.isSelected
        agreeTermsButton.isSelected = !sender.isSelected
    }
    
    @IBAction func handleShowPolicy(_ sender: UIButton) {
        var url : URL?
        
        if sender == showTermsButton {
            url = URL(string: "https://checkpulse.co/terms")
        } else if sender == showPrivacyButton {
            url = URL(string: "https://checkpulse.co/privacy")
        }
        
        if let url = url {
            let svc = SFSafariViewController(url: url)
            present(svc, animated: true, completion: nil)
        }
    }
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if !_hasMovedUp {
            UIView.animate(withDuration: 0.25, animations: {
                self.view.frame.origin.y -= 60
            }) 
            _hasMovedUp = true
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if _hasMovedUp {
            UIView.animate(withDuration: 0.25, animations: {
                self.view.frame.origin.y += 60
            }) 
            _hasMovedUp = false
        }
        
        if textField.tag == userEmail.tag {
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
        if textField.tag == userPassword.tag {
            GlobalFunctions.validatePassword(userPassword.text, completion: {[weak self] (verified, error) in
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
    
    @IBAction func emailLogin(_ sender: UIButton) {
        sender.setDisabled()
        let _loadingIndicator = sender.addLoadingIndicator()
        dismissKeyboard()
        
        guard termsChecked else {
            GlobalFunctions.showAlertBlock("Please Review Terms of Service", erMessage: "You need to agree to our terms of service prior to continuing")
            sender.setEnabled()
            sender.removeLoadingIndicator(_loadingIndicator)
            return
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        Auth.auth().signIn(withEmail: self.userEmail.text!, password: self.userPassword.text!) {[weak self] (aUser, blockError) in
            guard let `self` = self else { return }
            
            if let blockError = blockError {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                switch AuthErrorCode(rawValue: blockError._code)! {
                case .wrongPassword: self._passwordErrorLabel.text = "incorrect password"
                case .invalidEmail: self._emailErrorLabel.text = "invalid email"
                case .userNotFound: self._emailErrorLabel.text = "email not found"

                default: self.headerNav?.setNav(title: "Login", subtitle: "error logging in")
                }
            }
            else {
                self.headerNav?.setNav(title: "Welcome")
                self.view.endEditing(true)
                self._loggedInSuccess()
                self.userEmail.text = ""
                self.userPassword.text = ""
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            sender.setEnabled()
            sender.removeLoadingIndicator(_loadingIndicator)
        }
    }
    
    @IBAction func createAccount(_ sender: UIButton) {
        guard termsChecked else {
            GlobalFunctions.showAlertBlock("Please Review Terms of Service", erMessage: "You need to agree to our terms of service prior to continuing")
            return
        }
        
        if let createAccountVC = storyboard?.instantiateViewController(withIdentifier: "LoginCreateAccountVC") as? LoginCreateAccountVC {
            _currentLoadedView = .createAccount
            navigationController?.pushViewController(createAccountVC, animated: true)
        }
    }
    
    @IBAction func handleForgotPassword(_ sender: UIButton) {
        let resetPasswordConfirmation = UIAlertController(title: "Reset Password?",
                                                          message: "enter your email and we will send a password reset link if you have an account with us",
                                                          preferredStyle: .alert)
        
        let resetAction = UIAlertAction(title: "reset", style: .default, handler: { (action: UIAlertAction!) in
            if let email = resetPasswordConfirmation.textFields?.first?.text {
                Auth.auth().sendPasswordReset(withEmail: email) {[weak self] (error) in
                    guard let `self` = self else { return }
                    GlobalFunctions.showAlertBlock(viewController : self,
                                                   erTitle: "Request Sent",
                                                   erMessage: "check your inbox for the reset link",
                                                   buttonTitle: "done")
                }
            } else {
                resetPasswordConfirmation.textFields?.first?.text = ""
                resetPasswordConfirmation.textFields?.first?.placeholder = "please enter a valid email"
            }
        })
        
        resetAction.isEnabled = false
        
        resetPasswordConfirmation.addTextField(configurationHandler: { emailField in
            emailField.placeholder = "enter email"
            NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: emailField, queue: OperationQueue.main) { (notification) in
                GlobalFunctions.validateEmail(emailField.text, completion: {(success, error) in
                    resetAction.isEnabled = success ? true : false
                })
            }
        })
        
        resetPasswordConfirmation.addAction(UIAlertAction(title: "cancel", style: .cancel , handler: { (action: UIAlertAction!) in }))
        resetPasswordConfirmation.addAction(resetAction)
        
        self.present(resetPasswordConfirmation, animated: true, completion: nil)
    }
    
    @IBAction func fbLogin(_ sender: UIButton) {
        guard termsChecked else {
            GlobalFunctions.showAlertBlock("Please Review Terms of Service", erMessage: "You need to agree to our terms of service prior to continuing")
            return
        }
        
        toggleLoading(show: true, message: "Signing in...", showIcon: true)
        let facebookReadPermissions = ["public_profile", "email", "user_friends"]
        let loginButton = FBSDKLoginManager()
        loginButton.logIn(withReadPermissions: facebookReadPermissions, from: self, handler: {[weak self] (result, blockError) -> Void in
            guard let `self` = self else { return }

            if blockError != nil {
                self.toggleLoading(show: false, message: nil)
                GlobalFunctions.showAlertBlock("Facebook Login Failed", erMessage: blockError!.localizedDescription)
            } else if result!.isCancelled {
                self.toggleLoading(show: false, message: nil)
            } else {
                //login sucess - will get handled by FB profile updated notification
            }
        })
    }
    
    internal func onFBProfileUpdated(_ notification: Notification) {

        guard let _accessToken = FBSDKAccessToken.current() else {
            return
        }
        //var dict : NSDictionary!
        FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"]).start(completionHandler: { (connection, result, error) -> Void in
            if (error == nil){
                //dict = result as! NSDictionary
            }
        })
        
        let credential = FacebookAuthProvider.credential(withAccessToken: _accessToken.tokenString)
        Auth.auth().signIn(with: credential) {[weak self] (aUser, error) in
            guard let `self` = self else { return }

            if error != nil {
                self.toggleLoading(show: false, message: nil)
                GlobalFunctions.showAlertBlock("Facebook Login Failed", erMessage: error!.localizedDescription)
            }
            else {
                self.toggleLoading(show: false, message: nil)
                self.headerNav?.setNav(title: aUser!.displayName)
                self._loggedInSuccess()
            }
        }
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.FBSDKProfileDidChange, object: nil)
    }
    
    @IBAction func twtrLogin(_ sender: UIButton) {
        guard termsChecked else {
            GlobalFunctions.showAlertBlock("Please Review Terms of Service", erMessage: "You need to agree to our terms of service prior to continuing")
            return
        }
        
        toggleLoading(show: true, message: "Signing in...", showIcon: true)
        Twitter.sharedInstance().logIn {[weak self] session, error in
            guard let `self` = self else { return }
            
            if (session != nil) {
                self.currentTWTRSession = session
                let credential = TwitterAuthProvider.credential(withToken: session!.authToken, secret: session!.authTokenSecret)
                Auth.auth().signIn(with: credential) {[weak self] (aUser, blockError) in
                    guard let `self` = self else { return }

                    if let blockError = blockError {
                        self.toggleLoading(show: false, message: nil)
                        self.headerNav?.setNav(title: blockError.localizedDescription)
                    } else {
                        self.toggleLoading(show: false, message: nil)
                        self._loggedInSuccess()
                    }
                }
            } else {
                self.toggleLoading(show: false, message: nil)
                self.headerNav?.setNav(title: "Login", subtitle: "Error Logging in!")
            }
        }
    }
    
    fileprivate func _loggedInSuccess() {
        if let permissionsPopup = GlobalFunctions.askNotificationPermssion(viewController: self) {
            permissionsPopup.delegate = self
            
            blurViewBackground()
            view.addSubview(permissionsPopup)
        } else {
            postLoggedInNotification()
        }
    }
    
    fileprivate func postLoggedInNotification() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "LoginSuccess"), object: self)
    }
    
    internal func returnToParent(_ currentVC : UIViewController) {
        GlobalFunctions.dismissVC(currentVC)
    }
    
    
    internal func userClosedPreview(_ view : UIView) {
        view.removeFromSuperview()
        postLoggedInNotification()
    }
    
    internal func userClickedButton() {
        view.removeFromSuperview()
        GlobalFunctions.showNotificationPermissions()
        postLoggedInNotification()
    }
}
