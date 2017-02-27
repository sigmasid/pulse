//
//  AccountPageViewController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/14/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import MobileCoreServices

protocol accountDelegate: class {
    func userClickedCamera()
    func updateNav(title : String?, image: UIImage?)
}

class AccountPageVC: UIViewController, accountDelegate, cameraDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    fileprivate var nav : PulseNavVC?
    fileprivate var profileSummary = ProfileSummary()
    fileprivate var profileSettingsVC : SettingsTableVC!
    fileprivate var settingsLinks : AccountPageMenu!
    fileprivate lazy var browseItemsVC : BrowseCollectionVC = BrowseCollectionVC(collectionViewLayout: GlobalFunctions.getPulseCollectionLayout())

    fileprivate var cameraVC : CameraVC!
    fileprivate var panDismissInteractionController = PanContainerInteractionController()

    fileprivate var loadingOverlay : LoadingView!
    //fileprivate var icon : IconContainer!
    
    fileprivate var isLoaded = false
    fileprivate var notificationsSetup = false
    fileprivate var isShowingAnswers = false
    
    fileprivate var leadingProfileConstraint : NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let _nav = navigationController as? PulseNavVC {
            nav = _nav
        }
    }
    
    override func viewDidLayoutSubviews() {
        if !isLoaded {
            view.backgroundColor = UIColor.white
            //icon = addIcon(text: "ACCOUNT")
            
            setupProfileSummary()
            setupSettingsMenuLayout() //needs to be top layer
            setupLoading()
            
            profileSummary.delegate = self
            profileSummary.updateLabels()

            if !notificationsSetup {
                NotificationCenter.default.addObserver(self, selector: #selector(updateLabels), name: NSNotification.Name(rawValue: "UserUpdated"), object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(updateLabels), name: NSNotification.Name(rawValue: "AccountPageLoaded"), object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(updateLabels), name: NSNotification.Name(rawValue: "LogoutSuccess"), object: nil)
                
                notificationsSetup = true
            }
            isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeader(title: "Account", leftButton: .menu)
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
            GlobalFunctions.dismissVC(browseItemsVC)
            isShowingAnswers = false
        }
    }
    
    func updateLabels(_ notification: Notification) {
        updateHeader(title: "Account", leftButton: .menu)
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
        GlobalFunctions.addNewVC(browseItemsVC, parentVC: self)
        isShowingAnswers = true

        browseItemsVC.view.translatesAutoresizingMaskIntoConstraints = false
        browseItemsVC.view.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        browseItemsVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        browseItemsVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        browseItemsVC.view.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true

        toggleLoading(show: true, message: "Loading your answers...")
        updateHeader(title: "Your Answers", leftButton: .back)

        if let _user = User.currentUser {
            Database.getUserItems(uID: _user.uID!, completion: { items in
                if items.count > 0 {
                    self.browseItemsVC.allItems = items
                    self.toggleLoading(show: false, message: nil)
                }
                else {
                    self.toggleLoading(show: true, message: "You haven't created any content yet")
                    UIView.animate(withDuration: 0.1, animations: { self.loadingOverlay.alpha = 0.0 } ,
                                   completion: {(value: Bool) in
                                    self.toggleLoading(show: false, message: nil)
                    })
                }
            })
        }
        
        automaticallyAdjustsScrollViewInsets = false
        browseItemsVC.view.setNeedsLayout()
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
    
    override func goBack() {
        GlobalFunctions.dismissVC(browseItemsVC)
        updateHeader(title: "Account", leftButton: .menu)
        settingsLinks.setSelectedButton(type: nil)
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
        showCamera()
    }
    
    func updateNav(title : String?, image: UIImage?) {
        if let nav = nav {
            nav.setNav(title: title)
        }
    }
    
    /* CAMERA FUNCTIONS & DELEGATE METHODS */
    func showCamera() {
        guard let nav = parent?.navigationController else { return }

        cameraVC = CameraVC()
        cameraVC.delegate = self
        cameraVC.screenTitle = "smile!"
        
        panDismissInteractionController.wireToViewController(cameraVC, toViewController: nil, parentViewController: nav)
        panDismissInteractionController.delegate = self
        
        present(cameraVC, animated: true, completion: nil)
    }
    
    func doneRecording(_: URL?, image: UIImage?, location: String?, assetType : CreatedAssetType?) {
        guard let imageData = image?.mediumQualityJPEGNSData, cameraVC != nil else { return }
        
        cameraVC.toggleLoading(show: true, message: "saving! just a sec...")

        Database.uploadProfileImage(imageData, completion: {(URL, error) in
            if error != nil {
                self.toggleLoading(show: false, message: nil)
            } else {
                UIView.animate(withDuration: 0.1, animations: { self.cameraVC.view.alpha = 0.0 } ,
                               completion: {(value: Bool) in
                                self.cameraVC.toggleLoading(show: false, message: nil)
                                self.updateHeader(title: "Account", leftButton: .menu)
                                self.profileSummary.updateLabels()
                                self.cameraVC.dismiss(animated: true, completion: nil)
                })
            }
        })
    }
    
    func userDismissedCamera() {
        cameraVC.dismiss(animated: true, completion: nil)
    }
    
    func showAlbumPicker() {
        let albumPicker = UIImagePickerController()
        
        albumPicker.delegate = self
        albumPicker.allowsEditing = false
        albumPicker.sourceType = .photoLibrary
        albumPicker.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
        
        cameraVC.present(albumPicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        picker.dismiss(animated: true, completion: nil)

        cameraVC.toggleLoading(show: true, message: "saving! just a sec...")

        if mediaType.isEqual(to: kUTTypeImage as String) {
            let pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage

            Database.uploadProfileImage(pickedImage.highQualityJPEGNSData, completion: {(URL, error) in
                if error != nil {
                    self.cameraVC.toggleLoading(show: false, message: nil)
                } else {
                    UIView.animate(withDuration: 0.2, animations: { self.cameraVC.view.alpha = 0.0 } ,
                                   completion: {(value: Bool) in
                                    self.updateHeader(title: "Account", leftButton: .menu)
                                    self.profileSummary.updateLabels()
                                    self.toggleLoading(show: false, message: nil)
                                    self.cameraVC.dismiss(animated: true, completion: nil)
                    })
                }
            })
            // Media is an image
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    /* LAYOUT FUNCTION */
    fileprivate func updateHeader(title : String, leftButton : ButtonType) {
        if parent?.navigationController != nil {
            
            if leftButton == .menu {
                let button = PulseButton(size: .small, type: .menu, isRound : true, hasBackground: true)
                button.addTarget(self, action: #selector(clickedMenu), for: UIControlEvents.touchUpInside)
                parent?.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
            } else if leftButton == .back {
                let button = PulseButton(size: .small, type: .back, isRound : true, hasBackground: true)
                button.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
                parent?.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
            }
        }
        
        if let nav = navigationController as? PulseNavVC {
            nav.setNav(title: title)
        } else {
            parent?.title = title
        }
    }
    
    fileprivate func setupProfileSummary() {
        profileSummary.frame = view.frame
        view.addSubview(profileSummary)
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
