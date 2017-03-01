//
//  QuickBrowseCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/28/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class QuickBrowseCell: UICollectionViewCell {
    
    fileprivate lazy var titleLabel = UILabel()
    fileprivate lazy var previewImage = UIImageView()
    
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
            previewImage.image = image
            
            previewImage.layer.cornerRadius = 0
            previewImage.layer.masksToBounds = true
            previewImage.clipsToBounds = true
        }
    }
    
    override func prepareForReuse() {
        titleLabel.text = ""
        previewImage.image = nil
        
        super.prepareForReuse()
    }
    
    fileprivate func setupPreview() {
        addSubview(previewImage)
        addSubview(titleLabel)
        
        previewImage.frame = contentView.frame
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xxs.rawValue).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.xs.rawValue).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        titleLabel.layoutIfNeeded()
        
        previewImage.contentMode = UIViewContentMode.scaleAspectFill
        previewImage.clipsToBounds = true
        
        titleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightBold, color: .white, alignment: .left)
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setBlurredBackground()
    }
}
