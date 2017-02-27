//
//  ChannelExpertsPreviewCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/16/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ChannelHeaderCell: UICollectionViewCell {
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
        previewContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        previewContainer.layoutIfNeeded()

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor).isActive = true
        titleLabel.widthAnchor.constraint(equalTo: previewContainer.widthAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: Spacing.xxs.rawValue).isActive = true
        titleLabel.layoutIfNeeded()
        titleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightThin, color: .black, alignment: .center)

        let fontAttributes = [ NSFontAttributeName : UIFont.systemFont(ofSize: titleLabel.font.pointSize, weight: UIFontWeightThin)]
        let titleLabelHeight = GlobalFunctions.getLabelSize(title: "Very Long Name", width: titleLabel.frame.width, fontAttributes: fontAttributes)
        titleLabel.heightAnchor.constraint(equalToConstant: titleLabelHeight).isActive = true
        
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byTruncatingTail
        
        previewContainer.addShadow()
        
        previewImage.frame = previewContainer.bounds
        previewImage.backgroundColor = .lightGray
        previewImage.contentMode = .scaleAspectFill
        previewContainer.addSubview(previewImage)
        previewImage.makeRound()
        
    }
}
