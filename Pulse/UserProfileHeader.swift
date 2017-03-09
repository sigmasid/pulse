//
//  UserProfileHeader.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/16/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class UserProfileHeader: UICollectionReusableView {
    fileprivate var menuButton = PulseButton(size: .medium, type: .ellipsis, isRound: false, hasBackground: false, tint: .black)

    fileprivate var profileImage = UIImageView()
    fileprivate var profileShortBio = UILabel()
    fileprivate var profileLongBio = UILabel()
    
    fileprivate var shortBioHeightConstraint: NSLayoutConstraint!
    fileprivate var longBioHeightConstraint : NSLayoutConstraint!
    
    public var profileDelegate : UserProfileDelegate!
    
    ///setup order: first profile image + bio labels, then buttons + scope bar
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        addBottomBorder()
        setupProfileDetails()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func updateUserDetails(selectedUser: User) {
        profileImage.image = selectedUser.thumbPicImage
        
        let fontAttributes = [ NSFontAttributeName : UIFont.systemFont(ofSize: profileShortBio.font.pointSize, weight: UIFontWeightMedium)]
        let shortBioHeight = selectedUser.shortBio != nil ? GlobalFunctions.getLabelSize(title: selectedUser.shortBio!, width: profileShortBio.frame.width, fontAttributes: fontAttributes) : 0
        
        let bioFontAttributes = [ NSFontAttributeName : UIFont.systemFont(ofSize: profileLongBio.font.pointSize, weight: UIFontWeightMedium)]
        let longBioHeight = selectedUser.bio != nil ? GlobalFunctions.getLabelSize(title: selectedUser.bio!, width: profileLongBio.frame.width, fontAttributes: bioFontAttributes) : 0
        
        let maxHeight = GlobalFunctions.getLabelSize(title: "here is the bio", width: profileLongBio.frame.width, fontAttributes: bioFontAttributes) * 3
        
        shortBioHeightConstraint.constant = shortBioHeight
        longBioHeightConstraint.constant = min(maxHeight, longBioHeight)
        
        profileShortBio.text = selectedUser.shortBio
        profileLongBio.text = selectedUser.bio
        
        layoutIfNeeded()
    }
    
    internal func showMenu() {
        if profileDelegate != nil {
            profileDelegate.showMenu()
        }
    }
    
    fileprivate func setupProfileDetails() {
        addSubview(profileImage)
        addSubview(profileShortBio)
        addSubview(profileLongBio)
        addSubview(menuButton)

        profileImage.translatesAutoresizingMaskIntoConstraints = false
        profileImage.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.m.rawValue).isActive = true
        profileImage.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        profileImage.heightAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        profileImage.widthAnchor.constraint(equalTo: profileImage.heightAnchor).isActive = true
        
        menuButton.frame = CGRect(x: bounds.maxX - IconSizes.medium.rawValue - Spacing.xs.rawValue,
                                  y: Spacing.xs.rawValue,
                                  width: IconSizes.medium.rawValue,
                                  height: IconSizes.medium.rawValue)
        menuButton.removeShadow()
        menuButton.addTarget(self, action: #selector(showMenu), for: .touchUpInside)
        
        profileShortBio.translatesAutoresizingMaskIntoConstraints = false
        profileShortBio.topAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        profileShortBio.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        profileShortBio.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7)
        
        shortBioHeightConstraint = profileShortBio.heightAnchor.constraint(equalToConstant: 0)
        shortBioHeightConstraint.isActive = true
        
        profileLongBio.translatesAutoresizingMaskIntoConstraints = false
        profileLongBio.topAnchor.constraint(equalTo: profileShortBio.bottomAnchor).isActive = true
        profileLongBio.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        profileLongBio.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7).isActive = true
        
        longBioHeightConstraint = profileLongBio.heightAnchor.constraint(equalToConstant: 0)
        longBioHeightConstraint.isActive = true
        
        profileShortBio.setFont(FontSizes.body.rawValue, weight: UIFontWeightMedium, color: .lightGray, alignment: .center)
        profileLongBio.setFont(FontSizes.body2.rawValue, weight: UIFontWeightRegular, color: .lightGray, alignment: .center)
        profileLongBio.layoutIfNeeded()
        
        profileLongBio.numberOfLines = 3
        profileLongBio.lineBreakMode = .byTruncatingTail
        
        profileImage.layoutIfNeeded()
        profileImage.contentMode = .scaleAspectFill
        profileImage.makeRound()
    }
    
}
