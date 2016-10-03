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
    fileprivate lazy var settingsButton = UIButton()
    
    @IBOutlet weak var linkLinkedin: UILabel!
    @IBOutlet weak var linkTwitter: UILabel!
    @IBOutlet weak var linkFacebook: UILabel!
    
    fileprivate var _nameErrorLabel = UILabel()
    
    fileprivate lazy var _defaultProfileOverlay = UILabel()
    fileprivate lazy var _cameraView = UIView()
    fileprivate lazy var _Camera = CameraManager()
    fileprivate var _cameraOverlay : CameraOverlayView!
    
    fileprivate var _loadingOverlay : LoadingView!
    fileprivate var _tapGesture : UITapGestureRecognizer?
    
    fileprivate lazy var _headerView = UIView()
    fileprivate var _loginHeader : LoginHeaderView!
    fileprivate var _loaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        hideKeyboardWhenTappedAround()
        
        if !_loaded {
            addHeader()
            
            fbButton.makeRound()
            twtrButton.makeRound()
            inButton.makeRound()
            
            uNameLabel.delegate = self
            uNameLabel.clearsOnBeginEditing = true
            
            NotificationCenter.default.addObserver(self, selector: #selector(updateLabels), name: NSNotification.Name(rawValue: "UserUpdated"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(updateLabels), name: NSNotification.Name(rawValue: "AccountPageLoaded"), object: nil)
            
            _tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
            uProfilePic.addGestureRecognizer(_tapGesture!)
            uProfilePic.isUserInteractionEnabled = true
            uProfilePic.contentMode = UIViewContentMode.scaleAspectFill
            
            _loaded = true
            addIcon(text: "ACCOUNT")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        _nameErrorLabel.text = ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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
    
    func returnToParent(_ currentVC : UIViewController) {
        GlobalFunctions.dismissVC(currentVC)
    }

    @IBAction func LinkAccount(_ sender: UIButton) {
        //check w/ social source and connect to user profile on firebase
    }
    
    fileprivate func setupErrorLabel() {
        view.addSubview(_nameErrorLabel)
        
        _nameErrorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        _nameErrorLabel.topAnchor.constraint(equalTo: uNameLabel.topAnchor).isActive = true
        _nameErrorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        _nameErrorLabel.heightAnchor.constraint(equalTo: uNameLabel.heightAnchor).isActive = true
        _nameErrorLabel.leadingAnchor.constraint(equalTo: uNameLabel.trailingAnchor, constant: 10).isActive = true
        
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
            uNameLabel.text = _userName
            uNameLabel.isUserInteractionEnabled = false
        } else {
            _loginHeader?.updateStatusMessage(_message: "please login")
            uNameLabel.text = "tap to edit name"
            uNameLabel.isUserInteractionEnabled = true
        }
        
        if let _uPic = User.currentUser!.profilePic {
            _defaultProfileOverlay = UILabel(frame: uProfilePic.bounds)
            _defaultProfileOverlay.isHidden = true
            addUserProfilePic(URL(string: _uPic))
        } else {
            uProfilePic.image = UIImage(named: "default-profile")
            _defaultProfileOverlay.isHidden = false
            _defaultProfileOverlay = UILabel(frame: uProfilePic.bounds)
            _defaultProfileOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            _defaultProfileOverlay.text = "tap to add image"
            _defaultProfileOverlay.setPreferredFont(UIColor.white, alignment : .center)
            uProfilePic.addSubview(_defaultProfileOverlay)
        }
        
        if User.currentUser!.hasSavedTags() {
            addSavedTags(User.currentUser!.savedTags)
        }
        
        highlightConnectedSocialSources()
        numAnswersLabel.text = String(User.currentUser!.totalAnswers())
        view.setNeedsLayout()
    }
    
    fileprivate func addSavedTags(_ tagList : [String : String?]) {
        let _msg = tagList.map { (key, value) in "#"+key }.joined(separator: "\u{0085}")
        
//        let _msg = tagList.map {"#"+$0 }.joinWithSeparator("\u{0085}")
        
        savedTags.textAlignment = .left
        savedTags.text = _msg
//        savedTags.textColor = UIColor.white
        savedTags.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption2)

    }
    
    fileprivate func addUserProfilePic(_ _userImageURL : URL?) {
        if let _ = _userImageURL {
            DispatchQueue.global().async {
                let _userImageData = try? Data(contentsOf: _userImageURL!)
                DispatchQueue.main.async(execute: {
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
    
    fileprivate func highlightConnectedSocialSources() {
        if User.currentUser?.socialSources[.facebook] != true {
            fbButton.alpha = 0.5
            fbButton.backgroundColor = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 1.0 )
            linkFacebook.isHidden = false
        } else if User.currentUser?.socialSources[.facebook] == true {
            fbButton.alpha = 1.0
            fbButton.backgroundColor = UIColor(red: 78/255, green: 99/255, blue: 152/255, alpha: 1.0 )
            linkFacebook.isHidden = true
        }
        
        if User.currentUser?.socialSources[.twitter] != true {
            twtrButton.alpha = 0.5
            twtrButton.backgroundColor = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 1.0 )
            linkTwitter.isHidden = false

        }  else if User.currentUser?.socialSources[.twitter] == true {
            twtrButton.alpha = 1.0
            twtrButton.backgroundColor = UIColor(red: 58/255, green: 185/255, blue: 228/255, alpha: 1.0 )
            linkTwitter.isHidden = true
        }
        
        if User.currentUser?.socialSources[.linkedin] != true {
            inButton.alpha = 0.5
            inButton.backgroundColor = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 1.0 )
            linkLinkedin.isHidden = false

        }  else if User.currentUser?.socialSources[.linkedin] == true {
            inButton.alpha = 1.0
            inButton.backgroundColor = UIColor(red: 2/255, green: 116/255, blue: 179/255, alpha: 1.0 )
            linkLinkedin.isHidden = true
        }
    }
    
    fileprivate func setupLoading() {
        _loadingOverlay = LoadingView(frame: view.bounds, backgroundColor : UIColor.black.withAlphaComponent(0.7))
        view.addSubview(_loadingOverlay)
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
    
    fileprivate func addHeader() {
        _loginHeader = addHeader(text: "PROFILE")
        _loginHeader.addSettingsButton()
        _loginHeader._settings.addTarget(self, action: #selector(ClickedSettings), for: UIControlEvents.touchUpInside)
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
}
