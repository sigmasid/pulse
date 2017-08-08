//
//  NewForumThreadVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/3/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit
import CoreLocation
import MobileCoreServices

class NewForumThreadVC: PulseVC {

    //Set by parent
    public var selectedChannel : Channel!
    public var selectedItem : Item!
    public var delegate: BrowseContentDelegate?
    
    //UI Vars
    fileprivate var containerView = UIView()
    fileprivate var sShowCamera = PulseButton(size: .xLarge, type: .camera, isRound: true, background: .white, tint: .black)
    fileprivate var sShowCameraLabel = UILabel()
    
    fileprivate var sTitle = PaddingTextView()
    fileprivate var sDescription = PaddingTextView()
    fileprivate var sURL = PaddingTextView()

    fileprivate var submitButton = PulseButton(title: "Start Thread", isRound: true, hasShadow: false)
    
    fileprivate var sType = PaddingLabel()
    fileprivate var sTypeDescription = PaddingLabel()
    
    fileprivate var placeholderText = "interesting title for thread"
    fileprivate var descriptionPlaceholderText = "what do you want to say about this thread"
    fileprivate var urlPlaceholderText = "add a link"
    fileprivate var urlValidated = false

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
            containerView.frame = view.frame
            view.addSubview(containerView)
            
            updateHeader()
            setupLayout()
            hideKeyboardWhenTappedAround()
            
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
            
            isLoaded = true
        }
    }
    
    deinit {
        performCleanup()
    }
    
    func keyboardWillShow(notification: NSNotification) {
        UIView.animate(withDuration: 0.3, animations: { self.containerView.frame.origin.y = -175 })
        containerView.layoutIfNeeded()
    }
    
    func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3, animations: { self.containerView.frame.origin.y = 0 })
        containerView.layoutIfNeeded()
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
        tabBarHidden = true
        updateHeader()
    }
    
    /** HEADER FUNCTIONS **/
    internal func updateHeader() {
        addBackButton()
        updateChannelImage(channel: selectedChannel)
        
        headerNav?.setNav(title: "Start a New Thread", subtitle: selectedItem.itemTitle != "" ? selectedItem.itemTitle : selectedChannel.cTitle)
        headerNav?.showNavbar(animated: true)
    }
    
    internal func handleSubmit() {
        guard PulseUser.isLoggedIn() else { return }
        
        loading = submitButton.addLoadingIndicator()
        submitButton.setDisabled()
        
        let itemKey = databaseRef.child("items").childByAutoId().key
        let item = Item(itemID: itemKey, type: "thread")
        
        item.itemTitle = sTitle.text
        item.itemUserID = PulseUser.currentUser.uID
        item.contentType = contentType
        item.cID = selectedChannel.cID
        item.itemDescription = sDescription.text
        
        if sURL.text != "", urlValidated, let url = URL(string: sURL.text) {
            item.linkedURL = url
        }
        
        if let thumbImageData = self.thumbImageData {
            PulseDatabase.uploadImageData(channelID: item.cID, itemID: itemKey, imageData: thumbImageData, fileType: .thumb, completion: {[weak self] (metadata, error) in
                guard let `self` = self else { return }
                
                item.contentURL = metadata?.downloadURL()
                self.addThreadToDatabase(item: item)
            })
        } else {
            self.addThreadToDatabase(item: item)
        }
    }
    
    internal func addThreadToDatabase(item: Item) {
        PulseDatabase.addForumThread(channelID: selectedChannel.cID, parentItem: selectedItem, item: item, completion: {[weak self] success, error in
            guard let `self` = self else { return }
            
            success ? self.showSuccessMenu(item: item) : self.showErrorMenu(error: error!)
            if self.loading != nil {
                self.loading.removeFromSuperview()
            }
            self.submitButton.setEnabled()
        })
        
    }
    
    internal func showSuccessMenu(item: Item) {
        let menu = UIAlertController(title: "Successfully Added Thread",
                                     message: "Tap okay to finish & return!",
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
        thumbImageData = image.resizeImage(newWidth: ITEM_THUMB_WIDTH)?.highQualityJPEGNSData
    }
}

//UI Elements
extension NewForumThreadVC {
    func setupLayout() {
        containerView.addSubview(sShowCamera)
        containerView.addSubview(sShowCameraLabel)
        
        containerView.addSubview(sTitle)
        containerView.addSubview(sDescription)
        containerView.addSubview(sURL)

        sShowCamera.translatesAutoresizingMaskIntoConstraints = false
        sShowCamera.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        sShowCamera.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Spacing.l.rawValue).isActive = true
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
        sTitle.topAnchor.constraint(equalTo: sShowCameraLabel.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        sTitle.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        sTitle.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8).isActive = true
        sTitle.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        
        sTitle.delegate = self
        sDescription.delegate = self
        sURL.delegate = self

