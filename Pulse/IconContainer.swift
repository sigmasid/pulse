//
//  IconContainer.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/7/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class IconContainer: UIView {
    private var icon : Icon!
    private var viewTitleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let _iconWidth = bounds.width
        setupContainer(_iconWidth)
    }
    
    convenience init(frame: CGRect, iconColor : UIColor, iconBackgroundColor: UIColor) {
        self.init(frame: frame)
        let _iconWidth = bounds.width
        setupContainer(_iconWidth, iconColor: iconColor, iconBackgroundColor: iconBackgroundColor)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setupContainer(iconWidth : CGFloat) {
        setupContainer(iconWidth, iconColor: UIColor.whiteColor(), iconBackgroundColor: UIColor.blackColor())
    }
    
    private func setupContainer(iconWidth : CGFloat, iconColor : UIColor, iconBackgroundColor : UIColor) {
        addSubview(viewTitleLabel)
        viewTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        viewTitleLabel.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
        viewTitleLabel.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        viewTitleLabel.layoutIfNeeded()
        
        icon = Icon(frame: CGRectMake(0, 0, iconWidth, iconWidth))
        icon.drawIconBackground(iconBackgroundColor)
        icon.drawIcon(iconColor, iconThickness: IconThickness.Medium.rawValue)
        addSubview(icon)
        
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.bottomAnchor.constraintEqualToAnchor(viewTitleLabel.topAnchor).active = true
        icon.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        icon.widthAnchor.constraintEqualToConstant(iconWidth).active = true
        icon.heightAnchor.constraintEqualToConstant(iconWidth).active = true
        icon.layoutIfNeeded()
    }
    
    func setViewTitle(title : String) {
        viewTitleLabel.font = UIFont.systemFontOfSize(FontSizes.Caption.rawValue, weight: UIFontWeightBold)
        viewTitleLabel.text = title
    }
}
