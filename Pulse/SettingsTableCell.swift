//
//  SettingsTableCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/28/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class SettingsTableCell: UITableViewCell {
    let settingNameLabel = UILabel()
    let detailLabel = UILabel()
    
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
        contentView.addSubview(settingNameLabel)
        contentView.addSubview(detailLabel)

        settingNameLabel.translatesAutoresizingMaskIntoConstraints = false
        settingNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.s.rawValue).isActive = true
        settingNameLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.3).isActive = true
        settingNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.xs.rawValue).isActive = true
        settingNameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.xs.rawValue).isActive = true
        settingNameLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightMedium, color: .black, alignment: .left)
        settingNameLabel.layoutIfNeeded()
        
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.leadingAnchor.constraint(equalTo: settingNameLabel.trailingAnchor).isActive = true
        detailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        detailLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.xs.rawValue).isActive = true
        detailLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.xs.rawValue).isActive = true
        detailLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightMedium, color: .darkGray, alignment: .right)
        detailLabel.layoutIfNeeded()

        detailLabel.numberOfLines = 0
        detailLabel.lineBreakMode = .byWordWrapping
        
        backgroundColor = UIColor.clear
    }

}
