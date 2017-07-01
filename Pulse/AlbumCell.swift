//
//  AlbumCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/27/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class AlbumCell: UICollectionViewCell {
    fileprivate lazy var previewImage = UIImageView()
    fileprivate lazy var durationLabel : PaddingLabel = PaddingLabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupCell()
        addShadow()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        previewImage.image = nil
    }
    
    public func updateImage(image : UIImage?) {
        if let image = image {
            previewImage.image = image
            durationLabel.text = ""
        }
    }
    
    public func updateImageAndDuration(image: UIImage?, duration: Double) {
        previewImage.image = image
        
        if duration != 0 {
            durationLabel.text = GlobalFunctions.msFrom(seconds: duration)
        } else {
            durationLabel.text = ""
        }
    }
    
    override func prepareForReuse() {
        previewImage.image = nil
        super.prepareForReuse()
    }
    
    fileprivate func setupCell() {
        previewImage.frame = CGRect(x: contentView.bounds.origin.x, y: contentView.bounds.origin.y, width: contentView.bounds.width, height: contentView.bounds.height)
        durationLabel.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: Spacing.s.rawValue)
        addSubview(previewImage)
        addSubview(durationLabel)
        
        previewImage.backgroundColor = UIColor.pulseGrey.withAlphaComponent(0.5)
        previewImage.contentMode = .scaleAspectFill
        previewImage.clipsToBounds = true
        
        durationLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .white, alignment: .left)
        durationLabel.setBlurredBackground()
    }
}
