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
    
    fileprivate var sTitle = PaddingTextView()
    fileprivate var submitButton = UIButton()
    
    fileprivate var sType = PaddingLabel()
    fileprivate var sTypeDescription = PaddingLabel()
    
    fileprivate var placeholderText = "add a short title"
    
    //Capture Image
    fileprivate var inputVC : InputVC!
    fileprivate var contentType : CreatedAssetType? = .recordedImage
    fileprivate var contentLocation : CLLocation?
    
    //Deinit check
    fileprivate var cleanupComplete = false
    
    //Delegate var
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
    private func updateHeader() {
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
    fileprivate func setupLayout() {
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
        sAddCover.backgroundColor = UIColor.pulseGrey.withAlphaComponent(0.1)
        
        sShowCamera.translatesAutoresizingMaskIntoConstraints = false
        sShowCamera.centerXAnchor.constraint(equalTo: sAddCover.centerXAnchor).isActive = true
        sShowCamera.centerYAnchor.constraint(equalTo: sAddCover.centerYAnchor, constant: -Spacing.xs.rawValue).isActive = true
        sShowCamera.heightAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        sShowCamera.widthAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        sShowCamera.layoutIfNeeded()
        
        sShowCamera.addTarget(self, action: #selector(showCamera), for: .touchUpInside)
        
        sShowCameraLabel.translatesAutoresizingMaskIntoConstraints = false
        sShowCameraLabel.centerXAnchor.constraint(equalTo: sShowCamera.centerXAnchor).isActive = true
        sShowCameraLabel.topAnchor.constraint(equalTo: sShowCamera.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        sShowCameraLabel.text = "add a cover image"
        sShowCameraLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .black, alignment: .center)
        
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Spacing.max.rawValue).isActive = true
        submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        submitButton.heightAnchor.constraint(equalToConstant: PulseButton.regularButtonHeight).isActive = true
        submitButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        
        submitButton.setTitle("Post", for: UIControlState())
        submitButton.setButtonFont(FontSizes.body.rawValue, weight: UIFontWeightThin, color: .white, alignment: .center)
        submitButton.setDisabled()
        
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
        
        sTypeDescription.translatesAutoresizingMaskIntoConstraints = false
        sTypeDescription.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -Spacing.m.rawValue).isActive = true
        sTypeDescription.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        sTypeDescription.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        sTypeDescription.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        sTypeDescription.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .gray, alignment: .center)
        sTypeDescription.text = "All done? Click post to finish up."
        
        sTitle.translatesAutoresizingMaskIntoConstraints = false
        sTitle.bottomAnchor.constraint(equalTo: sTypeDescription.topAnchor, constant: -Spacing.l.rawValue).isActive = true
        sTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        sTitle.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        let titleConstraint : NSLayoutConstraint = sTitle.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue)
        titleConstraint.priority = 900
        titleConstraint.isActive = true
        
        sTitle.delegate = self
        sTitle.text = placeholderText
        sTitle.textColor = UIColor.placeholderGrey
    }
    
    fileprivate func checkEnabled() {
        if sTitle.text != nil, sTitle.text != "", sAddCover.image != nil {
            submitButton.setEnabled()
        } else {
            submitButton.setDisabled()
        }
    }
}

extension AddCoverVC: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        checkEnabled()
        
        if textView.text == "" {
            textView.text = placeholderText
            textView.textColor = UIColor.placeholderGrey
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholderText {
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text != "" {
            let currentHeight = textView.frame.height
            let sizeThatFitsTextView = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
            
            if currentHeight != sizeThatFitsTextView.height {
                //if new height is bigger, move the text view up and increase height
                sTitle.translatesAutoresizingMaskIntoConstraints = true

                textView.frame = CGRect(x: textView.frame.origin.x, y: textView.frame.origin.y - (sizeThatFitsTextView.height - currentHeight),
                                        width: textView.frame.width, height: sizeThatFitsTextView.height)
                textView.textContainer.size = CGSize(width: textView.frame.width, height: textView.frame.height)
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        
        let  char = text.cString(using: String.Encoding.utf8)!
        let isBackSpace = strcmp(char, "\\b")
        
        if isBackSpace == -92, text != "" {
            return true
        }
        
        let _text = text.lowercased()
        return (textView.text.characters.count + _text.characters.count) <= POST_TITLE_CHARACTER_COUNT
    }
}

extension AddCoverVC: InputMasterDelegate {
    /* CAMERA FUNCTIONS & DELEGATE METHODS */
    internal func showCamera() {
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
    
    internal func capturedItem(item: Any?, location: CLLocation?, assetType: CreatedAssetType) {
        guard let image = item as? UIImage else {
            GlobalFunctions.showAlertBlock("Error getting image", erMessage: "Sorry there was an error! Please try again")
            return
        }
                
        sAddCover.image = image
        sAddCover.contentMode = .scaleAspectFill
        sAddCover.clipsToBounds = true
        
        sShowCamera.removeFromSuperview()
        sShowCameraLabel.removeFromSuperview()
        
        sShowCamera = PulseButton(size: .xSmall, type: .camera, isRound: true, background: UIColor.white.withAlphaComponent(0.7), tint: .black)
        sShowCamera.frame = CGRect(x: Spacing.xs.rawValue, y: sAddCover.frame.maxY - Spacing.xs.rawValue - IconSizes.xSmall.rawValue,
                                        width: IconSizes.xSmall.rawValue, height: IconSizes.xSmall.rawValue)
        
        view.addSubview(sShowCamera)
        sShowCamera.addTarget(self, action: #selector(showCamera), for: .touchUpInside)
        
        contentType = assetType
        contentLocation = location
        checkEnabled()
        
        //update the header
        dismiss(animated: true, completion: {[weak self] in
            guard let `self` = self else { return }
            self.inputVC.updateAlpha()
        })
    }
    
    internal func dismissInput() {
        dismiss(animated: true, completion: nil)
    }
}
