//
//  AccountPageViewController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/14/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AccountPageVC: UIViewController, UITextFieldDelegate, ParentDelegate {

    @IBOutlet weak var uProfilePic: UIImageView!
    @IBOutlet weak var uNameLabel: UITextField!
    @IBOutlet weak var numAnswersLabel: UILabel!
    @IBOutlet weak var inButton: UIButton!
    @IBOutlet weak var twtrButton: UIButton!
    @IBOutlet weak var fbButton: UIButton!
    @IBOutlet weak var savedTags: UITextView!
    private lazy var settingsButton = UIButton()
    
    @IBOutlet weak var linkLinkedin: UILabel!
    @IBOutlet weak var linkTwitter: UILabel!
    @IBOutlet weak var linkFacebook: UILabel!
    
    weak var returnToParentDelegate : ParentDelegate!
    private var _nameErrorLabel = UILabel()
    
    private lazy var _defaultProfileOverlay = UILabel()
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
        let settingsVC = SettingsTableVC()
        settingsVC.returnToParentDelegate = self
        GlobalFunctions.addNewVC(settingsVC, parentVC: self)
    }
    
    func returnToParent(currentVC : UIViewController) {
        GlobalFunctions.dismissVC(currentVC)
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
            _loginHeader?.updateStatusMessage("Welcome \(_userName)")
            uNameLabel.text = _userName
            uNameLabel.userInteractionEnabled = false
        } else {
            _loginHeader?.updateStatusMessage("please login")
            uNameLabel.text = "tap to edit name"
            uNameLabel.userInteractionEnabled = true
        }
        
        if let _uPic = User.currentUser!.profilePic {
            _defaultProfileOverlay.hidden = true
            addUserProfilePic(NSURL(string: _uPic))
        } else {
            uProfilePic.image = UIImage(named: "default-profile")
            _defaultProfileOverlay.hidden = false
            _defaultProfileOverlay = UILabel(frame: CGRectMake(0, 0, uProfilePic.frame.width, uProfilePic.frame.height))
            _defaultProfileOverlay.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
            _defaultProfileOverlay.text = "tap to add image"
            _defaultProfileOverlay.setPreferredFont(UIColor.whiteColor(), alignment : .Center)
            uProfilePic.addSubview(_defaultProfileOverlay)
        }
        
        if User.currentUser!.hasSavedTags() {
            addSavedTags(User.currentUser!.savedTags!)
        }
        
        highlightConnectedSocialSources()
        numAnswersLabel.text = String(User.currentUser!.totalAnswers())
        view.setNeedsLayout()
    }
    
    private func addSavedTags(tagList : [String]) {
        let _msg = tagList.map {"#"+$0 }.joinWithSeparator("\u{0085}")
        
        savedTags.textAlignment = .Left
        savedTags.text = _msg
        savedTags.textColor = UIColor.whiteColor()
        savedTags.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)

    }
    
    private func addUserProfilePic(_userImageURL : NSURL?) {
        if let _ = _userImageURL {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let _userImageData = NSData(contentsOfURL: _userImageURL!)
                dispatch_async(dispatch_get_main_queue(), {
                    self.uProfilePic.image = UIImage(data: _userImageData!)
                    self.uProfilePic.clipsToBounds = true
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
        if User.currentUser?.socialSources[.facebook] != true {
            fbButton.alpha = 0.5
            fbButton.backgroundColor = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 1.0 )
            linkFacebook.hidden = false
        } else if User.currentUser?.socialSources[.facebook] == true {
            fbButton.alpha = 1.0
            fbButton.backgroundColor = UIColor(red: 78/255, green: 99/255, blue: 152/255, alpha: 1.0 )
            linkFacebook.hidden = true
        }
        
        if User.currentUser?.socialSources[.twitter] != true {
            twtrButton.alpha = 0.5
            twtrButton.backgroundColor = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 1.0 )
            linkTwitter.hidden = false

        }  else if User.currentUser?.socialSources[.twitter] == true {
            twtrButton.alpha = 1.0
            twtrButton.backgroundColor = UIColor(red: 58/255, green: 185/255, blue: 228/255, alpha: 1.0 )
            linkTwitter.hidden = true
        }
        
        if User.currentUser?.socialSources[.linkedin] != true {
            inButton.alpha = 0.5
            inButton.backgroundColor = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 1.0 )
            linkLinkedin.hidden = false

        }  else if User.currentUser?.socialSources[.linkedin] == true {
            inButton.alpha = 1.0
            inButton.backgroundColor = UIColor(red: 2/255, green: 116/255, blue: 179/255, alpha: 1.0 )
            linkLinkedin.hidden = true
        }
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
        
        _cameraOverlay.getButton(.Flip).addTarget(self, action: #selector(flipCamera), forControlEvents: UIControlEvents.TouchUpInside)
        _cameraOverlay.getButton(.Flash).addTarget(self, action: #selector(cycleFlash), forControlEvents: UIControlEvents.TouchUpInside)
        _cameraOverlay.updateQuestion("smile!")
    }
    
    private func addHeader() {
        view.addSubview(_headerView)
        
        _headerView.translatesAutoresizingMaskIntoConstraints = false
        _headerView.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: Spacing.xs.rawValue).active = true
        _headerView.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        _headerView.heightAnchor.constraintEqualToAnchor(view.heightAnchor, multiplier: 1/12).active = true
        _headerView.widthAnchor.constraintEqualToAnchor(view.widthAnchor).active = true
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
    
    func flipCamera() {
        if _Camera.cameraDevice == .Front {
            _Camera.cameraDevice = .Back
        } else {
            _Camera.cameraDevice = .Front
        }
    }
    
    func cycleFlash(oldButton : UIButton) {
        _Camera.changeFlashMode()
        
        switch _Camera.flashMode {
        case .Off: _cameraOverlay._flashMode =  .Off
        case .On: _cameraOverlay._flashMode = .On
        case .Auto: _cameraOverlay._flashMode = .Auto
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
                                self._defaultProfileOverlay.hidden = true
                                self._loadingOverlay.hidden = true
                                self._cameraView.removeFromSuperview()
                        })
                    }
                })
            }
        })
    }
}
