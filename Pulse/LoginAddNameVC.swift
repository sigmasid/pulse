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

class LoginAddNameVC: PulseVC, InputMasterDelegate, ItemPreviewDelegate {

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
            firstName.addBottomBorder()
            lastName.addBottomBorder()
            
            firstName.attributedPlaceholder = NSAttributedString(string: firstName.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
            lastName.attributedPlaceholder = NSAttributedString(string: lastName.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
            
            doneButton.layer.cornerRadius = buttonCornerRadius.radius(.regular)
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
        checkButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: checkButton)
        headerNav?.setNav(title: "Add Name")
    }
    
    @IBAction func addPic(_ sender: UIButton) {
        inputVC = InputVC(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        inputVC.cameraMode = .stillImage
        inputVC.albumShowsVideo = false
        inputVC.inputDelegate = self
        inputVC.cameraTitle = "smile!"
        
        present(inputVC, animated: true, completion: nil)
    }
    
    @IBAction func addName(_ sender: UIButton) {
        dismissKeyboard()
        sender.setDisabled()
        let _ = sender.addLoadingIndicator()
        
        GlobalFunctions.validateName(firstName.text, completion: {[weak self] (verified, error) in
            guard let `self` = self else { return }
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
                                if let checkPermissions = GlobalFunctions.askNotificationPermssion(viewController: self) {
                                    checkPermissions.delegate = self
                                } else {
                                    NotificationCenter.default.post(name: Notification.Name(rawValue: "LoginSuccess"), object: self)
                                    sender.setEnabled()
                                    self.profileUpdated()
                                }
                            }
                        })
                    }
                })
            }
        })
    }
    
    internal func userClosedPreview(_ view : UIView) {
        postCompletedNotification()
    }
    
    internal func userClickedButton() {
        GlobalFunctions.showNotificationPermissions()
        postCompletedNotification()
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
        
        
        UIView.animate(withDuration: 0.1, animations: { self.inputVC.view.alpha = 0.0; self.toggleLoading(show: true, message: "saving! just a sec...") } ,
                       completion: {(value: Bool) in
                        self.toggleLoading(show: false, message: nil)
                        self.inputVC.view.alpha = 1.0
                        self.inputVC.dismiss(animated: true, completion: nil)
        })
        
        PulseDatabase.uploadProfileImage(image, completion: {(URL, error) in
            if error == nil {
                DispatchQueue.main.async(execute: {
                    self.profilePicButton.setImage(image, for: UIControlState())
                    self.profilePicButton.contentMode = .scaleAspectFill
                    self.profilePicButton.setTitle("", for: UIControlState())
                    self.toggleLoading(show: false, message: nil)
                })
            } else {
                DispatchQueue.main.async(execute: {
                    self.toggleLoading(show: false, message: nil)
                    GlobalFunctions.showAlertBlock("Error adding photo", erMessage: "Sorry there was an error - please try again!")
                })
            }
        })
    }
    
    func dismissInput() {
        inputVC.dismiss(animated: true, completion: nil)
    }
}
