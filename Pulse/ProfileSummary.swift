//
//  ProfileSummary.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/21/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class ProfileSummary: UIView, UITextFieldDelegate, UITextViewDelegate {
    fileprivate var basicInfoSection = UIView()
    fileprivate var expertiseSection = UIView()
    fileprivate var socialSection = UIView()
    
    fileprivate var uProfilePic = UIImageView()
    fileprivate var uName = UITextField()
    fileprivate var uShortBio = UILabel()
    fileprivate var nameErrorLabel = UILabel()
    fileprivate lazy var _defaultProfileOverlay = UILabel()

    fileprivate var expertTagList = PulseMenu(_axis: .vertical, _spacing: Spacing.xs.rawValue)
    
    fileprivate var socialLinks = UIStackView()
    fileprivate var inButton = PulseButton(size: .medium, type: .inCircle, isRound: true, hasBackground: false)
    fileprivate var twtrButton = PulseButton(size: .medium, type: .twtrCircle, isRound: true, hasBackground: false)
    fileprivate var fbButton = PulseButton(size: .medium, type: .fbCircle, isRound: true, hasBackground: false)

    fileprivate var tapGesture : UITapGestureRecognizer?
    fileprivate var isLoaded = false
    
    var delegate : accountDelegate!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        if !isLoaded {
            setupProfileSummaryLayout()
            setupExpertTags()
            setupSocialButtonsLayout()
            
            uName.delegate = self
            uName.clearsOnBeginEditing = true
            
            tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
            uProfilePic.addGestureRecognizer(tapGesture!)
            uProfilePic.isUserInteractionEnabled = true
            uProfilePic.contentMode = UIViewContentMode.scaleAspectFill
            
            isLoaded = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func handleImageTap() {
        delegate.userClickedCamera()
    }
    
    fileprivate func addUserProfilePic(_ _userImageURL : URL?) {
        if let _ = _userImageURL {
            DispatchQueue.global().async {
                if let _userImageData = try? Data(contentsOf: _userImageURL!) {
                    User.currentUser?.thumbPicImage = UIImage(data: _userImageData)
                    DispatchQueue.main.async(execute: {
                        self.uProfilePic.image = User.currentUser?.thumbPicImage
                        self.uProfilePic.clipsToBounds = true
                        self.uProfilePic.layer.cornerRadius = self.uProfilePic.frame.width / 2
                    })
                }
            }
        }
    }
    
    fileprivate func highlightConnectedSocialSources() {
        guard let currentUser = User.currentUser else { return }

        if currentUser.socialSources[.facebook] == true {
            fbButton.alpha = 1.0
            fbButton.tintColor = UIColor(red: 78/255, green: 99/255, blue: 152/255, alpha: 1.0 )
        } else {
            fbButton.alpha = 1.0
            fbButton.tintColor = .white
        }
        
        if currentUser.socialSources[.twitter] == true {
            twtrButton.alpha = 1.0
            twtrButton.tintColor = UIColor(red: 58/255, green: 185/255, blue: 228/255, alpha: 1.0 )
        } else {
            twtrButton.alpha = 1.0
            twtrButton.tintColor = .white
        }
        
        if currentUser.socialSources[.linkedin] == true {
            inButton.alpha = 1.0
            inButton.tintColor = UIColor(red: 2/255, green: 116/255, blue: 179/255, alpha: 1.0 )
        } else {
            inButton.alpha = 1.0
            inButton.tintColor = .white
        }
    }
    
    fileprivate func updateErrorLabelText(_ _errorText : String) {
        nameErrorLabel.text = _errorText
    }
    
    fileprivate func clearExpertTags() {
        for aView in expertTagList.arrangedSubviews {
            expertTagList.removeArrangedSubview(aView)
            
            if aView.superview != nil {
                aView.removeFromSuperview()
            }
        }
    }
    
    fileprivate func updateExpertiseTags() {
        guard let currentUser = User.currentUser else { return }
        
        clearExpertTags()
        
        for channel in currentUser.approvedChannels {
            let tagButton = PulseButton(title: channel.cTitle ?? "Undefined", isRound: true)
            expertTagList.addArrangedSubview(tagButton)

            tagButton.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
            tagButton.backgroundColor = pulseBlue
            tagButton.setTitleColor(.white, for: UIControlState())
        }
    }
    
    func updateLabels() {
        guard let currentUser = User.currentUser else { return }

        if let _userName = currentUser.name {
            //delegate.updateNav(title: "welcome \(_userName)", image: nil)
            uName.text = _userName
            uName.isUserInteractionEnabled = false
        } else {
            delegate.updateNav(title: "please login", image: nil)
            uName.text = "tap to edit name"
            uName.isUserInteractionEnabled = true
        }
        
        if let _userBio = currentUser.shortBio {
            uShortBio.text = _userBio
        } else {
            uShortBio.text = ""
        }
        
        //add profile pic or use default image
        if currentUser.profilePic != nil || currentUser.thumbPic != nil {
            let _uPic = currentUser.thumbPic != nil ? currentUser.thumbPic : currentUser.profilePic
            _defaultProfileOverlay.isHidden = true
            addUserProfilePic(URL(string: _uPic!))
        } else {
            uProfilePic.image = UIImage(named: "default-profile")
            _defaultProfileOverlay.isHidden = false
            _defaultProfileOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            _defaultProfileOverlay.text = "tap to add image"
            _defaultProfileOverlay.setPreferredFont(UIColor.white, alignment : .center)
            uProfilePic.addSubview(_defaultProfileOverlay)
        }
        
        highlightConnectedSocialSources()
        
        if currentUser.hasExpertise() {
            updateExpertiseTags()
        } else {
            for aView in expertTagList.arrangedSubviews {
                expertTagList.removeArrangedSubview(aView)
                aView.removeFromSuperview()
            }
        }
        
        setNeedsLayout()
    }
    
    fileprivate func linkAccount() {
        //check w/ social source and connect to user profile on firebase
    }
    
    /* TEXT FIELD DELEGATES */
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
        nameErrorLabel.text = ""
    }
    
    func textViewShouldReturn(_ textView: UITextView) -> Bool {
        endEditing(true)
        return true
        // ADD FOR TEXT VIEW
    }

    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        endEditing(true)
        
        GlobalFunctions.validateName(uName.text, completion: {(verified, error) in
            if verified {
                Database.updateUserData(UserProfileUpdateType.displayName, value: self.uName.text!, completion: { (success, error) in
                    if success {
                        //print("updated name in DB")
                    } else {
                        self.setupErrorLabel()
                        self.updateErrorLabelText(error!.localizedDescription)
                    }
                })
            } else {
                self.setupErrorLabel()
                self.updateErrorLabelText(error!.localizedDescription)
            }
        })
        return true
    }

    /*LAYOUT FUNCTIONS */
    fileprivate func setupExpertTags() {
        addSubview(expertiseSection)
        expertiseSection.translatesAutoresizingMaskIntoConstraints = false
        expertiseSection.topAnchor.constraint(equalTo: basicInfoSection.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        expertiseSection.leadingAnchor.constraint(equalTo: basicInfoSection.leadingAnchor).isActive = true
        expertiseSection.trailingAnchor.constraint(equalTo: basicInfoSection.trailingAnchor).isActive = true
        expertiseSection.heightAnchor.constraint(equalToConstant: 200).isActive = true

        expertiseSection.backgroundColor = .white
        expertiseSection.layer.shadowColor = UIColor.darkGray.cgColor
        expertiseSection.layer.shadowOffset = CGSize(width: 1, height: 3)
        expertiseSection.layer.shadowRadius = 2.0
        expertiseSection.layer.shadowOpacity = 0.7

        let expertiseTitleLabel = UILabel()
        expertiseSection.addSubview(expertiseTitleLabel)
        expertiseSection.addSubview(expertTagList)

        expertiseTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        expertiseTitleLabel.topAnchor.constraint(equalTo: expertiseSection.topAnchor, constant: Spacing.xs.rawValue).isActive = true
        expertiseTitleLabel.leadingAnchor.constraint(equalTo: expertiseSection.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        expertiseTitleLabel.trailingAnchor.constraint(equalTo: expertiseSection.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true

        expertiseTitleLabel.text = "expertise"
        expertiseTitleLabel.setFont(FontSizes.title.rawValue, weight: UIFontWeightHeavy, color: .lightGray, alignment: .center)

        expertTagList.translatesAutoresizingMaskIntoConstraints = false
        expertTagList.topAnchor.constraint(equalTo: expertiseTitleLabel.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        expertTagList.trailingAnchor.constraint(equalTo: expertiseSection.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        expertTagList.leadingAnchor.constraint(equalTo: expertiseSection.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        
        expertTagList.distribution = .equalCentering
        expertTagList.alignment = .center
    }
    
    fileprivate func setupSocialButtonsLayout() {
        addSubview(socialSection)
        socialSection.translatesAutoresizingMaskIntoConstraints = false
        socialSection.topAnchor.constraint(equalTo: expertiseSection.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        socialSection.leadingAnchor.constraint(equalTo: expertiseSection.leadingAnchor).isActive = true
        socialSection.trailingAnchor.constraint(equalTo: expertiseSection.trailingAnchor).isActive = true
        socialSection.heightAnchor.constraint(equalToConstant: IconSizes.large.rawValue + Spacing.s.rawValue).isActive = true
        
        socialSection.backgroundColor = .white
        socialSection.layer.shadowColor = UIColor.darkGray.cgColor
        socialSection.layer.shadowOffset = CGSize(width: 1, height: 3)
        socialSection.layer.shadowRadius = 2.0
        socialSection.layer.shadowOpacity = 0.7
        
        let socialTitleLabel = UILabel()
        socialSection.addSubview(socialTitleLabel)
        socialSection.addSubview(socialLinks)
        
        socialTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        socialTitleLabel.topAnchor.constraint(equalTo: socialSection.topAnchor, constant: Spacing.xs.rawValue).isActive = true
        socialTitleLabel.leadingAnchor.constraint(equalTo: socialSection.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        socialTitleLabel.trailingAnchor.constraint(equalTo: socialSection.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        
        socialTitleLabel.text = "connect social"
        socialTitleLabel.setFont(FontSizes.title.rawValue, weight: UIFontWeightHeavy, color: .lightGray, alignment: .center)
        
        socialLinks.translatesAutoresizingMaskIntoConstraints = false
        socialLinks.widthAnchor.constraint(equalTo: socialSection.widthAnchor, multiplier: 0.7).isActive = true
        socialLinks.topAnchor.constraint(equalTo: socialTitleLabel.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        socialLinks.centerXAnchor.constraint(equalTo: socialSection.centerXAnchor).isActive = true
        
        socialLinks.addArrangedSubview(fbButton)
        socialLinks.addArrangedSubview(twtrButton)
        socialLinks.addArrangedSubview(inButton)

        socialLinks.alignment = .center
        socialLinks.distribution = .equalCentering
        socialLinks.spacing = Spacing.m.rawValue
    }
    
    fileprivate func setupProfileSummaryLayout() {
        addSubview(basicInfoSection)
        basicInfoSection.translatesAutoresizingMaskIntoConstraints = false
        basicInfoSection.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.m.rawValue).isActive = true
        basicInfoSection.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.xl.rawValue).isActive = true
        basicInfoSection.heightAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        basicInfoSection.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.xl.rawValue).isActive = true
        
        basicInfoSection.addSubview(uProfilePic)
        basicInfoSection.addSubview(uName)
        basicInfoSection.addSubview(uShortBio)
        
        uProfilePic.translatesAutoresizingMaskIntoConstraints = false
        uProfilePic.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        uProfilePic.heightAnchor.constraint(equalTo: uProfilePic.widthAnchor).isActive = true
        uProfilePic.leadingAnchor.constraint(equalTo: basicInfoSection.leadingAnchor, constant: Spacing.s.rawValue).isActive = true
        uProfilePic.topAnchor.constraint(equalTo: basicInfoSection.topAnchor, constant: Spacing.s.rawValue).isActive = true
        
        uName.translatesAutoresizingMaskIntoConstraints = false
        uName.bottomAnchor.constraint(equalTo: uProfilePic.centerYAnchor).isActive = true
        uName.leadingAnchor.constraint(equalTo: uProfilePic.trailingAnchor, constant: Spacing.s.rawValue).isActive = true
        uName.trailingAnchor.constraint(equalTo: basicInfoSection.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        uName.font = UIFont.systemFont(ofSize: FontSizes.title.rawValue, weight: UIFontWeightHeavy)
        uName.textColor = .lightGray
        
        uShortBio.translatesAutoresizingMaskIntoConstraints = false
        uShortBio.topAnchor.constraint(equalTo: uName.bottomAnchor).isActive = true
        uShortBio.leadingAnchor.constraint(equalTo: uName.leadingAnchor).isActive = true
        uShortBio.trailingAnchor.constraint(equalTo: uName.trailingAnchor).isActive = true
        uShortBio.font = UIFont.systemFont(ofSize: FontSizes.caption.rawValue, weight: UIFontWeightMedium)
        uShortBio.textColor = .lightGray
        uShortBio.numberOfLines = 0
        
        uProfilePic.clipsToBounds = true
        uProfilePic.layer.masksToBounds = true

        uName.textAlignment = .left
        uShortBio.textAlignment = .left
    }
    
    fileprivate func setupErrorLabel() {
        addSubview(nameErrorLabel)
        
        nameErrorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        nameErrorLabel.topAnchor.constraint(equalTo: uName.topAnchor).isActive = true
        nameErrorLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        nameErrorLabel.heightAnchor.constraint(equalTo: uName.heightAnchor).isActive = true
        nameErrorLabel.leadingAnchor.constraint(equalTo: uName.trailingAnchor, constant: 10).isActive = true
        
        nameErrorLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption2)
        nameErrorLabel.backgroundColor = UIColor.gray
        nameErrorLabel.textColor = UIColor.black
        nameErrorLabel.textAlignment = .left
    }
}
