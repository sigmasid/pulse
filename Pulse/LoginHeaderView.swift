//
//  LoginHeaderView.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/26/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class LoginHeaderView: UIView {
    
    let _appTitleLabel = UILabel()
    private let _screenTitleLabel = UILabel()
    private var _logoView : Icon!
    
    lazy var _goBack = UIButton()
    lazy var _settings = UIButton()

    private var _statusLabel : UILabel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addIcon()
        addScreenTitleLabel()
        addAppTitleLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if  self.hidden {
            return false
        } else {
            let expandedBounds = CGRectInset(self.bounds, -50, -50)
            return CGRectContainsPoint(expandedBounds, point)
        }
    }
    
    private func addAppTitleLabel() {
        addSubview(_appTitleLabel)

        _appTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        _appTitleLabel.topAnchor.constraintEqualToAnchor(_logoView.topAnchor).active = true
        _appTitleLabel.leadingAnchor.constraintEqualToAnchor(_logoView.leadingAnchor).active = true
        
        _appTitleLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
        _appTitleLabel.textColor = UIColor.whiteColor()
        _appTitleLabel.textAlignment = .Left
        _appTitleLabel.addTextSpacing(10)
    }
    
    private func addScreenTitleLabel() {
        addSubview(_screenTitleLabel)

        _screenTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        _screenTitleLabel.bottomAnchor.constraintEqualToAnchor(_logoView.bottomAnchor).active = true
        _screenTitleLabel.leadingAnchor.constraintEqualToAnchor(_logoView.leadingAnchor).active = true
        
        _screenTitleLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
        _screenTitleLabel.textColor = UIColor.whiteColor()
        _screenTitleLabel.textAlignment = .Left
    }
    
    private func addStatus() {
        _statusLabel = UILabel()
        
        if let _statusLabel = _statusLabel {
            addSubview(_statusLabel)
            
            _statusLabel.translatesAutoresizingMaskIntoConstraints = false
            _statusLabel.centerYAnchor.constraintEqualToAnchor(_logoView.centerYAnchor).active = true
            _statusLabel.widthAnchor.constraintEqualToConstant(IconSizes.Large.rawValue).active = true
            _statusLabel.heightAnchor.constraintEqualToAnchor(_statusLabel.widthAnchor).active = true
            _statusLabel.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
            
            _statusLabel.layoutIfNeeded()
            _statusLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
            _statusLabel.backgroundColor = UIColor.whiteColor()
            _statusLabel.textColor = UIColor.blackColor()
            
            _statusLabel.lineBreakMode = .ByWordWrapping
            _statusLabel.minimumScaleFactor = 0.1
            _statusLabel.numberOfLines = 0
            
            _statusLabel.textAlignment = .Center
            _statusLabel.layer.masksToBounds = true
        }
    }
    
    func updateStatusMessage(_message : String?) {
        if _statusLabel == nil {
            addStatus()
        }
        
        if _message != nil {
            _statusLabel!.text = _message
        }
    }
    
    func setAppTitleLabel(_message : String) {
        _appTitleLabel.text = _message
        _appTitleLabel.addTextSpacing(3)
    }
    
    func setScreenTitleLabel(_message : String) {
        _screenTitleLabel.text = _message
        _screenTitleLabel.addTextSpacing(3)

    }
    
    private func addIcon() {
        _logoView = Icon(frame: CGRectMake(0,0, frame.width, frame.height))
        _logoView.drawLongIcon(UIColor.whiteColor(), iconThickness: IconThickness.Medium.rawValue)
        addSubview(_logoView)
        
        _logoView.translatesAutoresizingMaskIntoConstraints = false
        _logoView.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
        _logoView.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        _logoView.heightAnchor.constraintEqualToAnchor(heightAnchor).active = true
        _logoView.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        _logoView.layoutIfNeeded()
    }
    
    func addGoBack() {
        addSubview(_goBack)
        _goBack.setImage(UIImage(named: "back"), forState: UIControlState.Normal)
        _goBack.translatesAutoresizingMaskIntoConstraints = false
        _goBack.centerYAnchor.constraintEqualToAnchor(_logoView.centerYAnchor).active = true
        _goBack.widthAnchor.constraintEqualToConstant(IconSizes.Small.rawValue).active = true
        _goBack.heightAnchor.constraintEqualToAnchor(_logoView.heightAnchor, multiplier: 0.8).active = true
        _goBack.leadingAnchor.constraintEqualToAnchor(_logoView.leadingAnchor , constant: -IconSizes.Small.rawValue).active = true
    }
    
    func addSettingsButton() {
        addSubview(_settings)
        
        _settings.translatesAutoresizingMaskIntoConstraints = false
        _settings.centerYAnchor.constraintEqualToAnchor(_logoView.centerYAnchor).active = true
        _settings.widthAnchor.constraintEqualToConstant(IconSizes.XSmall.rawValue).active = true
        _settings.heightAnchor.constraintEqualToAnchor(_settings.widthAnchor).active = true
        _settings.leadingAnchor.constraintEqualToAnchor(_logoView.leadingAnchor , constant: -IconSizes.Small.rawValue).active = true
        
        _settings.setImage(UIImage(named: "settings"), forState: .Normal)
    }
}
