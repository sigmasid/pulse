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
    private lazy var _numAnswers = UILabel()
    private let _backgroundColors = [UIColor.cyanColor(), UIColor.yellowColor(), UIColor.blueColor(), UIColor.greenColor(), UIColor.orangeColor(), UIColor.magentaColor()]
    
    private let _iconSize = IconSizes.Medium.rawValue
    private var _pulseIcon : Icon?
    private let _iconFrame = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addBackgroundColor()
        addQuestionLabel()
        addIconAndAnswerCount(UIColor.blackColor(), backgroundColor : UIColor.whiteColor().colorWithAlphaComponent(0.7))
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
    private func addIconAndAnswerCount(iconColor: UIColor, backgroundColor : UIColor) {
        addSubview(_iconFrame)
        
        _iconFrame.translatesAutoresizingMaskIntoConstraints = false
        _iconFrame.widthAnchor.constraintEqualToConstant(_iconSize).active = true
        _iconFrame.heightAnchor.constraintEqualToAnchor(_iconFrame.widthAnchor).active = true
        _iconFrame.topAnchor.constraintEqualToAnchor(topAnchor, constant: Spacing.m.rawValue).active = true
        _iconFrame.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: Spacing.m.rawValue).active = true
        _iconFrame.layoutIfNeeded()
        
        _pulseIcon = Icon(frame: CGRectMake(0,0, _iconFrame.frame.width, _iconFrame.frame.height))
        _pulseIcon!.drawIconBackground(backgroundColor)
        _pulseIcon!.drawIcon(iconColor, iconThickness: IconThickness.Medium.rawValue)
        
        _iconFrame.addSubview(_pulseIcon!)
        
        addSubview(_numAnswers)
        
        _numAnswers.font = UIFont.systemFontOfSize(14, weight: UIFontWeightSemibold)
        _numAnswers.textAlignment = .Center
        _numAnswers.translatesAutoresizingMaskIntoConstraints = false
        _numAnswers.topAnchor.constraintEqualToAnchor(_iconFrame.bottomAnchor, constant: Spacing.xs.rawValue).active = true
        _numAnswers.centerXAnchor.constraintEqualToAnchor(_iconFrame.centerXAnchor).active = true
    }
    
    func setQuestionLabel(qTitle : String?) {
        _questionLabel.text = qTitle?.uppercaseString
    }
    
    func setNumAnswersLabel(numAnswers : Int) {
        if numAnswers > 1 {
            _numAnswers.text = String("\(numAnswers) Answers")
        } else {
            _numAnswers.text = String("\(numAnswers) Answer")
        }
    }
}
