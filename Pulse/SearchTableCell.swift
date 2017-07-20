//
//  SearchTableCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/6/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import UIKit

class SearchTableCell: UITableViewCell {
    
    fileprivate var leftContainer = UIView()
    fileprivate var bodyContainer = PulseMenu(_axis: .vertical, _spacing: 0)
    
    var titleLabel = UILabel()
    var subtitleLabel = UILabel()
    var iconButton = PulseButton(size: .small, type: .blank, isRound: true, hasBackground: false)

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
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
        contentView.addSubview(leftContainer)
        leftContainer.translatesAutoresizingMaskIntoConstraints = false
        leftContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        leftContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        leftContainer.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        leftContainer.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        leftContainer.layoutIfNeeded()
        
        contentView.addSubview(bodyContainer)
        bodyContainer.translatesAutoresizingMaskIntoConstraints = false
        bodyContainer.leadingAnchor.constraint(equalTo: leftContainer.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
        bodyContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        bodyContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        bodyContainer.layoutIfNeeded()
        
        setupIcon()
        setupBody()
    }
    
    fileprivate func setupIcon() {
        leftContainer.addSubview(iconButton)
        iconButton.translatesAutoresizingMaskIntoConstraints = false
        iconButton.centerXAnchor.constraint(equalTo: leftContainer.centerXAnchor).isActive = true
        iconButton.centerYAnchor.constraint(equalTo: leftContainer.centerYAnchor).isActive = true
        iconButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        iconButton.widthAnchor.constraint(equalTo: iconButton.heightAnchor).isActive = true
        iconButton.layoutIfNeeded()
        
        iconButton.removeShadow()
    }
    
    fileprivate func setupBody() {
        bodyContainer.distribution = .equalCentering
        bodyContainer.alignment = .leading
        
        bodyContainer.addArrangedSubview(titleLabel)
        bodyContainer.addArrangedSubview(subtitleLabel)
        
        titleLabel.setFont(FontSizes.body.rawValue, weight: UIFontWeightRegular, color: .black, alignment: .left)
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        
        subtitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .gray, alignment: .left)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.lineBreakMode = .byWordWrapping
    }
}
