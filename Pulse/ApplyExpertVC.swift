//
//  ApplyExpertVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 1/3/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ApplyExpertVC: PulseVC, XMSegmentedControlDelegate {

    public var selectedChannel : Channel!
    
    fileprivate var applyView = UIView()
    fileprivate var applyText = UITextView()
    fileprivate var applyButton = PulseButton()
    fileprivate var isApplySetup = false
    
    fileprivate var recommendView = UIView()
    fileprivate var recommendName = UITextField()
    fileprivate var recommendEmail = UITextField()
    fileprivate var recommendText = UITextView()
    fileprivate var recommendButton = PulseButton()
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
    fileprivate let subText1 = "tell us why you will make a great expert"
    fileprivate let subText2 = "tell us why this person would be a great expert"
    
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
    }
    
    fileprivate func updateHeader() {
        addBackButton()
        tabBarHidden = true

        headerNav?.setNav(title: "Become Contributor", subtitle: selectedChannel.cTitle)
    }
    
    fileprivate func setupScope() {
        let scopeFrame = CGRect(x: 0, y: 0, width: view.bounds.width, height: scopeBarHeight)
        scopeBar = XMSegmentedControl(frame: scopeFrame, segmentTitle: ["Apply", "Recommend"] , selectedItemHighlightStyle: .bottomEdge)
        scopeBar.delegate = self
        scopeBar.addBottomBorder()
        
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
            
            if let title = selectedChannel.cTitle {
                headerNav?.setNav(title: "Become Contributor", subtitle: title)
                applySubtitle.text = "Contributors are thought leaders who create & shape content, start conversations & answer questions!"
                applyText.text = subText1
            }
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
            
            if let title = selectedChannel.cTitle {
                headerNav?.setNav(title: "Recommend Experts", subtitle: title)
                applySubtitle.text = "Know someone with standout ideas who should be featured on this topic? Tell us below!"
                applyText.text = subText2
            }
            view.layoutIfNeeded()
            
        default: return
        }
    }
    
    internal func clickedApply() {
        applyButton.setDisabled()
        let _loadingIndicator = applyButton.addLoadingIndicator()
        dismissKeyboard()
        
        if selectedChannel != nil {
            Database.contributorRequest(channel: selectedChannel, applyText: applyText.text, completion: {(success, error) in
                if success {
                    let applyConfirmation = UIAlertController(title: "Thanks for applying!",
                                                            message: "We individually review & hand select the best experts for each channel and will get back to you soon!",
                                                            preferredStyle: .actionSheet)
                    
                    applyConfirmation.addAction(UIAlertAction(title: "done", style: .default, handler: { (action: UIAlertAction!) in
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
    
    internal func recommendExpert() {
        recommendButton.setDisabled()
        let _loadingIndicator = applyButton.addLoadingIndicator()
        dismissKeyboard()
        
        if selectedChannel != nil {
            Database.recommendContributorRequest(channel: selectedChannel,
                                          applyName: recommendName.text!,
                                          applyEmail: recommendEmail.text!,
                                          applyText: recommendText.text, completion: { (success, error) in
                if success {
                    let applyConfirmation = UIAlertController(title: "Recommendation Sent!",
                                                              message: "We review & hand select the best experts for each channel and will carefully review your recommendation!",
                                                              preferredStyle: .actionSheet)
                    
                    applyConfirmation.addAction(UIAlertAction(title: "done", style: .default, handler: { (action: UIAlertAction!) in
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
extension ApplyExpertVC {
    fileprivate func setupRecommendView() {
        view.addSubview(recommendView)

        recommendView.translatesAutoresizingMaskIntoConstraints = false
        recommendView.topAnchor.constraint(equalTo: applyStack.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        recommendView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
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
        recommendName.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
        recommendName.layoutIfNeeded()
        
        nameErrorLabel.translatesAutoresizingMaskIntoConstraints = false
        nameErrorLabel.topAnchor.constraint(equalTo: recommendName.bottomAnchor).isActive = true
        nameErrorLabel.centerXAnchor.constraint(equalTo: recommendView.centerXAnchor).isActive = true
        nameErrorLabel.widthAnchor.constraint(equalTo: recommendView.widthAnchor).isActive = true

        recommendEmail.translatesAutoresizingMaskIntoConstraints = false
        recommendEmail.topAnchor.constraint(equalTo: recommendName.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        recommendEmail.widthAnchor.constraint(equalTo: recommendView.widthAnchor).isActive = true
        recommendEmail.centerXAnchor.constraint(equalTo: recommendView.centerXAnchor).isActive = true
        recommendEmail.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
        recommendEmail.layoutIfNeeded()
        
        emailErrorLabel.translatesAutoresizingMaskIntoConstraints = false
        emailErrorLabel.topAnchor.constraint(equalTo: recommendEmail.bottomAnchor).isActive = true
        emailErrorLabel.centerXAnchor.constraint(equalTo: recommendView.centerXAnchor).isActive = true
        emailErrorLabel.widthAnchor.constraint(equalTo: recommendView.widthAnchor).isActive = true

        recommendText.translatesAutoresizingMaskIntoConstraints = false
        recommendText.topAnchor.constraint(equalTo: recommendEmail.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        recommendText.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        recommendText.centerXAnchor.constraint(equalTo: recommendView.centerXAnchor).isActive = true
        recommendText.heightAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        recommendText.layoutIfNeeded()
        
        recommendText.backgroundColor = UIColor.white
        recommendText.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        recommendText.layer.borderColor = UIColor.lightGray.cgColor
        recommendText.layer.borderWidth = 1.0
        
        recommendText.text = "tell us why this person would be a great expert"
        recommendText.textColor = UIColor.lightGray
        recommendText.delegate = self
        
        recommendButton.translatesAutoresizingMaskIntoConstraints = false
        recommendButton.topAnchor.constraint(equalTo: recommendText.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        recommendButton.centerXAnchor.constraint(equalTo: recommendView.centerXAnchor).isActive = true
        recommendButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
        recommendButton.widthAnchor.constraint(equalTo: recommendView.widthAnchor).isActive = true
        recommendButton.layoutIfNeeded()
        
        recommendButton.makeRound()
        recommendButton.setTitle("Send Recommendation", for: UIControlState())
        recommendButton.titleLabel!.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        recommendButton.setDisabled()
        
        recommendButton.addTarget(self, action: #selector(recommendExpert), for: .touchUpInside)
        
        recommendEmail.borderStyle = .none
        recommendName.borderStyle = .none
        
        recommendName.layer.addSublayer(GlobalFunctions.addBorders(self.recommendName, _color: UIColor.black, thickness: IconThickness.thin.rawValue))
        recommendEmail.layer.addSublayer(GlobalFunctions.addBorders(self.recommendEmail, _color: UIColor.black, thickness: IconThickness.thin.rawValue))
        
        recommendName.placeholder = "expert name"
        recommendEmail.placeholder = "expert email"
        
        recommendName.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        recommendEmail.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
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
        applyView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
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
        
        applyText.backgroundColor = UIColor.white
        applyText.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        applyText.layer.borderColor = UIColor.lightGray.cgColor
        applyText.layer.borderWidth = 1.0
        
        applyText.text = subText1
        applyText.textColor = UIColor.lightGray
        applyText.delegate = self
        
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        applyButton.topAnchor.constraint(equalTo: applyText.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        applyButton.centerXAnchor.constraint(equalTo: applyView.centerXAnchor).isActive = true
        applyButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
        applyButton.widthAnchor.constraint(equalTo: applyView.widthAnchor).isActive = true
        applyButton.layoutIfNeeded()
        
        applyButton.makeRound()
        applyButton.setTitle("Request Approval", for: UIControlState())
        applyButton.titleLabel!.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        applyButton.setDisabled()
        
        applyButton.addTarget(self, action: #selector(clickedApply), for: .touchUpInside)
        
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
        applySubtitle.text = "Experts are thought leaders who create & shape content, start conversations & answer questions!"

        setupApplyView()
    }
}

//MARK: Text View and Text Field Delegate Methods
extension ApplyExpertVC: UITextFieldDelegate, UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if !isMovedUp, textView == recommendText {
            print("apply stack original frame is \(self.applyStack.frame)")

            UIView.animate(withDuration: 0.5, animations: {
                self.applyStack.frame.origin.y -= 100
                self.recommendView.frame.origin.y -= 100
                print("apply stack frame is \(self.applyStack.frame)")
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
            textView.textColor = UIColor.lightGray
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
