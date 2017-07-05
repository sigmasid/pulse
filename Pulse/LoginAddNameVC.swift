//
//  LoginAddNameVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/8/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import FirebaseAuth
import MobileCoreServices
import CoreLocation

class LoginAddNameVC: PulseVC, InputMasterDelegate, ModalDelegate {

    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var _firstNameError: UILabel!
    @IBOutlet weak var _lastNameError: UILabel!
    @IBOutlet weak var profilePicButton: UIButton!
    
    fileprivate var inputVC : InputVC!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !isLoaded {
            firstName.placeholder = firstName.placeholder
            lastName.placeholder = lastName.placeholder
            profilePicButton.imageEdgeInsets = UIEdgeInsetsMake(22.5, 22.5, 22.5, 22.5)
            
            profilePicButton.makeRound()
            profilePicButton.addShadow()
            
            doneButton.makeRound()
            doneButton.setEnabled()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeader()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func updateHeader() {
        let checkButton = PulseButton(size: .small, type: .check, isRound : true, background: .white, tint: .black)
        checkButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: checkButton)
        headerNav?.setNav(title: "Add Name")
    }
    
    @IBAction func addPic(_ sender: UIButton) {
        inputVC = InputVC(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        inputVC.cameraMode = .stillImage
        inputVC.captureSize = .square
        inputVC.albumShowsVideo = false
        inputVC.inputDelegate = self
        inputVC.cameraTitle = "smile!"
        inputVC.transitioningDelegate = self
        present(inputVC, animated: true, completion: nil)
    }
    
    @IBAction func addName(_ sender: UIButton) {
        dismissKeyboard()
        sender.setDisabled()
        let loading = sender.addLoadingIndicator()
        
        GlobalFunctions.validateName(firstName.text, completion: {[weak self] (verified, error) in
            guard let `self` = self else { return }
            loading.removeFromSuperview()
            if !verified {
                self._firstNameError.text = error!.localizedDescription
                sender.setEnabled()
            } else {
                GlobalFunctions.validateName(self.lastName.text, completion: {[weak self] (verified, error) in
                    guard let `self` = self else { return }
                    if !verified {
                        self._lastNameError.text = error!.localizedDescription
                        sender.setEnabled()
                    } else {
                        let fullName = self.firstName.text! + " " + self.lastName.text!
                        PulseDatabase.updateUserData(UserProfileUpdateType.displayName, value: fullName, completion: {[weak self] (success, error) in
                            guard let `self` = self else { return }
                            if !success {
                                self._firstNameError.text = error!.localizedDescription
                                sender.setEnabled()
                            }
                            else {
                                self.checkPremissions()
                            }
                        })
                    }
                })
            }
        })
    }
    
    internal func checkPremissions() {
        if !hasAskedNotificationPermission {
            let permissionsPopup = PMAlertController(title: "Allow Notifications",
                                                     description: "So we can remind you of requests to share your perspectives, ideas & expertise!",
                                                     image: UIImage(named: "notifications-popup") , style: .walkthrough)
            
            permissionsPopup.dismissWithBackgroudTouch = true
            permissionsPopup.modalDelegate = self
            
            permissionsPopup.addAction(PMAlertAction(title: "Allow", style: .default, action: {[weak self] () -> Void in
                guard let `self` = self else { return }
                GlobalFunctions.showNotificationPermissions()
                self.postCompletedNotification()
            }))
            
            permissionsPopup.addAction(PMAlertAction(title: "Cancel", style: .cancel, action: {[weak self] () -> Void in
                guard let `self` = self else { return }
                self.removeBlurBackground()
                self.postCompletedNotification()
            }))
            
            blurViewBackground()
            present(permissionsPopup, animated: true, completion: nil)
            
        } else {
            self.postCompletedNotification()
        }
    }
    
    internal func userClosedModal(_ viewController: UIViewController) {
        postCompletedNotification()
        removeBlurBackground()
        dismiss(animated: true, completion: nil)
    }
    
    internal func postCompletedNotification() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "LoginSuccess"), object: self)
        doneButton.setEnabled()
        profileUpdated()
    }
    
    internal func profileUpdated() {
        let _ = navigationController?.popToRootViewController(animated: true)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        _firstNameError.text = ""
        _lastNameError.text = ""
        
        textField.text = ""
    }
    
    func capturedItem(url : URL?, image: UIImage?, location: CLLocation?, assetType : CreatedAssetType?) {
        guard let image = image else { return }
        
        profilePicButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
        profilePicButton.clipsToBounds = true
        
        profilePicButton.setImage(image, for: .normal)
        profilePicButton.imageView?.contentMode = .scaleAspectFill
        profilePicButton.imageView?.clipsToBounds = true
        
        dismiss(animated: true, completion: {[weak self] in
            guard let `self` = self else { return }
            self.inputVC.updateAlpha()
        })
        
        PulseDatabase.uploadProfileImage(image, completion: {(URL, error) in
            if error != nil {
                DispatchQueue.main.async(execute: {
                    GlobalFunctions.showAlertBlock("Error adding photo", erMessage: "Sorry there was an error - please try again!")
                })
            }
        })
    }
    
    func dismissInput() {
        inputVC.dismiss(animated: true, completion: nil)
    }
}
