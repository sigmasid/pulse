//
//  ExploreChannelsCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/18/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ExploreChannelsCell: UICollectionViewCell {
    fileprivate var titleStack = PulseMenu(_axis: .vertical, _spacing: 0)
    fileprivate lazy var titleLabel = UILabel()
    fileprivate lazy var subtitleLabel = UILabel()
    fileprivate var subscribeButton = PulseButton(size: .xxSmall, type: .addCircle, isRound: true, hasBackground: false, tint: .black)
    fileprivate lazy var previewImage = UIImageView()
    
    public var delegate : ExploreChannelsDelegate!
    
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
    
    public func updateSubscribe(type : FollowToggle, tag: Int) {
        DispatchQueue.main.async {
            type == .follow ? self.subscribeButton.setImage(UIImage(named: "add-circle"), for: .normal) : self.subscribeButton.setImage(UIImage(named: "remove-circle"), for: .normal)
        }
        subscribeButton.tag = tag
    }
    
    internal func userClickedSubscribe(sender : UIButton) {
        if delegate != nil {
            delegate.userClickedSubscribe(senderTag: sender.tag)
        }
    }
    
    override func prepareForReuse() {
        titleLabel.text = ""
        subtitleLabel.text = ""
        previewImage.image = nil
        
        super.prepareForReuse()
    }
    
    fileprivate func setupCell() {
        previewImage.frame = CGRect(x: contentView.bounds.origin.x, y: contentView.bounds.origin.y, width: contentView.bounds.width, height: contentView.bounds.height * 0.75)
        //titleStack.frame = CGRect(x: Spacing.xs.rawValue, y: contentView.bounds.height * 0.75,
        //                          width: contentView.bounds.width - IconSizes.small.rawValue - Spacing.xs.rawValue, height: contentView.bounds.height * 0.24)
        subscribeButton.frame.origin = CGPoint(x: contentView.bounds.maxX - IconSizes.small.rawValue - Spacing.xxs.rawValue,
                                            y: contentView.bounds.height * 0.75 + ((contentView.bounds.height * 0.25 - IconSizes.xSmall.rawValue) / 2))
        subscribeButton.addTarget(self, action: #selector(userClickedSubscribe), for: .touchUpInside)

        addSubview(previewImage)
        addSubview(titleStack)
        addSubview(subscribeButton)
        
        titleStack.translatesAutoresizingMaskIntoConstraints = false
        titleStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        titleStack.topAnchor.constraint(equalTo: previewImage.bottomAnchor, constant: Spacing.xxs.rawValue).isActive = true
        titleStack.trailingAnchor.constraint(equalTo: subscribeButton.leadingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        
        titleStack.addArrangedSubview(titleLabel)
        titleStack.addArrangedSubview(subtitleLabel)
        titleStack.alignment = .leading
        
        titleLabel.setFont(FontSizes.body.rawValue, weight: UIFontWeightHeavy, color: .black, alignment: .left)
        titleLabel.numberOfLines = 1
        subtitleLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .darkText, alignment: .left)
        subtitleLabel.numberOfLines = 2

        previewImage.backgroundColor = UIColor.pulseGrey.withAlphaComponent(0.5)
        previewImage.contentMode = .scaleAspectFill
        previewImage.clipsToBounds = true
    }
}
