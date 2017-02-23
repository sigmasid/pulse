//
//  QuestionHeader.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/19/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ItemHeader: UICollectionReusableView {
    fileprivate var titleLabel = UILabel()
    lazy var answerCount = PulseButton(size: .small, type: .answerCount, isRound: false, hasBackground: false)
    
    fileprivate var reuseCell = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addShadow()
        setupPreview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateLabel(_ _title : String?, count: Int) {
        if let _title = _title {
            titleLabel.text = _title
        }
        
        answerCount.setTitle("\(count)", for: .normal)
    }
    
    override func prepareForReuse() {
        titleLabel.text = ""
        answerCount.setTitle("", for: UIControlState())
        
        super.prepareForReuse()
    }
    
    fileprivate func setupPreview() {
        addSubview(titleLabel)
        addSubview(answerCount)
        
        answerCount.frame = CGRect(x: bounds.width - answerCount.bounds.width - Spacing.xs.rawValue,
                                   y: bounds.height / 2 - answerCount.bounds.height / 2,
                                   width: answerCount.bounds.width,
                                   height: answerCount.bounds.height)
        
        titleLabel.frame = CGRect(x: Spacing.s.rawValue,
                                  y: 0,
                                  width: bounds.width - Spacing.m.rawValue - answerCount.bounds.width,
                                  height: bounds.height)
        
        titleLabel.setFont(FontSizes.title.rawValue, weight: UIFontWeightRegular, color: UIColor.black, alignment: .left)
    }
}
