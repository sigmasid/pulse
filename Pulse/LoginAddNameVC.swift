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

class LoginAddNameVC: PulseVC, CameraDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PanAnimationDelegate, ItemPreviewDelegate {

    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var _firstNameError: UILabel!
    @IBOutlet weak var _lastNameError: UILabel!
    @IBOutlet weak var profilePicButton: UIButton!
    
    fileprivate var cameraVC : CameraVC!
    internal lazy var panDismissCameraInteractionController = PanContainerInteractionController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !isLoaded {
            firstName.layer.addSublayer(GlobalFunctions.addBorders(self.firstName, _color: UIColor.black, thickness: IconThickness.thin.rawValue))
            lastName.layer.addSublayer(GlobalFunctions.addBorders(self.lastName, _color: UIColor.black, thickness: IconThickness.thin.rawValue))
            
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
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: checkButton)
        headerNav?.setNav(title: "Add Name")
    }
    
    @IBAction func addPic(_ sender: UIButton) {
        guard let nav = navigationController else { return }
        
        cameraVC = CameraVC()
        cameraVC.cameraMode = .stillImage
        cameraVC.delegate = self
        cameraVC.screenTitle = "smile!"
        
        panDismissCameraInteractionController.wireToViewController(cameraVC, toViewController: nil, parentViewController: nav, modal: true)
        panDismissCameraInteractionController.delegate = self
        
        present(cameraVC, animated: true, completion: nil)
    }
    
    @IBAction func addName(_ sender: UIButton) {
        dismissKeyboard()
        sender.setDisabled()
        let _ = sender.addLoadingIndicator()
        
        GlobalFunctions.validateName(firstName.text, completion: {(verified, error) in
            if !verified {
                self._firstNameError.text = error!.localizedDescription
                sender.setEnabled()
            } else {
                GlobalFunctions.validateName(self.lastName.text, completion: {(verified, error) in
                    if !verified {
                        self._lastNameError.text = error!.localizedDescription
                        sender.setEnabled()
                    } else {
                        let fullName = self.firstName.text! + " " + self.lastName.text!
                        PulseDatabase.updateUserData(UserProfileUpdateType.displayName, value: fullName, completion: { (success, error) in
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
    
    func doneRecording(isCapturing: Bool, url : URL?, image: UIImage?, location: CLLocation?, assetType : CreatedAssetType?) {
        guard let imageData = image?.mediumQualityJPEGNSData, cameraVC != nil else {
            if isCapturing {
                self.cameraVC.toggleLoading(show: true, message: "saving! just a sec...")
            }
            return
        }
        
        PulseDatabase.uploadProfileImage(imageData, completion: {(URL, error) in
            if error == nil {
                UIView.animate(withDuration: 0.1, animations: { self.cameraVC.view.alpha = 0.0 } ,
                               completion: {(value: Bool) in
                                self.cameraVC.toggleLoading(show: false, message: nil)
                                self.cameraVC.dismiss(animated: true, completion: nil)
                })
                
                DispatchQueue.main.async(execute: {
                    self.profilePicButton.setImage(image, for: UIControlState())
                    self.profilePicButton.contentMode = .scaleAspectFit
                    self.profilePicButton.setTitle("", for: UIControlState())
                })
            }
        })
    }
    
    func panCompleted(success: Bool, fromVC: UIViewController?) {
        if success {
            if cameraVC != nil, fromVC is CameraVC {
                cameraVC.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func userDismissedCamera() {
        cameraVC.dismiss(animated: true, completion: nil)
    }
    
    func showAlbumPicker() {
        let albumPicker = UIImagePickerController()
        
        albumPicker.delegate = self
        albumPicker.allowsEditing = false
        albumPicker.sourceType = .photoLibrary
        albumPicker.mediaTypes = [kUTTypeImage as String]
        
        cameraVC.present(albumPicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        picker.dismiss(animated: true, completion: nil)
        
        cameraVC.toggleLoading(show: true, message: "saving! just a sec...")
        
        if mediaType.isEqual(to: kUTTypeImage as String) {
            let pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            
            PulseDatabase.uploadProfileImage(pickedImage.highQualityJPEGNSData, completion: {(URL, error) in
                if error != nil {
                    self.cameraVC.toggleLoading(show: false, message: nil)
                } else {
                    UIView.animate(withDuration: 0.2, animations: { self.cameraVC.view.alpha = 0.0 } ,
                                   completion: {(value: Bool) in
                                    self.cameraVC.toggleLoading(show: false, message: nil)
                                    self.cameraVC.dismiss(animated: true, completion: nil)
                    })
                }
            })
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

}
