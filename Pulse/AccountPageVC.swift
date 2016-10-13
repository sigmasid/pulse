//
//  AccountPageViewController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/14/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AccountPageVC: UIViewController, UITextFieldDelegate, ParentDelegate {
    
    fileprivate var profileSummary = UIView()
    fileprivate var uProfilePic = UIImageView()
    fileprivate var uName = UITextField()
    fileprivate var uShortBio = UITextField()
    fileprivate var uMessages = UIButton()
    
    fileprivate var socialLinks = UIStackView()
    fileprivate var inButton = UIButton()
    fileprivate var twtrButton = UIButton()
    fileprivate var fbButton = UIButton()
    
    fileprivate var settingsLinks = UIStackView()
    fileprivate var sAboutButton = UIButton()
    fileprivate var sMessagesButton = UIButton()
    fileprivate var sActivityButton = UIButton()
    fileprivate var sLogoutButton = UIButton()
    fileprivate var sAnswersButton = UIButton()

    fileprivate var _nameErrorLabel = UILabel()
    
    fileprivate lazy var _defaultProfileOverlay = UILabel()
    fileprivate lazy var _cameraView = UIView()
    fileprivate lazy var _Camera = CameraManager()
    fileprivate var _cameraOverlay : CameraOverlayView!
    
    fileprivate var _loadingOverlay : LoadingView!
    fileprivate var _icon : IconContainer!
    fileprivate var _tapGesture : UITapGestureRecognizer?
    
    fileprivate var _loginHeader : LoginHeaderView!
    fileprivate var _isLoaded = false
    fileprivate var _notificationsSetup = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !_notificationsSetup {
            NotificationCenter.default.addObserver(self, selector: #selector(updateLabels), name: NSNotification.Name(rawValue: "UserUpdated"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(updateLabels), name: NSNotification.Name(rawValue: "AccountPageLoaded"), object: nil)

            _notificationsSetup = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        if !_isLoaded {
            hideKeyboardWhenTappedAround()
            view.backgroundColor = UIColor.white
            _icon = addIcon(text: "ACCOUNT")

            addHeader()
            setupProfileSummaryLayout()
            setupSocialButtonsLayout()
            setupSettingsMenuLayout()
            
            uName.delegate = self
            uName.clearsOnBeginEditing = true
            
            _tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
            uProfilePic.addGestureRecognizer(_tapGesture!)
            uProfilePic.isUserInteractionEnabled = true
            uProfilePic.contentMode = UIViewContentMode.scaleAspectFill
            
            _isLoaded = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /* TEXT FIELD DELEGATES */
    func textFieldDidBeginEditing(_ textField: UITextField) {
        _nameErrorLabel.text = ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        GlobalFunctions.validateName(uName.text, completion: {(verified, error) in
            if verified {
                Database.updateUserData(UserProfileUpdateType.displayName, value: self.uName.text!, completion: { (success, error) in
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
    
    func clickedSettings() {
        settingsLinks.isHidden = settingsLinks.isHidden ? false : true
        
//        let settingsVC = SettingsTableVC()
//        settingsVC.returnToParentDelegate = self
//        GlobalFunctions.addNewVC(settingsVC, parentVC: self)
    }
    
    func clickedProfile() {
        
    }
    
    func clickedMessages() {
        Database.getConversations(completion: { conversations in
            let inboxVC = InboxVC()
            inboxVC.conversations = conversations
            GlobalFunctions.addNewVC(inboxVC, parentVC: self)
        })
    }
    
    func clickedActivity() {
        
    }
    
    func clickedAnswers() {
        
    }
    
    func clickedLogout() {
        let confirmLogout = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .actionSheet)
        
        confirmLogout.addAction(UIAlertAction(title: "logout", style: .default, handler: { (action: UIAlertAction!) in
            Database.signOut({ success in
                if !success {
                    GlobalFunctions.showErrorBlock("Error Logging Out", erMessage: "Sorry there was an error logging out, please try again!")
                }
            })
        }))
        
        confirmLogout.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            confirmLogout.dismiss(animated: true, completion: nil)
        }))
        
        present(confirmLogout, animated: true, completion: nil)

    }
    
    func returnToParent(_ currentVC : UIViewController) {
        GlobalFunctions.dismissVC(currentVC)
    }

    fileprivate func linkAccount() {
        //check w/ social source and connect to user profile on firebase
    }
    
    fileprivate func setupErrorLabel() {
        view.addSubview(_nameErrorLabel)
        
        _nameErrorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        _nameErrorLabel.topAnchor.constraint(equalTo: uName.topAnchor).isActive = true
        _nameErrorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        _nameErrorLabel.heightAnchor.constraint(equalTo: uName.heightAnchor).isActive = true
        _nameErrorLabel.leadingAnchor.constraint(equalTo: uName.trailingAnchor, constant: 10).isActive = true
        
        _nameErrorLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption2)
        _nameErrorLabel.backgroundColor = UIColor.gray
        _nameErrorLabel.textColor = UIColor.black
        _nameErrorLabel.textAlignment = .left
    }
    
    fileprivate func updateErrorLabelText(_ _errorText : String) {
        _nameErrorLabel.text = _errorText
    }
    
    func updateLabels(_ notification: Notification) {
        if let _userName = User.currentUser!.name {
            _loginHeader?.updateStatusMessage(_message: "Welcome \(_userName)")
            uName.text = _userName
            uName.isUserInteractionEnabled = false
        } else {
            _loginHeader?.updateStatusMessage(_message: "please login")
            uName.text = "tap to edit name"
            uName.isUserInteractionEnabled = true
        }
        
        if let _userBio = User.currentUser!.shortBio {
            uShortBio.text = _userBio
            uShortBio.isUserInteractionEnabled = false
        } else {
            uShortBio.text = "tap to edit bio"
            uShortBio.isUserInteractionEnabled = true
        }
        
        //add profile pic or use default image
        if User.currentUser!.profilePic != nil || User.currentUser!.thumbPic != nil {
            let _uPic = User.currentUser!.thumbPic != nil ? User.currentUser!.thumbPic : User.currentUser!.profilePic
            _defaultProfileOverlay.isHidden = true
            addUserProfilePic(URL(string: _uPic!))
        } else {
            uProfilePic.image = UIImage(named: "default-profile")
            _defaultProfileOverlay.isHidden = false
            _defaultProfileOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            _defaultProfileOverlay.text = "tap to add image"
            _defaultProfileOverlay.setPreferredFont(UIColor.white, alignment : .center)
            uProfilePic.addSubview(_defaultProfileOverlay)
        }
        
        if User.currentUser!.hasSavedTags() {
        }
        
        highlightConnectedSocialSources()
        view.setNeedsLayout()
    }
    
    fileprivate func addUserProfilePic(_ _userImageURL : URL?) {
        if let _ = _userImageURL {
            DispatchQueue.global().async {
                if let _userImageData = try? Data(contentsOf: _userImageURL!) {
                    User.currentUser?.thumbPicImage = UIImage(data: _userImageData)
                    DispatchQueue.main.async(execute: {
                        print("got image for user")
                        self.uProfilePic.image = User.currentUser?.thumbPicImage
                        self.uProfilePic.clipsToBounds = true
                    })
                }
            }
        }
    }
    
    
    fileprivate func highlightConnectedSocialSources() {
        if User.currentUser?.socialSources[.facebook] != true {
            fbButton.alpha = 0.5
            fbButton.backgroundColor = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 1.0 )
        } else if User.currentUser?.socialSources[.facebook] == true {
            fbButton.alpha = 1.0
            fbButton.backgroundColor = UIColor(red: 78/255, green: 99/255, blue: 152/255, alpha: 1.0 )
        }
        
        if User.currentUser?.socialSources[.twitter] != true {
            twtrButton.alpha = 0.5
            twtrButton.backgroundColor = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 1.0 )
        }  else if User.currentUser?.socialSources[.twitter] == true {
            twtrButton.alpha = 1.0
            twtrButton.backgroundColor = UIColor(red: 58/255, green: 185/255, blue: 228/255, alpha: 1.0 )
        }
        
        if User.currentUser?.socialSources[.linkedin] != true {
            inButton.alpha = 0.5
            inButton.backgroundColor = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 1.0 )
        }  else if User.currentUser?.socialSources[.linkedin] == true {
            inButton.alpha = 1.0
            inButton.backgroundColor = UIColor(red: 2/255, green: 116/255, blue: 179/255, alpha: 1.0 )
        }
    }
    
    fileprivate func setupLoading() {
        _loadingOverlay = LoadingView(frame: view.bounds, backgroundColor : UIColor.black.withAlphaComponent(0.7))
        view.addSubview(_loadingOverlay)
    }
    
    /* CAMERA FUNCTIONS */
    func handleImageTap() {
        setupCamera()
        setupCameraOverlay()
        setupLoading()
    }
    
    fileprivate func setupCamera() {
        _cameraView = UIView(frame: view.bounds)
        _cameraView.backgroundColor = UIColor.white
        view.addSubview(_cameraView)
        
        _Camera.showAccessPermissionPopupAutomatically = true
        _Camera.shouldRespondToOrientationChanges = false
        _Camera.cameraDevice = .front
        
        _ = _Camera.addPreviewLayerToView(_cameraView, newCameraOutputMode: .stillImage, completition: {() in
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2, animations: { self._loadingOverlay.alpha = 0.0 } ,
                    completion: {(value: Bool) in
                        self._loadingOverlay.removeFromSuperview()
                })
                self._cameraOverlay.getButton(.shutter).isEnabled = true
            }
        })
        
        _Camera.showErrorBlock = { [weak self] (erTitle: String, erMessage: String) -> Void in
            
            let alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (alertAction) -> Void in  }))
            
            self?.present(alertController, animated: true, completion: nil)
        }
    }
    
    fileprivate func setupCameraOverlay() {
        _cameraOverlay = CameraOverlayView(frame: view.bounds)
        _cameraView.addSubview(_cameraOverlay)
        
        switch _Camera.flashMode {
        case .off: _cameraOverlay._flashMode =  .off
        case .on: _cameraOverlay._flashMode = .on
        case .auto: _cameraOverlay._flashMode = .auto
        }
        
        _cameraOverlay.getButton(.shutter).addTarget(self, action: #selector(gotImage), for: UIControlEvents.touchUpInside)
        _cameraOverlay.getButton(.shutter).isEnabled = false
        
        _cameraOverlay.getButton(.flip).addTarget(self, action: #selector(flipCamera), for: UIControlEvents.touchUpInside)
        _cameraOverlay.getButton(.flash).addTarget(self, action: #selector(cycleFlash), for: UIControlEvents.touchUpInside)
        _cameraOverlay.updateQuestion("smile!")
    }
    
    func flipCamera() {
        if _Camera.cameraDevice == .front {
            _Camera.cameraDevice = .back
        } else {
            _Camera.cameraDevice = .front
        }
    }
    
    func cycleFlash(_ oldButton : UIButton) {
        let newFlashMode = _Camera.changeFlashMode()
        
        switch newFlashMode {
        case .off: _cameraOverlay._flashMode =  .off
        case .on: _cameraOverlay._flashMode = .on
        case .auto: _cameraOverlay._flashMode = .auto
        }
    }
    
    func gotImage() {
        setupLoading()

        _cameraOverlay.getButton(.shutter).isEnabled = false
        _loadingOverlay.addIcon(IconSizes.medium, _iconColor: UIColor.white, _iconBackgroundColor: nil)
        _loadingOverlay.addMessage("saving! just a sec...", _color: UIColor.white)
        
        _Camera.capturePictureDataWithCompletition({ (imageData, error) -> Void in
            if let errorOccured = error {
                self._Camera.showErrorBlock("Error occurred", errorOccured.localizedDescription)
                self._cameraOverlay.getButton(.shutter).isEnabled = true
            } else {
                Database.uploadProfileImage(imageData!, completion: {(URL, error) in
                    if error != nil {
                        self._Camera.showErrorBlock("Error occurred", error!.localizedDescription)
                        self._cameraOverlay.getButton(.shutter).isEnabled = true
                        self._loadingOverlay.removeFromSuperview()
                    } else {
                        self._Camera.stopAndRemoveCaptureSession()
                        UIView.animate(withDuration: 0.2, animations: { self._cameraView.alpha = 0.0 } ,
                            completion: {(value: Bool) in
                                self._defaultProfileOverlay.isHidden = true
                                self._loadingOverlay.isHidden = true
                                self._cameraView.removeFromSuperview()
                        })
                    }
                })
            }
        })
    }
    
    /* LAYOUT FUNCTION */
    fileprivate func addHeader() {
        _loginHeader = addHeader(text: "PROFILE")
        _loginHeader.addSettingsButton()
        _loginHeader._settings.addTarget(self, action: #selector(clickedSettings), for: UIControlEvents.touchUpInside)
    }
    
    fileprivate func updateProfileSummaryLayout() {
        
    }
    
    fileprivate func setupProfileSummaryLayout() {
        view.addSubview(profileSummary)
        
        profileSummary.translatesAutoresizingMaskIntoConstraints = false
        profileSummary.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85).isActive = true
        profileSummary.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        profileSummary.heightAnchor.constraint(equalToConstant: view.frame.height * 0.2).isActive = true
        profileSummary.topAnchor.constraint(equalTo: _loginHeader.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        profileSummary.layoutIfNeeded()
        
        profileSummary.addSubview(uProfilePic)
        profileSummary.addSubview(uName)
        profileSummary.addSubview(uShortBio)
        profileSummary.addSubview(uMessages)
        
        uProfilePic.translatesAutoresizingMaskIntoConstraints = false
        uProfilePic.widthAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        uProfilePic.heightAnchor.constraint(equalTo: uProfilePic.widthAnchor).isActive = true
        uProfilePic.centerXAnchor.constraint(equalTo: profileSummary.centerXAnchor).isActive = true
        uProfilePic.topAnchor.constraint(equalTo: profileSummary.topAnchor, constant: Spacing.xs.rawValue).isActive = true
        uProfilePic.layoutIfNeeded()
        
        uName.translatesAutoresizingMaskIntoConstraints = false
        uName.topAnchor.constraint(equalTo: uProfilePic.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        uName.widthAnchor.constraint(equalTo: profileSummary.widthAnchor).isActive = true
        uName.centerXAnchor.constraint(equalTo: profileSummary.centerXAnchor).isActive = true
        uName.heightAnchor.constraint(equalToConstant: Spacing.s.rawValue).isActive = true
        uName.layoutIfNeeded()
        uName.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightHeavy)

        uShortBio.translatesAutoresizingMaskIntoConstraints = false
        uShortBio.topAnchor.constraint(equalTo: uName.bottomAnchor).isActive = true
        uShortBio.widthAnchor.constraint(equalTo: profileSummary.widthAnchor).isActive = true
        uShortBio.centerXAnchor.constraint(equalTo: profileSummary.centerXAnchor).isActive = true
        uShortBio.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        uShortBio.layoutIfNeeded()
        uShortBio.font = UIFont.systemFont(ofSize: FontSizes.caption.rawValue, weight: UIFontWeightMedium)

        uMessages.translatesAutoresizingMaskIntoConstraints = false
        uMessages.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue * 0.8).isActive = true
        uMessages.heightAnchor.constraint(equalTo: uMessages.widthAnchor).isActive = true
        uMessages.leadingAnchor.constraint(equalTo: uProfilePic.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
        uMessages.bottomAnchor.constraint(equalTo: uProfilePic.topAnchor, constant: Spacing.s.rawValue).isActive = true
        uMessages.layoutIfNeeded()
        
        uMessages.titleEdgeInsets = UIEdgeInsetsMake(0, 0, uMessages.frame.height / 4, 0)
        uMessages.titleLabel!.font = UIFont.systemFont(ofSize: FontSizes.body2.rawValue, weight: UIFontWeightHeavy)
        uMessages.titleLabel!.textColor = UIColor.white
        uMessages.titleLabel!.textAlignment = .center
        uMessages.setBackgroundImage(UIImage(named: "count-label"), for: UIControlState())
        uMessages.imageView?.contentMode = .scaleAspectFit
        uMessages.titleLabel?.sizeToFit()
        
        uProfilePic.layer.cornerRadius = 5
        uProfilePic.clipsToBounds = true
        uProfilePic.layer.masksToBounds = true

        uName.textAlignment = .center
        uShortBio.textAlignment = .center
    }
    
    fileprivate func setupSocialButtonsLayout() {
        view.addSubview(socialLinks)
        
        socialLinks.translatesAutoresizingMaskIntoConstraints = false
        socialLinks.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue * 3 + Spacing.m.rawValue * 2).isActive = true
        socialLinks.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        socialLinks.bottomAnchor.constraint(equalTo: _icon.topAnchor).isActive = true
        socialLinks.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        socialLinks.layoutIfNeeded()
    
        fbButton.setImage(UIImage(named: "facebook-icon"), for: UIControlState())
        twtrButton.setImage(UIImage(named: "twitter-icon"), for: UIControlState())
        inButton.setImage(UIImage(named: "linkedin-icon"), for: UIControlState())
        
        fbButton.backgroundColor = UIColor(red: 78/255, green: 99/255, blue: 152/255, alpha: 1.0)
        twtrButton.backgroundColor = UIColor(red: 58/255, green: 185/255, blue: 228/255, alpha: 1.0)
        inButton.backgroundColor = UIColor(red: 2/255, green: 116/255, blue: 179/255, alpha: 1.0)
        
        socialLinks.addArrangedSubview(fbButton)
        socialLinks.addArrangedSubview(twtrButton)
        socialLinks.addArrangedSubview(inButton)
        
        fbButton.translatesAutoresizingMaskIntoConstraints = false
        fbButton.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        fbButton.widthAnchor.constraint(equalTo: fbButton.heightAnchor).isActive = true
        
        twtrButton.translatesAutoresizingMaskIntoConstraints = false
        twtrButton.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        twtrButton.widthAnchor.constraint(equalTo: twtrButton.heightAnchor).isActive = true
        
        inButton.translatesAutoresizingMaskIntoConstraints = false
        inButton.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        inButton.widthAnchor.constraint(equalTo: inButton.heightAnchor).isActive = true
        
        socialLinks.alignment = .center
        socialLinks.distribution = .fillEqually
        socialLinks.spacing = Spacing.m.rawValue
        
        fbButton.layoutIfNeeded()
        twtrButton.layoutIfNeeded()
        inButton.layoutIfNeeded()
        
        fbButton.makeRound()
        twtrButton.makeRound()
        inButton.makeRound()
    }
    
    fileprivate func setupSettingsMenuLayout() {
        view.addSubview(settingsLinks)
        
        settingsLinks.translatesAutoresizingMaskIntoConstraints = false
        settingsLinks.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.1).isActive = true
        settingsLinks.topAnchor.constraint(equalTo: _loginHeader.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        settingsLinks.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        settingsLinks.layoutIfNeeded()
        
//        let logoutImage = UIImage(cgImage: UIImage(named: "login")!.cgImage!, scale: CGFloat(1.0), orientation: .downMirrored)

        sAboutButton.setImage(UIImage(named: "profile"), for: UIControlState())
        sMessagesButton.setImage(UIImage(named: "messenger"), for: UIControlState())
        sActivityButton.setImage(UIImage(named: "messenger"), for: UIControlState())
        sAnswersButton.setImage(UIImage(named: "messenger"), for: UIControlState())
        sLogoutButton.setImage(UIImage(named: "login"), for: UIControlState())
        
        sAboutButton.setTitle("PROFILE", for: UIControlState())
        sMessagesButton.setTitle("MESSAGES", for: UIControlState())
        sActivityButton.setTitle("ACTIVITY", for: UIControlState())
        sAnswersButton.setTitle("ANSWERS", for: UIControlState())
        sLogoutButton.setTitle("LOGOUT", for: UIControlState())
        
        sAboutButton.addTarget(self, action: #selector(clickedProfile), for: .touchUpInside)
        sMessagesButton.addTarget(self, action: #selector(clickedMessages), for: .touchUpInside)
        sActivityButton.addTarget(self, action: #selector(clickedActivity), for: .touchUpInside)
        sActivityButton.addTarget(self, action: #selector(clickedAnswers), for: .touchUpInside)
        sLogoutButton.addTarget(self, action: #selector(clickedLogout), for: .touchUpInside)
        
        sAboutButton.setButtonFont(FontSizes.caption2.rawValue, weight: UIFontWeightMedium, color: .black, alignment: .center)
        sMessagesButton.setButtonFont(FontSizes.caption2.rawValue, weight: UIFontWeightMedium, color: .black, alignment: .center)
        sActivityButton.setButtonFont(FontSizes.caption2.rawValue, weight: UIFontWeightMedium, color: .black, alignment: .center)
        sAnswersButton.setButtonFont(FontSizes.caption2.rawValue, weight: UIFontWeightMedium, color: .black, alignment: .center)
        sLogoutButton.setButtonFont(FontSizes.caption2.rawValue, weight: UIFontWeightMedium, color: .black, alignment: .center)

        sAboutButton.translatesAutoresizingMaskIntoConstraints = false
        sAboutButton.widthAnchor.constraint(equalTo: sAboutButton.heightAnchor).isActive = true
        sMessagesButton.translatesAutoresizingMaskIntoConstraints = false
        sMessagesButton.widthAnchor.constraint(equalTo: sMessagesButton.heightAnchor).isActive = true
        sActivityButton.translatesAutoresizingMaskIntoConstraints = false
        sActivityButton.widthAnchor.constraint(equalTo: sActivityButton.heightAnchor).isActive = true
        sAnswersButton.translatesAutoresizingMaskIntoConstraints = false
        sAnswersButton.widthAnchor.constraint(equalTo: sAnswersButton.heightAnchor).isActive = true
        sLogoutButton.translatesAutoresizingMaskIntoConstraints = false
        sLogoutButton.widthAnchor.constraint(equalTo: sLogoutButton.heightAnchor).isActive = true
        
        sAboutButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, Spacing.xs.rawValue, Spacing.xs.rawValue)
        sMessagesButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, Spacing.xs.rawValue, Spacing.xs.rawValue)
        sActivityButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, Spacing.xs.rawValue, Spacing.xs.rawValue)
        sAnswersButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, Spacing.xs.rawValue, Spacing.xs.rawValue)
        sLogoutButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, Spacing.xs.rawValue, Spacing.xs.rawValue)
        
        settingsLinks.addArrangedSubview(sAboutButton)
        settingsLinks.addArrangedSubview(sMessagesButton)
        settingsLinks.addArrangedSubview(sActivityButton)
        settingsLinks.addArrangedSubview(sAnswersButton)
        settingsLinks.addArrangedSubview(sLogoutButton)
        
        sAboutButton.titleEdgeInsets = UIEdgeInsetsMake(0, -settingsLinks.frame.width - Spacing.xxs.rawValue, -settingsLinks.frame.width, 0)
        sMessagesButton.titleEdgeInsets = UIEdgeInsetsMake(0, -settingsLinks.frame.width - Spacing.xxs.rawValue, -settingsLinks.frame.width, 0)
        sActivityButton.titleEdgeInsets = UIEdgeInsetsMake(0, -settingsLinks.frame.width - Spacing.xxs.rawValue, -settingsLinks.frame.width, 0)
        sAnswersButton.titleEdgeInsets = UIEdgeInsetsMake(0, -settingsLinks.frame.width - Spacing.xxs.rawValue, -settingsLinks.frame.width, 0)
        sLogoutButton.titleEdgeInsets = UIEdgeInsetsMake(0, -settingsLinks.frame.width - Spacing.xxs.rawValue, -settingsLinks.frame.width, 0)
        
        settingsLinks.axis = .vertical
        settingsLinks.alignment = .top
        settingsLinks.distribution = .fillEqually
        settingsLinks.spacing = Spacing.m.rawValue
        
        settingsLinks.isHidden = true
    }
}
