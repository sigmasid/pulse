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
    fileprivate var profileName = PaddingLabel()
    fileprivate var profileShortBio = UILabel()
    fileprivate var profileLongBio = UILabel()
    
    fileprivate var shortBioHeightConstraint: NSLayoutConstraint!
    fileprivate var longBioHeightConstraint : NSLayoutConstraint!
    fileprivate var nameHeightAnchor: NSLayoutConstraint!
    
    public weak var profileDelegate : UserProfileDelegate?
    public var isModal : Bool = false {
        didSet {
            if isModal {
                addMenu()
            }
        }
    }
    ///setup order: first profile image + bio labels, then buttons + scope bar
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        addBottomBorder(color: .pulseGrey)
        setupProfileDetails(isModal: isModal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        profileDelegate = nil
        menuButton.removeFromSuperview()
        profileImage.image = nil
        profileImage.removeFromSuperview()
    }
    
    public func updateUserImage(image: UIImage?) {
        DispatchQueue.main.async {[weak self] in
            guard let `self` = self else { return }
            self.profileImage.image = image ?? UIImage(named: "default-profile")
            self.profileImage.tintColor = .black
        }
    }
    
    public func updateUserDetails(selectedUser: PulseUser?, isModal : Bool) {
        if let selectedUser = selectedUser {
            
            let fontAttributes = [ NSFontAttributeName : UIFont.pulseFont(ofWeight: UIFontWeightMedium, size: profileShortBio.font.pointSize)]
            let shortBioHeight = selectedUser.shortBio != nil ? GlobalFunctions.getLabelSize(title: selectedUser.shortBio!,
                                                                                             width: profileShortBio.frame.width,
                                                                                             fontAttributes: fontAttributes) : 0
            let nameHeight = selectedUser.name != nil ? GlobalFunctions.getLabelSize(title: selectedUser.name!,
                                                                                     width: profileName.frame.width,
                                                                                     fontAttributes: fontAttributes) : 0
            
            
            let bioFontAttributes = [ NSFontAttributeName : UIFont.pulseFont(ofWeight: UIFontWeightMedium, size: profileLongBio.font.pointSize)]
            let longBioHeight = selectedUser.bio != nil ? GlobalFunctions.getLabelSize(title: selectedUser.bio!,
                                                                                       width: profileLongBio.frame.width,
                                                                                       fontAttributes: bioFontAttributes) : 0
            
            let maxHeight = GlobalFunctions.getLabelSize(title: "here is the bio", width: profileLongBio.frame.width,
                                                         fontAttributes: bioFontAttributes) * 3
            
            shortBioHeightConstraint.constant = shortBioHeight
            longBioHeightConstraint.constant = min(maxHeight, longBioHeight)
            nameHeightAnchor.constant = isModal ? nameHeight : 0
            
            DispatchQueue.main.async {
                self.profileImage.image = selectedUser.thumbPicImage ?? UIImage(named: "default-profile")
                self.profileImage.tintColor = .black
                self.profileName.text = isModal ? selectedUser.name : ""
                self.profileShortBio.text = selectedUser.shortBio
                self.profileLongBio.text = selectedUser.bio
                self.layoutIfNeeded()
            }
            
        } else {
            profileImage.image = UIImage(named: "default-profile")
            profileName.text = ""
            profileShortBio.text = ""
            profileLongBio.text = ""
        }
    }
    
    internal func showMenu() {
        profileDelegate?.showMenu()
    }
    
    internal func addMenu() {
        addSubview(menuButton)
        menuButton.frame = CGRect(x: bounds.maxX - IconSizes.medium.rawValue - Spacing.xs.rawValue,
                                  y: Spacing.xs.rawValue,
                                  width: IconSizes.medium.rawValue,
                                  height: IconSizes.medium.rawValue)
        menuButton.removeShadow()
        menuButton.addTarget(self, action: #selector(showMenu), for: .touchUpInside)
    }
    
    fileprivate func setupProfileDetails(isModal : Bool = false) {
        addSubview(profileImage)
        addSubview(profileName)
        addSubview(profileShortBio)
        addSubview(profileLongBio)

        profileImage.translatesAutoresizingMaskIntoConstraints = false
        profileImage.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.m.rawValue).isActive = true
        profileImage.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        profileImage.heightAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        profileImage.widthAnchor.constraint(equalTo: profileImage.heightAnchor).isActive = true
        
        profileName.translatesAutoresizingMaskIntoConstraints = false
        profileName.topAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        profileName.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        profileName.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7)
        
        nameHeightAnchor = profileShortBio.heightAnchor.constraint(equalToConstant: 0)
        nameHeightAnchor.priority = 900
        nameHeightAnchor.isActive = true
        
        profileShortBio.translatesAutoresizingMaskIntoConstraints = false
        profileShortBio.topAnchor.constraint(equalTo: profileName.bottomAnchor).isActive = true
        profileShortBio.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        profileShortBio.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7)
        
        shortBioHeightConstraint = profileShortBio.heightAnchor.constraint(equalToConstant: 0)
        shortBioHeightConstraint.priority = 900
        shortBioHeightConstraint.isActive = true
        
        profileLongBio.translatesAutoresizingMaskIntoConstraints = false
        profileLongBio.topAnchor.constraint(equalTo: profileShortBio.bottomAnchor).isActive = true
        profileLongBio.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        profileLongBio.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7).isActive = true
        
        longBioHeightConstraint = profileLongBio.heightAnchor.constraint(equalToConstant: 0)
        longBioHeightConstraint.priority = 900
        longBioHeightConstraint.isActive = true
        
        profileName.setFont(FontSizes.body.rawValue, weight: UIFontWeightBold, color: .black, alignment: .center)
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
