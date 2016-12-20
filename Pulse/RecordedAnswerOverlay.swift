//
//  RecordedAnswerOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/6/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class RecordedAnswerOverlay: UIView {
    fileprivate var saveButton = PulseButton(size: .small, type: .save, isRound: true, hasBackground: false)
    fileprivate var closeButton = PulseButton(size: .small, type: .close, isRound : true, hasBackground: false)

    fileprivate var addMoreStack = PulseMenu(_axis: .vertical, _spacing: Spacing.xs.rawValue)
    fileprivate var addMoreLabel = UILabel()
    fileprivate var addMoreButton = PulseButton(size: .large, type: .addCircle, isRound: true, hasBackground: false, tint: pulseBlue)

    fileprivate var postLabel = UILabel()
    fileprivate var postStack = PulseMenu(_axis: .vertical, _spacing: Spacing.xs.rawValue)
    fileprivate var postButton = PulseButton(size: .large, type: .postCircle, isRound: true, hasBackground: false, tint: pulseBlue)
    
    fileprivate var progressLabel = UILabel()
    fileprivate var progressBar = UIProgressView()
    
    fileprivate var pagers = [UIView]()
    fileprivate lazy var answerPagers = UIStackView()
    
    var tap : UITapGestureRecognizer!
    
    internal enum ControlButtons: Int {
        case save, post, close, addMore
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        addFooterButtons()
        addCloseButton()
        addSaveButton()
        setupAnswerPagers()
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
    
    fileprivate func addFooterButtons() {
        addSubview(postStack)
        addSubview(addMoreStack)

        postStack.translatesAutoresizingMaskIntoConstraints = false
        postStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.m.rawValue).isActive = true
        postStack.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        postStack.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5).isActive = true

        postStack.layoutIfNeeded()
        
        addMoreStack.translatesAutoresizingMaskIntoConstraints = false
        addMoreStack.bottomAnchor.constraint(equalTo: postStack.bottomAnchor).isActive = true
        addMoreStack.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        addMoreStack.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5).isActive = true

        addMoreStack.layoutIfNeeded()

        postLabel.text = "Post"
        addMoreLabel.text = "Add More"

        postLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightMedium, color: .white, alignment: .center)
        addMoreLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightMedium, color: .white, alignment: .center)
        
        postLabel.setBlurredBackground()
        addMoreLabel.setBlurredBackground()
        
        addMoreStack.addArrangedSubview(addMoreButton)
        addMoreStack.addArrangedSubview(addMoreLabel)

        postStack.addArrangedSubview(postButton)
        postStack.addArrangedSubview(postLabel)
    }
    
    fileprivate func addSaveButton() {
        addSubview(saveButton)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        saveButton.leadingAnchor.constraint(equalTo: closeButton.leadingAnchor).isActive = true
        saveButton.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        saveButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        saveButton.layoutIfNeeded()

    }
    
    fileprivate func addCloseButton() {
        addSubview(closeButton)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.s.rawValue + statusBarHeight).isActive = true
        closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.m.rawValue).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        
        closeButton.layoutIfNeeded()
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
    
    func setupAnswerPagers() {
        addSubview(answerPagers)
        
        answerPagers.translatesAutoresizingMaskIntoConstraints = false
        answerPagers.widthAnchor.constraint(equalToConstant: Spacing.xs.rawValue).isActive = true
        answerPagers.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.s.rawValue + statusBarHeight).isActive = true
        answerPagers.trailingAnchor.constraint(equalTo: trailingAnchor, constant : -Spacing.s.rawValue).isActive = true
        
        answerPagers.axis = .vertical
        answerPagers.distribution = .fillEqually
        answerPagers.spacing = Spacing.s.rawValue
    }
    
    func addAnswerPagers() {
        let _pager = UIView()
        _pager.translatesAutoresizingMaskIntoConstraints = false
        _pager.heightAnchor.constraint(equalTo: _pager.widthAnchor).isActive = true
        _pager.backgroundColor = pulseBlue
        
        if answerPagers.arrangedSubviews.last != nil {
            answerPagers.arrangedSubviews.last!.backgroundColor = .white
        }
        
        answerPagers.addArrangedSubview(_pager)
        
        _pager.layoutIfNeeded()
        _pager.layer.cornerRadius = _pager.frame.width / 2
        _pager.layer.masksToBounds = true
    }
    
    func removeAnswerPager() {
        if answerPagers.arrangedSubviews.last != nil {
            let lastView = answerPagers.arrangedSubviews.last!
            answerPagers.removeArrangedSubview(lastView)
            lastView.removeFromSuperview()
        }
        
        if answerPagers.arrangedSubviews.last != nil {
            answerPagers.arrangedSubviews.last!.backgroundColor = pulseBlue
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
