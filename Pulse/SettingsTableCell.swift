//
//  SettingsTableCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/28/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class SettingsTableCell: UITableViewCell {
    let _detailTextLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCellLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    private func setupCellLayout() {
        addSubview(_detailTextLabel)
        
        _detailTextLabel.translatesAutoresizingMaskIntoConstraints = false
        _detailTextLabel.widthAnchor.constraintEqualToAnchor(widthAnchor, multiplier: 0.5).active = true
        _detailTextLabel.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: -Spacing.m.rawValue).active = true
        _detailTextLabel.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
        _detailTextLabel.setPreferredFont(UIColor.whiteColor())
        _detailTextLabel.textAlignment = .Right
        
        backgroundColor = UIColor.clearColor()
        textLabel?.textColor = UIColor.whiteColor()
        textLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
    }

}
