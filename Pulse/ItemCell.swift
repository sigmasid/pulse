//
//  ChannelCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/19/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ItemCell: UICollectionViewCell {
    
    public weak var delegate : ItemCellDelegate!

    fileprivate var titleLabel: UILabel! = UILabel()
    fileprivate var subtitleLabel: UILabel! = UILabel()
    fileprivate var createdAtLabel: UILabel! = UILabel()
    fileprivate var itemImage: UIImageView! = UIImageView()
    
    fileprivate var cellCard: PulseMenu! = PulseMenu(_axis: .vertical, _spacing: 10)
    fileprivate var itemFooter: UIView! = UIView()
    fileprivate var itemHeader: UIView! = UIView()

    fileprivate lazy var itemTag: UILabel! = UILabel()
    fileprivate var itemHeightAnchor : NSLayoutConstraint!
    fileprivate var footerHeightAnchor : NSLayoutConstraint!

    fileprivate var itemButton: PulseButton! = PulseButton(size: .xSmall, type: .logoCircle, isRound: true, hasBackground: false)
    fileprivate var itemMenu: PulseButton! = PulseButton(size: .small, type: .ellipsis, isRound: false, hasBackground: false, tint: .black)
    
    public var itemType : ItemTypes? {
        didSet {
            switch itemType! {
            case .question, .answer, .interview:
                itemImage.isHidden = true
                itemHeightAnchor.constant = 0
                titleLabel.setFont(FontSizes.headline.rawValue, weight: UIFontWeightThin, color: UIColor.black, alignment: .left)
                titleLabel.numberOfLines = 2

            case .post, .thread, .perspective, .session, .showcase:
                itemHeightAnchor.constant = POST_HEIGHT
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        addBottomBorder()        
        setupCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        delegate = nil
        cellCard = nil
        itemButton = nil
        itemMenu = nil
    }
    
    func updateLabel(_ _title : String?, _subtitle : String?, _createdAt: Date?, _tag : String?) {
        
        
        let fontAttributes = [ NSFontAttributeName : UIFont.pulseFont(ofWeight: UIFontWeightThin, size: titleLabel.font.pointSize)]
        let labelHeight = GlobalFunctions.getLabelSize(title: _title ?? "test string", width: frame.width, fontAttributes: fontAttributes)
        let singleLineHeight = GlobalFunctions.getLabelSize(title: "test string", width: frame.width, fontAttributes: fontAttributes)
        
        let font2Attributes = [ NSFontAttributeName : UIFont.pulseFont(ofWeight: UIFontWeightThin, size: createdAtLabel.font.pointSize)]
        let label2Height = GlobalFunctions.getLabelSize(title: _tag ?? "test string", width: frame.width, fontAttributes: font2Attributes)
        
        footerHeightAnchor.constant = Spacing.xxs.rawValue + min(labelHeight, singleLineHeight * 2) + Spacing.xs.rawValue + label2Height + Spacing.xs.rawValue
        titleLabel.text = _title
        
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.minimumScaleFactor = 0.9
        
        if let _subtitle = _subtitle {
            
            let subAttributes = [NSFontAttributeName: UIFont.pulseFont(ofWeight: UIFontWeightBold, size: FontSizes.caption.rawValue)]
            let attributedString : NSMutableAttributedString = NSMutableAttributedString(string: _subtitle.capitalized, attributes: subAttributes)
            
            var subRestAttributes = [String : Any]()
            subRestAttributes[NSFontAttributeName] = UIFont.pulseFont(ofWeight: UIFontWeightThin, size: FontSizes.caption.rawValue)
            subRestAttributes[NSForegroundColorAttributeName] = UIColor.gray
            
            if let itemType = itemType {
                switch itemType {
                case .post:
                    let restAttributedString = NSAttributedString(string: " posted", attributes: subRestAttributes)
                    attributedString.append(restAttributedString)
                    
                case .question:
                    let restAttributedString = NSAttributedString(string: " asked", attributes: subRestAttributes)
                    attributedString.append(restAttributedString)

                case .answer:
                    let restAttributedString = NSAttributedString(string: " answered", attributes: subRestAttributes)
                    attributedString.append(restAttributedString)

                case .thread:
                    let restAttributedString = NSAttributedString(string: " thread on", attributes: subRestAttributes)
                    attributedString.append(restAttributedString)
                    
                case .perspective:
                    let restAttributedString = NSAttributedString(string: " perspective on", attributes: subRestAttributes)
                    attributedString.append(restAttributedString)
                    
                case .interview:
                    let restAttributedString = NSAttributedString(string: " interview on", attributes: subRestAttributes)
                    attributedString.append(restAttributedString)
                    
                case .session:
                    let restAttributedString = NSAttributedString(string: " requested feedback", attributes: subRestAttributes)
                    attributedString.append(restAttributedString)
                    
                case .showcase:
                    let restAttributedString = NSAttributedString(string: " added a showcase", attributes: subRestAttributes)
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
    
    internal func clickedItemButton() {
        if delegate != nil {
            delegate.clickedUserButton(itemRow: tag)
        }
    }
    
    internal func clickedMenuButton() {
        if delegate != nil {
            delegate.clickedMenuButton(itemRow: tag)
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
        
        cellCard.addArrangedSubview(itemHeader)
        cellCard.addArrangedSubview(itemImage)
        cellCard.addArrangedSubview(itemFooter)
        
        itemImage.translatesAutoresizingMaskIntoConstraints = false
        itemHeightAnchor = itemImage.heightAnchor.constraint(equalToConstant: POST_HEIGHT)
        itemHeightAnchor.priority = 100
        itemHeightAnchor.isActive = true
        
        itemFooter.translatesAutoresizingMaskIntoConstraints = false
        footerHeightAnchor = itemFooter.heightAnchor.constraint(greaterThanOrEqualToConstant: 54)
        footerHeightAnchor.isActive = true
        itemFooter.backgroundColor = .white
        
        itemHeader.translatesAutoresizingMaskIntoConstraints = false
        itemHeader.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        itemHeader.addSubview(itemButton)
        itemHeader.addSubview(subtitleLabel)
        itemHeader.addSubview(itemMenu)

        itemFooter.addSubview(itemTag)
        itemFooter.addSubview(titleLabel)
        itemFooter.addSubview(createdAtLabel)
        
        /** HEADER - USER IMAGE, USER NAME AND MENU BUTTON **/
        itemButton.translatesAutoresizingMaskIntoConstraints = false
        itemButton.leadingAnchor.constraint(equalTo: itemHeader.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        itemButton.centerYAnchor.constraint(equalTo: itemHeader.centerYAnchor, constant: Spacing.xxs.rawValue).isActive = true
        itemButton.widthAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
        itemButton.heightAnchor.constraint(equalTo: itemButton.widthAnchor).isActive = true
        itemButton.addTarget(self, action: #selector(clickedItemButton), for: .touchUpInside)
        
        itemButton.imageView?.contentMode = .scaleAspectFill
        itemButton.imageView?.frame = itemButton.bounds
        itemButton.imageView?.clipsToBounds = true
        itemButton.contentMode = .scaleAspectFill
        itemButton.clipsToBounds = true
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.leadingAnchor.constraint(equalTo: itemButton.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
        subtitleLabel.centerYAnchor.constraint(equalTo: itemButton.centerYAnchor).isActive = true
        subtitleLabel.heightAnchor.constraint(equalTo: itemHeader.heightAnchor).isActive = true
        
        itemMenu.translatesAutoresizingMaskIntoConstraints = false
        itemMenu.trailingAnchor.constraint(equalTo: itemHeader.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        itemMenu.centerYAnchor.constraint(equalTo: itemButton.centerYAnchor).isActive = true
        itemMenu.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        itemMenu.heightAnchor.constraint(equalTo: itemMenu.widthAnchor).isActive = true
        itemMenu.removeShadow()
        
        itemMenu.addTarget(self, action: #selector(clickedMenuButton), for: .touchUpInside)
        
        /** FOOTER - SUBTITLE (MAIN CONTENT), TAG & CREATED AT**/
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leadingAnchor.constraint(equalTo: itemFooter.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: itemFooter.trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        titleLabel.topAnchor.constraint(equalTo: itemFooter.topAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: createdAtLabel.topAnchor, constant: -Spacing.xs.rawValue).isActive = true
        
        createdAtLabel.translatesAutoresizingMaskIntoConstraints = false
        createdAtLabel.leadingAnchor.constraint(equalTo: itemFooter.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        createdAtLabel.bottomAnchor.constraint(equalTo: itemFooter.bottomAnchor, constant: -Spacing.xs.rawValue).isActive = true
        createdAtLabel.heightAnchor.constraint(equalToConstant: 12).isActive = true
        
        titleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightThin, color: .black, alignment: .left)
        createdAtLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .gray, alignment: .left)
        itemTag.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .gray, alignment: .right)
        
        itemTag.translatesAutoresizingMaskIntoConstraints = false
        itemTag.trailingAnchor.constraint(equalTo: itemFooter.trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        itemTag.centerYAnchor.constraint(equalTo: createdAtLabel.centerYAnchor).isActive = true
        
        itemImage.contentMode = UIViewContentMode.scaleAspectFill
        itemImage.backgroundColor = UIColor.pulseGrey.withAlphaComponent(0.7)
        titleLabel.backgroundColor = .white
        subtitleLabel.backgroundColor = .white
        itemImage.clipsToBounds = true
        titleLabel.numberOfLines = 2

        subtitleLabel.numberOfLines = 1
        
        subtitleLabel.lineBreakMode = .byTruncatingTail
    }
}
