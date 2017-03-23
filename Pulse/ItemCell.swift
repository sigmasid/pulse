//
//  ChannelCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/19/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ItemCell: UICollectionViewCell {
    
    public var delegate : ItemCellDelegate!

    fileprivate var titleLabel = UILabel()
    fileprivate var subtitleLabel = UILabel()
    fileprivate var createdAtLabel = UILabel()
    fileprivate var itemImage = UIImageView()
    
    fileprivate var cellCard = PulseMenu(_axis: .vertical, _spacing: 0)
    fileprivate var itemFooter = UIView()
    fileprivate lazy var itemTag = UILabel()
    fileprivate var itemHeightAnchor : NSLayoutConstraint!
    
    fileprivate var itemButton = PulseButton(size: .small, type: .logoCircle, isRound: true, hasBackground: false)
    
    public var itemType : ItemTypes? {
        didSet {
            switch itemType! {
            case .question, .answer:
                itemImage.isHidden = true
                itemHeightAnchor.constant = 0
                titleLabel.setFont(FontSizes.headline.rawValue, weight: UIFontWeightThin, color: UIColor.black, alignment: .left)
                titleLabel.numberOfLines = 3

            case .post, .thread, .perspective:
                itemHeightAnchor.constant = defaultPostHeight
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
        addBottomBorder()        
        setupCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateLabel(_ _title : String?, _subtitle : String?, _createdAt: Date?, _tag : String?) {

        titleLabel.text = _title
        
        if let _subtitle = _subtitle {
            let subAttributes = [NSFontAttributeName: UIFont.systemFont(ofSize: FontSizes.caption.rawValue, weight: UIFontWeightBold)]
            let attributedString : NSMutableAttributedString = NSMutableAttributedString(string: _subtitle.capitalized, attributes: subAttributes)
            
            var subRestAttributes = [String : Any]()
            subRestAttributes[NSFontAttributeName] = UIFont.systemFont(ofSize: FontSizes.caption.rawValue, weight: UIFontWeightThin)
            subRestAttributes[NSForegroundColorAttributeName] = UIColor.gray
            
            if let itemType = itemType {
                switch itemType {
                case .post:
                    let restAttributedString = NSAttributedString(string: " added", attributes: subRestAttributes)
                    attributedString.append(restAttributedString)
                    
                case .question:
                    let restAttributedString = NSAttributedString(string: " asked", attributes: subRestAttributes)
                    attributedString.append(restAttributedString)

                case .answer:
                    let restAttributedString = NSAttributedString(string: " answered", attributes: subRestAttributes)
                    attributedString.append(restAttributedString)

                case .thread:
                    let restAttributedString = NSAttributedString(string: " started thread", attributes: subRestAttributes)
                    attributedString.append(restAttributedString)
                    
                case .perspective:
                    let restAttributedString = NSAttributedString(string: " added a perspective", attributes: subRestAttributes)
                    attributedString.append(restAttributedString)
                    
                default:
                    break
                }
            }
            
            subtitleLabel.attributedText = attributedString

        } else {
            subtitleLabel.text = nil
            subtitleLabel.attributedText = nil
        }
        
        
        if let _createdAt = _createdAt {
            createdAtLabel.text = GlobalFunctions.getFormattedTime(timeString: _createdAt, style: .medium)
        }
        
        itemTag.text = _tag != nil ? "# \(_tag!)" : nil
    }
    
    func updateCell(_ _title : String?, _subtitle : String?, _tag : String?, _createdAt: Date?, _image : UIImage?) {
        updateLabel(_title, _subtitle: _subtitle, _createdAt: _createdAt, _tag: _tag)
        
        if let _image = _image, !itemImage.isHidden {
            itemImage.image = _image
        }
    }
    
    func updateImage( image : UIImage?) {
        if let image = image, !itemImage.isHidden {
            itemImage.image = image
            
            itemImage.layer.cornerRadius = 0
            itemImage.layer.masksToBounds = true
            itemImage.clipsToBounds = true
        }
    }
    
    func updateButtonImage(image : UIImage?, itemTag : Int) {
        itemButton.setImage(image ?? UIImage(named: "pulse-logo"), for: .normal)
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
        addSubview(cellCard)
        
        cellCard.translatesAutoresizingMaskIntoConstraints = false
        cellCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        cellCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        cellCard.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        cellCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        cellCard.layoutIfNeeded()
        
        cellCard.addArrangedSubview(itemImage)
        cellCard.addArrangedSubview(itemFooter)
        
        itemImage.translatesAutoresizingMaskIntoConstraints = false
        itemHeightAnchor = itemImage.heightAnchor.constraint(lessThanOrEqualToConstant: defaultPostHeight)
        itemHeightAnchor.priority = 100
        itemHeightAnchor.isActive = true
        
        itemFooter.translatesAutoresizingMaskIntoConstraints = false
        itemFooter.heightAnchor.constraint(greaterThanOrEqualToConstant: 75).isActive = true

        itemFooter.addSubview(itemButton)
        itemFooter.addSubview(titleLabel)
        itemFooter.addSubview(itemTag)
        itemFooter.addSubview(subtitleLabel)
        itemFooter.addSubview(createdAtLabel)
        
        itemButton.translatesAutoresizingMaskIntoConstraints = false
        itemButton.leadingAnchor.constraint(equalTo: itemFooter.leadingAnchor, constant: Spacing.xxs.rawValue).isActive = true
        itemButton.centerYAnchor.constraint(equalTo: itemFooter.centerYAnchor).isActive = true
        itemButton.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        itemButton.heightAnchor.constraint(equalTo: itemButton.widthAnchor).isActive = true
        itemButton.addTarget(self, action: #selector(clickedItemButton), for: .touchUpInside)
        
        itemButton.imageView?.contentMode = .scaleAspectFill
        itemButton.imageView?.frame = itemButton.bounds
        itemButton.imageView?.clipsToBounds = true
        itemButton.contentMode = .scaleAspectFill
        itemButton.clipsToBounds = true
        
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
        
        createdAtLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .gray, alignment: .left)
        itemTag.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .gray, alignment: .right)
        
        createdAtLabel.translatesAutoresizingMaskIntoConstraints = false
        createdAtLabel.leadingAnchor.constraint(equalTo: itemButton.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
        createdAtLabel.bottomAnchor.constraint(equalTo: itemFooter.bottomAnchor, constant: -Spacing.xs.rawValue).isActive = true
        let createdAtfontAttributes = [ NSFontAttributeName : UIFont.systemFont(ofSize: createdAtLabel.font.pointSize, weight: UIFontWeightRegular)]
        let createdAtHeight = GlobalFunctions.getLabelSize(title: "Jan 1, 2017", width: contentView.frame.width, fontAttributes: createdAtfontAttributes)
        createdAtLabel.heightAnchor.constraint(equalToConstant: createdAtHeight).isActive = true
        
        itemTag.translatesAutoresizingMaskIntoConstraints = false
        itemTag.trailingAnchor.constraint(equalTo: itemFooter.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        itemTag.bottomAnchor.constraint(equalTo: createdAtLabel.bottomAnchor).isActive = true
        itemTag.heightAnchor.constraint(equalToConstant: createdAtHeight).isActive = true
        
        itemImage.contentMode = UIViewContentMode.scaleAspectFill
        itemImage.backgroundColor = UIColor.pulseGrey.withAlphaComponent(0.7)
        itemImage.clipsToBounds = true
                
        titleLabel.numberOfLines = 2
        subtitleLabel.numberOfLines = 1
        
        titleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.lineBreakMode = .byTruncatingTail
    }
}
