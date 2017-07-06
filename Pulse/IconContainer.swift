//
//  IconContainer.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/7/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class IconContainer: UIView {
    fileprivate var icon : Icon!
    fileprivate var viewTitleLabel = UILabel()
    
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
    
    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let relativeFrame = bounds
        let hitTestEdgeInsets = UIEdgeInsetsMake(-44, -44, -44, -44)
        let hitFrame = UIEdgeInsetsInsetRect(relativeFrame, hitTestEdgeInsets)
        return hitFrame.contains(point)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func setupContainer(_ iconWidth : CGFloat) {
        setupContainer(iconWidth, iconColor: UIColor.white, iconBackgroundColor: UIColor.black)
    }
    
    fileprivate func setupContainer(_ iconWidth : CGFloat, iconColor : UIColor, iconBackgroundColor : UIColor) {
        addSubview(viewTitleLabel)
        viewTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        viewTitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        viewTitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        viewTitleLabel.layoutIfNeeded()
        
        icon = Icon(frame: CGRect(x: 0, y: 0, width: iconWidth, height: iconWidth))
        icon.drawIconBackground(iconBackgroundColor)
        icon.drawIcon(iconColor, iconThickness: IconThickness.medium.rawValue)
        addSubview(icon)
        
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.bottomAnchor.constraint(equalTo: viewTitleLabel.topAnchor).isActive = true
        icon.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        icon.widthAnchor.constraint(equalToConstant: iconWidth).isActive = true
        icon.heightAnchor.constraint(equalToConstant: iconWidth).isActive = true
        icon.layoutIfNeeded()
    }
    
    func setViewTitle(_ title : String) {
        viewTitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightBold, color: .gray, alignment: .center)
        viewTitleLabel.text = title
    }
}
