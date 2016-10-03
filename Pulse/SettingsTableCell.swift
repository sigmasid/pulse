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
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    fileprivate func setupCellLayout() {
        addSubview(_detailTextLabel)
        
        _detailTextLabel.translatesAutoresizingMaskIntoConstraints = false
        _detailTextLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5).isActive = true
        _detailTextLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.m.rawValue).isActive = true
        _detailTextLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        _detailTextLabel.setPreferredFont(UIColor.black, alignment : .right)
        
        backgroundColor = UIColor.clear
        textLabel?.textColor = UIColor.black
        textLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
    }

}
