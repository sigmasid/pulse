//
//  BecomeContributorVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 1/3/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class BecomeContributorVC: PulseVC, XMSegmentedControlDelegate {

    public var selectedChannel : Channel!
    
    fileprivate var applyView = UIView()
    fileprivate var applyText = PaddingTextView()
    fileprivate var applyButton = PulseButton(title: "Request Approval", isRound: true, hasShadow: false)
    fileprivate var isApplySetup = false
    
    fileprivate var recommendView = UIView()
    fileprivate var recommendName = PaddingTextField()
    fileprivate var recommendEmail = PaddingTextField()
    fileprivate var recommendText = PaddingTextView()
    fileprivate var recommendButton = PulseButton(title: "Send Recommendation", isRound: true, hasShadow: false)
    fileprivate var isRecommendSetup = false
    
    fileprivate var nameErrorLabel = UILabel()
    fileprivate var emailErrorLabel = UILabel()
    
    fileprivate var emailVerified = false
    fileprivate var nameVerified = false
    fileprivate var reasonVerified = false
    
    fileprivate var applyStack = UIStackView()
    fileprivate var applySubtitle = UILabel()
    
    fileprivate var scopeBar : XMSegmentedControl!
    
    fileprivate var isMovedUp = false
    fileprivate let subText1 = "tell us why you will make a great contributor"
    fileprivate let subText2 = "tell us why this person would be a great contributor"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !isLoaded {
            setupScope()
            setupApply()
            updateHeader()
            
            hideKeyboardWhenTappedAround()
            isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarHidden = true
        updateHeader()
    }
    
    fileprivate func updateHeader() {
        addBackButton()
        updateChannelImage(channel: selectedChannel)
        tabBarHidden = true
        headerNav?.setNav(title: "Channel Contributors", subtitle: selectedChannel.cTitle)
    }
    
    fileprivate func setupScope() {
        let scopeFrame = CGRect(x: 0, y: 0, width: view.bounds.width, height: SCOPE_HEIGHT)
        scopeBar = XMSegmentedControl(frame: scopeFrame, segmentTitle: ["Apply", "Recommend"] , selectedItemHighlightStyle: .bottomEdge)
        scopeBar.delegate = self
        scopeBar.addBottomBorder(color: .pulseGrey)
        
        scopeBar.backgroundColor = .white
        scopeBar.highlightColor = .pulseBlue
        scopeBar.highlightTint = .black
        scopeBar.tint = .gray
        
        view.addSubview(scopeBar)
    }
    
    func xmSegmentedControl(_ xmSegmentedControl: XMSegmentedControl, selectedSegment: Int) {
        guard selectedChannel != nil else { return }
        
        switch selectedSegment {
        case 0:
            if !isApplySetup {
                setupApplyView()
            }
            
            applyView.isHidden = false
            recommendView.isHidden = true
            
            reasonVerified = false
            
            applySubtitle.text = "Showcase your expertise & brand!\nContributors can showcase new content, start discussions & invite guests!"
            applyText.text = subText1
            
            checkButton()
            view.layoutIfNeeded()
            
        case 1:
            if !isRecommendSetup {
                setupRecommendView()
            }
            
            applyView.isHidden = true
            recommendView.isHidden = false

            emailVerified = false
            nameVerified = false
            reasonVerified = false
            
            applySubtitle.text = "Know someone with standout ideas who would be interested in becoming a contributor? Tell us below!"
            applyText.text = subText2
            
            checkButton()
            view.layoutIfNeeded()
            
        default: return
        }
    }
    
    internal func clickedApply() {
        guard PulseUser.isLoggedIn() else {
            GlobalFunctions.showAlertBlock("Please Login", erMessage: "You need to be logged in to apply!")
            return
        }
        
        applyButton.setDisabled()
        let _loadingIndicator = applyButton.addLoadingIndicator()
        dismissKeyboard()
        
        if selectedChannel != nil {
            PulseDatabase.createContributorInvite(channel: selectedChannel, type: .contributorInvite, description: applyText.text,
                                             toUser: PulseUser.currentUser, toName: PulseUser.currentUser.name, completion: {(inviteID, error) in
                
                if error == nil {
                    let applyConfirmation = UIAlertController(title: "Thanks for applying!",
                                                              message: "We individually review & hand select the best contributors and will get back to you soon!",
                                                              preferredStyle: .actionSheet)
                    
                    applyConfirmation.addAction(UIAlertAction(title: "done", style: .default, handler: {[weak self] (action: UIAlertAction!) in
                        guard let `self` = self else { return }
                        self.goBack()
                    }))
                    
                    self.present(applyConfirmation, animated: true, completion: nil)
                    
                    self.applyButton.setEnabled()
                    self.applyButton.removeLoadingIndicator(_loadingIndicator)
                    
                } else {
                    let applyConfirmation = UIAlertController(title: "Error Applying!", message: error?.localizedDescription, preferredStyle: .actionSheet)
                    
                    applyConfirmation.addAction(UIAlertAction(title: "okay", style: .default, handler: { (action: UIAlertAction!) in
                        applyConfirmation.dismiss(animated: true, completion: nil)
                    }))
                    
                    self.present(applyConfirmation, animated: true, completion: nil)
                    self.applyButton.setEnabled()
                    self.applyButton.removeLoadingIndicator(_loadingIndicator)
                }
            })
        }
    }
    
    internal func clickedRecommend() {
        recommendButton.setDisabled()
        let _loadingIndicator = applyButton.addLoadingIndicator()
        dismissKeyboard()
        
        if selectedChannel != nil {
            PulseDatabase.createContributorInvite(channel: selectedChannel, type: .contributorInvite, description: recommendText.text, toUser: nil,
                                                  toName: recommendName.text ?? "", toEmail: recommendEmail.text!, completion: {[weak self] (inviteID, error) in
                guard let `self` = self else { return }
            
                if error == nil {
                    let applyConfirmation = UIAlertController(title: "Thanks for the recommendation!",
                                                              message: "We review & hand select best contributors and will carefully review your recommendation!",
                                                              preferredStyle: .actionSheet)
                    
                    applyConfirmation.addAction(UIAlertAction(title: "done", style: .default, handler: {[weak self] (action: UIAlertAction!) in
                        guard let `self` = self else { return }
                        self.goBack()
                    }))
                    
                    self.present(applyConfirmation, animated: true, completion: nil)
                    
                    self.recommendButton.setEnabled()
                    self.recommendButton.removeLoadingIndicator(_loadingIndicator)
                    
                } else {
                    let applyConfirmation = UIAlertController(title: "Error Applying!", message: error?.localizedDescription, preferredStyle: .actionSheet)
                    
                    applyConfirmation.addAction(UIAlertAction(title: "okay", style: .default, handler: { (action: UIAlertAction!) in
                        applyConfirmation.dismiss(animated: true, completion: nil)
                    }))
                    
                    self.present(applyConfirmation, animated: true, completion: nil)
                    self.recommendButton.setEnabled()
                    self.recommendButton.removeLoadingIndicator(_loadingIndicator)
                    
                }
            })
        }
    }
    
    fileprivate func checkButton() {
        if recommendView.isHidden {
            reasonVerified ? applyButton.setEnabled() : applyButton.setDisabled()
        } else {
            if emailVerified, nameVerified, reasonVerified {
                recommendButton.setEnabled()
            } else {
                recommendButton.setDisabled()
            }
        }
    }
}

