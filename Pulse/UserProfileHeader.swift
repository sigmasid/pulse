//
//  UserProfileHeader.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/16/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class UserProfileHeader: UICollectionReusableView {
    private var buttonStack = PulseMenu(_axis: .horizontal, _spacing: Spacing.s.rawValue)
    private var askQuestionButton = PulseButton(size: ButtonSizes.small, type: ButtonType.questionCircle, isRound: true, hasBackground: false, tint: .black)
    private var contactButton = PulseButton(size: ButtonSizes.small, type: ButtonType.messageCircle, isRound: true, hasBackground: false, tint: .black)
    private var shareProfileButton = PulseButton(size: ButtonSizes.small, type: ButtonType.shareCircle, isRound: true, hasBackground: false, tint: .black)

    private var profileImage = UIImageView()
    private var profileShortBio = UILabel()
    private var profileLongBio = UILabel()
    
    public var profileOptions : XMSegmentedControl!
    private let profileOptionIcons = [UIImage(named: "answers")!, UIImage(named: "tag")!]
    
    ///setup order: first profile image + bio labels, then buttons + scope bar
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        setupProfileDetails()
        setupScopeBar()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func updateUserDetails(selectedUser: User) {
        profileImage.image = selectedUser.thumbPicImage
        profileShortBio.text = selectedUser.shortBio
        profileLongBio.text = selectedUser.bio
    }

    fileprivate func setupScopeBar() {
        let frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: scopeBarHeight)
        let titles = [" ", " ", " "]
        
        profileOptions = XMSegmentedControl(frame: frame,
                                           segmentTitle: titles,
                                           selectedItemHighlightStyle: XMSelectedItemHighlightStyle.bottomEdge)
        addSubview(profileOptions)
        
        profileOptions.translatesAutoresizingMaskIntoConstraints = false
        profileOptions.topAnchor.constraint(equalTo: profileLongBio.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        profileOptions.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        profileOptions.heightAnchor.constraint(equalToConstant: scopeBarHeight).isActive = true
        profileOptions.widthAnchor.constraint(equalTo: widthAnchor).isActive = true

        profileOptions.backgroundColor = UIColor.white
        profileOptions.highlightColor = pulseBlue
        profileOptions.tint = .lightGray
        profileOptions.highlightTint = pulseBlue
        
        profileOptions.segmentIcon = (profileOptionIcons)
        profileOptions.selectedSegment = 0
    }
    
    fileprivate func setupProfileDetails() {
        addSubview(profileImage)
        addSubview(profileShortBio)
        addSubview(profileLongBio)

        profileImage.translatesAutoresizingMaskIntoConstraints = false
        profileImage.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.xs.rawValue).isActive = true
        profileImage.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        profileImage.heightAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        profileImage.widthAnchor.constraint(equalTo: profileImage.heightAnchor).isActive = true
        
        addSubview(buttonStack)
        
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.topAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        buttonStack.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        buttonStack.layoutIfNeeded()
        
        buttonStack.addArrangedSubview(askQuestionButton)
        buttonStack.addArrangedSubview(contactButton)
        buttonStack.addArrangedSubview(shareProfileButton)
        
        buttonStack.distribution = .fillEqually
        
        profileShortBio.translatesAutoresizingMaskIntoConstraints = false
        profileShortBio.topAnchor.constraint(equalTo: buttonStack.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        profileShortBio.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        profileShortBio.widthAnchor.constraint(equalTo: widthAnchor)
        
        profileLongBio.translatesAutoresizingMaskIntoConstraints = false
        profileLongBio.topAnchor.constraint(equalTo: profileShortBio.bottomAnchor).isActive = true
        profileLongBio.leadingAnchor.constraint(equalTo: profileImage.leadingAnchor).isActive = true
        profileLongBio.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true

        profileShortBio.setFont(FontSizes.body.rawValue, weight: UIFontWeightRegular, color: .lightGray, alignment: .center)
        profileLongBio.setFont(FontSizes.body.rawValue, weight: UIFontWeightRegular, color: .lightGray, alignment: .center)
        profileLongBio.numberOfLines = 3
        profileLongBio.sizeToFit()
        
        profileImage.layoutIfNeeded()
        profileShortBio.layoutIfNeeded()
        profileLongBio.layoutIfNeeded()
        
        profileImage.contentMode = .scaleAspectFill
        profileImage.makeRound()
    }
    
}
