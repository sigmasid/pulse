//
//  RecordedAnswerOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/6/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class RecordedAnswerOverlay: UIView {
    private var _saveToDiskButton = UIButton()
    private var _postButton = UIButton()
    private var _closeButton = UIButton()
    private var _savingLabel = UILabel()
    
    private var _iconSize : CGFloat = 20
    private var _postButtonHeight : CGFloat = 50
    private var _elementSpacer : CGFloat = 30
    var _didSaveSuccess = false {
        didSet {
            if _didSaveSuccess {
                hideSavingLabel("File Saved")
            }
        }
    }
    
    internal enum ControlButtons: Int {
        case Save, Post, Close
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addPostButton()
        self.addCloseButton()
        self.addSaveButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func getButton(buttonName : ControlButtons) -> UIButton {
        switch buttonName {
        case .Save: return _saveToDiskButton
        case .Post: return _postButton
        case .Close: return _closeButton
        }
    }
    
    private func addSaveButton() {
        if let saveToDiskImage = UIImage(named: "download-to-disk") {
            _saveToDiskButton.setImage(saveToDiskImage, forState: UIControlState.Normal)
            _saveToDiskButton.frame = CGRectMake(20, UIScreen.mainScreen().bounds.height - 100, saveToDiskImage.size.width, saveToDiskImage.size.width)
        }
        self.addSubview(_saveToDiskButton)
        
        _saveToDiskButton.translatesAutoresizingMaskIntoConstraints = false
        
        _saveToDiskButton.topAnchor.constraintEqualToAnchor(_closeButton.bottomAnchor, constant: _elementSpacer).active = true
        _saveToDiskButton.trailingAnchor.constraintEqualToAnchor(self.trailingAnchor, constant: -_elementSpacer).active = true
        _saveToDiskButton.widthAnchor.constraintEqualToConstant(_iconSize).active = true
        _saveToDiskButton.heightAnchor.constraintEqualToConstant(_iconSize).active = true
    }
    
    private func addPostButton() {
        _postButton.backgroundColor = UIColor( red: 245/255, green: 44/255, blue:90/255, alpha: 0.7 )
        _postButton.setTitle("Add Answer", forState: UIControlState.Normal)
        _postButton.titleLabel!.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
        _postButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        
        self.addSubview(_postButton)
        
        _postButton.translatesAutoresizingMaskIntoConstraints = false
        
        _postButton.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor).active = true
        _postButton.widthAnchor.constraintEqualToAnchor(self.widthAnchor).active = true
        _postButton.leadingAnchor.constraintEqualToAnchor(self.leadingAnchor).active = true
        _postButton.heightAnchor.constraintEqualToConstant(_postButtonHeight).active = true
    }
    
    private func addCloseButton() {
        if let closeButtonImage = UIImage(named: "close") {
            _closeButton.setImage(closeButtonImage, forState: UIControlState.Normal)
        } else {
            _closeButton.titleLabel?.text = "Close"
        }
        self.addSubview(_closeButton)
        
        _closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        _closeButton.topAnchor.constraintEqualToAnchor(self.topAnchor, constant: _elementSpacer).active = true
        _closeButton.trailingAnchor.constraintEqualToAnchor(self.trailingAnchor, constant: -_elementSpacer).active = true
        _closeButton.widthAnchor.constraintEqualToConstant(_iconSize).active = true
        _closeButton.heightAnchor.constraintEqualToConstant(_iconSize).active = true
    }
    
    func addSavingLabel(label : String) {
        _savingLabel.hidden = false
        _savingLabel.text = label
        _savingLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        _savingLabel.textAlignment = .Center
        _savingLabel.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        _savingLabel.textColor = UIColor.whiteColor()
        self.addSubview(_savingLabel)
        
        _savingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        _savingLabel.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor).active = true
        _savingLabel.centerYAnchor.constraintEqualToAnchor(self.centerYAnchor).active = true
        _savingLabel.widthAnchor.constraintEqualToAnchor(self.widthAnchor, multiplier: 0.7).active = true
        _savingLabel.heightAnchor.constraintEqualToConstant(_postButtonHeight).active = true
    }
    
    func hideSavingLabel(label : String) {
        _savingLabel.text = label
        
        let delay = 1 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            self._savingLabel.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor).active = false
            self._savingLabel.centerYAnchor.constraintEqualToAnchor(self.centerYAnchor).active = false
            self._savingLabel.heightAnchor.constraintEqualToConstant(self._postButtonHeight).active = false
            self._savingLabel.widthAnchor.constraintEqualToAnchor(self.widthAnchor, multiplier: 0.7).active = false
            super.updateConstraints()

            self._savingLabel.hidden = true
        }
        
        UIView.animateWithDuration(1) { () -> Void in
            self.layoutIfNeeded()
        }
    }
}
