//
//  PulseFirstLoadVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/15/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class PulseIntroCell: UICollectionViewCell {
    
    internal var topImage : UIImageView! = UIImageView()
    internal var titleLabel : UILabel! = UILabel()
    internal var imageDescriptionLabel : UILabel! = UILabel()
    internal var screenDescriptionLabel : UILabel! = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addTopImage()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        topImage.image = nil
        titleLabel.removeFromSuperview()
        imageDescriptionLabel.removeFromSuperview()
        screenDescriptionLabel.removeFromSuperview()
    }
    
    internal func setScreenItems(title: String?, imageDescription : String?, screenDescription: String?, imageName: String?) {
        topImage.image = imageName != nil ? UIImage(named: imageName!) : GlobalFunctions.imageWithColor(UIColor.white)
        titleLabel.text = title
        screenDescriptionLabel.text = screenDescription
        imageDescriptionLabel.text = imageDescription
    }
    
    fileprivate func addTopImage() {
        addSubview(topImage)
        addSubview(titleLabel)
        addSubview(imageDescriptionLabel)
        addSubview(screenDescriptionLabel)
        
        topImage.translatesAutoresizingMaskIntoConstraints  = false
        topImage.topAnchor.constraint(equalTo: topAnchor).isActive = true
        topImage.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        topImage.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        topImage.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.425).isActive = true

        topImage.layoutIfNeeded()
        topImage.contentMode = .scaleAspectFill
        topImage.backgroundColor = .clear
        topImage.clipsToBounds = true
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: topImage.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        titleLabel.layoutIfNeeded()
        
        screenDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        screenDescriptionLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        screenDescriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        screenDescriptionLabel.layoutIfNeeded()
        
        titleLabel.setFont(25, weight: UIFontWeightBlack, color: .black, alignment: .center)
        imageDescriptionLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightBold, color: .white, alignment: .left)
        screenDescriptionLabel.setFont(FontSizes.body.rawValue, weight: UIFontWeightRegular, color: .lightGray, alignment: .center)
    }


}
