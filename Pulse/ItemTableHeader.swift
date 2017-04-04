//
//  ItemTableHeader.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/23/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ItemTableHeader: UITableViewHeaderFooterView {
    public var delegate : HeaderDelegate!
    
    fileprivate var titleLabel = UILabel()
    lazy var addButton = PulseButton(size: .small, type: .add, isRound: true, background: .white, tint: .black)
    
    fileprivate var reuseCell = false
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        addBottomBorder()
        setupPreview()
        addButton.removeShadow()
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
            delegate.clickedHeaderMenu()
        }
    }
    
    fileprivate func setupPreview() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(addButton)
        
        addButton.addTarget(self, action: #selector(clickedMenu), for: .touchUpInside)
        addButton.frame = CGRect(x: Spacing.s.rawValue,
                                  y: contentView.bounds.height / 2 - addButton.bounds.height / 2,
                                  width: addButton.bounds.width,
                                  height: addButton.bounds.height)
        
        titleLabel.frame = CGRect(x: Spacing.m.rawValue + addButton.bounds.width,
                                  y: 0,
                                  width: contentView.bounds.width - Spacing.m.rawValue - addButton.bounds.width,
                                  height: contentView.bounds.height)
        
        titleLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightBold, color: UIColor.black, alignment: .left)
    }

}
