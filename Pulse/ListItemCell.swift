//
//  ListItemCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/21/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ListItemCell: UITableViewCell {
    public var listDelegate : ListDelegate?
    public var itemID : String?
    
    private var backgroundImage = UIImageView()
    private var itemCount = PaddingLabel()
    
    private var itemButtonStack = PulseMenu(_axis: .horizontal, _spacing: Spacing.xxs.rawValue)
    private var itemLink = PulseButton(size: .small, type: .related, isRound: true, hasBackground: false, tint: .white)
    private var itemImage = PulseButton(size: .small, type: .blank, isRound: true, hasBackground: false, tint: .white)
    private var itemMenu = PulseButton(size: .small, type: .ellipsisVertical, isRound: true, hasBackground: false, tint: .white)
    
    private var itemTitleStack = PulseMenu(_axis: .vertical, _spacing: -5)
    private var itemTitle = PaddingLabel()
    private var itemDescription = PaddingLabel()
    
    private var itemCountWidth : NSLayoutConstraint!
    private var itemMenuWidth : NSLayoutConstraint!
    private var isLayoutSetup = false
    
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
        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func prepareForReuse() {
        updateItemDetails(title: nil, subtitle: nil)
        updateImage(image: nil)
    }
    
    public func updateImage(image : UIImage?, showBackground: Bool = true, showSmallPreview : Bool = true, addBorder: Bool = false) {
        if let image = image{
            itemImage.setImage(image, for: .normal)
            itemImage.isHidden = !showSmallPreview
            itemImage.layoutIfNeeded()
            itemImage.makeRound()

            if showBackground {
                backgroundImage.image = image.applyImageFilter()
                backgroundImage.contentMode = .center
                backgroundImage.clipsToBounds = true
            }
        } else {
            itemImage.isHidden = true
            backgroundImage.image = nil
            backgroundImage.backgroundColor = UIColor.pulseDarkGrey
        }
    }
    
    public func showItemMenu(show: Bool = true) {
        if show {
            itemMenu.isHidden = false
            itemMenu.addTarget(self, action: #selector(menuClick), for: .touchUpInside)
        } else {
            itemMenu.isHidden = true
        }
        
        guard itemMenuWidth != nil else { return }
        itemMenuWidth.constant = show ? IconSizes.small.rawValue : 0
    }
    
    public func addLinkButton() {
        itemLink.isHidden = false
    }
    
    public func showImageBorder(show: Bool) {
        if show {
            itemImage.isHidden = false
            if itemImage.image(for: .normal) == nil {
                itemImage.setImage(UIImage(named: "related"), for: .normal)
            }
            itemImage.layer.addBorder(color: .white, thickness: 3.0)
        } else {
            itemImage.isEnabled = false
            itemImage.layer.borderWidth = 0
        }
    }
    
    public func updateItemDetails(title: String?, subtitle: String?, countText: String? = nil) {
        itemTitle.text = title
        itemDescription.text = subtitle
        itemTitle.textColor = .white
        itemDescription.textColor = .white
        
        if countText != nil {
            itemCount.text = countText
            itemCountWidth.constant = IconSizes.small.rawValue
            contentView.layoutIfNeeded()
        }
    }
    
    internal func menuClick() {
        if let itemID = itemID {
            listDelegate?.showMenuFor(itemID: itemID)
        }
    }
    
    private func setupCellLayout() {
        if !isLayoutSetup {
            let marginGuide = contentView.layoutMarginsGuide
            
            contentView.addSubview(backgroundImage)
            contentView.addSubview(itemTitleStack)
            contentView.addSubview(itemButtonStack)
            contentView.addSubview(itemMenu)
            contentView.addSubview(itemCount)
            
            itemCount.translatesAutoresizingMaskIntoConstraints = false
            itemCount.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            itemCount.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.xxs.rawValue).isActive = true
            itemCount.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.xxs.rawValue).isActive = true
            itemCountWidth = itemCount.widthAnchor.constraint(equalToConstant: 0)
            itemCountWidth.isActive = true
            
            backgroundImage.translatesAutoresizingMaskIntoConstraints = false
            backgroundImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            backgroundImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.xxs.rawValue).isActive = true
            backgroundImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
            backgroundImage.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
            backgroundImage.clipsToBounds = true
            backgroundImage.backgroundColor = UIColor.pulseDarkGrey
            
            itemMenu.translatesAutoresizingMaskIntoConstraints = false
            itemMenu.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
            itemMenu.centerYAnchor.constraint(equalTo: marginGuide.centerYAnchor).isActive = true
            itemMenuWidth = itemMenu.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue)
            itemMenuWidth.isActive = true
            itemMenu.heightAnchor.constraint(equalTo: itemMenu.widthAnchor).isActive = true
            itemMenu.removeShadow()

            itemButtonStack.translatesAutoresizingMaskIntoConstraints = false
            itemButtonStack.trailingAnchor.constraint(equalTo: itemMenu.leadingAnchor, constant: -Spacing.xxs.rawValue).isActive = true
            itemButtonStack.centerYAnchor.constraint(equalTo: marginGuide.centerYAnchor).isActive = true
            itemButtonStack.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
            
            itemImage.translatesAutoresizingMaskIntoConstraints = false
            let itemImageWidthAnchor : NSLayoutConstraint = itemImage.widthAnchor.constraint(equalTo: itemImage.heightAnchor)
            itemImageWidthAnchor.priority = 900
            itemImageWidthAnchor.isActive = true

            itemLink.translatesAutoresizingMaskIntoConstraints = false
            let itemLinkWidthAnchor : NSLayoutConstraint = itemLink.widthAnchor.constraint(equalTo: itemLink.heightAnchor)
            itemLinkWidthAnchor.priority = 900
            itemLinkWidthAnchor.isActive = true
            
            itemButtonStack.addArrangedSubview(itemLink)
            itemButtonStack.addArrangedSubview(itemImage)
            
            itemLink.removeShadow()
            itemImage.removeShadow()
            
            itemImage.isHidden = true
            itemLink.isHidden = true
            
            itemTitleStack.translatesAutoresizingMaskIntoConstraints = false
            itemTitleStack.leadingAnchor.constraint(equalTo: itemCount.trailingAnchor, constant: Spacing.xxs.rawValue).isActive = true
            itemTitleStack.trailingAnchor.constraint(equalTo: itemButtonStack.leadingAnchor, constant: -Spacing.xxs.rawValue).isActive = true
            itemTitleStack.centerYAnchor.constraint(equalTo: marginGuide.centerYAnchor).isActive = true
            
            let itemDescriptionWrapper = UIView()
            itemDescriptionWrapper.addSubview(itemDescription)
            
            itemDescription.translatesAutoresizingMaskIntoConstraints = false
            itemDescription.leadingAnchor.constraint(equalTo: itemDescriptionWrapper.leadingAnchor).isActive = true
            itemDescription.trailingAnchor.constraint(equalTo: itemDescriptionWrapper.trailingAnchor).isActive = true
            itemDescription.topAnchor.constraint(equalTo: itemDescriptionWrapper.topAnchor).isActive = true
            itemDescription.bottomAnchor.constraint(equalTo: itemDescriptionWrapper.bottomAnchor).isActive = true
            
            itemTitleStack.addArrangedSubview(itemTitle)
            itemTitleStack.addArrangedSubview(itemDescriptionWrapper) //otherwise it shows as a single line uilabel vs. multiline
            
            itemCount.setFont(FontSizes.headline2.rawValue, weight: UIFontWeightBlack, color: .white, alignment: .left)
            itemTitle.setFont(FontSizes.body.rawValue, weight: UIFontWeightBlack, color: .white, alignment: .left)
            itemDescription.setFont(FontSizes.body2.rawValue, weight: UIFontWeightRegular, color: .white, alignment: .left)

            itemTitle.lineBreakMode = .byTruncatingTail
            itemTitle.numberOfLines = 1
            itemTitle.sizeToFit()
            
            itemDescription.lineBreakMode = .byTruncatingTail
            itemDescription.numberOfLines = 3
            
            isLayoutSetup = true
        }
    }
}
