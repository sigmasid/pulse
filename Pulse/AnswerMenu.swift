//
//  AnswerMenu.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/12/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AnswerMenu: UIView {
    
    private let _addAnswer = UIButton()
    private let _quickBrowse = UIButton()
        
    internal enum AnswerMenuButtonSelector: Int {
        case AddAnswer, BrowseAnswers
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
        self.userInteractionEnabled = true
        layoutButtons()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func layoutButtons() {
        addSubview(_addAnswer)
        addSubview(_quickBrowse)
        
        _addAnswer.translatesAutoresizingMaskIntoConstraints = false
        _addAnswer.topAnchor.constraintEqualToAnchor(topAnchor, constant: Spacing.s.rawValue).active = true
        _addAnswer.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        _addAnswer.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: Spacing.xs.rawValue).active = true
        _addAnswer.heightAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue).active = true

        _quickBrowse.translatesAutoresizingMaskIntoConstraints = false
        _quickBrowse.topAnchor.constraintEqualToAnchor(_addAnswer.bottomAnchor, constant: Spacing.s.rawValue).active = true
        _quickBrowse.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        _quickBrowse.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: Spacing.xs.rawValue).active = true
        _quickBrowse.heightAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue).active = true
        
        _addAnswer.backgroundColor = UIColor.clearColor()
        _quickBrowse.backgroundColor = UIColor.clearColor()
        
        _addAnswer.setTitle("add answer", forState: .Normal)
        _quickBrowse.setTitle("browse answers", forState: .Normal)
        
        _addAnswer.titleLabel?.shadowColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        _quickBrowse.titleLabel?.shadowColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        _addAnswer.titleLabel?.shadowOffset = CGSizeMake(1, 1)
        _quickBrowse.titleLabel?.shadowOffset = CGSizeMake(1, 1)
        _addAnswer.titleLabel?.font = UIFont.systemFontOfSize(FontSizes.Caption.rawValue, weight: UIFontWeightMedium)
        _quickBrowse.titleLabel?.font = UIFont.systemFontOfSize(FontSizes.Caption.rawValue, weight: UIFontWeightMedium)
        _addAnswer.titleLabel?.textAlignment = .Left
        _quickBrowse.titleLabel?.textAlignment = .Left

        _addAnswer.setImage(UIImage(named: "add"), forState: .Normal)
        _addAnswer.imageView?.contentMode = .ScaleAspectFit
        _addAnswer.imageEdgeInsets = UIEdgeInsetsMake(15, -10, 15, 15) //to better align both buttons

        _quickBrowse.setImage(UIImage(named: "browse"), forState: .Normal)
        _quickBrowse.imageView?.contentMode = .ScaleAspectFit
        _quickBrowse.imageEdgeInsets = UIEdgeInsetsMake(15, -10, 15, 15)
        
        _addAnswer.contentHorizontalAlignment = .Left
        _quickBrowse.contentHorizontalAlignment = .Left

        
    }
    
    func getButton(buttonName : AnswerMenuButtonSelector) -> UIButton {
        switch buttonName {
        case .AddAnswer: return _addAnswer
        case .BrowseAnswers: return _quickBrowse
        }
    }
}
