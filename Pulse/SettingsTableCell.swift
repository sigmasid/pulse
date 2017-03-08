//
//  SettingsTableCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/28/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class SettingsTableCell: UITableViewCell {
    let _settingNameLabel = UILabel()
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
        contentView.addSubview(_settingNameLabel)
        contentView.addSubview(_detailTextLabel)

        _settingNameLabel.translatesAutoresizingMaskIntoConstraints = false
        _settingNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.s.rawValue).isActive = true
        _settingNameLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.3).isActive = true
        _settingNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.xs.rawValue).isActive = true
        _settingNameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.xs.rawValue).isActive = true
        _settingNameLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightMedium, color: .black, alignment: .left)
        _settingNameLabel.layoutIfNeeded()
        
        _detailTextLabel.translatesAutoresizingMaskIntoConstraints = false
        _detailTextLabel.leadingAnchor.constraint(equalTo: _settingNameLabel.trailingAnchor).isActive = true
        _detailTextLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        _detailTextLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.xs.rawValue).isActive = true
        _detailTextLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.xs.rawValue).isActive = true
        _detailTextLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightMedium, color: .black, alignment: .right)
        _detailTextLabel.layoutIfNeeded()

        _detailTextLabel.numberOfLines = 0
        _detailTextLabel.lineBreakMode = .byWordWrapping
        
        backgroundColor = UIColor.clear
    }

}
