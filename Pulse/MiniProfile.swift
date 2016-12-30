//
//  MiniProfile.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/5/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class MiniProfile: UIView {

    fileprivate var profileImage : UIImageView!
    fileprivate var nameLabel : UILabel!
    fileprivate var tagLine : UILabel!
    fileprivate var bioLabel : UILabel!
    fileprivate var messageButton : UIButton!
    fileprivate var closeButton : PulseButton!
    
    var delegate : answerDetailDelegate!

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.cornerRadius = buttonCornerRadius.radius(.regular)
        clipsToBounds = true
        
        addProfileImage()
        addMessageButton()
        addLabels()
        addCloseButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func point(inside point : CGPoint, with event : UIEvent?) -> Bool {
        for _view in self.subviews {
            if _view.isUserInteractionEnabled == true && _view.point(inside: convert(point, to: _view) , with: event) {
                return true
            }
        }
        return false
    }
    
    func gestureRecognizer(_ gesture: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer : UIGestureRecognizer) -> Bool {
        return false
    }
    
    fileprivate func addProfileImage() {
        profileImage = UIImageView(frame: bounds)
        addSubview(profileImage)
        
        profileImage.contentMode = UIViewContentMode.scaleAspectFill
    }
    
    fileprivate func addLabels() {
        nameLabel = UILabel()
        addSubview(nameLabel)
        
        tagLine = UILabel()
        addSubview(tagLine)
        
        bioLabel = UILabel()
        addSubview(bioLabel)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.s.rawValue).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.s.rawValue).isActive = true
        
        bioLabel.translatesAutoresizingMaskIntoConstraints = false
        bioLabel.bottomAnchor.constraint(equalTo: messageButton.topAnchor, constant: -Spacing.s.rawValue).isActive = true
        bioLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        bioLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8).isActive = true
        
        tagLine.translatesAutoresizingMaskIntoConstraints = false
        tagLine.bottomAnchor.constraint(equalTo: messageButton.topAnchor, constant: -Spacing.xs.rawValue).isActive = true
        tagLine.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        tagLine.widthAnchor.constraint(equalTo: bioLabel.widthAnchor).isActive = true
    }
    
    fileprivate func addMessageButton() {
        messageButton = UIButton()
        addSubview(messageButton)
        
        messageButton.setTitle("send a message", for: UIControlState())
        messageButton.backgroundColor = iconBackgroundColor
        
        messageButton.titleLabel?.setPreferredFont(UIColor.white, alignment : .center)
        messageButton.translatesAutoresizingMaskIntoConstraints = false
        messageButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.s.rawValue).isActive = true
        messageButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        messageButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7).isActive = true
        messageButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        
        messageButton.layoutIfNeeded()
        messageButton.layer.cornerRadius = messageButton.frame.height / 2

        messageButton.addTarget(self, action: #selector(messageButtonClicked), for: UIControlEvents.touchDown)
    }
    
    public func setMessageButton(disabled : Bool) {
        if disabled {
            messageButton.setDisabled()
        }
    }
    
    fileprivate func addCloseButton() {
        closeButton = PulseButton(size: .small, type: .close, isRound : true, hasBackground: false)
        closeButton.addTarget(self, action: #selector(closeButtonClicked), for: UIControlEvents.touchUpInside)

        addSubview(closeButton)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        
        closeButton.layoutIfNeeded()
    }
    
    /* SETTER / PUBLIC FUNCTIONS */
    func closeButtonClicked() {
        delegate.userClosedMiniProfile(self)
    }
    
    func messageButtonClicked() {
        delegate.userClickedSendMessage()
    }
    
    func setNameLabel(_ name : String?) {
        nameLabel.text = name?.capitalized
        nameLabel.setFont(FontSizes.title.rawValue, weight: UIFontWeightHeavy, color: .white, alignment: .left)
        nameLabel.setBlurredBackground()
    }
    
    func setTagLabel(_ text : String?) {
        tagLine.text = text
        tagLine.numberOfLines = 0
        tagLine.setFont(FontSizes.body.rawValue, weight: UIFontWeightHeavy, color: .white, alignment: .center)
        tagLine.setBlurredBackground()
    }
    
    func setBioLabel(_ text : String?) {
        //bioLabel.text = text
        bioLabel.numberOfLines = 0
        
        bioLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightHeavy, color: .white, alignment: .center)
        bioLabel.setBlurredBackground()
    }
    
    func setProfileImage(_ image : UIImage) {
        guard let cgimg = image.cgImage else {
            return
        }
        
        let openGLContext = EAGLContext(api: .openGLES2)
        let context = CIContext(eaglContext: openGLContext!)
        
        let coreImage = CIImage(cgImage: cgimg)
        
        let filter = CIFilter(name: "CIPhotoEffectTransfer")
        filter?.setValue(coreImage, forKey: kCIInputImageKey)
        
        if let output = filter?.value(forKey: kCIOutputImageKey) as? CIImage {
            let cgimgresult = context.createCGImage(output, from: output.extent)
            let result = UIImage(cgImage: cgimgresult!)
            profileImage?.image = result
        } else {
            profileImage.image = image
        }
        
        profileImage.clipsToBounds = true
    }

}
