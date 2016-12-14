//
//  ProfileSummary.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/21/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class ProfileSummary: UIView, UITextFieldDelegate, UITextViewDelegate {
    
    fileprivate var uProfilePic = UIImageView()
    fileprivate var uName = UITextField()
    fileprivate var uShortBio = UILabel()
    fileprivate var uMessages = UIButton()
    fileprivate var nameErrorLabel = UILabel()
    
    fileprivate var expertiseTitleLabel = UILabel()
    fileprivate var expertTagList = PulseMenu(_axis: .vertical, _spacing: Spacing.xs.rawValue)
    fileprivate lazy var tagRow1 = PulseMenu(_axis: .horizontal, _spacing: Spacing.xs.rawValue)
    fileprivate lazy var tagRow2 = PulseMenu(_axis: .horizontal, _spacing: Spacing.xs.rawValue)
    fileprivate lazy var tagRow3 = PulseMenu(_axis: .horizontal, _spacing: Spacing.xs.rawValue)
    
    fileprivate var socialLinks = UIStackView()
    fileprivate var inButton = UIButton()
    fileprivate var twtrButton = UIButton()
    fileprivate var fbButton = UIButton()

    fileprivate var tapGesture : UITapGestureRecognizer?
    fileprivate var isLoaded = false
    
    var delegate : accountDelegate!
    
    fileprivate lazy var _defaultProfileOverlay = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        if !isLoaded {
            setupProfileSummaryLayout()
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
                    })
                }
            }
        }
    }
    
    fileprivate func highlightConnectedSocialSources() {
        guard let currentUser = User.currentUser else { return }

        if currentUser.socialSources[.facebook] != true {
            fbButton.alpha = 0.5
            fbButton.backgroundColor = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 1.0 )
        } else if currentUser.socialSources[.facebook] == true {
            fbButton.alpha = 1.0
            fbButton.backgroundColor = UIColor(red: 78/255, green: 99/255, blue: 152/255, alpha: 1.0 )
        }
        
        if currentUser.socialSources[.twitter] != true {
            twtrButton.alpha = 0.5
            twtrButton.backgroundColor = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 1.0 )
        }  else if currentUser.socialSources[.twitter] == true {
            twtrButton.alpha = 1.0
            twtrButton.backgroundColor = UIColor(red: 58/255, green: 185/255, blue: 228/255, alpha: 1.0 )
        }
        
        if currentUser.socialSources[.linkedin] != true {
            inButton.alpha = 0.5
            inButton.backgroundColor = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 1.0 )
        }  else if currentUser.socialSources[.linkedin] == true {
            inButton.alpha = 1.0
            inButton.backgroundColor = UIColor(red: 2/255, green: 116/255, blue: 179/255, alpha: 1.0 )
        }
    }
    
    fileprivate func updateErrorLabelText(_ _errorText : String) {
        nameErrorLabel.text = _errorText
    }
    
    fileprivate func updateExpertiseTags() {
        guard let currentUser = User.currentUser else { return }
        
        switch currentUser.expertiseTags.count {
        case 0:
            return
        case 1..<4:
            tagRow1.alignment = .firstBaseline

            expertTagList.addArrangedSubview(tagRow1)
            
        case 4..<7:
            expertTagList.addArrangedSubview(tagRow1)
            expertTagList.addArrangedSubview(tagRow2)
            
            tagRow1.alignment = .firstBaseline
            tagRow2.alignment = .firstBaseline

        case 7..<10:
            expertTagList.addArrangedSubview(tagRow1)
            expertTagList.addArrangedSubview(tagRow2)
            expertTagList.addArrangedSubview(tagRow3)
            
            tagRow1.alignment = .firstBaseline
            tagRow2.alignment = .firstBaseline
            tagRow3.alignment = .firstBaseline

        default:
            expertTagList.addArrangedSubview(tagRow1)
            expertTagList.addArrangedSubview(tagRow2)
            expertTagList.addArrangedSubview(tagRow3)
            
            tagRow1.alignment = .firstBaseline
            tagRow2.alignment = .firstBaseline
            tagRow3.alignment = .firstBaseline
            //show more button
        }
        
        for (offset : index, (key : _, value : val)) in currentUser.expertiseTags.enumerated() {
            let tagLabel = PaddingLabel()
            tagLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .darkGray, alignment: .left)
            
            tagLabel.backgroundColor = .white
            tagLabel.text = val
            tagLabel.numberOfLines = 3
            
            if index < 3 {
                tagRow1.addArrangedSubview(tagLabel)
                
            } else if index < 6 {
                tagRow2.addArrangedSubview(tagLabel)
            } else {
                tagRow3.addArrangedSubview(tagLabel)
            }
            
            tagLabel.layer.shadowColor = UIColor.black.cgColor
            tagLabel.layer.shadowOffset = CGSize(width: 2, height: 4)
            tagLabel.layer.shadowRadius = 4.0
            tagLabel.layer.shadowOpacity = 0.7
            
            tagLabel.leftInset = 2.5
            tagLabel.rightInset = 2.5
            tagLabel.topInset = 5
            tagLabel.bottomInset = 5

            tagLabel.layoutIfNeeded()
        }
    }
    
    func updateLabels() {
        guard let currentUser = User.currentUser else { return }

        if let _userName = currentUser.name {
            delegate.updateNav(title: "welcome \(_userName)")
            uName.text = _userName
            uName.isUserInteractionEnabled = false
        } else {
            delegate.updateNav(title: "please login")
            uName.text = "tap to edit name"
            uName.isUserInteractionEnabled = true
        }
        
        var fontAttributes = [ NSFontAttributeName : UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightHeavy)]
        var titleHeight = GlobalFunctions.getLabelSize(title: uName.text!, width: uName.frame.width, fontAttributes: fontAttributes)
        uName.heightAnchor.constraint(equalToConstant: titleHeight).isActive = true
        uName.layoutIfNeeded()

        if let _userBio = currentUser.shortBio {
            uShortBio.text = _userBio
        } else {
            uShortBio.text = ""
        }
        
        fontAttributes = [ NSFontAttributeName : UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightHeavy)]
        titleHeight = GlobalFunctions.getLabelSize(title: uShortBio.text!, width: uName.frame.width, fontAttributes: fontAttributes)
        uShortBio.heightAnchor.constraint(equalToConstant: titleHeight).isActive = true
        uShortBio.layoutIfNeeded()

        
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
            setupExpertTags()
            updateExpertiseTags()
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
        addSubview(expertiseTitleLabel)
        addSubview(expertTagList)
        
        expertiseTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        expertiseTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        expertiseTitleLabel.topAnchor.constraint(equalTo: uShortBio.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        expertiseTitleLabel.leadingAnchor.constraint(equalTo: uShortBio.leadingAnchor).isActive = true

        expertiseTitleLabel.text = "Expert in"
        expertiseTitleLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightHeavy, color: .black, alignment: .left)
        expertiseTitleLabel.layoutIfNeeded()
        
        expertTagList.translatesAutoresizingMaskIntoConstraints = false
        expertTagList.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        expertTagList.topAnchor.constraint(equalTo: expertiseTitleLabel.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        expertTagList.leadingAnchor.constraint(equalTo: expertiseTitleLabel.leadingAnchor).isActive = true
        expertTagList.layoutIfNeeded()
        
        expertTagList.distribution = .equalCentering
        expertTagList.alignment = .top
    }
    
    fileprivate func setupSocialButtonsLayout() {
        addSubview(socialLinks)
        
        socialLinks.translatesAutoresizingMaskIntoConstraints = false
        socialLinks.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue * 3 + Spacing.m.rawValue * 2).isActive = true
        socialLinks.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        socialLinks.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -IconSizes.large.rawValue).isActive = true
        socialLinks.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        socialLinks.layoutIfNeeded()
        
        fbButton.setImage(UIImage(named: "facebook-icon"), for: UIControlState())
        twtrButton.setImage(UIImage(named: "twitter-icon"), for: UIControlState())
        inButton.setImage(UIImage(named: "linkedin-icon"), for: UIControlState())
        
        fbButton.backgroundColor = UIColor(red: 78/255, green: 99/255, blue: 152/255, alpha: 1.0)
        twtrButton.backgroundColor = UIColor(red: 58/255, green: 185/255, blue: 228/255, alpha: 1.0)
        inButton.backgroundColor = UIColor(red: 2/255, green: 116/255, blue: 179/255, alpha: 1.0)
        
        socialLinks.addArrangedSubview(fbButton)
        socialLinks.addArrangedSubview(twtrButton)
        socialLinks.addArrangedSubview(inButton)
        
        fbButton.translatesAutoresizingMaskIntoConstraints = false
        fbButton.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        fbButton.widthAnchor.constraint(equalTo: fbButton.heightAnchor).isActive = true
        
        twtrButton.translatesAutoresizingMaskIntoConstraints = false
        twtrButton.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        twtrButton.widthAnchor.constraint(equalTo: twtrButton.heightAnchor).isActive = true
        
        inButton.translatesAutoresizingMaskIntoConstraints = false
        inButton.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        inButton.widthAnchor.constraint(equalTo: inButton.heightAnchor).isActive = true
        
        socialLinks.alignment = .center
        socialLinks.distribution = .fillEqually
        socialLinks.spacing = Spacing.m.rawValue
        
        fbButton.layoutIfNeeded()
        twtrButton.layoutIfNeeded()
        inButton.layoutIfNeeded()
        
        fbButton.makeRound()
        twtrButton.makeRound()
        inButton.makeRound()
    }
    
    fileprivate func setupProfileSummaryLayout() {
        addSubview(uProfilePic)
        addSubview(uName)
        addSubview(uShortBio)
        addSubview(uMessages)
        
        uProfilePic.translatesAutoresizingMaskIntoConstraints = false
        uProfilePic.widthAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        uProfilePic.heightAnchor.constraint(equalTo: uProfilePic.widthAnchor).isActive = true
        uProfilePic.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        uProfilePic.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.l.rawValue).isActive = true
        uProfilePic.layoutIfNeeded()
        
        uName.translatesAutoresizingMaskIntoConstraints = false
        uName.topAnchor.constraint(equalTo: uProfilePic.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        uName.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6).isActive = true
        uName.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        uName.font = UIFont.systemFont(ofSize: FontSizes.body2.rawValue, weight: UIFontWeightHeavy)

        uShortBio.translatesAutoresizingMaskIntoConstraints = false
        uShortBio.topAnchor.constraint(equalTo: uName.bottomAnchor).isActive = true
        uShortBio.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6).isActive = true
        uShortBio.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        uShortBio.font = UIFont.systemFont(ofSize: FontSizes.body2.rawValue, weight: UIFontWeightMedium)
        
        uMessages.translatesAutoresizingMaskIntoConstraints = false
        uMessages.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        uMessages.heightAnchor.constraint(equalTo: uMessages.widthAnchor).isActive = true
        uMessages.leadingAnchor.constraint(equalTo: uProfilePic.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
        uMessages.bottomAnchor.constraint(equalTo: uProfilePic.topAnchor, constant: Spacing.s.rawValue).isActive = true
        uMessages.layoutIfNeeded()
        
        uMessages.titleEdgeInsets = UIEdgeInsetsMake(0, 0, uMessages.frame.height / 4, 0)
        uMessages.titleLabel!.font = UIFont.systemFont(ofSize: FontSizes.body2.rawValue, weight: UIFontWeightHeavy)
        uMessages.titleLabel!.textColor = UIColor.white
        uMessages.titleLabel!.textAlignment = .center
        uMessages.setBackgroundImage(UIImage(named: "count-label"), for: UIControlState())
        uMessages.imageView?.contentMode = .scaleAspectFit
        uMessages.titleLabel?.sizeToFit()
        
        uProfilePic.layer.cornerRadius = 5
        uProfilePic.clipsToBounds = true
        uProfilePic.layer.masksToBounds = true
        
        uName.textAlignment = .center
        uShortBio.textAlignment = .center
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
