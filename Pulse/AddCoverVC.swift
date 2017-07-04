//
//  AddCoverVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/1/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit
import CoreLocation
import MobileCoreServices

class AddCoverVC: PulseVC  {
    //UI Vars
    fileprivate var sAddCover = UIImageView()
    fileprivate var sShowCamera = PulseButton(size: .large, type: .camera, isRound: true, background: .white, tint: .black)
    fileprivate var sShowCameraLabel = UILabel()
    
    fileprivate var sTitle = UITextField()
    fileprivate var submitButton = UIButton()
    
    fileprivate var sType = PaddingLabel()
    fileprivate var sTypeDescription = PaddingLabel()
    
    //Capture Image
    fileprivate var inputVC : InputVC!
    fileprivate var contentType : CreatedAssetType? = .recordedImage
    fileprivate var contentLocation : CLLocation?
    
    //Deinit check
    fileprivate var cleanupComplete = false
    
    //Loading icon on Button
    fileprivate var loading : UIView!
    
    //Vars to send back
    public weak var delegate : AddCoverDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            tabBarHidden = true
            navigationController?.isNavigationBarHidden = false
            setupLayout()
            hideKeyboardWhenTappedAround()
            
            isLoaded = true
        }
    }
    
    deinit {
        print("deinit for add cover called")
        performCleanup()
    }
    
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func goBack() {
        navigationController?.isNavigationBarHidden = true
        super.goBack()
    }
    
    public func performCleanup() {
        if !cleanupComplete {
            
            if inputVC != nil {
                inputVC.performCleanup()
                inputVC.inputDelegate = nil
                inputVC = nil
            }
            
            delegate = nil
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
        headerNav?.setNav(title: "Add Cover")
    }
    
    internal func handleSubmit() {
        guard let delegate = delegate, let image = sAddCover.image, let title = sTitle.text, let contentType = contentType else { return }
        navigationController?.isNavigationBarHidden = true
        delegate.addCover(image: image, title: title, location: contentLocation, assetType: contentType)
    }
}

//UI Elements
extension AddCoverVC {
    func setupLayout() {
        view.addSubview(sAddCover)
        view.addSubview(sShowCamera)
        view.addSubview(sShowCameraLabel)
        
        view.addSubview(sTitle)
        
        view.addSubview(sTypeDescription)
        view.addSubview(submitButton)
        
        sAddCover.translatesAutoresizingMaskIntoConstraints = false
        sAddCover.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        sAddCover.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        sAddCover.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        sAddCover.heightAnchor.constraint(equalToConstant: 250).isActive = true
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
        sTitle.topAnchor.constraint(equalTo: sAddCover.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        sTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        sTitle.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        sTitle.layoutIfNeeded()
        
        sTitle.delegate = self
        sTitle.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightThin)
        sTitle.addBottomBorder()
        sTitle.attributedPlaceholder = NSAttributedString(string: "add a short title",
                                                          attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
        
        sTypeDescription.translatesAutoresizingMaskIntoConstraints = false
        sTypeDescription.topAnchor.constraint(equalTo: sTitle.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        sTypeDescription.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        sTypeDescription.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        sTypeDescription.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        sTypeDescription.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .gray, alignment: .center)
        
        sTypeDescription.numberOfLines = 3
        sTypeDescription.text = "All done? Click post to finish up."
        
        addSubmitButton()
    }
    
    internal func addSubmitButton() {
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.topAnchor.constraint(equalTo: sTypeDescription.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        submitButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
        submitButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        
        submitButton.layer.cornerRadius = buttonCornerRadius.radius(.regular)
        submitButton.setTitle("Post", for: UIControlState())
        submitButton.titleLabel!.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        submitButton.setDisabled()
        
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
    }
    
    fileprivate func checkEnabled() {
        if sTitle.text != nil, sTitle.text != "", sAddCover.image != nil {
            submitButton.setEnabled()
        } else {
            submitButton.setDisabled()
        }
    }
}

extension AddCoverVC: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        checkEnabled()
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
        
        if let text = textField.text?.lowercased() {
            return text.characters.count + (text.characters.count - range.length) <= 140
        }
        
        return true
    }
}

extension AddCoverVC: InputMasterDelegate {
    /* CAMERA FUNCTIONS & DELEGATE METHODS */
    func showCamera() {
        if inputVC == nil {
            inputVC = InputVC(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
            inputVC.cameraMode = .stillImage
            inputVC.captureSize = .square
            inputVC.albumShowsVideo = false
            inputVC.inputDelegate = self
            inputVC.transitioningDelegate = self
            inputVC.cameraTitle = "snap a pic to use as cover!"
        }
        present(inputVC, animated: true, completion: nil)
    }
    
    func capturedItem(url : URL?, image: UIImage?, location: CLLocation?, assetType : CreatedAssetType?) {
        guard let image = image else {
            GlobalFunctions.showAlertBlock("Error getting image", erMessage: "Sorry there was an error! Please try again")
            return
        }
                
        sAddCover.image = image
        sAddCover.contentMode = .scaleAspectFill
        sAddCover.clipsToBounds = true
        
        sShowCameraLabel.text = "tap image to change"
        sShowCameraLabel.textColor = .gray
        sShowCamera.alpha = 0.3
        
        sShowCamera = PulseButton(size: .xSmall, type: .camera, isRound: true, background: UIColor.white.withAlphaComponent(0.7), tint: .black)
        sShowCamera.frame = CGRect(x: Spacing.xs.rawValue, y: self.sAddCover.frame.maxY - Spacing.xs.rawValue -  IconSizes.xSmall.rawValue,
                                        width: IconSizes.xSmall.rawValue, height: IconSizes.xSmall.rawValue)
        
        contentType = assetType
        contentLocation = location
        checkEnabled()
        
        //update the header
        dismiss(animated: true, completion: {[weak self] in
            guard let `self` = self else { return }
            self.inputVC.updateAlpha()
        })
    }
    
    func dismissInput() {
        dismiss(animated: true, completion: nil)
    }
}
