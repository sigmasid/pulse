//
//  StartChannelVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/30/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class StartChannelVC: PulseVC {
    
    fileprivate var startChannelInfo = PaddingLabel()
    fileprivate var cTitle = UITextField()
    fileprivate var cDescription = UITextView()
    fileprivate var submitButton = UIButton()
    
    internal var descriptionPlaceholder = "briefly tell us what this channel will be about!"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /** HEADER FUNCTIONS **/
    internal func updateHeader() {
        addBackButton()
        
        headerNav?.setNav(title: "Start a New Channel")
        headerNav?.updateBackgroundImage(image: nil)
        headerNav?.showNavbar(animated: true)
    }
    
    internal func handleSubmit() {
        
    }
    
    internal func setupLayout() {
        view.addSubview(startChannelInfo)
        view.addSubview(cTitle)
        view.addSubview(cDescription)
        view.addSubview(submitButton)

        startChannelInfo.translatesAutoresizingMaskIntoConstraints = false
        startChannelInfo.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: Spacing.xxl.rawValue).isActive = true
        startChannelInfo.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        startChannelInfo.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        
        cTitle.translatesAutoresizingMaskIntoConstraints = false
        cTitle.topAnchor.constraint(equalTo: startChannelInfo.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        cTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        cTitle.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        cTitle.layoutIfNeeded()
        
        cDescription.translatesAutoresizingMaskIntoConstraints = false
        cDescription.topAnchor.constraint(equalTo: cTitle.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        cDescription.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        cDescription.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        cDescription.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        cDescription.layoutIfNeeded()
        
        cTitle.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightThin)
        cTitle.layer.addSublayer(GlobalFunctions.addBorders(self.cTitle, _color: UIColor.black, thickness: IconThickness.thin.rawValue))
        cTitle.placeholder = "name of channel"
        
        cDescription.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightThin)
        cDescription.layer.borderColor = UIColor.gray.cgColor
        cDescription.layer.borderWidth = 1.0
        cDescription.text = descriptionPlaceholder
        cDescription.delegate = self
        cDescription.textColor = UIColor.gray.withAlphaComponent(0.7)

        startChannelInfo.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .gray, alignment: .center)
        startChannelInfo.numberOfLines = 3
        startChannelInfo.lineBreakMode = .byWordWrapping
        
        addSubmitButton()
    }

    internal func addSubmitButton() {
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.topAnchor.constraint(equalTo: cDescription.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        submitButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
        submitButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        
        submitButton.layer.cornerRadius = buttonCornerRadius.radius(.regular)
        submitButton.setTitle("Apply", for: UIControlState())
        submitButton.titleLabel!.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        submitButton.setDisabled()
        
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
    }
}

extension StartChannelVC: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView)
    {
        if (textView.text == descriptionPlaceholder)
        {
            textView.text = ""
            textView.textColor = .black
        }
        textView.becomeFirstResponder()
    }
    
    func textViewDidEndEditing(_ textView: UITextView)
    {
        if (textView.text == "")
        {
            textView.text = descriptionPlaceholder
            textView.textColor = .lightGray
        }
        textView.resignFirstResponder()
    }
}
