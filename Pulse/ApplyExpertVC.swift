//
//  ApplyExpertVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 1/3/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ApplyExpertVC: UIViewController, UITextViewDelegate {

    public var selectedTag : Tag! {
        didSet {
            setAskTag()
        }
    }
    
    fileprivate var isLoaded = false
    fileprivate var applyText = UITextView()
    fileprivate var postButton = PulseButton()
    
    fileprivate var apply = UIStackView()
    fileprivate var applyTitle = UILabel()
    fileprivate var applySubtitle = UILabel()
    
    fileprivate let subText = "briefly tell us why you will make a great expert"
    
    fileprivate var hideStatusBar = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !isLoaded {
            updateHeader()
            setupApply()
            setupApplyBox()
            
            view.backgroundColor = UIColor.white
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
            nav.setNav(navTitle: "Apply to Become an Expert", screenTitle: nil, screenImage: nil)
            nav.shouldShowScope = false
        } else {
            title = "Apply to Become an Expert"
        }
    }
    
    func goBack() {
        let _ = navigationController?.popViewController(animated: true)
    }
    
    func askQuestion() {
        postButton.setDisabled()
        let _loadingIndicator = postButton.addLoadingIndicator()
        dismissKeyboard()
        
        if selectedTag != nil {
            Database.becomeExpert(tag: selectedTag, applyText: applyText.text, completion: {(success, error) in
                if success {
                    let applyConfirmation = UIAlertController(title: "Thanks for applying!",
                                                                 message: "We individually review & hand select the best experts in each area and will get back to you soon!",
                                                                 preferredStyle: .actionSheet)
                    
                    applyConfirmation.addAction(UIAlertAction(title: "done", style: .default, handler: { (action: UIAlertAction!) in
                        self.goBack()
                    }))
                    
                    self.present(applyConfirmation, animated: true, completion: nil)
                    
                    self.postButton.setEnabled()
                    self.postButton.removeLoadingIndicator(_loadingIndicator)
                    
                } else {
                    let applyConfirmation = UIAlertController(title: "Error Applying!", message: error?.localizedDescription, preferredStyle: .actionSheet)
                    
                    applyConfirmation.addAction(UIAlertAction(title: "okay", style: .default, handler: { (action: UIAlertAction!) in
                        applyConfirmation.dismiss(animated: true, completion: nil)
                    }))
                    
                    self.present(applyConfirmation, animated: true, completion: nil)
                    self.postButton.setEnabled()
                    self.postButton.removeLoadingIndicator(_loadingIndicator)
                    
                }
            })
        }
    }
    
    fileprivate func setAskTag() {
        guard selectedTag != nil else { return }
        
        if let tagTitle = selectedTag.tagTitle {
            applyTitle.text = "Become a Verified Expert in\n\(tagTitle.capitalized)"
            applySubtitle.text = "apply to get featured as a trusted expert, respond to questions and get discovered based on your expertise & knowledge!"
            applyText.text = subText
        }
    }
    
    fileprivate func setupApplyBox() {
        view.addSubview(applyText)
        view.addSubview(postButton)
        
        applyText.translatesAutoresizingMaskIntoConstraints = false
        applyText.topAnchor.constraint(equalTo: apply.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        applyText.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        applyText.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        applyText.heightAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        applyText.layoutIfNeeded()
        
        applyText.backgroundColor = UIColor.white
        applyText.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        applyText.layer.borderColor = UIColor.lightGray.cgColor
        applyText.layer.borderWidth = 1.0
        
        applyText.text = subText
        applyText.textColor = UIColor.lightGray
        applyText.delegate = self
        
        postButton.translatesAutoresizingMaskIntoConstraints = false
        postButton.topAnchor.constraint(equalTo: applyText.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        postButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        postButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
        postButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        postButton.layoutIfNeeded()
        
        postButton.makeRound()
        postButton.setTitle("Request Approval", for: UIControlState())
        postButton.titleLabel!.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        postButton.setDisabled()
        
        postButton.addTarget(self, action: #selector(askQuestion), for: .touchUpInside)
    }
    
    fileprivate func setupApply() {
        view.addSubview(apply)
        
        apply.translatesAutoresizingMaskIntoConstraints = false
        apply.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        apply.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
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
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if textView.text == subText {
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text != "" {
            postButton.setEnabled()
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = subText
            textView.textColor = UIColor.lightGray
            postButton.setDisabled()
        }
    }

}
