//
//  addText.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/16/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class AddText: UIView, UITextViewDelegate, UIGestureRecognizerDelegate {

    public var delegate : ParentTextViewDelegate!
    
    fileprivate var isLoaded = false
    fileprivate var observersAdded = false
    
    fileprivate var txtContainer = UIView()
    fileprivate var txtBody = UITextView()
    fileprivate var txtButton = PulseButton()
    
    fileprivate var txtBottomConstraint : NSLayoutConstraint!
    fileprivate var textViewHeightConstraint : NSLayoutConstraint!
    fileprivate var containerHeightConstraint: NSLayoutConstraint!
    fileprivate var tap: UITapGestureRecognizer!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, buttonText: String, bodyText: String) {
        self.init(frame: frame)
        setupLayout(buttonText: buttonText, bodyText: bodyText)
        txtBody.becomeFirstResponder()

    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        removeGestureRecognizer(tap)
    }
    
    func addObservers() {
        if !observersAdded {
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
            backgroundColor = UIColor.black.withAlphaComponent(0.5)
            
            tap = UITapGestureRecognizer(target: self, action: #selector(dismissView))
            tap.cancelsTouchesInView = false
            tap.isEnabled = true
            addGestureRecognizer(tap)
            
            observersAdded = true
        }
    }
    
    func clickedDone() {
        if delegate != nil, let text = txtBody.text {
            delegate.buttonClicked(text)
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

    func dismissView() {
        if delegate != nil {
            txtBody.resignFirstResponder()
            delegate.dismiss(self)
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            txtBottomConstraint.constant = -keyboardHeight
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        txtBottomConstraint.constant = 0
        txtContainer.layoutIfNeeded()
    }
    
    fileprivate func setupLayout(buttonText : String, bodyText: String) {
        addSubview(txtContainer)
        
        txtContainer.addSubview(txtBody)
        txtContainer.addSubview(txtButton)
        
        txtContainer.translatesAutoresizingMaskIntoConstraints = false
        txtBottomConstraint = txtContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
        txtBottomConstraint.isActive = true
        txtContainer.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        containerHeightConstraint = txtContainer.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue)
        containerHeightConstraint.isActive = true
        txtContainer.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        txtContainer.backgroundColor = .white
        
        txtButton.translatesAutoresizingMaskIntoConstraints = false
        txtButton.trailingAnchor.constraint(equalTo: txtContainer.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        txtButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        txtButton.widthAnchor.constraint(equalTo: txtButton.heightAnchor).isActive = true
        txtButton.centerYAnchor.constraint(equalTo: txtContainer.centerYAnchor).isActive = true
        txtButton.layoutIfNeeded()
        
        txtBody.translatesAutoresizingMaskIntoConstraints = false
        txtBody.centerYAnchor.constraint(equalTo: txtContainer.centerYAnchor).isActive = true
        txtBody.leadingAnchor.constraint(equalTo: txtContainer.leadingAnchor).isActive = true
        txtBody.trailingAnchor.constraint(equalTo: txtButton.leadingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        
        textViewHeightConstraint = txtBody.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue)
        textViewHeightConstraint.isActive = true
        txtBody.layoutIfNeeded()
        
        txtBody.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightThin)
        txtBody.backgroundColor = .white
        txtBody.delegate = self
        txtBody.textColor = UIColor.black
        txtBody.isScrollEnabled = false
        txtBody.text = bodyText
        
        txtButton.makeRound()
        txtButton.setTitle(buttonText, for: UIControlState())
        txtButton.setButtonFont(FontSizes.caption2.rawValue, weight: UIFontWeightBold, color: .white, alignment: .center)
        txtButton.setDisabled()
        txtButton.backgroundColor = .pulseRed
        txtContainer.layoutIfNeeded()
        
        txtButton.addTarget(self, action: #selector(clickedDone), for: .touchUpInside)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text != "" {
            txtButton.setEnabled()
            
            let sizeThatFitsTextView = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
            textViewHeightConstraint.constant = sizeThatFitsTextView.height
            containerHeightConstraint.constant = max(IconSizes.medium.rawValue, sizeThatFitsTextView.height)
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Type your message here" {
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = "Type your message here"
            textView.textColor = UIColor.lightGray
            txtButton.setDisabled()
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            clickedDone()
            textView.resignFirstResponder()
            return false
        }
        
        return textView.text.characters.count + (text.characters.count - range.length) <= 140
    }
}
