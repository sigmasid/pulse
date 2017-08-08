//
//  ForumListCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/2/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ForumListCell: UITableViewCell {
    public var item : Item! {
        didSet {
            updateItemDetails(title: item.itemTitle, createdAt: item.getCreatedAt())
        }
    }
    
    private var userName = PaddingLabel()
    private var createdAtLabel = PaddingLabel()

    private var threadImage = UIImageView()
    private var threadTitle = PaddingLabel()
    private var isLayoutSetup = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        updateItemDetails(title: nil, createdAt: nil)
        updateImage(image: nil)
        updateName(name: nil)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupCellLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func updateImage( image : UIImage?) {
        if let image = image{
            threadImage.image = image
            threadImage.makeRound()
        }
    }
    
    public func updateItemDetails(title: String?, createdAt: String?) {
        threadTitle.text = title
        threadTitle.backgroundColor = UIColor.pulseGrey.withAlphaComponent(0.3)
        threadTitle.makeRound()
        createdAtLabel.text = createdAt
    }
    
    public func updateName(name : String?) {
        userName.text = name?.capitalized
    }
    
    private func setupCellLayout() {
        if !isLayoutSetup {
            let marginGuide = contentView.layoutMarginsGuide

            contentView.addSubview(userName)
            contentView.addSubview(createdAtLabel)
            contentView.addSubview(threadTitle)
            contentView.addSubview(threadImage)

            threadImage.translatesAutoresizingMaskIntoConstraints = false
            threadImage.leadingAnchor.constraint(equalTo: marginGuide.leadingAnchor).isActive = true
            threadImage.topAnchor.constraint(equalTo: marginGuide.topAnchor).isActive = true
            threadImage.widthAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
            threadImage.heightAnchor.constraint(equalTo: threadImage.widthAnchor).isActive = true
            threadImage.tintColor = .black
            threadImage.contentMode = .scaleAspectFill
            
            threadTitle.translatesAutoresizingMaskIntoConstraints = false
            threadTitle.trailingAnchor.constraint(equalTo: marginGuide.trailingAnchor).isActive = true
            threadTitle.leadingAnchor.constraint(equalTo: threadImage.trailingAnchor, constant: Spacing.s.rawValue).isActive = true
            threadTitle.topAnchor.constraint(equalTo: marginGuide.topAnchor).isActive = true
            
            userName.translatesAutoresizingMaskIntoConstraints = false
            userName.leadingAnchor.constraint(equalTo: threadImage.trailingAnchor, constant: Spacing.s.rawValue).isActive = true
            userName.topAnchor.constraint(equalTo: threadTitle.bottomAnchor).isActive = true
            userName.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .gray, alignment: .left)
            
            createdAtLabel.translatesAutoresizingMaskIntoConstraints = false
            createdAtLabel.leadingAnchor.constraint(equalTo: userName.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
            createdAtLabel.trailingAnchor.constraint(equalTo: marginGuide.trailingAnchor).isActive = true
            createdAtLabel.topAnchor.constraint(equalTo: threadTitle.bottomAnchor).isActive = true
            createdAtLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .gray, alignment: .left)
            createdAtLabel.lineBreakMode = .byTruncatingTail
            
            threadTitle.setFont(FontSizes.body.rawValue, weight: UIFontWeightBold, color: .black, alignment: .left)
            threadTitle.lineBreakMode = .byTruncatingTail
            threadTitle.numberOfLines = 3
            isLayoutSetup = true
        }
    }
}