        sTitle.text = placeholderText
        sDescription.text = descriptionPlaceholderText
        sURL.text = urlPlaceholderText

        sTitle.textColor = UIColor.placeholderGrey
        sDescription.textColor = UIColor.placeholderGrey
        sURL.textColor = UIColor.placeholderGrey

        sDescription.translatesAutoresizingMaskIntoConstraints = false
        sDescription.topAnchor.constraint(equalTo: sTitle.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        sDescription.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        sDescription.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8).isActive = true
        sDescription.heightAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        
        sURL.translatesAutoresizingMaskIntoConstraints = false
        sURL.topAnchor.constraint(equalTo: sDescription.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        sURL.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        sURL.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8).isActive = true
        sURL.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        sURL.keyboardType = .URL
        
        addSubmitButton()
    }
    
    internal func addSubmitButton() {
        containerView.addSubview(sTypeDescription)
        containerView.addSubview(submitButton)
        
        sTypeDescription.translatesAutoresizingMaskIntoConstraints = false
        sTypeDescription.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        sTypeDescription.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        sTypeDescription.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8).isActive = true
        sTypeDescription.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .gray, alignment: .center)
        
        sTypeDescription.numberOfLines = 3
        sTypeDescription.text = "Forums are open to all subscribers. Please be respectful and adhere to the rules when posting. Editors can flag / remove any user posts."
        
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        submitButton.heightAnchor.constraint(equalToConstant: PulseButton.regularButtonHeight).isActive = true
        submitButton.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        
        submitButton.layoutIfNeeded()
        submitButton.setDisabled()
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
    }
}

extension NewForumThreadVC: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == sTitle, textView.text != "" {
            submitButton.setEnabled()
        } else if textView.text == "" {
            textView.text = textView == sTitle ? placeholderText : textView == sDescription ? descriptionPlaceholderText : urlPlaceholderText
            textView.textColor = UIColor.placeholderGrey
        } else if textView == sURL, textView.text != "" {
            urlValidated = GlobalFunctions.validateURL(urlString: textView.text)
        }
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        textView.textColor = UIColor.black
        textView.text = textView.text == placeholderText || textView.text == descriptionPlaceholderText || textView.text == urlPlaceholderText ? "" : textView.text
        return true
    }
    
    func textView(_ textView: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textView == sTitle, textView.text != "" {
            submitButton.setEnabled()
        }
        
        if string == "\n" {
            textView.resignFirstResponder()
            return false
        }
        
        let  char = string.cString(using: String.Encoding.utf8)!
        let isBackSpace = strcmp(char, "\\b")
        
        if isBackSpace == -92, textView.text != "" {
            return true
        }
        
        if textView == sTitle, let text = textView.text?.lowercased() {
            return text.characters.count + (text.characters.count - range.length) <= 250
        }
        
        return true
    }
}

extension NewForumThreadVC: InputMasterDelegate {
    /* CAMERA FUNCTIONS & DELEGATE METHODS */
    func showCamera() {
        if inputVC == nil {
            inputVC = InputVC(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
            inputVC.cameraMode = .stillImage
            inputVC.captureSize = .square
            inputVC.albumShowsVideo = false
            inputVC.inputDelegate = self
            inputVC.transitioningDelegate = self
            inputVC.cameraTitle = "snap a pic to use as cover image!"
        }
        
        present(inputVC, animated: true, completion: nil)
    }
    
    func capturedItem(item: Any?, location: CLLocation?, assetType: CreatedAssetType) {
        guard let image = item as? UIImage else {
            GlobalFunctions.showAlertBlock("Error getting image", erMessage: "Sorry there was an error! Please try again")
            return
        }
        
        
        DispatchQueue.main.async {[unowned self] in
            self.sShowCamera.setImage(nil, for: .normal)
            self.sShowCamera.setBackgroundImage(image, for: .normal)
            self.sShowCamera.contentMode = .scaleAspectFill
            self.sShowCamera.clipsToBounds = true
            self.sShowCamera.layoutIfNeeded()
        }
        
        sShowCameraLabel.text = "tap to edit image"
        contentType = assetType
        
        dismiss(animated: true, completion: {[weak self] in
            guard let `self` = self else { return }
            self.inputVC.updateAlpha()
        })
        
        createCompressedImages(image: image)
    }
    
    func dismissInput() {
        inputVC.dismiss(animated: true, completion: nil)
    }
}
