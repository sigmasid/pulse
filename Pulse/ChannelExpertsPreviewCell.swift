//
//  ChannelExpertsPreviewCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/16/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ChannelExpertsPreviewCell: UICollectionViewCell {
    fileprivate lazy var titleLabel = UILabel()
    fileprivate lazy var previewContainer = UIView()
    fileprivate lazy var previewImage = UIImageView()
    
    fileprivate lazy var previewVC : Preview = Preview()
    fileprivate var reuseCell = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateCell(_ _title : String?, _image : UIImage?) {
        titleLabel.text = _title
        previewImage.image = _image
    }
    
    func updateImage( image : UIImage?) {
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
        addSubview(previewContainer)
        addSubview(titleLabel)
        
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        previewContainer.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        previewContainer.widthAnchor.constraint(equalTo: previewContainer.heightAnchor).isActive = true
        previewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor).isActive = true
        titleLabel.widthAnchor.constraint(equalTo: previewContainer.widthAnchor).isActive = true

        titleLabel.topAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: Spacing.xxs.rawValue).isActive = true
        
        titleLabel.numberOfLines = 1
        
        previewContainer.layoutIfNeeded()
        previewContainer.addShadow()
        
        previewImage.frame = previewContainer.bounds
        previewImage.backgroundColor = .lightGray
        previewImage.contentMode = .scaleAspectFill
        previewContainer.addSubview(previewImage)
        previewImage.makeRound()
        
        titleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .black, alignment: .center)
    }
}
