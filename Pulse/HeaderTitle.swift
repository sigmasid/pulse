//
//  HeaderTitle.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/8/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class HeaderTitle: UICollectionReusableView {

    public var titleLabel = UILabel()
    
    ///setup order: first profile image + bio labels, then buttons + scope bar
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        setupChannelHeader()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func setTitle(title : String?) {
        titleLabel.text = title
    }
    
    fileprivate func setupChannelHeader() {
        titleLabel.frame = bounds
        addSubview(titleLabel)
        titleLabel.text = "subscriptions"
        titleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightMedium, color: .black, alignment: .center)
    }
}
