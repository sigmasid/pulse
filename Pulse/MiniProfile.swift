//
//  MiniProfile.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/5/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class MiniProfile: UIView {

    private var profileImage : UIImageView!
    private var nameLabel : UILabel!
    private var tagLine : UILabel!
    private var bioLabel : UILabel!
    private var messageButton : UIButton!
    private var closeButton : UIButton!
    private var selectedUser : User!
    
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
    
    override func pointInside(point : CGPoint, withEvent event : UIEvent?) -> Bool {
        for _view in self.subviews {
            if _view.userInteractionEnabled == true && _view.pointInside(convertPoint(point, toView: _view) , withEvent: event) {
                return true
            }
        }
        return false
    }
    
    func gestureRecognizer(gesture: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer : UIGestureRecognizer) -> Bool {
        return false
    }
    
    private func addProfileImage() {
        profileImage = UIImageView(frame: bounds)
        addSubview(profileImage)
        
        profileImage.contentMode = UIViewContentMode.ScaleAspectFill
    }
    
    private func addLabels() {
        nameLabel = UILabel()
        addSubview(nameLabel)
        
        tagLine = UILabel()
        addSubview(tagLine)
        
        bioLabel = UILabel()
        addSubview(bioLabel)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.topAnchor.constraintEqualToAnchor(topAnchor, constant: Spacing.s.rawValue).active = true
        nameLabel.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: Spacing.s.rawValue).active = true
        
        bioLabel.translatesAutoresizingMaskIntoConstraints = false
        bioLabel.bottomAnchor.constraintEqualToAnchor(messageButton.topAnchor, constant: -Spacing.s.rawValue).active = true
        bioLabel.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        bioLabel.widthAnchor.constraintEqualToAnchor(widthAnchor, multiplier: 0.8).active = true
        
        tagLine.translatesAutoresizingMaskIntoConstraints = false
        tagLine.bottomAnchor.constraintEqualToAnchor(bioLabel.topAnchor, constant: -Spacing.xs.rawValue).active = true
        tagLine.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        tagLine.widthAnchor.constraintEqualToAnchor(bioLabel.widthAnchor).active = true
    }
    
    private func addMessageButton() {
        messageButton = UIButton()
        addSubview(messageButton)
        
        messageButton.setTitle("message", forState: .Normal)
        messageButton.backgroundColor = iconBackgroundColor
        messageButton.layer.cornerRadius = buttonCornerRadius.radius(.small)
        
        messageButton.titleLabel?.setPreferredFont(UIColor.whiteColor(), alignment : .Center)
        messageButton.translatesAutoresizingMaskIntoConstraints = false
        messageButton.bottomAnchor.constraintEqualToAnchor(bottomAnchor, constant: -Spacing.s.rawValue).active = true
        messageButton.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        messageButton.widthAnchor.constraintEqualToAnchor(widthAnchor, multiplier: 0.7).active = true
        messageButton.heightAnchor.constraintEqualToConstant(IconSizes.Small.rawValue).active = true
        
        messageButton.layoutIfNeeded()
    }
    
    private func addCloseButton() {
        closeButton = UIButton()
        addSubview(closeButton)

        if let closeButtonImage = UIImage(named: "close") {
            closeButton.setImage(closeButtonImage, forState: UIControlState.Normal)
        } else {
            closeButton.titleLabel?.text = "close"
        }
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        closeButton.centerYAnchor.constraintEqualToAnchor(nameLabel.centerYAnchor).active = true
        closeButton.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: -Spacing.s.rawValue).active = true
        closeButton.widthAnchor.constraintEqualToConstant(IconSizes.Small.rawValue).active = true
        closeButton.heightAnchor.constraintEqualToConstant(IconSizes.Small.rawValue).active = true
        closeButton.addTarget(self, action: #selector(closeButtonClicked), forControlEvents: UIControlEvents.TouchDown)
        
        closeButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        closeButton.layoutIfNeeded()
    }
    
    /* SETTER / PUBLIC FUNCTIONS */
    func closeButtonClicked() {
        delegate.userClosedMiniProfile(self)
    }
    
    func setNameLabel(name : String?) {
        nameLabel.text = name?.uppercaseString
        nameLabel.font = UIFont.systemFontOfSize(FontSizes.Title.rawValue, weight: UIFontWeightHeavy)
        nameLabel.textAlignment = .Left
        nameLabel.textColor = UIColor.whiteColor()
    }
    
    func setTagLabel(text : String?) {
        tagLine.text = text
        tagLine.numberOfLines = 0
        tagLine.font = UIFont.systemFontOfSize(FontSizes.Body.rawValue, weight: UIFontWeightHeavy)
        tagLine.textAlignment = .Center
        tagLine.textColor = UIColor.whiteColor()
    }
    
    func setBioLabel(text : String?) {
        bioLabel.text = text
        bioLabel.numberOfLines = 0
        bioLabel.font = UIFont.systemFontOfSize(FontSizes.Caption.rawValue, weight: UIFontWeightRegular)
        bioLabel.textAlignment = .Center
        bioLabel.textColor = UIColor.whiteColor()

    }
    
    func setProfileImage(image : UIImage) {
        profileImage.image = image
        profileImage.clipsToBounds = true
    }
}
