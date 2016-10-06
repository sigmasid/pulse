//
//  SearchHeaderCellView.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/28/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class SearchHeaderCell: UICollectionReusableView {
    var showSearchField = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        
        addSubview(showSearchField)
        showSearchField.frame = frame.insetBy(dx: 5, dy: 5)
        showSearchField.setButtonFont(FontSizes.body2.rawValue, weight: UIFontWeightRegular, color: UIColor.lightGray, alignment: .center)
        showSearchField.backgroundColor = UIColor.white

        let searchTintedImage = UIImage(named: "search")?.withRenderingMode(.alwaysTemplate)
        showSearchField.setImage(searchTintedImage, for: UIControlState())
        showSearchField.tintColor = UIColor.lightGray
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
