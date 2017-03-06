//
//  ChannelCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/19/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

protocol ItemCellDelegate : class {
    func clickedItemButton(itemRow : Int)
}

class ItemCell: UICollectionViewCell {
    
    public var delegate : ItemCellDelegate!

    fileprivate var titleLabel = UILabel()
    fileprivate var subtitleLabel = UILabel()
    fileprivate var itemImage = UIImageView()
    
    fileprivate var cellCard = PulseMenu(_axis: .vertical, _spacing: 0)
    fileprivate var itemFooter = UIView()
    fileprivate lazy var itemTag = UILabel()
    fileprivate var itemHeightAnchor : NSLayoutConstraint!
    
    fileprivate var itemButton = PulseButton(size: .small, type: .logo, isRound: true, hasBackground: false)
    
    public var itemType : ItemTypes? {
        didSet {
            switch itemType! {
            case .question, .answer:
                itemHeightAnchor.constant = 0
                titleLabel.setFont(FontSizes.headline.rawValue, weight: UIFontWeightThin, color: UIColor.black, alignment: .left)
                titleLabel.numberOfLines = 3
                itemImage.isHidden = true

            case .post:
                itemHeightAnchor.constant = 225
                titleLabel.setFont(FontSizes.body.rawValue, weight: UIFontWeightThin, color: .black, alignment: .left)
                titleLabel.numberOfLines = 2
                itemImage.isHidden = false

            default:
                itemHeightAnchor.constant = 0
                titleLabel.setFont(FontSizes.headline.rawValue, weight: UIFontWeightThin, color: UIColor.black, alignment: .left)
                titleLabel.numberOfLines = 1
                itemImage.isHidden = true
            }
        }
    }
    
    fileprivate var reuseCell = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        
        addShadow()
        setupCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateLabel(_ _title : String?, _subtitle : String?, _tag : String?) {
        titleLabel.text = _title
        subtitleLabel.text = _subtitle
        itemTag.text = _tag != nil ? "# \(_tag!)" : nil
    }
    
    func updateCell(_ _title : String?, _subtitle : String?, _tag : String?, _image : UIImage?) {
        updateLabel(_title, _subtitle: _subtitle, _tag: _tag)
        
        if let _image = _image {
            itemImage.isHidden = false
            itemImage.image = _image
        }
    }
    
    func updateImage( image : UIImage?) {
        if let image = image {
            itemImage.isHidden = false
            itemImage.image = image
            
            itemImage.layer.cornerRadius = 0
            itemImage.layer.masksToBounds = true
            itemImage.clipsToBounds = true
        }
    }
    
    func updateButtonImage(image : UIImage?, itemTag : Int) {
        if let image = image {
            itemButton.setBackgroundImage(image, for: .normal)
        }
        
        itemButton.tag = itemTag
    }
    
    override func prepareForReuse() {
        titleLabel.text = ""
        subtitleLabel.text = ""
        itemImage.image = nil
        itemHeightAnchor.constant = 0

        super.prepareForReuse()
    }
    
    func clickedItemButton() {
        if delegate != nil {
            delegate.clickedItemButton(itemRow: tag)
        }
    }
    
    fileprivate func setupCell() {
        cellCard.frame = contentView.frame
        addSubview(cellCard)
        
        cellCard.addArrangedSubview(itemImage)
        cellCard.addArrangedSubview(itemFooter)
        
        itemButton.translatesAutoresizingMaskIntoConstraints = false
        itemHeightAnchor = itemImage.heightAnchor.constraint(equalToConstant: 0)
        itemHeightAnchor.isActive = true
        
        itemFooter.addSubview(itemButton)
        itemFooter.addSubview(titleLabel)
        itemFooter.addSubview(itemTag)
        itemFooter.addSubview(subtitleLabel)
        
        itemButton.translatesAutoresizingMaskIntoConstraints = false
        itemButton.leadingAnchor.constraint(equalTo: itemFooter.leadingAnchor, constant: Spacing.xxs.rawValue).isActive = true
        itemButton.centerYAnchor.constraint(equalTo: itemFooter.centerYAnchor).isActive = true
        itemButton.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        itemButton.heightAnchor.constraint(equalTo: itemButton.widthAnchor).isActive = true
        
        itemButton.contentMode = .scaleAspectFill
        itemButton.clipsToBounds = true
        itemButton.addTarget(self, action: #selector(clickedItemButton), for: .touchUpInside)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leadingAnchor.constraint(equalTo: itemButton.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
        let titleCenterConstraint = titleLabel.centerYAnchor.constraint(equalTo: itemFooter.centerYAnchor)
        titleCenterConstraint.priority = 40
        titleCenterConstraint.isActive = true
        
        titleLabel.trailingAnchor.constraint(equalTo: itemFooter.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true
        subtitleLabel.trailingAnchor.constraint(equalTo: itemTag.leadingAnchor).isActive = true
        let subtitleTopConstraint = subtitleLabel.topAnchor.constraint(equalTo: itemFooter.topAnchor, constant: Spacing.xs.rawValue)
        subtitleTopConstraint.priority = 50
        subtitleTopConstraint.isActive = true
        
        subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: titleLabel.topAnchor, constant: -Spacing.xxs.rawValue).isActive = true

        subtitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightBold, color: .black, alignment: .left)
        let fontAttributes = [ NSFontAttributeName : UIFont.systemFont(ofSize: subtitleLabel.font.pointSize, weight: UIFontWeightBold)]
        let subtitleLabelHeight = GlobalFunctions.getLabelSize(title: "label", width: contentView.frame.width, fontAttributes: fontAttributes)
        subtitleLabel.heightAnchor.constraint(equalToConstant: subtitleLabelHeight).isActive = true
        
        itemTag.translatesAutoresizingMaskIntoConstraints = false
        itemTag.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor).isActive = true
        let tagTopConstraint = itemTag.topAnchor.constraint(equalTo: itemFooter.topAnchor, constant: Spacing.xs.rawValue)
        tagTopConstraint.priority = 50
        tagTopConstraint.isActive = true
        
        itemTag.bottomAnchor.constraint(lessThanOrEqualTo: titleLabel.topAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        itemTag.heightAnchor.constraint(equalToConstant: subtitleLabelHeight).isActive = true
        
        itemTag.setFont(FontSizes.caption.rawValue, weight: UIFontWeightThin, color: .darkText, alignment: .right)
        
        itemImage.contentMode = UIViewContentMode.scaleAspectFill
        itemImage.clipsToBounds = true
                
        titleLabel.numberOfLines = 2
        subtitleLabel.numberOfLines = 1
        
        titleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.lineBreakMode = .byTruncatingTail
    }
}
