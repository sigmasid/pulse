//
//  QuestionHeader.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/19/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ItemHeader: UICollectionReusableView {
    public var delegate : HeaderDelegate!
    
    fileprivate var titleLabel = UILabel()
    lazy var headerMenu = PulseButton(size: .small, type: .ellipsis, isRound: false, hasBackground: false, tint: .black)
    
    fileprivate var reuseCell = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addBottomBorder()
        setupPreview()
        headerMenu.removeShadow()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateLabel(_ _title : String?) {
        if let _title = _title {
            titleLabel.text = _title
        }
    }
    
    override func prepareForReuse() {
        titleLabel.text = ""
        super.prepareForReuse()
    }
    
    func clickedMenu() {
        if delegate != nil {
            delegate.userClickedMenu()
        }
    }
    
    fileprivate func setupPreview() {
        addSubview(titleLabel)
        addSubview(headerMenu)
        
        headerMenu.addTarget(self, action: #selector(clickedMenu), for: .touchUpInside)
        headerMenu.frame = CGRect(x: bounds.width - headerMenu.bounds.width - Spacing.xs.rawValue,
                                   y: bounds.height / 2 - headerMenu.bounds.height / 2,
                                   width: headerMenu.bounds.width,
                                   height: headerMenu.bounds.height)
        
        titleLabel.frame = CGRect(x: Spacing.s.rawValue,
                                  y: 0,
                                  width: bounds.width - Spacing.s.rawValue - headerMenu.bounds.width,
                                  height: bounds.height)
        
        titleLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightBold, color: UIColor.black, alignment: .left)
    }
}
