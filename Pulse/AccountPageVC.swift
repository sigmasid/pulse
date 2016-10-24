//
//  AccountPageViewController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/14/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

protocol accountDelegate: class {
    func userClickedCamera()
    func updateNav(title : String)
}

class AccountPageVC: UIViewController, accountDelegate {
    
    fileprivate var nav : NavVC?
    fileprivate var profileSummary = ProfileSummary()
    fileprivate var profileSettingsVC : SettingsTableVC!
    fileprivate var settingsLinks : AccountPageMenu!
    fileprivate var answersVC : FeedVC!

    fileprivate lazy var cameraView = UIView()
    fileprivate lazy var Camera = CameraManager()
    fileprivate var cameraOverlay : CameraOverlayView!
    
    fileprivate var loadingOverlay : LoadingView!
    fileprivate var icon : IconContainer!
    
    fileprivate var isLoaded = false
    fileprivate var notificationsSetup = false
    fileprivate var isShowingAnswers = false
    
    fileprivate var leadingProfileConstraint : NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let _nav = navigationController as? NavVC {
            nav = _nav
        }
    }
    
    override func viewDidLayoutSubviews() {
        if !isLoaded {
            
            view.backgroundColor = UIColor.white
            automaticallyAdjustsScrollViewInsets = false

            icon = addIcon(text: "ACCOUNT")
            
            setupProfileSummary()
            setupSettingsMenuLayout() //needs to be top layer
            setupLoading()
            
            profileSummary.delegate = self
            profileSummary.updateLabels()

            if !notificationsSetup {
                NotificationCenter.default.addObserver(self, selector: #selector(updateLabels), name: NSNotification.Name(rawValue: "UserUpdated"), object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(updateLabels), name: NSNotification.Name(rawValue: "AccountPageLoaded"), object: nil)
                
                notificationsSetup = true
            }
            
            isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("view will appear fired")
        updateHeader(title: "PROFILE", leftButton: .menu)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if settingsLinks != nil {
            settingsLinks.setSelectedButton(type: nil)
            settingsLinks.isHidden = true
        }
        
        if isShowingAnswers {
            GlobalFunctions.dismissVC(answersVC)
            isShowingAnswers = false
        }
    }
    
    func updateLabels(_ notification: Notification) {
        profileSummary.updateLabels()
    }
    
    
    /* HANDLE SETTINGS MENU SELECTIONS */
    func clickedMenu() {
        settingsLinks.isHidden = settingsLinks.isHidden ? false : true
    }
    
    func clickedSettings() {
        settingsLinks.setSelectedButton(type: .settings)
        
        profileSettingsVC = SettingsTableVC()
        profileSettingsVC.settingSection = "account"
        navigationController?.pushViewController(profileSettingsVC, animated: true)
    }
    
    func clickedProfile() {
        settingsLinks.setSelectedButton(type: .profile)
        
        profileSettingsVC = SettingsTableVC()
        profileSettingsVC.settingSection = "personalInfo"
        navigationController?.pushViewController(profileSettingsVC, animated: true)
    }
    
    func clickedMessages() {
        settingsLinks.setSelectedButton(type: .messages)

        Database.getConversations(completion: { conversations in
            let inboxVC = InboxVC()
            inboxVC.conversations = conversations
            self.navigationController?.pushViewController(inboxVC, animated: true)
        })
    }
    
    func clickedActivity() {
        settingsLinks.setSelectedButton(type: .activity)

    }
    
    func clickedAnswers() {
        settingsLinks.setSelectedButton(type: .answers)
        
        answersVC = FeedVC()
        GlobalFunctions.addNewVC(answersVC, parentVC: self)
        isShowingAnswers = true

        answersVC.view.translatesAutoresizingMaskIntoConstraints = false
        answersVC.view.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        answersVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        answersVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        answersVC.view.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        answersVC.view.layoutIfNeeded()
        
        toggleLoading(show: true, message: "Loading your answers...")
        updateHeader(title: "Your Answers", leftButton: .back)

        if let _user = User.currentUser {
            Database.getUserAnswerIDs(uID: _user.uID!, completion: { answers in
                if answers.count > 0 {
                    self.answersVC.selectedUser = _user
                    self.answersVC.allAnswers = answers
                    self.answersVC.feedItemType = .answer

                    self.toggleLoading(show: false, message: nil)
                }
                else {
                    self.toggleLoading(show: true, message: "You haven't shared any answers yet")
                    UIView.animate(withDuration: 0.1, animations: { self.loadingOverlay.alpha = 0.0 } ,
                                   completion: {(value: Bool) in
                                    self.toggleLoading(show: false, message: nil)
                    })
                }
            })
        }
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
    
    func goBack() {
        GlobalFunctions.dismissVC(answersVC)
        isShowingAnswers = false
    }
    
    fileprivate func setupLoading() {
        loadingOverlay = LoadingView(frame: view.bounds, backgroundColor : UIColor.white.withAlphaComponent(0.7))
        loadingOverlay.addIcon(IconSizes.medium, _iconColor: UIColor.black, _iconBackgroundColor: nil)
        loadingOverlay.isHidden = true

        view.addSubview(loadingOverlay)
    }
    
    fileprivate func toggleLoading(show: Bool, message: String?) {
        loadingOverlay?.isHidden = show ? false : true
        loadingOverlay?.addMessage(message)
    }

    /* DELEGATE METHODS */
    func userClickedCamera() {
        setupCamera()
        setupCameraOverlay()
        toggleLoading(show: true, message: "Smile!")
    }
    
    func updateNav(title : String) {
        nav?.updateTitle(title: title)
    }
    
    /* CAMERA FUNCTIONS */
    fileprivate func setupCamera() {
        cameraView = UIView(frame: view.bounds)
        cameraView.backgroundColor = UIColor.white
        nav?.toggleLogo(mode: .none)
        nav?.toggleStatus(show: false)
        view.addSubview(cameraView)
        
        Camera.showAccessPermissionPopupAutomatically = true
        Camera.shouldRespondToOrientationChanges = false
        Camera.cameraDevice = .front
        
        _ = Camera.addPreviewLayerToView(cameraView, newCameraOutputMode: .stillImage, completition: {() in
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2, animations: { self.loadingOverlay.alpha = 0.0 } ,
                    completion: {(value: Bool) in
                        self.toggleLoading(show: false, message: nil)
                })
                self.cameraOverlay.getButton(.shutter).isEnabled = true
            }
        })
        
        Camera.showErrorBlock = { [weak self] (erTitle: String, erMessage: String) -> Void in
            
            let alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (alertAction) -> Void in  }))
            
            self?.present(alertController, animated: true, completion: nil)
        }
    }
    
    fileprivate func setupCameraOverlay() {
        cameraOverlay = CameraOverlayView(frame: view.bounds)
        cameraView.addSubview(cameraOverlay)
        
        switch Camera.flashMode {
        case .off: cameraOverlay._flashMode =  .off
        case .on: cameraOverlay._flashMode = .on
        case .auto: cameraOverlay._flashMode = .auto
        }
        
        cameraOverlay.getButton(.shutter).addTarget(self, action: #selector(gotImage), for: UIControlEvents.touchUpInside)
        cameraOverlay.getButton(.shutter).isEnabled = false
        
        cameraOverlay.getButton(.flip).addTarget(self, action: #selector(flipCamera), for: UIControlEvents.touchUpInside)
        cameraOverlay.getButton(.flash).addTarget(self, action: #selector(cycleFlash), for: UIControlEvents.touchUpInside)
        cameraOverlay.updateTitle("smile!")
    }
    
    func flipCamera() {
        if Camera.cameraDevice == .front {
            Camera.cameraDevice = .back
        } else {
            Camera.cameraDevice = .front
        }
    }
    
    func cycleFlash(_ oldButton : UIButton) {
        let newFlashMode = Camera.changeFlashMode()
        
        switch newFlashMode {
        case .off: cameraOverlay._flashMode =  .off
        case .on: cameraOverlay._flashMode = .on
        case .auto: cameraOverlay._flashMode = .auto
        }
    }
    
    func gotImage() {
        setupLoading()

        cameraOverlay.getButton(.shutter).isEnabled = false
        toggleLoading(show: true, message: "saving! just a sec...")
        
        Camera.capturePictureDataWithCompletition({ (imageData, error) -> Void in
            if let errorOccured = error {
                self.Camera.showErrorBlock("Error occurred", errorOccured.localizedDescription)
                self.cameraOverlay.getButton(.shutter).isEnabled = true
            } else {
                Database.uploadProfileImage(imageData!, completion: {(URL, error) in
                    if error != nil {
                        self.Camera.showErrorBlock("Error occurred", error!.localizedDescription)
                        self.cameraOverlay.getButton(.shutter).isEnabled = true
                        self.toggleLoading(show: false, message: nil)
                    } else {
                        self.Camera.stopAndRemoveCaptureSession()
                        UIView.animate(withDuration: 0.2, animations: { self.cameraView.alpha = 0.0 } ,
                            completion: {(value: Bool) in
                                self.toggleLoading(show: false, message: nil)
                                self.cameraView.removeFromSuperview()
                                self.nav?.toggleLogo(mode: .full)
                                self.nav?.toggleStatus(show: true)
                                self.profileSummary.updateLabels()
                        })
                    }
                })
            }
        })
    }
    
    /* LAYOUT FUNCTION */
    fileprivate func updateHeader(title : String, leftButton : ButtonType) {
        if parent?.navigationController != nil {
            
            if leftButton == .menu {
                let button = NavVC.getButton(type: .menu)
                button.addTarget(self, action: #selector(clickedMenu), for: UIControlEvents.touchUpInside)
                parent?.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
            } else if leftButton == .back {
                print("left button is back)")
                let button = NavVC.getButton(type: .back)
                button.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
                parent?.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
            }
        }
        
        if let nav = navigationController as? NavVC {
            print("got nav with title \(title)")
            nav.updateBackgroundImage(image: GlobalFunctions.imageWithColor(.red))
            nav.updateTitle(title: title)
            nav.toggleLogo(mode: .full)
        } else {
            parent?.title = title
        }
    }
    
    fileprivate func setupProfileSummary() {
        view.addSubview(profileSummary)
        
        profileSummary.translatesAutoresizingMaskIntoConstraints = false
        leadingProfileConstraint = profileSummary.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0)
        leadingProfileConstraint.isActive = true
        
        profileSummary.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        profileSummary.bottomAnchor.constraint(equalTo: icon.topAnchor).isActive = true
        profileSummary.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        profileSummary.layoutIfNeeded()
    }
    
    fileprivate func setupSettingsMenuLayout() {
        settingsLinks = AccountPageMenu(frame: CGRect.zero)
        view.addSubview(settingsLinks)
        
        settingsLinks.translatesAutoresizingMaskIntoConstraints = false
        settingsLinks.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.15).isActive = true
        settingsLinks.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        settingsLinks.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        settingsLinks.layoutIfNeeded()
        
        settingsLinks.setupSettingsMenuLayout()
        
        settingsLinks.getButton(type: .profile).addTarget(self, action: #selector(clickedProfile), for: .touchUpInside)
        settingsLinks.getButton(type: .messages).addTarget(self, action: #selector(clickedMessages), for: .touchUpInside)
        settingsLinks.getButton(type: .activity).addTarget(self, action: #selector(clickedActivity), for: .touchUpInside)
        settingsLinks.getButton(type: .answers).addTarget(self, action: #selector(clickedAnswers), for: .touchUpInside)
        settingsLinks.getButton(type: .settings).addTarget(self, action: #selector(clickedSettings), for: .touchUpInside)
        settingsLinks.getButton(type: .logout).addTarget(self, action: #selector(clickedLogout), for: .touchUpInside)
        
        clickedMenu()

    }
}
