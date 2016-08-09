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
    private var messageButton : UIButton!
    private var closeButton : UIButton!
    private var selectedUser : User!
    
    var delegate : answerDetailDelegate!

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
        layer.cornerRadius = buttonCornerRadius.radius(.regular)
        layer.borderWidth = 4.0
        layer.borderColor = UIColor.blackColor().CGColor
        
        addCloseButton()
        addProfileImage()
        addNameLabel()
        addTagLineLabel()
        addMessageButton()
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
    
    private func addProfileImage() {
        profileImage = UIImageView()
        addSubview(profileImage)
        
        profileImage.translatesAutoresizingMaskIntoConstraints = false
        
        profileImage.topAnchor.constraintEqualToAnchor(closeButton.bottomAnchor, constant: Spacing.s.rawValue).active = true
        profileImage.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        profileImage.widthAnchor.constraintEqualToConstant(IconSizes.Large.rawValue).active = true
        profileImage.heightAnchor.constraintEqualToConstant(IconSizes.Large.rawValue).active = true
        profileImage.contentMode = UIViewContentMode.ScaleAspectFill
        profileImage.clipsToBounds = true
        profileImage.layoutIfNeeded()
        
        profileImage.layer.cornerRadius = buttonCornerRadius.radius(.round, width: Int(profileImage.bounds.width))
    }
    
    func setProfileImage(image : UIImage) {
        profileImage.image = image
    }
    
    private func addNameLabel() {
        nameLabel = UILabel()
        addSubview(nameLabel)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.systemFontOfSize(12, weight: UIFontWeightBold)
        nameLabel.textAlignment = .Center
        nameLabel.textColor = UIColor.whiteColor()
        
        nameLabel.topAnchor.constraintEqualToAnchor(profileImage.bottomAnchor, constant: Spacing.m.rawValue).active = true
        nameLabel.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        nameLabel.widthAnchor.constraintEqualToAnchor(widthAnchor, multiplier: 0.7).active = true
    }
    
    func setNameLabel(name : String?) {
        nameLabel.text = name
    }
    
    private func addTagLineLabel() {
        tagLine = UILabel()
        addSubview(tagLine)
        
        tagLine.translatesAutoresizingMaskIntoConstraints = false
        tagLine.setPreferredFont(UIColor.whiteColor())
        
        tagLine.topAnchor.constraintEqualToAnchor(nameLabel.bottomAnchor).active = true
        tagLine.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        tagLine.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
    }
    
    func setTagline(text : String?) {
        tagLine.text = text
    }
    
    
    private func addMessageButton() {
        messageButton = UIButton()
        addSubview(messageButton)
        
        messageButton.setTitle("message", forState: .Normal)
        messageButton.backgroundColor = iconBackgroundColor
        messageButton.layer.cornerRadius = buttonCornerRadius.radius(.small)
        
        messageButton.titleLabel?.setPreferredFont(UIColor.whiteColor())
        messageButton.translatesAutoresizingMaskIntoConstraints = false
        messageButton.topAnchor.constraintEqualToAnchor(tagLine.bottomAnchor, constant: Spacing.m.rawValue).active = true

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
            closeButton.titleLabel?.text = "Close"
        }
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        closeButton.topAnchor.constraintEqualToAnchor(topAnchor, constant: Spacing.s.rawValue).active = true
        closeButton.trailingAnchor.constraintEqualToAnchor(self.trailingAnchor, constant: -Spacing.s.rawValue).active = true
        closeButton.widthAnchor.constraintEqualToConstant(IconSizes.Small.rawValue / 2).active = true
        closeButton.heightAnchor.constraintEqualToConstant(IconSizes.Small.rawValue / 2).active = true
        closeButton.addTarget(self, action: #selector(closeButtonClicked), forControlEvents: UIControlEvents.TouchDown)
        closeButton.layoutIfNeeded()
        
        closeButton.imageEdgeInsets = UIEdgeInsetsMake(3, 3, 3, 3)
        closeButton.backgroundColor = iconBackgroundColor
        closeButton.makeRound()
    }
    
    func closeButtonClicked() {
        delegate.userClosedMiniProfile(self)
    }

}
