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
    fileprivate let _screenTitleLabel = UILabel()
    fileprivate var _logoView : Icon!
    fileprivate var _screenButton = UIView()
    
    lazy var _goBack = UIButton()
    lazy var _settings = UIButton()
    lazy var _emptyButton = UIButton()

    fileprivate var _statusLabel : UILabel?
    fileprivate var _statusImage : UIImageView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addIcon()
        addScreenTitleLabel()
        addAppTitleLabel()
        addScreenButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if  isHidden {
            return false
        } else {
            let expandedBounds = bounds.insetBy(dx: -50, dy: -50)
            return expandedBounds.contains(point)
        }
    }
    
    fileprivate func addAppTitleLabel() {
        addSubview(_appTitleLabel)

        _appTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        _appTitleLabel.topAnchor.constraint(equalTo: _logoView.topAnchor).isActive = true
        _appTitleLabel.leadingAnchor.constraint(equalTo: _logoView.leadingAnchor).isActive = true
        
        _appTitleLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption2)
        _appTitleLabel.textColor = UIColor.black
        _appTitleLabel.textAlignment = .left
        _appTitleLabel.addTextSpacing(10)
    }
    
    fileprivate func addScreenTitleLabel() {
        addSubview(_screenTitleLabel)

        _screenTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        _screenTitleLabel.bottomAnchor.constraint(equalTo: _logoView.bottomAnchor).isActive = true
        _screenTitleLabel.leadingAnchor.constraint(equalTo: _logoView.leadingAnchor).isActive = true
        
        _screenTitleLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption2)
        _screenTitleLabel.textColor = UIColor.black
        _screenTitleLabel.textAlignment = .left
    }
    
    fileprivate func addScreenButton() {
        addSubview(_screenButton)
        
        _screenButton.translatesAutoresizingMaskIntoConstraints = false
        _screenButton.centerYAnchor.constraint(equalTo: _logoView.centerYAnchor).isActive = true
        _screenButton.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        _screenButton.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        _screenButton.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        _screenButton.layoutIfNeeded()
        
    }
    
    fileprivate func addStatus() {
        _statusLabel = UILabel()
        
        if let _statusLabel = _statusLabel {
            addSubview(_statusLabel)
            
            _statusLabel.translatesAutoresizingMaskIntoConstraints = false
            _statusLabel.centerYAnchor.constraint(equalTo: _logoView.centerYAnchor).isActive = true
            _statusLabel.widthAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
            _statusLabel.heightAnchor.constraint(equalTo: _statusLabel.widthAnchor).isActive = true
            _statusLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            _screenTitleLabel.trailingAnchor.constraint(equalTo: _statusLabel.leadingAnchor).isActive = true

            
            _statusLabel.layoutIfNeeded()
            _statusLabel.font = UIFont.systemFont(ofSize: FontSizes.caption.rawValue, weight: UIFontWeightThin)
            _statusLabel.backgroundColor = UIColor.black
            _statusLabel.textColor = UIColor.white
            _statusLabel.layer.cornerRadius = _statusLabel.bounds.width / 2
            
            _statusLabel.lineBreakMode = .byWordWrapping
            _statusLabel.minimumScaleFactor = 0.1
            _statusLabel.numberOfLines = 0
            
            _statusLabel.textAlignment = .center
            _statusLabel.layer.masksToBounds = true
        }
    }
    
    fileprivate func addStatusImage() {
        _statusImage = UIImageView()
        if let _statusImage = _statusImage {
            addSubview(_statusImage)
            
            _statusImage.translatesAutoresizingMaskIntoConstraints = false
            _statusImage.centerYAnchor.constraint(equalTo: _logoView.centerYAnchor).isActive = true
            _statusImage.widthAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
            _statusImage.heightAnchor.constraint(equalTo: _statusImage.widthAnchor).isActive = true
            _statusImage.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            _screenTitleLabel.trailingAnchor.constraint(equalTo: _statusImage.leadingAnchor).isActive = true
            _statusImage.layoutIfNeeded()
            
            _statusImage.layer.cornerRadius = _statusImage.bounds.width / 2
            _statusImage.layer.masksToBounds = true
            _statusImage.layer.shouldRasterize = true
            _statusImage.layer.rasterizationScale = UIScreen.main.scale
            _statusImage.backgroundColor = UIColor.lightGray
            _statusImage.contentMode = .scaleAspectFill
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
    
    func updateStatusBackground(_image : UIImage?) {
        if _statusImage == nil {
            addStatusImage()
        }
        
        _statusImage?.image = _image
        
    }
    
    func setAppTitleLabel(_message : String) {
        _appTitleLabel.text = _message
        _appTitleLabel.addTextSpacing(2.5)
    }
    
    func setScreenTitleLabel(_message : String) {
        _screenTitleLabel.text = _message
        _screenTitleLabel.addTextSpacing(2.5)
        _screenTitleLabel.adjustsFontSizeToFitWidth = true
    }
    
    fileprivate func addIcon() {
        _logoView = Icon(frame: CGRect(x: 0,y: 0, width: frame.width - IconSizes.medium.rawValue, height: frame.height))
        _logoView.drawLongIcon(UIColor.black, iconThickness: IconThickness.medium.rawValue)
        addSubview(_logoView)
        
        _logoView.translatesAutoresizingMaskIntoConstraints = false
        _logoView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        _logoView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        _logoView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: IconSizes.medium.rawValue).isActive = true
        _logoView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -IconSizes.medium.rawValue).isActive = true
        _logoView.layoutIfNeeded()
    }
    
    func addGoBack() {
        _screenButton.addSubview(_goBack)
        _goBack.frame = _screenButton.bounds
        
        let settingTintedImage = UIImage(named: "back")?.withRenderingMode(.alwaysTemplate)
        _goBack.setImage(settingTintedImage, for: UIControlState())
        _goBack.tintColor = UIColor.black
    }
    
    func addSettingsButton() {
        _screenButton.addSubview(_settings)
        _settings.frame = _screenButton.bounds
        
        let settingTintedImage = UIImage(named: "settings")?.withRenderingMode(.alwaysTemplate)
        _settings.setImage(settingTintedImage, for: UIControlState())
        _settings.tintColor = UIColor.black
    }
    
    func addEmptyButton(image : UIImage) {
        _screenButton.addSubview(_emptyButton)
        _emptyButton.frame = _screenButton.bounds
        
        let emptyTintedImage = image.withRenderingMode(.alwaysTemplate)
        _emptyButton.setImage(emptyTintedImage, for: UIControlState())
        _emptyButton.tintColor = UIColor.black
    }
}
