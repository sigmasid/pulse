//
//  ForumItemHeader.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/3/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ForumItemHeader: UITableViewHeaderFooterView {
    
    private var titleLabel = UILabel()
    private var subtitleLabel = UILabel()
    private var imageView = UIImageView()
    private var linkedButton = PulseButton(size: .xSmall, type: .related, isRound: true, background: UIColor.white.withAlphaComponent(0.3), tint: .black)
    private var reuseCell = false
    private var isSetup = false
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        imageView.image = nil
    }
    
    public func updateLabels(title : String?, subtitle: String?) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
    
    public func updateImage(image: UIImage?) {
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }
    
    override func prepareForReuse() {
        titleLabel.text = ""
        super.prepareForReuse()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupCell()
    }
    
    public func addLink() -> PulseButton {
        contentView.addSubview(linkedButton)
        linkedButton.translatesAutoresizingMaskIntoConstraints = false
        linkedButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        linkedButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        linkedButton.widthAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
        linkedButton.heightAnchor.constraint(equalTo: linkedButton.widthAnchor).isActive = true
        linkedButton.layoutIfNeeded()
        
        return linkedButton
    }
    
    fileprivate func setupCell() {
        if !isSetup {
            contentView.backgroundColor = .white
            contentView.addSubview(linkedButton)
            contentView.addSubview(imageView)
            contentView.addSubview(titleLabel)
            contentView.addSubview(subtitleLabel)
            
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
            imageView.widthAnchor.constraint(equalToConstant: IconSizes.xLarge.rawValue).isActive = true
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
            imageView.layoutIfNeeded()
            
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.image = UIImage(named: "forum")
            
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.xs.rawValue).isActive = true
            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
            titleLabel.layoutIfNeeded()
            
            subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
            subtitleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
            subtitleLabel.layoutIfNeeded()
            
            titleLabel.setFont(FontSizes.body.rawValue, weight: UIFontWeightBold, color: UIColor.black, alignment: .left)
            subtitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: UIColor.gray, alignment: .left)

            contentView.addBottomBorder(color: .pulseGrey)
            isSetup = true
        }
    }
    
}
