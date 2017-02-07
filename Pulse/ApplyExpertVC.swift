//
//  ApplyExpertVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 1/3/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ApplyExpertVC: UIViewController, XMSegmentedControlDelegate {

    public var selectedTag : Tag!
    
    fileprivate var isLoaded = false
    
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
    
    fileprivate var apply = UIStackView()
    fileprivate var applyTitle = UILabel()
    fileprivate var applySubtitle = UILabel()
    
    fileprivate var isMovedUp = false
    fileprivate let subText1 = "briefly tell us why you will make a great expert"
    fileprivate let subText2 = "tell us why this person would be a great expert"

    fileprivate var hideStatusBar = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !isLoaded {
            setupApply()
            updateHeader()

            view.backgroundColor = UIColor.white
            self.hideKeyboardWhenTappedAround()
            isLoaded = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var prefersStatusBarHidden: Bool {
        return hideStatusBar
    }
    
    fileprivate func updateHeader() {
        let backButton = PulseButton(size: .small, type: .back, isRound : true, hasBackground: true)
        backButton.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        
        if let nav = navigationController as? PulseNavVC {
            nav.setNav(navTitle: nil, screenTitle: "Recommend Experts", screenImage: nil)
            nav.shouldShowScope = true
            nav.updateScopeBar(titles: ["Apply","Recommend"], icons: nil, selected: 0)
            nav.getScopeBar()?.delegate = self

            xmSegmentedControl(nav.getScopeBar()!, selectedSegment: 0)

        } else {
            title = "Recommend an Expert"
        }
    }
    
    func xmSegmentedControl(_ xmSegmentedControl: XMSegmentedControl, selectedSegment: Int) {
        guard selectedTag != nil else { return }
        
        switch selectedSegment {
        case 0:
            if !isApplySetup {
                setupApplyView()
            }
            
            applyView.isHidden = false
            recommendView.isHidden = true
            
            reasonVerified = false
            
            if let tagTitle = selectedTag.tagTitle {
                applyTitle.text = "Become a Verified Expert in\n\(tagTitle.capitalized)"
                applySubtitle.text = "apply to be featured as a trusted expert, respond to questions and showcase your expertise!"
                applyText.text = subText1
            }
            
        case 1:
            if !isRecommendSetup {
                setupRecommendView()
            }
            
            applyView.isHidden = true
            recommendView.isHidden = false

            emailVerified = false
            nameVerified = false
            reasonVerified = false
            
            if let tagTitle = selectedTag.tagTitle {
                applyTitle.text = "Recommend an Expert for\n\(tagTitle.capitalized)"
                applySubtitle.text = "we feature experts so interested users can hear directly from the best trusted voices!"
                applyText.text = subText2
            }
            
        default: return
        }
    }
    
    internal func goBack() {
        let _ = navigationController?.popViewController(animated: true)
    }
    
    internal func askQuestion() {
        applyButton.setDisabled()
        let _loadingIndicator = applyButton.addLoadingIndicator()
        dismissKeyboard()
        
        if selectedTag != nil {
            Database.becomeExpert(tag: selectedTag, applyText: applyText.text, completion: {(success, error) in
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
        
        if selectedTag != nil {
            Database.recommendExpert(tag: selectedTag,
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
        recommendView.topAnchor.constraint(equalTo: apply.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
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

        recommendName.tag = 25
        recommendEmail.tag = 50
        recommendText.tag = 75

        recommendName.delegate = self
        recommendEmail.delegate = self
        recommendText.delegate = self
        
        isRecommendSetup = true
    }
    
    fileprivate func setupApplyView() {
        view.addSubview(applyView)
        
        applyView.translatesAutoresizingMaskIntoConstraints = false
        applyView.topAnchor.constraint(equalTo: apply.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
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
        applyText.tag = 100
        
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        applyButton.topAnchor.constraint(equalTo: applyText.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        applyButton.centerXAnchor.constraint(equalTo: applyView.centerXAnchor).isActive = true
        applyButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
        applyButton.widthAnchor.constraint(equalTo: applyView.widthAnchor).isActive = true
        applyButton.layoutIfNeeded()
        
        applyButton.makeRound()
        applyButton.setTitle("Request Approval", for: UIControlState())
        applyButton.titleLabel!.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        applyButton.setDisabled()
        
        applyButton.addTarget(self, action: #selector(askQuestion), for: .touchUpInside)
        
        isApplySetup = true
    }
    
    fileprivate func setupApply() {
        view.addSubview(apply)
        
        apply.translatesAutoresizingMaskIntoConstraints = false
        apply.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        apply.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        apply.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        apply.axis = .vertical
        
        applyTitle.numberOfLines = 0
        applySubtitle.numberOfLines = 0
        applyTitle.lineBreakMode = .byWordWrapping
        applySubtitle.lineBreakMode = .byWordWrapping
        
        applyTitle.setFont(FontSizes.body.rawValue, weight: UIFontWeightBold, color: UIColor.black, alignment: .center)
        applySubtitle.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: UIColor.gray, alignment: .center)

        apply.addArrangedSubview(applyTitle)
        apply.addArrangedSubview(applySubtitle)
    }
}

//MARK: Text View and Text Field Delegate Methods
extension ApplyExpertVC: UITextFieldDelegate, UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if !isMovedUp {
            apply.frame.origin.y -= 100
            
            if textView.tag == applyText.tag {
                applyView.frame.origin.y -= 100
            } else if textView.tag == recommendText.tag {
                recommendView.frame.origin.y -= 100
            }
            
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
        if isMovedUp {
            apply.frame.origin.y += 100
            
            if textView.tag == applyText.tag {
                applyView.frame.origin.y += 100
            } else if textView.tag == recommendText.tag {
                recommendView.frame.origin.y += 100
            }
            
            isMovedUp = false
        }
        
        if textView.text == "" {
            textView.text = textView.tag == applyText.tag ? subText1 : subText2
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
        if textField.tag == recommendEmail.tag {
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
        } else if textField.tag == recommendName.tag {
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
