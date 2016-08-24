//
//  QuestionPreviewOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/2/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class QuestionPreviewOverlay: UIView {
    
    private let _questionLabel = UILabel()
    
    private let _iconSize = IconSizes.Large.rawValue
    private let _answerCount = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addBackgroundColor()
        addQuestionLabel()
        addAnswerCount()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func addBackgroundColor() {
        let _rand = arc4random_uniform(UInt32(_backgroundColors.count))
        backgroundColor = _backgroundColors[Int(_rand)]
    }
    
    private func addQuestionLabel() {
        addSubview(_questionLabel)
        
        _questionLabel.backgroundColor = UIColor.clearColor()
        _questionLabel.font = UIFont.systemFontOfSize(40, weight: UIFontWeightBlack)
        _questionLabel.numberOfLines = 0
        _questionLabel.textAlignment = .Center
        _questionLabel.lineBreakMode = .ByWordWrapping
        
        _questionLabel.translatesAutoresizingMaskIntoConstraints = false
        _questionLabel.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        _questionLabel.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        _questionLabel.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
    }
    
    ///Add icon in top left
    private func addAnswerCount() {
        addSubview(_answerCount)
        
        _answerCount.translatesAutoresizingMaskIntoConstraints = false
        _answerCount.widthAnchor.constraintEqualToConstant(_iconSize).active = true
        _answerCount.heightAnchor.constraintEqualToAnchor(_answerCount.widthAnchor).active = true
        _answerCount.topAnchor.constraintEqualToAnchor(topAnchor, constant: Spacing.m.rawValue).active = true
        _answerCount.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: -Spacing.m.rawValue).active = true
        _answerCount.layoutIfNeeded()
        
        _answerCount.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 10, 0)
        _answerCount.titleLabel!.font = UIFont.systemFontOfSize(25, weight: UIFontWeightBold)
        _answerCount.titleLabel!.textColor = UIColor.whiteColor()
        _answerCount.titleLabel!.textAlignment = .Center
        _answerCount.setBackgroundImage(UIImage(named: "count-label"), forState: .Normal)
        _answerCount.imageView?.contentMode = .ScaleAspectFit
    }
    
    func setQuestionLabel(qTitle : String?) {
        _questionLabel.text = qTitle?.uppercaseString
    }
    
    func setNumAnswersLabel(numAnswers : Int) {
        _answerCount.setTitle(String(numAnswers), forState: .Normal)
    }
}
