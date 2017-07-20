//
//  RecordedAnswerOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/6/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import UIKit

class RecordingOverlay: UIView {
    fileprivate var saveButton = PulseButton(size: .xSmall, type: .save, isRound: true, background: UIColor.white.withAlphaComponent(0.3), tint: .black)
    fileprivate var closeButton = PulseButton(size: .xSmall, type: .close, isRound : true, background: UIColor.white.withAlphaComponent(0.3), tint: .black)
    fileprivate var titleButton = PulseButton(size: .xSmall, type: .text, isRound: true, background: UIColor.white.withAlphaComponent(0.3), tint: .black)
    fileprivate var addMoreStack = PulseMenu(_axis: .vertical, _spacing: Spacing.xs.rawValue)
    fileprivate var addMoreLabel = UILabel()
    fileprivate var addMoreButton = PulseButton(size: .small, type: .add, isRound: true, background: UIColor.white.withAlphaComponent(0.6), tint: .black)

    fileprivate var postLabel = UILabel()
    fileprivate var postStack = PulseMenu(_axis: .vertical, _spacing: Spacing.xs.rawValue)
    fileprivate var postButton = PulseButton(size: .small, type: .post, isRound: true, background: UIColor.white.withAlphaComponent(0.6), tint: .black)
    
    fileprivate var progressLabel = UILabel()
    fileprivate var progressBar = UIProgressView()
    
    fileprivate lazy var addTitleField = UITextView()
    public var title : String = ""
    
    fileprivate var pagers = [UIView]()
    fileprivate lazy var pagersStack = UIStackView()
    fileprivate var isTitleSetup = false
    fileprivate var observersAdded = false
    
    internal enum ControlButtons: Int {
        case save, post, close, addMore
    }
    
    deinit {
        addMoreStack.removeFromSuperview()
        postStack.removeFromSuperview()
        pagers.removeAll()
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
        pagersStack.removeFromSuperview()
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
    
    func updateControls(type: CreatedAssetType) {
        switch type {
        case .albumImage, .recordedImage, .albumVideo, .recordedVideo:
            saveButton.isHidden = false
            titleButton.isHidden = false
            postLabel.setBlurredBackground()
            addMoreLabel.setBlurredBackground()
            
            UIView.animate(withDuration: 0.3, animations: {
                self.saveButton.backgroundColor = UIColor.white.withAlphaComponent(0.3);
                self.titleButton.backgroundColor = UIColor.white.withAlphaComponent(0.3);
                self.postButton.backgroundColor = UIColor.white.withAlphaComponent(0.3);
                self.addMoreButton.backgroundColor = UIColor.white.withAlphaComponent(0.3);
                self.closeButton.backgroundColor = UIColor.white.withAlphaComponent(0.3);
            }, completion: {[unowned self] _ in
                self.layoutIfNeeded()
            })
        case .postcard:
            saveButton.isHidden = true
            titleButton.isHidden = true
            postLabel.removeShadow()
            addMoreLabel.removeShadow()
            
            postLabel.textColor = .black
            addMoreLabel.textColor = .black
            
            UIView.animate(withDuration: 0.3, animations: {
                self.postButton.backgroundColor = UIColor.pulseGrey.withAlphaComponent(0.3);
                self.addMoreButton.backgroundColor = UIColor.pulseGrey.withAlphaComponent(0.3);
                self.closeButton.backgroundColor = UIColor.pulseGrey.withAlphaComponent(0.3);
            }, completion: {[unowned self] _ in
                self.layoutIfNeeded()
            })
        }
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
        
        addMoreLabel.translatesAutoresizingMaskIntoConstraints = false
        addMoreLabel.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -frame.width / 4).isActive = true
        addMoreLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.xs.rawValue).isActive = true
        
        postLabel.translatesAutoresizingMaskIntoConstraints = false
        postLabel.centerXAnchor.constraint(equalTo: centerXAnchor, constant: frame.width / 4).isActive = true
        postLabel.bottomAnchor.constraint(equalTo: addMoreLabel.bottomAnchor).isActive = true
        
