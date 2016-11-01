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
    var nav : PulseNavVC!
    
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
    
    fileprivate var _isLoaded = false
    var _currentLoadedView : currentLoadedView?

    enum currentLoadedView {
        case login
        case createAccount
    }
    
    var currentTWTRSession : TWTRSession?
    
    fileprivate var loadingView : LoadingView?
    fileprivate var _hasMovedUp = false
    
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
    
    override func viewDidLayoutSubviews() {
        if !_isLoaded {
            hideKeyboardWhenTappedAround()
            setupView()
            emailButton.setDisabled()
            _currentLoadedView = .login
            
            NotificationCenter.default.addObserver(self, selector: #selector(onFBProfileUpdated), name:NSNotification.Name.FBSDKAccessTokenDidChange, object: nil)
            
            _isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeader()
    }
    
    override func viewDidDisappear(_ animated : Bool) {
        super.viewDidDisappear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func updateHeader() {
        if parent?.navigationController != nil {
            let loginButton = PulseButton(size: .small, type: .login, isRound : true, hasBackground: true)
            parent?.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: loginButton)
        }
        
        if let nav = navigationController as? PulseNavVC {
            self.nav = nav
            self.nav.setNav(navTitle: "Login", screenTitle: nil, screenImage: nil)
        } else {
            parent?.title = "Login"
        }
    }
    
    fileprivate func setupView() {
        userEmail.delegate = self
        userPassword.delegate = self
        userPassword.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)

        userEmail.layer.addSublayer(GlobalFunctions.addBorders(userEmail))
        userPassword.layer.addSublayer(GlobalFunctions.addBorders(userPassword))
        userEmail.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0)
        userPassword.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0)
        
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
            GlobalFunctions.validateEmail(userEmail.text, completion: {(verified, error) in
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
            GlobalFunctions.validatePassword(userPassword.text, completion: {(verified, error) in
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
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        FIRAuth.auth()?.signIn(withEmail: self.userEmail.text!, password: self.userPassword.text!) { (aUser, blockError) in
            if let blockError = blockError as? NSError {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                sender.setEnabled()
                sender.removeLoadingIndicator(_loadingIndicator)
                switch blockError.code {
                case FIRAuthErrorCode.errorCodeWrongPassword.rawValue: self._passwordErrorLabel.text = "incorrect password"
                case FIRAuthErrorCode.errorCodeInvalidEmail.rawValue: self._emailErrorLabel.text = "invalid email"
                case FIRAuthErrorCode.errorCodeUserNotFound.rawValue: self._emailErrorLabel.text = "email not found"

                default: self.nav?.setNav(navTitle: "error signing in", screenTitle: nil, screenImage: nil)
                }
            }
            else {
                sender.setEnabled()
                sender.removeLoadingIndicator(_loadingIndicator)
                self.nav?.setNav(navTitle: "welcome", screenTitle: nil, screenImage: nil)
                self.view.endEditing(true)
                self._loggedInSuccess()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }
    
    @IBAction func createAccount(_ sender: UIButton) {
        if let createAccountVC = storyboard?.instantiateViewController(withIdentifier: "LoginCreateAccountVC") as? LoginCreateAccountVC {
            _currentLoadedView = .createAccount
            self.parent?.navigationController?.pushViewController(createAccountVC, animated: true)
        }
    }
    
    @IBAction func fbLogin(_ sender: UIButton) {
        addLoading()
        let facebookReadPermissions = ["public_profile", "email", "user_friends"]
        let loginButton = FBSDKLoginManager()
        loginButton.logIn(withReadPermissions: facebookReadPermissions, from: self, handler: { (result, blockError) -> Void in
            if blockError != nil {
                self.removeLoading()
                GlobalFunctions.showErrorBlock("Facebook Login Failed", erMessage: blockError!.localizedDescription)
            } else if result!.isCancelled {
                self.removeLoading()
            } else {
                print("fb login done - success")
                //login sucess - will get handled by FB profile updated notification
            }
        })
        
    }
    
    func onFBProfileUpdated(_ notification: Notification) {

        guard let _accessToken = FBSDKAccessToken.current() else {
            return
        }
        var dict : NSDictionary!
        FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"]).start(completionHandler: { (connection, result, error) -> Void in
            if (error == nil){
                dict = result as! NSDictionary
                print(dict)
            }
        })
        
        let credential = FIRFacebookAuthProvider.credential(withAccessToken: _accessToken.tokenString)
        FIRAuth.auth()?.signIn(with: credential) { (aUser, error) in
            if error != nil {
                self.removeLoading()
                GlobalFunctions.showErrorBlock("Facebook Login Failed", erMessage: error!.localizedDescription)
            }
            else {
                self.removeLoading()
                self.nav?.setNav(navTitle: aUser!.displayName, screenTitle: nil, screenImage: nil)
                self._loggedInSuccess()
                print("posted facebook login success update")
            }
        }
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.FBSDKProfileDidChange, object: nil)
    }
    
    @IBAction func twtrLogin(_ sender: UIButton) {
        addLoading()
        Twitter.sharedInstance().logIn { session, error in
            if (session != nil) {
                self.currentTWTRSession = session
                let credential = FIRTwitterAuthProvider.credential(withToken: session!.authToken, secret: session!.authTokenSecret)
                FIRAuth.auth()?.signIn(with: credential) { (aUser, blockError) in
                    if let blockError = blockError as? NSError {
                        self.removeLoading()
                        self.nav?.setNav(navTitle: blockError.description, screenTitle: nil, screenImage: nil)
                    } else {
                        self.removeLoading()
                        self._loggedInSuccess()
                    }
                }
            } else {
                self.removeLoading()
                self.nav?.setNav(navTitle: "Uh oh! That didn't work", screenTitle: nil, screenImage: nil)
            }
        }
    }
    
    func _loggedInSuccess() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "LoginSuccess"), object: self)
//        if let _ = loginVCDelegate {
//            loginVCDelegate!.loginSuccess(self)
//        }
    }
    
    func addLoading() {
        loadingView = LoadingView(frame: view.bounds, backgroundColor: UIColor.white)
        loadingView?.addIcon(IconSizes.medium, _iconColor: UIColor.black, _iconBackgroundColor: nil)
        loadingView?.addMessage("Signing in...")
        view.addSubview(loadingView!)
    }
    
    func returnToParent(_ currentVC : UIViewController) {
        GlobalFunctions.dismissVC(currentVC)
    }
    
    func removeLoading() {
        if loadingView != nil {
            UIView.animate(withDuration: 0.2, animations: { self.loadingView!.alpha = 0.0 } ,
                                       completion: {(value: Bool) in
                                        self.loadingView!.removeFromSuperview()
            })
        }
    }
}
