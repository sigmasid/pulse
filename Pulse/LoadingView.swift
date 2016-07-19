//
//  LoadingView.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/19/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class LoadingView: UIView {
    
    private let _messageLabel = UILabel()
    private var _iconManager : Icon!

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, backgroundColor : UIColor) {
        self.init(frame: frame)
        self.backgroundColor = backgroundColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func addMessage(_text : String) {
        self.addSubview(_messageLabel)
        _messageLabel.text = _text
        _messageLabel.adjustsFontSizeToFitWidth = true
        _messageLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        _messageLabel.textAlignment = .Center
        
        _messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        _messageLabel.topAnchor.constraintEqualToAnchor(_iconManager.bottomAnchor, constant: 5).active = true
        _messageLabel.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor).active = true
    }
    
    func addMessage(_text : String, _color : UIColor) {
        _messageLabel.textColor = _color
        addMessage(_text)
    }
    
    func addIcon(iconSize : IconSizes, _iconColor : UIColor, _iconBackgroundColor : UIColor?) {
        let _iconSize = iconSize.rawValue
        _iconManager = Icon(frame: CGRectMake(0, 0, _iconSize, _iconSize))

        if let _iconBackgroundColor = _iconBackgroundColor {
            _iconManager.drawIconBackground(_iconBackgroundColor)
        }
        _iconManager.drawIcon(_iconColor, iconThickness: iconThickness)
        self.addSubview(_iconManager)
        
        _iconManager.translatesAutoresizingMaskIntoConstraints = false
        _iconManager.widthAnchor.constraintEqualToConstant(_iconSize).active = true
        _iconManager.heightAnchor.constraintEqualToConstant(_iconSize).active = true
        _iconManager.centerYAnchor.constraintEqualToAnchor(self.centerYAnchor).active = true
        _iconManager.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor).active = true


    }
}
