//
//  FeedPeopleCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 12/8/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class FeedPeopleCell: UICollectionViewCell {
    fileprivate lazy var titleLabel = UILabel()
    fileprivate lazy var subtitleLabel = UILabel()
    fileprivate lazy var previewContainer = UIView()
    fileprivate lazy var previewImage = UIImageView()
    fileprivate lazy var titleStack = PulseMenu(_axis: .vertical, _spacing: 0)
    
    fileprivate lazy var previewVC : Preview = Preview()
    fileprivate var reuseCell = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addShadow()
        setupPeoplePreview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateLabel(_ _title : String?, _subtitle : String?) {
        titleLabel.text = _title
        subtitleLabel.text = _subtitle
    }
    
    func updateLabel(_ _title : String?, _subtitle : String?, _image : UIImage?) {
        updateLabel(_title, _subtitle: _subtitle)
        previewImage.image = _image
    }
    
    func updateImage( image : UIImage?) {
        if let image = image {
            previewImage.image = image
        }
    }
    
    override func prepareForReuse() {
        titleLabel.text = ""
        subtitleLabel.text = ""
        previewImage.image = nil
        
        super.prepareForReuse()
    }
    
    fileprivate func setupPeoplePreview() {
        addSubview(previewContainer)
        addSubview(titleStack)
        
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue * 1.25).isActive = true
        previewContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        previewContainer.widthAnchor.constraint(equalTo: previewContainer.heightAnchor).isActive = true
        previewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.m.rawValue).isActive = true

        
        titleStack.translatesAutoresizingMaskIntoConstraints = false
        titleStack.leadingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: Spacing.m.rawValue).isActive = true
        titleStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        titleStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        
        titleStack.spacing = 5
        titleStack.addArrangedSubview(titleLabel)
        titleStack.addArrangedSubview(subtitleLabel)
        
        previewContainer.layoutIfNeeded()
        previewContainer.addShadow()

        previewImage.frame = previewContainer.bounds
        previewImage.contentMode = .scaleAspectFill
        previewContainer.addSubview(previewImage)
        previewImage.makeRound()

        titleLabel.setFont(FontSizes.body.rawValue, weight: UIFontWeightBold, color: .black, alignment: .left)
        subtitleLabel.setFont(FontSizes.body.rawValue, weight: UIFontWeightRegular, color: .lightGray, alignment: .left)
    }
}
