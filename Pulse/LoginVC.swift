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

class LoginVC: UIViewController {
    var firebaseRef = FIRDatabaseReference.init()
    weak var loginDelegate : childVCDelegate?
    
    @IBOutlet weak var logoView: UIView!
    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var userPassword: UITextField!
    @IBOutlet weak var showStatus: UILabel!
    var currentTWTRSession : TWTRSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.onFBProfileUpdated), name:FBSDKProfileDidChangeNotification, object: nil)
    }
    
    override func viewDidAppear(animated : Bool) {
        super.viewDidAppear(true)
        self.view.alpha = 0.8
        
        let pulseIcon = Icon(frame: CGRectMake(0,0,self.logoView.frame.width, self.logoView.frame.height))
        pulseIcon.drawIcon(iconColor, iconThickness: 3)
        logoView.addSubview(pulseIcon)
        
        let borderColor = UIColor( red: 191/255, green: 191/255, blue:191/255, alpha: 1.0 ).CGColor
        userEmail.layer.borderWidth = 1
        userPassword.layer.borderWidth = 1
        
        userEmail.layer.borderColor = borderColor
        userPassword.layer.borderColor = borderColor
        
        userEmail.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0)
        userPassword.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0)
        
        if (User.currentUser.uID == nil) {
            self.showStatus.backgroundColor = UIColor.grayColor()
            self.showStatus.textColor = UIColor.whiteColor()
            self.showStatus.text = "You need to be logged in to post"
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func emailLogin(sender: UIButton) {
        guard let email = userEmail.text else {
            self.showStatus.text = "Please Enter a Valid Email"
            return
        }
        guard let password = userPassword.text else {
            self.showStatus.text = "Please Enter Your Password"
            return
        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        FIRAuth.auth()?.signInWithEmail(email, password: password) { (aUser, error) in
            if let error = error {
                switch error.code {
                case FIRAuthErrorCode.ErrorCodeWrongPassword.rawValue: self.showStatus.text = "Incorrect Password"
                case FIRAuthErrorCode.ErrorCodeInvalidEmail.rawValue: self.showStatus.text = "Invalid Email"
                default: self.showStatus.text = "Error Signing in"
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
            }
            else {
                self.showStatus.text = "Welcome!"
                AuthHelper.createUser(aUser!.uid)
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
                    print(currentTWTRSession?.userID)
                } else {
                    User.currentUser.signOut()
                    self.showStatus.text = "signed off successfully"
                }
            }
        }
        catch {
            self.showStatus.text = "there was an error signing out"
        }
    }
    
    func userFBLoggedIn(token : String) {
        let credential = FIRFacebookAuthProvider.credentialWithAccessToken(token)
        FIRAuth.auth()?.signInWithCredential(credential) { (aUser, error) in
            if error != nil {
                print(error?.localizedDescription)
            }
            else {
                if let _aUser = aUser {
                    self.showStatus.text = _aUser.displayName
                    print(_aUser.displayName)
                    AuthHelper.createUser(_aUser.uid, name: _aUser.displayName!)
                    self._loggedInSuccess()
                }
            }
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
                print("login success")
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
                if let _aUser = aUser {
                    self.showStatus.text = _aUser.displayName
                    AuthHelper.createUser(_aUser.uid, name: _aUser.displayName!, pic : FIRAuth.auth()?.currentUser?.photoURL)
                    self._loggedInSuccess()
                }
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
                        print(error?.description)
                    } else {
                        AuthHelper.createUser(aUser!.uid, name: session!.userName, pic : FIRAuth.auth()?.currentUser?.photoURL)
                        self._loggedInSuccess()
                    }
                }
            } else {
                self.showStatus.text = "Uh oh! That didn't work: \(error!.localizedDescription)"
            }
        }
    }
    
    func _loggedInSuccess() {
        self.loginDelegate!.loginSuccess(self)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
    }

}
