//
//  RecordedAnswerOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/6/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class RecordingOverlay: UIView {
    fileprivate var saveButton = PulseButton(size: .small, type: .save, isRound: true, hasBackground: false, tint: .white)
    fileprivate var closeButton = PulseButton(size: .small, type: .close, isRound : true, hasBackground: false, tint: .white)
    fileprivate var titleButton = PulseButton(size: .small, type: .text, isRound: true, hasBackground: false, tint: .white)

    fileprivate var addMoreStack = PulseMenu(_axis: .vertical, _spacing: Spacing.xs.rawValue)
    fileprivate var addMoreLabel = UILabel()
    fileprivate var addMoreButton = PulseButton(size: .large, type: .addCircle, isRound: true, hasBackground: false, tint: .pulseBlue)

    fileprivate var postLabel = UILabel()
    fileprivate var postStack = PulseMenu(_axis: .vertical, _spacing: Spacing.xs.rawValue)
    fileprivate var postButton = PulseButton(size: .large, type: .postCircle, isRound: true, hasBackground: false, tint: .pulseBlue)
    
    fileprivate var progressLabel = UILabel()
    fileprivate var progressBar = UIProgressView()
    
    fileprivate lazy var addTitleField = UITextView()
    fileprivate var titleBottomConstraint : NSLayoutConstraint!
    public var title : String = ""
    
    fileprivate var pagers = [UIView]()
    fileprivate lazy var pagersStack = UIStackView()
    fileprivate var isTitleSetup = false
    fileprivate var observersAdded = false
    
    internal enum ControlButtons: Int {
        case save, post, close, addMore
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        addFooterButtons()
        addCloseButton()
        addSaveButton()
        addTitleButton()
        
        setupPagers()
        
        if !observersAdded {
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
            observersAdded = true
        }
        
    }
    
    func gestureRecognizer(_ gesture: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer : UIGestureRecognizer) -> Bool {
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func point(inside point : CGPoint, with event : UIEvent?) -> Bool {
        for _view in self.subviews {
            if (_view.isUserInteractionEnabled == true && _view.point(inside: self.convert(point, to: _view) , with: event)) {
                return true
            }
        }
        return false
    }
    
    func getButton(_ buttonName : ControlButtons) -> UIButton {
        switch buttonName {
        case .save: return saveButton
        case .post: return postButton
        case .close: return closeButton
        case .addMore: return addMoreButton
        }
    }
    
    func getTitleField() -> UITextView {
        return addTitleField
    }
        
    fileprivate func addFooterButtons() {
        addSubview(postButton)
        addSubview(addMoreButton)
        
        addSubview(postLabel)
        addSubview(addMoreLabel)

        postButton.translatesAutoresizingMaskIntoConstraints = false
        postButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.m.rawValue).isActive = true
        postButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: frame.width / 4).isActive = true
        postButton.layoutIfNeeded()
        
        addMoreButton.translatesAutoresizingMaskIntoConstraints = false
        addMoreButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.m.rawValue).isActive = true
        addMoreButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -frame.width / 4).isActive = true
        addMoreButton.layoutIfNeeded()

        postLabel.text = "Post"
        addMoreLabel.text = "Add More"

        postLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightMedium, color: .white, alignment: .center)
        addMoreLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightMedium, color: .white, alignment: .center)
        
        postLabel.setBlurredBackground()
        addMoreLabel.setBlurredBackground()
        
        addMoreLabel.translatesAutoresizingMaskIntoConstraints = false
        addMoreLabel.centerXAnchor.constraint(equalTo: addMoreButton.centerXAnchor).isActive = true
        addMoreLabel.topAnchor.constraint(equalTo: addMoreButton.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        
        postLabel.translatesAutoresizingMaskIntoConstraints = false
        postLabel.centerXAnchor.constraint(equalTo: postButton.centerXAnchor).isActive = true
        postLabel.topAnchor.constraint(equalTo: postButton.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        
        postLabel.layoutIfNeeded()
        addMoreLabel.layoutIfNeeded()
    }
    
    func userClickedAddTitle(sender: UIButton) {
        showAddTitleField(makeFirstResponder: true)
    }
    
    func showAddTitleField(makeFirstResponder: Bool, placeholderText: String) {
        if !isTitleSetup {
            setupTitleField(placeholderText: placeholderText)
        }
        
        addTitleField.text = placeholderText
        titleBottomConstraint.constant = -Spacing.xl.rawValue - IconSizes.medium.rawValue
        
        if makeFirstResponder {
            addTitleField.becomeFirstResponder()
        }
    }
    
    func showAddTitleField(makeFirstResponder: Bool) {
        showAddTitleField(makeFirstResponder: makeFirstResponder, placeholderText: title)
    }
    
    func clearAddTitleField() {
        addTitleField.text = ""
        
        if titleBottomConstraint  != nil {
            titleBottomConstraint.constant = addTitleField.frame.height
        }
    }
    
    fileprivate func setupTitleField(placeholderText : String) {
        addSubview(addTitleField)
        
        addTitleField.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        addTitleField.textColor = .white
        addTitleField.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightThin)
    
        addTitleField.translatesAutoresizingMaskIntoConstraints = false
        addTitleField.returnKeyType = .done
        
        addTitleField.textContainer.maximumNumberOfLines = 2
        addTitleField.textContainer.lineBreakMode = .byTruncatingTail
        
        titleBottomConstraint = addTitleField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.xl.rawValue - IconSizes.medium.rawValue)
        titleBottomConstraint.isActive = true
        
        let fontAttributes = [ NSFontAttributeName : UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightThin)]
        let labelHeight = GlobalFunctions.getLabelSize(title: placeholderText, width: frame.width, fontAttributes: fontAttributes)
        
        addTitleField.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        addTitleField.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        addTitleField.heightAnchor.constraint(equalToConstant: max(IconSizes.small.rawValue,labelHeight * 1.2)).isActive = true

        addTitleField.layoutIfNeeded()
        
        isTitleSetup = true
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        if addTitleField.text == "" {
            titleBottomConstraint.constant = addTitleField.frame.height
        } else {
            titleBottomConstraint.constant = -Spacing.xl.rawValue - IconSizes.medium.rawValue
        }
        
        addTitleField.layoutIfNeeded()
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            titleBottomConstraint.constant = -keyboardHeight
            addTitleField.layoutIfNeeded()
        }
    }
    
    fileprivate func addCloseButton() {
        addSubview(closeButton)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.s.rawValue + statusBarHeight).isActive = true
        closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.s.rawValue).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        
        closeButton.layoutIfNeeded()
        
        closeButton.removeShadow()
    }
    
    fileprivate func addSaveButton() {
        addSubview(saveButton)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        saveButton.leadingAnchor.constraint(equalTo: closeButton.leadingAnchor).isActive = true
        saveButton.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        saveButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        saveButton.layoutIfNeeded()
        
        saveButton.removeShadow()
    }

    
    fileprivate func addTitleButton() {
        addSubview(titleButton)
        
        titleButton.translatesAutoresizingMaskIntoConstraints = false
        titleButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        titleButton.leadingAnchor.constraint(equalTo: saveButton.leadingAnchor).isActive = true
        titleButton.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        titleButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        titleButton.layoutIfNeeded()
        
        titleButton.addTarget(self, action: #selector(userClickedAddTitle), for: .touchUpInside)
        
        titleButton.removeShadow()
    }
    
    func addProgressLabel(_ label : String) {
        progressLabel.isHidden = false
        progressLabel.text = label
        progressLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        
        progressLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .white, alignment: .center)
        progressLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        addSubview(progressLabel)
        
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        
        progressLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        progressLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        progressLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7).isActive = true
        progressLabel.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
    }
    
    func setupPagers() {
        addSubview(pagersStack)
        
        pagersStack.translatesAutoresizingMaskIntoConstraints = false
        pagersStack.widthAnchor.constraint(equalToConstant: Spacing.xs.rawValue).isActive = true
        pagersStack.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.s.rawValue + statusBarHeight).isActive = true
        pagersStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant : -Spacing.s.rawValue).isActive = true
        
        pagersStack.axis = .vertical
        pagersStack.distribution = .fillEqually
        pagersStack.spacing = Spacing.s.rawValue
    }
    
    func addPagers() {
        let _pager = UIView()
        _pager.translatesAutoresizingMaskIntoConstraints = false
        _pager.heightAnchor.constraint(equalTo: _pager.widthAnchor).isActive = true
        _pager.backgroundColor = .pulseBlue
        
        if pagersStack.arrangedSubviews.last != nil {
            pagersStack.arrangedSubviews.last!.backgroundColor = .white
        }
        
        pagersStack.addArrangedSubview(_pager)
        
        _pager.layoutIfNeeded()
        _pager.layer.cornerRadius = _pager.frame.width / 2
        _pager.layer.masksToBounds = true
    }
    
    func removePager() {
        if pagersStack.arrangedSubviews.last != nil {
            let lastView = pagersStack.arrangedSubviews.last!
            pagersStack.removeArrangedSubview(lastView)
            lastView.removeFromSuperview()
        }
        
        if pagersStack.arrangedSubviews.last != nil {
            pagersStack.arrangedSubviews.last!.backgroundColor = .pulseBlue
        }
    }
    
    func hideProgressLabel(_ label : String) {
        progressLabel.text = label
        
        let delay = 1 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) {
            self.progressLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = false
            self.progressLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = false
            self.progressLabel.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = false
            self.progressLabel.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.7).isActive = false
            super.updateConstraints()

            self.progressLabel.isHidden = true
        }
        
        UIView.animate(withDuration: 1, animations: { () -> Void in
            self.layoutIfNeeded()
        }) 
    }
    
    func addUploadProgressBar() {
        progressBar.progressTintColor = UIColor.white
        progressBar.trackTintColor = UIColor.black.withAlphaComponent(0.7)
        progressBar.progressViewStyle = .bar
        
        self.addSubview(progressBar)
        
        progressBar.translatesAutoresizingMaskIntoConstraints = false

        progressBar.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        progressBar.topAnchor.constraint(equalTo: topAnchor).isActive = true
        progressBar.heightAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
        progressBar.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }
    
    func updateProgressBar(_ percentComplete : Float) {
        progressBar.setProgress(percentComplete, animated: true)
    }
}