//MARK: Setup UI Items
extension BecomeContributorVC {
    fileprivate func setupRecommendView() {
        view.addSubview(recommendView)

        recommendView.translatesAutoresizingMaskIntoConstraints = false
        recommendView.topAnchor.constraint(equalTo: applyStack.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        recommendView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        recommendView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        recommendView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        recommendView.layoutIfNeeded()
        
        recommendView.addSubview(recommendName)
        recommendView.addSubview(recommendEmail)
        recommendView.addSubview(recommendText)
        recommendView.addSubview(recommendButton)
        recommendView.addSubview(nameErrorLabel)
        recommendView.addSubview(emailErrorLabel)

        recommendName.translatesAutoresizingMaskIntoConstraints = false
        recommendName.topAnchor.constraint(equalTo: recommendView.topAnchor).isActive = true
        recommendName.widthAnchor.constraint(equalTo: recommendView.widthAnchor).isActive = true
        recommendName.centerXAnchor.constraint(equalTo: recommendView.centerXAnchor).isActive = true
        recommendName.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        recommendName.layoutIfNeeded()
        
        nameErrorLabel.translatesAutoresizingMaskIntoConstraints = false
        nameErrorLabel.topAnchor.constraint(equalTo: recommendName.bottomAnchor).isActive = true
        nameErrorLabel.centerXAnchor.constraint(equalTo: recommendView.centerXAnchor).isActive = true
        nameErrorLabel.widthAnchor.constraint(equalTo: recommendView.widthAnchor).isActive = true

        recommendEmail.translatesAutoresizingMaskIntoConstraints = false
        recommendEmail.topAnchor.constraint(equalTo: recommendName.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        recommendEmail.widthAnchor.constraint(equalTo: recommendView.widthAnchor).isActive = true
        recommendEmail.centerXAnchor.constraint(equalTo: recommendView.centerXAnchor).isActive = true
        recommendEmail.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        recommendEmail.layoutIfNeeded()
        
        emailErrorLabel.translatesAutoresizingMaskIntoConstraints = false
        emailErrorLabel.topAnchor.constraint(equalTo: recommendEmail.bottomAnchor).isActive = true
        emailErrorLabel.centerXAnchor.constraint(equalTo: recommendView.centerXAnchor).isActive = true
        emailErrorLabel.widthAnchor.constraint(equalTo: recommendView.widthAnchor).isActive = true

        recommendText.translatesAutoresizingMaskIntoConstraints = false
        recommendText.topAnchor.constraint(equalTo: recommendEmail.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        recommendText.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        recommendText.centerXAnchor.constraint(equalTo: recommendView.centerXAnchor).isActive = true
        recommendText.heightAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        recommendText.layoutIfNeeded()
                
        recommendText.text = "tell us why this person would be a great contributor"
        recommendText.textColor = UIColor.placeholderGrey
        recommendText.delegate = self
        
        recommendButton.translatesAutoresizingMaskIntoConstraints = false
        recommendButton.topAnchor.constraint(equalTo: recommendText.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        recommendButton.centerXAnchor.constraint(equalTo: recommendView.centerXAnchor).isActive = true
        recommendButton.heightAnchor.constraint(equalToConstant: PulseButton.regularButtonHeight).isActive = true
        recommendButton.widthAnchor.constraint(equalTo: recommendView.widthAnchor).isActive = true
        recommendButton.layoutIfNeeded()
        recommendButton.setDisabled()
        recommendButton.makeRound()
        
        recommendButton.addTarget(self, action: #selector(clickedRecommend), for: .touchUpInside)
        recommendEmail.keyboardType = .emailAddress
        
        recommendName.placeholder = "contributor name"
        recommendEmail.placeholder = "contributor email"
        
        emailErrorLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightThin, color: .lightGray, alignment: .left)
        nameErrorLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightThin, color: .lightGray, alignment: .left)

        recommendName.delegate = self
        recommendEmail.delegate = self
        recommendText.delegate = self
        
        isRecommendSetup = true
    }
    
    fileprivate func setupApplyView() {
        view.addSubview(applyView)
        
        applyView.translatesAutoresizingMaskIntoConstraints = false
        applyView.topAnchor.constraint(equalTo: applyStack.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        applyView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        applyView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        applyView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        applyView.layoutIfNeeded()
        
        applyView.addSubview(applyText)
        applyView.addSubview(applyButton)
        
        applyText.translatesAutoresizingMaskIntoConstraints = false
        applyText.topAnchor.constraint(equalTo: applyView.topAnchor).isActive = true
        applyText.widthAnchor.constraint(equalTo: applyView.widthAnchor).isActive = true
        applyText.centerXAnchor.constraint(equalTo: applyView.centerXAnchor).isActive = true
        applyText.heightAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        applyText.layoutIfNeeded()
        
        applyText.text = subText1
        applyText.textColor = UIColor.placeholderGrey
        applyText.delegate = self
        
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        applyButton.topAnchor.constraint(equalTo: applyText.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        applyButton.centerXAnchor.constraint(equalTo: applyView.centerXAnchor).isActive = true
        applyButton.heightAnchor.constraint(equalToConstant: PulseButton.regularButtonHeight).isActive = true
        applyButton.widthAnchor.constraint(equalTo: applyView.widthAnchor).isActive = true
        applyButton.layoutIfNeeded()
        applyButton.setDisabled()
        
        applyButton.addTarget(self, action: #selector(clickedApply), for: .touchUpInside)
        applyButton.makeRound()
        
        applyView.isHidden = false
        recommendView.isHidden = true
        
        isApplySetup = true
    }
    
    fileprivate func setupApply() {
        view.addSubview(applyStack)
        
        applyStack.translatesAutoresizingMaskIntoConstraints = false
        applyStack.topAnchor.constraint(equalTo: scopeBar.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        applyStack.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        applyStack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        applyStack.axis = .vertical
        
        applySubtitle.numberOfLines = 0
        applySubtitle.lineBreakMode = .byWordWrapping
        applySubtitle.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: UIColor.gray, alignment: .center)

        applyStack.addArrangedSubview(applySubtitle)
        applySubtitle.text = "Contributors are thought leaders who create & shape content, start conversations & connect with subscribers!"

        setupApplyView()
    }
}

//MARK: Text View and Text Field Delegate Methods
extension BecomeContributorVC: UITextFieldDelegate, UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if !isMovedUp, textView == recommendText {

            UIView.animate(withDuration: 0.5, animations: {
                self.applyStack.frame.origin.y -= 100
                self.recommendView.frame.origin.y -= 100
            })
            
            view.bringSubview(toFront: scopeBar)
            isMovedUp = true
        }
        
        if textView.text == subText1 || textView.text == subText2 {
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text != "" {
            reasonVerified = true
            checkButton()
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if isMovedUp, textView == recommendText {
            
            UIView.animate(withDuration: 0.5, animations: {
                self.applyStack.frame.origin.y += 100
                self.recommendView.frame.origin.y += 100
            })
            
            isMovedUp = false
        }
        
        if textView.text == "" {
            textView.text = textView == applyText ? subText1 : subText2
            textView.textColor = UIColor.placeholderGrey
            reasonVerified = false
        } else {
            reasonVerified = true
            checkButton()
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        nameErrorLabel.text = ""
        emailErrorLabel.text = ""
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == recommendEmail {
            GlobalFunctions.validateEmail(recommendEmail.text, completion: {(verified, error) in
                if !verified {
                    self.emailVerified = false
                    DispatchQueue.main.async {
                        self.emailErrorLabel.text = error!.localizedDescription
                    }
                } else {
                    self.emailVerified = true
                    self.emailErrorLabel.text = ""
                }
            })
        } else if textField == recommendName {
            GlobalFunctions.validateName(recommendName.text, completion: {(verified, error) in
                if !verified {
                    self.nameVerified = false
                    DispatchQueue.main.async {
                        self.nameErrorLabel.text = error!.localizedDescription
                    }
                }  else {
                    self.nameVerified = true
                    self.nameErrorLabel.text = ""
                }
            })
        }
        
        checkButton()
    }
}
