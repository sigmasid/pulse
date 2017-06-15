//
//  StartThread.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/22/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit
import CoreLocation
import MobileCoreServices

class NewThreadVC: PulseVC, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    //Set by parent
    public var selectedChannel : Channel!
    public var selectedItem : Item!
    
    //UI Vars
    fileprivate var sAddCover = UIImageView()
    fileprivate var sShowCamera = PulseButton(size: .large, type: .camera, isRound: true, background: .white, tint: .black)
    fileprivate var sShowCameraLabel = UILabel()
    
    fileprivate var sTitle = UITextField()
    fileprivate var sDescription = UITextField()
    fileprivate var submitButton = UIButton()
    
    fileprivate var sType = PaddingLabel()
    fileprivate var sTypeDescription = PaddingLabel()
    
    //Capture Image
    fileprivate lazy var panDismissInteractionController : PanContainerInteractionController! = PanContainerInteractionController()
    fileprivate lazy var cameraVC : CameraVC! = CameraVC()
    fileprivate var capturedImage : UIImage?
    fileprivate var contentType : CreatedAssetType? = .recordedImage
    
    //Deinit check
    fileprivate var cleanupComplete = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            tabBarHidden = true
            updateHeader()
            setupLayout()
            hideKeyboardWhenTappedAround()
            
            isLoaded = true
        }
    }
    
    deinit {
        performCleanup()
    }
    
    public func performCleanup() {
        if !cleanupComplete {
            selectedChannel = nil
            selectedItem = nil
            
            sAddCover.removeFromSuperview()
            sShowCamera.removeFromSuperview()
            sShowCameraLabel.removeFromSuperview()
            
            if cameraVC != nil {
                cameraVC.performCleanup()
                cameraVC.delegate = nil
                cameraVC = nil
            }
            
            capturedImage = nil
            panDismissInteractionController.delegate = nil
            panDismissInteractionController = nil
            
            cleanupComplete = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeader()
    }
    
    /** HEADER FUNCTIONS **/
    internal func updateHeader() {
        addBackButton()
        
        headerNav?.setNav(title: "Start a New Thread", subtitle: selectedItem.itemTitle != "" ? selectedItem.itemTitle : selectedChannel.cTitle)
        headerNav?.updateBackgroundImage(image: GlobalFunctions.processImage(selectedChannel.cPreviewImage))
        headerNav?.showNavbar(animated: true)
    }
    
    internal func handleSubmit() {
        guard PulseUser.isLoggedIn() else { return }
        
        let loading = submitButton.addLoadingIndicator()
        submitButton.setDisabled()
        
        let itemKey = databaseRef.child("items").childByAutoId().key
        let item = Item(itemID: itemKey, type: "thread")
        
        item.itemTitle = sTitle.text ?? ""
        item.itemUserID = PulseUser.currentUser.uID
        item.itemDescription = sDescription.text ?? ""
        item.content = capturedImage
        item.contentType = contentType
        item.cID = selectedChannel.cID
        
        PulseDatabase.addThread(channelID: selectedChannel.cID, parentItem: selectedItem, item: item, completion: { success, error in
            if success, let capturedImage = self.capturedImage {
                PulseDatabase.uploadImage(channelID: item.cID, itemID: itemKey, image: capturedImage, fileType: .content, completion: {(success, error) in
                    success ? self.showSuccessMenu() : self.showErrorMenu(error: error!)
                    loading.removeFromSuperview()
                    self.submitButton.setEnabled()
                })
                PulseDatabase.uploadImage(channelID: item.cID, itemID: itemKey, image: capturedImage, fileType: .thumb, completion: {(success, error) in
                    loading.removeFromSuperview()
                })
            } else {
                loading.removeFromSuperview()
                self.showErrorMenu(error: error!)
                self.submitButton.setEnabled()
            }
        })
    }
    
    internal func showSuccessMenu() {
        let menu = UIAlertController(title: "Successfully Added Thread",
                                     message: "Tap okay to return and start contributing to this thread!",
                                     preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "done", style: .default, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
            self.goBack()
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func showErrorMenu(error : Error) {
        let menu = UIAlertController(title: "Error Creating Series", message: error.localizedDescription, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "cancel", style: .default, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
}

//UI Elements
extension NewThreadVC {
    func setupLayout() {
        view.addSubview(sAddCover)
        view.addSubview(sShowCamera)
        view.addSubview(sShowCameraLabel)
        
        view.addSubview(sTitle)
        view.addSubview(sDescription)
        
        view.addSubview(sTypeDescription)
        view.addSubview(submitButton)
        
        sAddCover.translatesAutoresizingMaskIntoConstraints = false
        sAddCover.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        sAddCover.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        sAddCover.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        sAddCover.heightAnchor.constraint(equalToConstant: 175).isActive = true
        sAddCover.layoutIfNeeded()
        sAddCover.backgroundColor = UIColor.pulseGrey.withAlphaComponent(0.3)
        
        sShowCamera.translatesAutoresizingMaskIntoConstraints = false
        sShowCamera.centerXAnchor.constraint(equalTo: sAddCover.centerXAnchor).isActive = true
        sShowCamera.centerYAnchor.constraint(equalTo: sAddCover.centerYAnchor).isActive = true
        sShowCamera.heightAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        sShowCamera.widthAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        sShowCamera.layoutIfNeeded()
        
        sShowCamera.addTarget(self, action: #selector(showCamera), for: .touchUpInside)
        
        sShowCameraLabel.translatesAutoresizingMaskIntoConstraints = false
        sShowCameraLabel.centerXAnchor.constraint(equalTo: sShowCamera.centerXAnchor).isActive = true
        sShowCameraLabel.topAnchor.constraint(equalTo: sShowCamera.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        sShowCameraLabel.text = "add a cover image"
        sShowCameraLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .black, alignment: .center)
        
        sTitle.translatesAutoresizingMaskIntoConstraints = false
        sTitle.topAnchor.constraint(equalTo: sAddCover.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        sTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        sTitle.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        sTitle.layoutIfNeeded()
        
        sDescription.translatesAutoresizingMaskIntoConstraints = false
        sDescription.topAnchor.constraint(equalTo: sTitle.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        sDescription.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        sDescription.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        sDescription.layoutIfNeeded()
        
        sTitle.delegate = self
        sDescription.delegate = self
        
        sTitle.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightThin)
        sDescription.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightThin)
        
        sTitle.layer.addSublayer(GlobalFunctions.addBorders(self.sTitle, _color: UIColor.black, thickness: IconThickness.thin.rawValue))
        sDescription.layer.addSublayer(GlobalFunctions.addBorders(self.sDescription, _color: UIColor.black, thickness: IconThickness.thin.rawValue))
        
        sTitle.attributedPlaceholder = NSAttributedString(string: "short title for thread",
                                                          attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
        sDescription.attributedPlaceholder = NSAttributedString(string: "short thread description",
                                                                attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
        
        
        sTypeDescription.translatesAutoresizingMaskIntoConstraints = false
        sTypeDescription.topAnchor.constraint(equalTo: sDescription.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        sTypeDescription.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        sTypeDescription.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        sTypeDescription.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        sTypeDescription.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .gray, alignment: .center)
        
        sTypeDescription.numberOfLines = 3
        sTypeDescription.text = "Threads are open to all channel contributors and anyone invited by a verified contributor."
        
        addSubmitButton()
    }
    
    internal func addSubmitButton() {
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.topAnchor.constraint(equalTo: sTypeDescription.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        submitButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
        submitButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        
        submitButton.layer.cornerRadius = buttonCornerRadius.radius(.regular)
        submitButton.setTitle("Start Thread", for: UIControlState())
        submitButton.titleLabel!.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        submitButton.setDisabled()
        
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
    }
}

extension NewThreadVC: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == sTitle, textField.text != "", sDescription.text != "" {
            submitButton.setEnabled()
        } else if textField == sDescription, textField.text != "", sTitle.text != "" {
            submitButton.setEnabled()
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string == "\n" {
            textField.resignFirstResponder()
            return false
        }
        
        let  char = string.cString(using: String.Encoding.utf8)!
        let isBackSpace = strcmp(char, "\\b")
        
        if isBackSpace == -92, textField.text != "" {
            return true
        }
        
        if textField == sTitle, let text = textField.text?.lowercased() {
            return text.characters.count + (text.characters.count - range.length) <= 100
        } else if textField == sDescription, let text = textField.text?.lowercased() {
            return text.characters.count + (text.characters.count - range.length) <= 150
        }
        
        return true
    }
}

extension NewThreadVC: CameraDelegate, PanAnimationDelegate {
    /* CAMERA FUNCTIONS & DELEGATE METHODS */
    func panCompleted(success: Bool, fromVC: UIViewController?) {
        if success {
            if fromVC is CameraVC {
                print("from vc is content camera VC")
                userDismissedCamera()
            }
        }
    }
    
    func showCamera() {
        guard let nav = navigationController else { return }
        
        cameraVC = CameraVC()
        cameraVC.cameraMode = .stillImage
        
        cameraVC.delegate = self
        cameraVC.screenTitle = "snap a pic to use as cover!"
        
        panDismissInteractionController.wireToViewController(cameraVC, toViewController: nil, parentViewController: nav, modal: true)
        panDismissInteractionController.delegate = self
        
        present(cameraVC, animated: true, completion: nil)
    }
    
    func doneRecording(isCapturing: Bool, url : URL?, image: UIImage?, location: CLLocation?, assetType : CreatedAssetType?) {
        guard let imageData = image?.mediumQualityJPEGNSData else {
            if isCapturing {
                self.cameraVC.toggleLoading(show: true, message: "saving! just a sec...")
            }
            return
        }
        
        capturedImage = UIImage(data: imageData)
        
        UIView.animate(withDuration: 0.1, animations: { self.cameraVC.view.alpha = 0.0 } ,
                       completion: {(value: Bool) in
                        
                        DispatchQueue.main.async {
                            self.cameraVC.toggleLoading(show: false, message: nil)
                            
                            if let capturedImage = self.capturedImage {
                                self.sAddCover.image = capturedImage
                                self.sAddCover.contentMode = .scaleAspectFill
                                self.sAddCover.clipsToBounds = true
                                
                                self.sShowCamera.imageView?.alpha = 0.5
                                self.sShowCameraLabel.text = "tap icon to change"
                                self.sShowCameraLabel.textColor = .white
                            }
                            
                            //update the header
                            self.cameraVC.dismiss(animated: true, completion: nil)
                        }
                        
        })
        
    }
    
    func userDismissedCamera() {
        cameraVC.dismiss(animated: true, completion: nil)
    }
    
    func showAlbumPicker() {
        let albumPicker = UIImagePickerController()
        
        albumPicker.delegate = self
        albumPicker.allowsEditing = true
        albumPicker.sourceType = .photoLibrary
        albumPicker.mediaTypes = [kUTTypeImage as String]
        
        cameraVC.present(albumPicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        guard mediaType.isEqual(to: kUTTypeImage as String) else {
            return
        }
        
        picker.dismiss(animated: true, completion: nil)
        capturedImage = info[UIImagePickerControllerOriginalImage] as? UIImage

        if let capturedImage = capturedImage {
            self.sAddCover.image = capturedImage
            self.sAddCover.contentMode = .scaleAspectFill
            self.sAddCover.clipsToBounds = true
            
            self.sShowCamera.imageView?.alpha = 0.5
            self.sShowCameraLabel.text = "tap icon to change"
            self.sShowCameraLabel.textColor = .white
            
            cameraVC.dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
