//
//  ForumDetailCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/2/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ForumDetailCell: UITableViewCell {
    
    public var item : Item! {
        didSet {
            let createdAtTime = item.getCreatedAt(style: DateFormatter.Style.short)
            subtitleLabel.text = createdAtTime != nil ? "\u{2022}  \(item.getCreatedAt(style: DateFormatter.Style.short)!)" : ""
            titleLabel.text = item.itemTitle
            
            if !isSetup {
                setupCell()
                subtitleLabel.sizeToFit()
                isSetup = true
            }
        }
    }
    
    private var senderImage = UIImageView()
    private var senderName = UILabel()
    private var subtitleLabel = UILabel()
    private var titleLabel = UILabel()
    private var isSetup = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        item = nil
        senderImage.image = nil
    }
    
    public func updateName(name: String?) {
        senderName.text = name
        senderName.sizeToFit()
    }
    
    public func updateImage(image: UIImage?) {
        
        if !isSetup {
            setupCell()
            isSetup = true
        }
        
        senderImage.image = image
        senderImage.layoutIfNeeded()
        senderImage.makeRound()
    }
    
    public func updateLabels(title: String?, subtitle: String?) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        
        if !isSetup {
            setupCell()
            isSetup = true
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    fileprivate func setupCell() {
        let marginGuide = contentView.layoutMarginsGuide

        contentView.addSubview(senderImage)
        contentView.addSubview(senderName)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(titleLabel)
        
        senderImage.translatesAutoresizingMaskIntoConstraints = false
        senderImage.topAnchor.constraint(equalTo: marginGuide.topAnchor).isActive = true
        senderImage.leadingAnchor.constraint(equalTo: marginGuide.leadingAnchor).isActive = true
        senderImage.widthAnchor.constraint(equalTo: marginGuide.widthAnchor, multiplier: 0.1).isActive = true
        senderImage.heightAnchor.constraint(equalTo: senderImage.widthAnchor).isActive = true
        
        senderImage.image = UIImage(named: "default-profile")
        senderImage.tintColor = UIColor.black
        senderImage.contentMode = .scaleAspectFit
        
        senderName.translatesAutoresizingMaskIntoConstraints = false
        senderName.topAnchor.constraint(equalTo: marginGuide.topAnchor).isActive = true
        senderName.leadingAnchor.constraint(equalTo: senderImage.trailingAnchor, constant: Spacing.xxs.rawValue).isActive = true
        senderName.setFont(FontSizes.caption2.rawValue, weight: UIFontWeightBold, color: .black, alignment: .left)
        senderName.numberOfLines = 1

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: senderName.bottomAnchor, constant: Spacing.xxs.rawValue).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: senderName.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: marginGuide.trailingAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: marginGuide.bottomAnchor).isActive = true

        titleLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightRegular, color: .black, alignment: .left)
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.topAnchor.constraint(equalTo: senderName.topAnchor).isActive = true
        subtitleLabel.leadingAnchor.constraint(equalTo: senderName.trailingAnchor, constant: Spacing.xxs.rawValue).isActive = true
        let subtitleTrailingContraint = subtitleLabel.trailingAnchor.constraint(equalTo: marginGuide.trailingAnchor)
        subtitleTrailingContraint.priority = 250
        subtitleTrailingContraint.isActive = true
        subtitleLabel.bottomAnchor.constraint(equalTo: senderName.bottomAnchor).isActive = true
        subtitleLabel.setFont(FontSizes.caption2.rawValue, weight: UIFontWeightRegular, color: .gray, alignment: .left)
        subtitleLabel.numberOfLines = 1
    }
}
