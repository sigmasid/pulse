//
//  ExploreChannelsCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/18/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ExploreChannelsCell: UICollectionViewCell {
    fileprivate lazy var titleLabel = UILabel()
    fileprivate lazy var subtitleLabel = UILabel()

    fileprivate lazy var previewImage = UIImageView()
    
    fileprivate lazy var previewVC : Preview = Preview()
    fileprivate var reuseCell = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupCell()
        addShadow()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func updateCell(_ _title : String?, subtitle : String?) {
        titleLabel.text = _title?.capitalized
        subtitleLabel.text = subtitle
    }
    
    public func updateImage(image : UIImage?) {
        if let image = image {
            previewImage.image = image
        }
    }
    
    override func prepareForReuse() {
        titleLabel.text = ""
        previewImage.image = nil
        
        super.prepareForReuse()
    }
    
    fileprivate func setupCell() {
        previewImage.frame = contentView.bounds

        addSubview(previewImage)
        addSubview(titleLabel)
        addSubview(subtitleLabel)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.xs.rawValue).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.xs.rawValue).isActive = true
        titleLabel.setFont(FontSizes.headline.rawValue, weight: UIFontWeightHeavy, color: .white, alignment: .left)
        
        titleLabel.numberOfLines = 0
        
        previewImage.backgroundColor = .white
        previewImage.contentMode = .scaleAspectFill
        previewImage.clipsToBounds = true
        
        titleLabel.setBlurredBackground()
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true
        subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.xs.rawValue).isActive = true
        subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        subtitleLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: UIColor.white, alignment: .left)
        
        subtitleLabel.setBlurredBackground()
    }
}
