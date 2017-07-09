//
//  QuickBrowseCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/28/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class QuickBrowseCell: UICollectionViewCell {
    
    fileprivate var titleLabel = UILabel()
    fileprivate var previewImage = UIImageView()
    fileprivate var textBox: RecordedTextView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        addShadow()
        setupPreview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateLabel(_ _title : String?) {
        titleLabel.text = _title
    }
    
    func updateImage( image : UIImage?) {
        if let image = image {
            textBox.isHidden = true
            previewImage.isHidden = false
            
            previewImage.image = image
            previewImage.contentMode = .scaleAspectFill
            previewImage.layer.cornerRadius = 0
            previewImage.layer.masksToBounds = true
            previewImage.clipsToBounds = true
        }
    }
    
    func updatePostcard(text: String) {
        previewImage.isHidden = true
        textBox.isHidden = false
        textBox.textToShow = text
    }
    
    override func prepareForReuse() {
        titleLabel.text = ""
        previewImage.image = nil
        textBox.isHidden = true
        
        super.prepareForReuse()
    }
    
    fileprivate func setupPreview() {
        textBox = RecordedTextView(frame: contentView.frame)
        addSubview(previewImage)
        addSubview(titleLabel)
        addSubview(textBox)
        
        previewImage.frame = contentView.frame
        textBox.isEditable = false
        textBox.isPreview = true
        textBox.reduceQuoteSize = true
        textBox.isHidden = true
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xxs.rawValue).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        titleLabel.layoutIfNeeded()
        
        previewImage.contentMode = UIViewContentMode.scaleAspectFill
        previewImage.clipsToBounds = true
        
        titleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightMedium, color: .white, alignment: .left)
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setBlurredBackground()
    }
}
