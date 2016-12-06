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
    fileprivate var uShortBio = UITextView()
    fileprivate var uMessages = UIButton()
    fileprivate var nameErrorLabel = UILabel()

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
            
            uShortBio.delegate = self

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
        if User.currentUser?.socialSources[.facebook] != true {
            fbButton.alpha = 0.5
            fbButton.backgroundColor = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 1.0 )
        } else if User.currentUser?.socialSources[.facebook] == true {
            fbButton.alpha = 1.0
            fbButton.backgroundColor = UIColor(red: 78/255, green: 99/255, blue: 152/255, alpha: 1.0 )
        }
        
        if User.currentUser?.socialSources[.twitter] != true {
            twtrButton.alpha = 0.5
            twtrButton.backgroundColor = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 1.0 )
        }  else if User.currentUser?.socialSources[.twitter] == true {
            twtrButton.alpha = 1.0
            twtrButton.backgroundColor = UIColor(red: 58/255, green: 185/255, blue: 228/255, alpha: 1.0 )
        }
        
        if User.currentUser?.socialSources[.linkedin] != true {
            inButton.alpha = 0.5
            inButton.backgroundColor = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 1.0 )
        }  else if User.currentUser?.socialSources[.linkedin] == true {
            inButton.alpha = 1.0
            inButton.backgroundColor = UIColor(red: 2/255, green: 116/255, blue: 179/255, alpha: 1.0 )
        }
    }
    
    fileprivate func updateErrorLabelText(_ _errorText : String) {
        nameErrorLabel.text = _errorText
    }
    
    func updateLabels() {
        if let _userName = User.currentUser!.name {
            delegate.updateNav(title: "welcome \(_userName)")
            uName.text = _userName
            uName.isUserInteractionEnabled = false
        } else {
            delegate.updateNav(title: "please login")
            uName.text = "tap to edit name"
            uName.isUserInteractionEnabled = true
        }
        
        if let _userBio = User.currentUser!.shortBio {
            uShortBio.text = _userBio
            uShortBio.isUserInteractionEnabled = false
        } else {
            uShortBio.text = "tap to edit bio"
            uShortBio.isUserInteractionEnabled = true
        }
        
        //add profile pic or use default image
        if User.currentUser!.profilePic != nil || User.currentUser!.thumbPic != nil {
            let _uPic = User.currentUser!.thumbPic != nil ? User.currentUser!.thumbPic : User.currentUser!.profilePic
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
        setNeedsLayout()
    }
    
    fileprivate func linkAccount() {
        //check w/ social source and connect to user profile on firebase
    }
    
    /* TEXT FIELD DELEGATES */
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.text = ""
    }
    
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
    fileprivate func setupSocialButtonsLayout() {
        addSubview(socialLinks)
        
        socialLinks.translatesAutoresizingMaskIntoConstraints = false
        socialLinks.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue * 3 + Spacing.m.rawValue * 2).isActive = true
        socialLinks.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        socialLinks.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -IconSizes.xLarge.rawValue).isActive = true
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
        uName.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        uName.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        uName.heightAnchor.constraint(equalToConstant: Spacing.s.rawValue).isActive = true
        uName.layoutIfNeeded()
        uName.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightHeavy)
        
        uShortBio.translatesAutoresizingMaskIntoConstraints = false
        uShortBio.topAnchor.constraint(equalTo: uName.bottomAnchor).isActive = true
        uShortBio.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6).isActive = true
        uShortBio.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        uShortBio.layoutIfNeeded()
        uShortBio.font = UIFont.systemFont(ofSize: FontSizes.caption.rawValue, weight: UIFontWeightMedium)
        
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