        postLabel.layoutIfNeeded()
        addMoreLabel.layoutIfNeeded()

        postButton.translatesAutoresizingMaskIntoConstraints = false
        postButton.bottomAnchor.constraint(equalTo: postLabel.topAnchor, constant: -Spacing.xs.rawValue).isActive = true
        postButton.centerXAnchor.constraint(equalTo: postLabel.centerXAnchor).isActive = true
        postButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        postButton.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        postButton.layoutIfNeeded()
        postButton.removeShadow()
        
        addMoreButton.translatesAutoresizingMaskIntoConstraints = false
        addMoreButton.bottomAnchor.constraint(equalTo: addMoreLabel.topAnchor, constant: -Spacing.xs.rawValue).isActive = true
        addMoreButton.centerXAnchor.constraint(equalTo: addMoreLabel.centerXAnchor).isActive = true
        addMoreButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        addMoreButton.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        addMoreButton.layoutIfNeeded()
        addMoreButton.removeShadow()

        postLabel.text = "Post"
        addMoreLabel.text = "Add More"

        postLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightMedium, color: .white, alignment: .center)
        addMoreLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightMedium, color: .white, alignment: .center)
        
        postLabel.setBlurredBackground()
        addMoreLabel.setBlurredBackground()
    }
    
    public func updatePostLabel(text: String) {
        postLabel.text = text
    }
    
    public func userClickedAddTitle(sender: UIButton) {
        showAddTitleField(makeFirstResponder: true)
    }
    
    public func showAddTitleField(makeFirstResponder: Bool, placeholderText: String) {
        if !isTitleSetup {
            setupTitleField(placeholderText: placeholderText)
        }
        addTitleField.text = placeholderText
    
        if makeFirstResponder {
            addTitleField.becomeFirstResponder()
        }
    }
    
    public func showAddTitleField(makeFirstResponder: Bool) {
        showAddTitleField(makeFirstResponder: makeFirstResponder, placeholderText: title)
    }
    
    public func clearAddTitleField() {
        addTitleField.text = ""
        addTitleField.frame = CGRect(x: addTitleField.frame.origin.x, y: frame.maxY, width: addTitleField.frame.width, height: addTitleField.frame.height)
    }
    
    fileprivate func setupTitleField(placeholderText : String) {
        
        addTitleField.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        addTitleField.setFont(FontSizes.body.rawValue, weight: UIFontWeightThin, color: .white, alignment: .left)
        addTitleField.returnKeyType = .done
        
        let sizeThatFitsTextView = addTitleField.sizeThatFits(CGSize(width: frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        let labelHeight = max(sizeThatFitsTextView.height, 33)
        addTitleField.frame = CGRect(x: 0, y: frame.maxY, width: frame.width, height: labelHeight)
        addTitleField.textContainer.size = CGSize(width: addTitleField.frame.width, height: addTitleField.frame.height)
        addTitleField.alpha = 0.0
        
        addSubview(addTitleField)
        UIView.animate(withDuration: 0.3, animations: { self.addTitleField.alpha = 1.0 })
        isTitleSetup = true
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        if addTitleField.text == "" {
            addTitleField.frame = CGRect(x: addTitleField.frame.origin.x, y: frame.maxY, width: addTitleField.frame.width, height: addTitleField.frame.height)
        } else {
            addTitleField.frame = CGRect(x: addTitleField.frame.origin.x, y: frame.maxY - addTitleField.frame.height - IconSizes.medium.rawValue - Spacing.l.rawValue,
                                         width: addTitleField.frame.width, height: addTitleField.frame.height)
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            addTitleField.frame = CGRect(x: addTitleField.frame.origin.x, y: frame.maxY - keyboardHeight - addTitleField.frame.height,
                                         width: frame.width, height: addTitleField.frame.height)
        }
    }
    
    fileprivate func addCloseButton() {
        addSubview(closeButton)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.s.rawValue + STATUS_BAR_HEIGHT).isActive = true
        closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.s.rawValue).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
        
        closeButton.layoutIfNeeded()
        closeButton.removeShadow()
    }
    
    fileprivate func addSaveButton() {
        addSubview(saveButton)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        saveButton.leadingAnchor.constraint(equalTo: closeButton.leadingAnchor).isActive = true
        saveButton.widthAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
        saveButton.heightAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
        saveButton.layoutIfNeeded()
        
        saveButton.removeShadow()
    }

    
    fileprivate func addTitleButton() {
        addSubview(titleButton)
        
        titleButton.translatesAutoresizingMaskIntoConstraints = false
        titleButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        titleButton.leadingAnchor.constraint(equalTo: saveButton.leadingAnchor).isActive = true
        titleButton.widthAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
        titleButton.heightAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
        titleButton.layoutIfNeeded()
        
        titleButton.addTarget(self, action: #selector(userClickedAddTitle), for: .touchUpInside)
        titleButton.removeShadow()
    }
    
    public func addProgressLabel(_ label : String) {
        progressLabel.isHidden = false
        progressLabel.text = label
        progressLabel.font = UIFont.pulseFont(ofWeight: UIFontWeightRegular, size: FontSizes.caption.rawValue)
        
        progressLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .white, alignment: .center)
        progressLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        addSubview(progressLabel)
        
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        
        progressLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        progressLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        progressLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7).isActive = true
        progressLabel.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
    }
    
    public func setupPagers() {
        addSubview(pagersStack)
        
        pagersStack.translatesAutoresizingMaskIntoConstraints = false
        pagersStack.widthAnchor.constraint(equalToConstant: Spacing.xs.rawValue).isActive = true
        pagersStack.topAnchor.constraint(equalTo: closeButton.centerYAnchor).isActive = true
        pagersStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant : -Spacing.s.rawValue).isActive = true
        
        pagersStack.axis = .vertical
        pagersStack.distribution = .fillEqually
        pagersStack.spacing = Spacing.s.rawValue
    }
    
    public func addPagers() {
        let pagerButton = UIView()
        pagerButton.translatesAutoresizingMaskIntoConstraints = false
        pagerButton.heightAnchor.constraint(equalTo: pagerButton.widthAnchor).isActive = true
        pagerButton.backgroundColor = .pulseBlue
        
        if pagersStack.arrangedSubviews.last != nil {
            pagersStack.arrangedSubviews.last!.backgroundColor = .pulseGrey
        }
        
        pagersStack.addArrangedSubview(pagerButton)
        
        pagerButton.layoutIfNeeded()
        pagerButton.layer.cornerRadius = pagerButton.frame.width / 2
        pagerButton.layer.masksToBounds = true
    }
    
    public func removePager() {
        if pagersStack.arrangedSubviews.last != nil {
            let lastView = pagersStack.arrangedSubviews.last!
            pagersStack.removeArrangedSubview(lastView)
            lastView.removeFromSuperview()
        }
        
        if pagersStack.arrangedSubviews.last != nil {
            pagersStack.arrangedSubviews.last!.backgroundColor = .pulseBlue
        }
    }
    
    public func hideProgressLabel(_ label : String) {
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
    
    public func addUploadProgressBar() {
        progressBar.progressTintColor = UIColor.white
        progressBar.trackTintColor = UIColor.black.withAlphaComponent(0.7)
        progressBar.progressViewStyle = .bar
        
        self.addSubview(progressBar)
        
        progressBar.translatesAutoresizingMaskIntoConstraints = false

        progressBar.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        progressBar.topAnchor.constraint(equalTo: topAnchor).isActive = true
        progressBar.heightAnchor.constraint(equalToConstant: STATUS_BAR_HEIGHT).isActive = true
        progressBar.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }
    
    public func updateProgressBar(_ percentComplete : Float) {
        progressBar.setProgress(percentComplete, animated: true)
    }
}
