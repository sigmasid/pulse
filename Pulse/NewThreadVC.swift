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

class NewThreadVC: PulseVC, UINavigationControllerDelegate  {
    //Set by parent
    public var selectedChannel : Channel!
    public var selectedItem : Item!
    
    //UI Vars
    fileprivate var sAddCover = UIImageView()
    fileprivate var sShowCamera = PulseButton(size: .xLarge, type: .camera, isRound: true, background: .white, tint: .black)
    fileprivate var sShowCameraLabel = UILabel()
    
    fileprivate var sTitle = UITextField()
    fileprivate var sDescription = UITextField()
    fileprivate var submitButton = UIButton()
    
    fileprivate var sType = PaddingLabel()
    fileprivate var sTypeDescription = PaddingLabel()
    
    //Capture Image
    fileprivate var inputVC : InputVC!
    fileprivate var fullImageData : Data?
    fileprivate var thumbImageData : Data?
    fileprivate var contentType : CreatedAssetType? = .recordedImage
    
    //Deinit check
    fileprivate var cleanupComplete = false
    
    //Loading icon on Button
    fileprivate var loading : UIView!
    
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
    
    override func goBack() {
        DispatchQueue.global(qos: .background).async {[weak self] in
            guard let `self` = self else { return }
            if self.inputVC != nil {
                self.inputVC.performCleanup()
                self.inputVC.inputDelegate = nil
                self.inputVC = nil
            }
        }
        super.goBack()
    }
    
    public func performCleanup() {
        if !cleanupComplete {
            selectedChannel = nil
            selectedItem = nil
            
            fullImageData = nil
            thumbImageData = nil
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
        headerNav?.updateBackgroundImage(image: selectedChannel.getNavImage())
        headerNav?.showNavbar(animated: true)
    }
    
    internal func handleSubmit() {
        guard PulseUser.isLoggedIn() else { return }
        
        loading = submitButton.addLoadingIndicator()
        submitButton.setDisabled()
        
        let itemKey = databaseRef.child("items").childByAutoId().key
        let item = Item(itemID: itemKey, type: "thread")
        
        item.itemTitle = sTitle.text ?? ""
        item.itemUserID = PulseUser.currentUser.uID
        item.itemDescription = sDescription.text ?? ""
        item.contentType = contentType
        item.cID = selectedChannel.cID
        
        if let fullImageData = self.fullImageData {
            PulseDatabase.uploadImageData(channelID: item.cID, itemID: itemKey, imageData: fullImageData, fileType: .content, completion: {[weak self] (metadata, error) in
                guard let `self` = self else { return }
                
                item.contentURL = metadata?.downloadURL()
                self.addThreadToDatabase(item: item)
                PulseDatabase.uploadImageData(channelID: item.cID, itemID: itemKey, imageData: self.thumbImageData, fileType: .thumb, completion: {_ in })
            })
        } else {
            self.addThreadToDatabase(item: item)
        }
    }
    
    internal func addThreadToDatabase(item: Item) {
        PulseDatabase.addThread(channelID: selectedChannel.cID, parentItem: selectedItem, item: item, completion: {[weak self] success, error in
            guard let `self` = self else { return }
            
            success ? self.showSuccessMenu() : self.showErrorMenu(error: error!)
            if self.loading != nil {
                self.loading.removeFromSuperview()
            }
            self.submitButton.setEnabled()
        })
        
    }
    
    internal func showSuccessMenu() {
        let menu = UIAlertController(title: "Successfully Added Thread",
                                     message: "Tap okay to return and start contributing to this thread!",
                                     preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "done", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
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
    
    fileprivate func createCompressedImages(image: UIImage) {
        fullImageData = image.mediumQualityJPEGNSData
        thumbImageData = image.resizeImage(newWidth: profileThumbWidth)?.highQualityJPEGNSData
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
        sAddCover.heightAnchor.constraint(equalToConstant: 150).isActive = true
        sAddCover.layoutIfNeeded()
        
        sShowCamera.translatesAutoresizingMaskIntoConstraints = false
        sShowCamera.centerXAnchor.constraint(equalTo: sAddCover.centerXAnchor).isActive = true
        sShowCamera.centerYAnchor.constraint(equalTo: sAddCover.centerYAnchor).isActive = true
        sShowCamera.heightAnchor.constraint(equalToConstant: IconSizes.xLarge.rawValue).isActive = true
        sShowCamera.widthAnchor.constraint(equalToConstant: IconSizes.xLarge.rawValue).isActive = true
        sShowCamera.layoutIfNeeded()
        
        sShowCamera.addTarget(self, action: #selector(showCamera), for: .touchUpInside)
        
        sShowCameraLabel.translatesAutoresizingMaskIntoConstraints = false
        sShowCameraLabel.centerXAnchor.constraint(equalTo: sShowCamera.centerXAnchor).isActive = true
        sShowCameraLabel.topAnchor.constraint(equalTo: sShowCamera.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        sShowCameraLabel.text = "add a cover image"
        sShowCameraLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .black, alignment: .center)
        
        sTitle.translatesAutoresizingMaskIntoConstraints = false
        sTitle.topAnchor.constraint(equalTo: sAddCover.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
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
        
        sTitle.addBottomBorder()
        sDescription.addBottomBorder()
        
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
        sTypeDescription.text = "Threads are open to all channel contributors and invited guests."
        
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
            return text.characters.count + (text.characters.count - range.length) <= 140
        }
        
        return true
    }
}

extension NewThreadVC: InputMasterDelegate {
    /* CAMERA FUNCTIONS & DELEGATE METHODS */
    func showCamera() {
        if inputVC == nil {
            inputVC = InputVC(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
            inputVC.cameraMode = .stillImage
            inputVC.captureSize = .square
            inputVC.albumShowsVideo = false
            inputVC.inputDelegate = self
            inputVC.cameraTitle = "snap a pic to use as cover!"
        }
        
        present(inputVC, animated: true, completion: nil)
    }
    
    func capturedItem(url : URL?, image: UIImage?, location: CLLocation?, assetType : CreatedAssetType?) {
        guard let image = image else {
            GlobalFunctions.showAlertBlock("Error getting image", erMessage: "Sorry there was an error! Please try again")
            return
        }
        
        UIView.animate(withDuration: 0.1, animations: { self.inputVC.view.alpha = 0.0 } ,
                       completion: {(value: Bool) in
                        
            DispatchQueue.main.async {
                
                self.sShowCamera.setImage(image, for: .normal)
                self.sShowCamera.imageView?.contentMode = .scaleAspectFill
                self.sShowCamera.imageView?.clipsToBounds = true
                
                self.sShowCamera.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
                self.sShowCamera.clipsToBounds = true
                
                self.sShowCameraLabel.text = "tap image to change"
                self.sShowCameraLabel.textColor = .gray
                self.inputVC.view.alpha = 1.0
                self.contentType = assetType
                
                //update the header
                self.inputVC.dismiss(animated: true, completion: nil)
            }
                        
        })
        
        createCompressedImages(image: image)
        
    }
    
    func dismissInput() {
        inputVC.dismiss(animated: true, completion: nil)
    }
}
