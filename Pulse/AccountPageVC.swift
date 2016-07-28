//
//  AccountPageViewController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/14/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AccountPageVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var uProfilePic: UIImageView!
    @IBOutlet weak var uNameLabel: UITextField!
    @IBOutlet weak var numAnswersLabel: UILabel!
    @IBOutlet weak var inButton: UIButton!
    @IBOutlet weak var twtrButton: UIButton!
    @IBOutlet weak var fbButton: UIButton!
    @IBOutlet weak var savedTags: UITextView!
    private lazy var settingsButton = UIButton()
    
    weak var returnToParentDelegate : ParentDelegate!
    private var _nameErrorLabel = UILabel()
    
    private lazy var _cameraView = UIView()
    private lazy var _Camera = CameraManager()
    private var _cameraOverlay : CameraOverlayView!
    
    private var _loadingOverlay : LoadingView!
    private var _tapGesture : UITapGestureRecognizer?
    
    private lazy var _headerView = UIView()
    private var _loginHeader : LoginHeaderView?
    private var _loaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        
        if !_loaded {
            setDarkBackground()
            addHeader()
            
            fbButton.makeRound()
            twtrButton.makeRound()
            inButton.makeRound()
            
            uNameLabel.delegate = self
            uNameLabel.clearsOnBeginEditing = true
            
            _loginHeader = GlobalFunctions.addHeader(view, appTitle: "PULSE", screenTitle: "PROFILE")
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateLabels), name: "UserUpdated", object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateLabels), name: "AccountPageLoaded", object: nil)

            _tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
            uProfilePic.addGestureRecognizer(_tapGesture!)
            uProfilePic.userInteractionEnabled = true
            uProfilePic.contentMode = UIViewContentMode.ScaleAspectFill
            
            _loaded = true
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        _nameErrorLabel.text = ""
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        dismissKeyboard()
        GlobalFunctions.validateName(uNameLabel.text, completion: {(verified, error) in
            if verified {
                Database.updateUserData(UserProfileUpdateType.displayName, value: self.uNameLabel.text!, completion: { (success, error) in
                    if success {
                        //print("updated name in DB")
                    } else {
                        self.setupErrorLabel()
                        self.updateErrorLabelText(error!.localizedDescription)
                    }
                })
            } else {
                self.setupErrorLabel()
                self.updateErrorLabelText(error!.localizedDescription)
            }
        })
        return true
    }
    
    
    func ClickedSettings() {
        Database.signOut({ success in
            if success {
                NSNotificationCenter.defaultCenter().postNotificationName("LogoutSuccess", object: self)
            } else {
                //show error that could not sign out - try again later
            }
        })
    }

    @IBAction func LinkAccount(sender: UIButton) {
        //check w/ social source and connect to user profile on firebase
    }
    
    private func setupErrorLabel() {
        view.addSubview(_nameErrorLabel)
        
        _nameErrorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        _nameErrorLabel.topAnchor.constraintEqualToAnchor(uNameLabel.topAnchor).active = true
        _nameErrorLabel.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        _nameErrorLabel.heightAnchor.constraintEqualToAnchor(uNameLabel.heightAnchor).active = true
        _nameErrorLabel.leadingAnchor.constraintEqualToAnchor(uNameLabel.trailingAnchor, constant: 10).active = true
        
        _nameErrorLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
        _nameErrorLabel.backgroundColor = UIColor.grayColor()
        _nameErrorLabel.textColor = UIColor.blackColor()
        _nameErrorLabel.textAlignment = .Left
    }
    
    private func updateErrorLabelText(_errorText : String) {
        _nameErrorLabel.text = _errorText
    }
    
    func updateLabels(notification: NSNotification) {
        if let _userName = User.currentUser!.name {
            _loginHeader?.updateStatusMessage("welcome \(_userName)!")
            uNameLabel.text = _userName
            uNameLabel.userInteractionEnabled = false
        } else {
            _loginHeader?.updateStatusMessage("please login")
            uNameLabel.text = "tap to edit name"
            uNameLabel.userInteractionEnabled = true
        }
        
        if let _uPic = User.currentUser!.profilePic {
            addUserProfilePic(NSURL(string: _uPic))
        } else {
            uProfilePic.image = UIImage(named: "default-profile")
        }
        
        if User.currentUser!.hasSavedTags() {
//            savedTags.text = "new hello"
            addSavedTags(User.currentUser!.savedTags!)
        }
        
        numAnswersLabel.text = String(User.currentUser!.totalAnswers())
        view.setNeedsLayout()
    }
    
    private func addSavedTags(tagList : [String]) {
        let _msg = tagList.joinWithSeparator("\u{0085}")
        savedTags.textColor = UIColor.whiteColor()
        savedTags.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCallout)
        savedTags.text = _msg
    }
    
    private func addUserProfilePic(_userImageURL : NSURL?) {
        if let _ = _userImageURL {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let _userImageData = NSData(contentsOfURL: _userImageURL!)
                dispatch_async(dispatch_get_main_queue(), {
                    self.uProfilePic.image = UIImage(data: _userImageData!)
                })
            }
        }
    }
    
    func handleImageTap() {
        setupCamera()
        setupCameraOverlay()
        setupLoading()
    }
    
    private func highlightConnectedSocialSources() {
        
    }
    
    private func setupLoading() {
        _loadingOverlay = LoadingView(frame: view.bounds, backgroundColor : UIColor.blackColor().colorWithAlphaComponent(0.7))
        view.addSubview(_loadingOverlay)
    }
    
    private func setupCamera() {
        _cameraView = UIView(frame: view.bounds)
        _cameraView.backgroundColor = UIColor.whiteColor()
        view.addSubview(_cameraView)
        
        _Camera.showAccessPermissionPopupAutomatically = true
        _Camera.shouldRespondToOrientationChanges = false
        _Camera.cameraDevice = .Front
        
        _Camera.addPreviewLayerToView(_cameraView, newCameraOutputMode: .StillImage, completition: {() in
            dispatch_async(dispatch_get_main_queue()) {
                UIView.animateWithDuration(0.2, animations: { self._loadingOverlay.alpha = 0.0 } ,
                    completion: {(value: Bool) in
                        self._loadingOverlay.removeFromSuperview()
                })
                self._cameraOverlay.getButton(.Shutter).enabled = true
            }
        })
        
        _Camera.showErrorBlock = { [weak self] (erTitle: String, erMessage: String) -> Void in
            
            let alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (alertAction) -> Void in  }))
            
            self?.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    private func setupCameraOverlay() {
        _cameraOverlay = CameraOverlayView(frame: view.bounds)
        _cameraView.addSubview(_cameraOverlay)
        
        switch _Camera.flashMode {
        case .Off: _cameraOverlay._flashMode =  .Off
        case .On: _cameraOverlay._flashMode = .On
        case .Auto: _cameraOverlay._flashMode = .Auto
        }
        
        _cameraOverlay.getButton(.Shutter).addTarget(self, action: #selector(gotImage), forControlEvents: UIControlEvents.TouchUpInside)
        _cameraOverlay.getButton(.Shutter).enabled = false
        
        _cameraOverlay.getButton(.Flip).addTarget(self, action: #selector(CameraVC.flipCamera), forControlEvents: UIControlEvents.TouchUpInside)
        _cameraOverlay.getButton(.Flash).addTarget(self, action: #selector(CameraVC.cycleFlash), forControlEvents: UIControlEvents.TouchUpInside)
        _cameraOverlay.updateQuestion("smile!")
    }
    
    private func addHeader() {
        view.addSubview(_headerView)
        
        _headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraint(NSLayoutConstraint(item: _headerView, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .TopMargin , multiplier: 2, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: _headerView, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX , multiplier: 1, constant: 0))
        _headerView.heightAnchor.constraintEqualToAnchor(view.heightAnchor, multiplier: 1/13).active = true
        _headerView.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 1 - (Spacing.m.rawValue/view.frame.width)).active = true
        _headerView.layoutIfNeeded()
        
        _loginHeader = LoginHeaderView(frame: _headerView.frame)
        if let _loginHeader = _loginHeader {
            _loginHeader.setAppTitleLabel("PULSE")
            _loginHeader.setScreenTitleLabel("PROFILE")
            _loginHeader.addSettingsButton()
            _loginHeader._settings.addTarget(self, action: #selector(ClickedSettings), forControlEvents: UIControlEvents.TouchUpInside)

            _headerView.addSubview(_loginHeader)
        }
    }
    
    func gotImage() {
        _cameraOverlay.getButton(.Shutter).enabled = false
        setupLoading()
        _loadingOverlay.addIcon(IconSizes.Medium, _iconColor: UIColor.whiteColor(), _iconBackgroundColor: nil)
        _loadingOverlay.addMessage("saving! just a sec...", _color: UIColor.whiteColor())
        
        _Camera.capturePictureDataWithCompletition({ (imageData, error) -> Void in
            if let errorOccured = error {
                self._Camera.showErrorBlock(erTitle: "Error occurred", erMessage: errorOccured.localizedDescription)
                self._cameraOverlay.getButton(.Shutter).enabled = true
            } else {
                Database.uploadProfileImage(imageData!, completion: {(URL, error) in
                    if error != nil {
                        self._Camera.showErrorBlock(erTitle: "Error occurred", erMessage: error!.localizedDescription)
                        self._cameraOverlay.getButton(.Shutter).enabled = true
                        self._loadingOverlay.removeFromSuperview()
                    } else {
                        self._Camera.stopAndRemoveCaptureSession()
                        UIView.animateWithDuration(0.2, animations: { self._cameraView.alpha = 0.0 } ,
                            completion: {(value: Bool) in
                                self._loadingOverlay.removeFromSuperview()
                                self._cameraView.removeFromSuperview()
                        })
                    }
                })
            }
        })
    }
}
