//
//  QuestionHeader.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/19/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class AnswersHeader: UICollectionReusableView {
    fileprivate lazy var titleLabel = UILabel()
    lazy var answerCount = PulseButton(size: .small, type: .answerCount, isRound: false, hasBackground: false)
    
    fileprivate var reuseCell = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addShadow()
        setupQuestionPreview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateLabel(_ _title : String?) {
        if let _title = _title {
            self.titleLabel.text = "# \(_title)"
        }
    }
    
    override func prepareForReuse() {
        titleLabel.text = ""
        answerCount.setTitle("", for: UIControlState())
        
        super.prepareForReuse()
    }
    
    fileprivate func setupQuestionPreview() {
        
        addSubview(titleLabel)
        addSubview(answerCount)
        
        answerCount.frame = CGRect(x: bounds.width - answerCount.bounds.width - Spacing.xs.rawValue, y: bounds.height / 2, width: answerCount.bounds.width, height: answerCount.bounds.height)
        titleLabel.frame = CGRect(x: Spacing.xs.rawValue, y: 0, width: bounds.width - Spacing.s.rawValue - answerCount.bounds.width, height: bounds.height)
        titleLabel.setFont(FontSizes.title.rawValue, weight: UIFontWeightRegular, color: UIColor.black, alignment: .left)
    }
}
