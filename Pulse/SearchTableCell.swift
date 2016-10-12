//
//  SearchTableCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/6/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class SearchTableCell: UITableViewCell {
    
    fileprivate var leftContainer = UIView()
    fileprivate var bodyContainer = UIView()
    
    var titleLabel = UILabel()
    var subtitleLabel = UILabel()
    var iconButton = UIButton()

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
        leftContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        leftContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        leftContainer.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        leftContainer.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        leftContainer.layoutIfNeeded()
        
        contentView.addSubview(bodyContainer)
        bodyContainer.translatesAutoresizingMaskIntoConstraints = false
        bodyContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        bodyContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        bodyContainer.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        bodyContainer.leadingAnchor.constraint(equalTo: leftContainer.trailingAnchor, constant: Spacing.s.rawValue).isActive = true
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
        
        iconButton.makeRound()
        iconButton.backgroundColor = .lightGray
        iconButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
    }
    
    fileprivate func setupBody() {
        bodyContainer.addSubview(titleLabel)
        bodyContainer.addSubview(subtitleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.trailingAnchor.constraint(equalTo: bodyContainer.trailingAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: bodyContainer.leadingAnchor).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: bodyContainer.centerYAnchor).isActive = true
        titleLabel.layoutIfNeeded()
        
        titleLabel.setFont(FontSizes.body.rawValue, weight: UIFontWeightRegular, color: .black, alignment: .left)
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.trailingAnchor.constraint(equalTo: bodyContainer.trailingAnchor).isActive = true
        subtitleLabel.leadingAnchor.constraint(equalTo: bodyContainer.leadingAnchor).isActive = true
        subtitleLabel.bottomAnchor.constraint(equalTo: bodyContainer.bottomAnchor).isActive = true
        subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true

        subtitleLabel.layoutIfNeeded()
        
        subtitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .black, alignment: .left)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.lineBreakMode = .byWordWrapping
        

    }
}
