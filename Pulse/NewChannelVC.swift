//
//  StartChannelVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/30/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class NewChannelVC: PulseVC {
    
    fileprivate var startChannelInfo = PaddingLabel()
    fileprivate var cTitle = UITextField()
    fileprivate var cDescription = UITextView()
    fileprivate var submitButton = UIButton()
    
    internal var descriptionPlaceholder = "briefly tell us what your channel will be about!"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !isLoaded {
            setupLayout()
            updateHeader()
            hideKeyboardWhenTappedAround()
            
            isLoaded=true
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeader()
    }
    
    /** HEADER FUNCTIONS **/
    internal func updateHeader() {
        addBackButton()
        
        headerNav?.setNav(title: "Start a New Channel")
        headerNav?.updateBackgroundImage(image: nil)
        headerNav?.showNavbar(animated: true)
    }
    
    internal func handleSubmit() {
        let loading = submitButton.addLoadingIndicator()
        submitButton.setDisabled()
        
        PulseDatabase.addNewChannel(cTitle: cTitle.text!, cDescription: cDescription.text!, completion: {(success, error) in
            success ? self.showSuccessMenu(): self.showErrorMenu(errorTitle: "Error Submitting Request", error: error!)
            loading.removeFromSuperview()
        })
    }
    
    internal func showErrorMenu(errorTitle : String, error : Error) {
        let menu = UIAlertController(title: errorTitle, message: error.localizedDescription, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "cancel", style: .default, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
            self.submitButton.setEnabled()
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func showSuccessMenu() {
        let menu = UIAlertController(title: "All Set! Request sent",
                                     message: "You will hear back from the Pulse Team shortly",
                                     preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "done", style: .default, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
            self.submitButton.setEnabled()
            self.goBack()
        }))
        
        present(menu, animated: true, completion: nil)
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
        cTitle.topAnchor.constraint(equalTo: startChannelInfo.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        cTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        cTitle.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        cTitle.layoutIfNeeded()
        
        cDescription.translatesAutoresizingMaskIntoConstraints = false
        cDescription.topAnchor.constraint(equalTo: cTitle.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        cDescription.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        cDescription.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        cDescription.heightAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        cDescription.layoutIfNeeded()
        
        cTitle.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightThin)
        cTitle.layer.addSublayer(GlobalFunctions.addBorders(self.cTitle, _color: UIColor.black, thickness: IconThickness.thin.rawValue))
        cTitle.placeholder = "name of channel"
        cTitle.delegate = self
        
        cDescription.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightThin)
        cDescription.layer.borderColor = UIColor.black.cgColor
        cDescription.layer.borderWidth = 1.0
        cDescription.text = descriptionPlaceholder
        cDescription.delegate = self
        cDescription.textColor = UIColor.gray.withAlphaComponent(0.7)

        startChannelInfo.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .gray, alignment: .center)
        startChannelInfo.numberOfLines = 0
        startChannelInfo.lineBreakMode = .byWordWrapping
        startChannelInfo.text = "got an idea to create the next ESPN, CNBC or HGTV? Or maybe the next Vogue? We are looking for creative innovators who want to push the boundaries of content creation! Interested?"
        addSubmitButton()
    }

    internal func addSubmitButton() {
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.topAnchor.constraint(equalTo: cDescription.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
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

extension NewChannelVC: UITextFieldDelegate, UITextViewDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text != "", cDescription.text != "", cDescription.text != descriptionPlaceholder {
            self.submitButton.setEnabled()
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if (textView.text == descriptionPlaceholder) {
            textView.text = ""
            textView.textColor = .black
        }
        textView.becomeFirstResponder()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if (textView.text == "") {
            textView.text = descriptionPlaceholder
            textView.textColor = .lightGray
        } else if cTitle.text != "" {
            self.submitButton.setEnabled()
        }
        textView.resignFirstResponder()
    }
}
