//
//  AnswerMenu.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/12/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AnswerMenu: UIView {
    
    fileprivate let _addAnswer = UIButton()
    fileprivate let _quickBrowse = UIButton()
        
    internal enum AnswerMenuButtonSelector: Int {
        case addAnswer, browseAnswers
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.3)

        layoutButtons()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if  isHidden {
            return false
        } else {
            print("expanded bounds fired")
            let expandedBounds = bounds.insetBy(dx: -50, dy: -50)
            return expandedBounds.contains(point)
        }
    }
    
    fileprivate func layoutButtons() {

        addSubview(_addAnswer)
        addSubview(_quickBrowse)
        
        _addAnswer.translatesAutoresizingMaskIntoConstraints = false
        _addAnswer.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.s.rawValue).isActive = true
        _addAnswer.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        _addAnswer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        _addAnswer.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true

        _quickBrowse.translatesAutoresizingMaskIntoConstraints = false
        _quickBrowse.topAnchor.constraint(equalTo: _addAnswer.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        _quickBrowse.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        _quickBrowse.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        _quickBrowse.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        
        _addAnswer.backgroundColor = UIColor.clear
        _quickBrowse.backgroundColor = UIColor.clear
        
        _addAnswer.setTitle("add answer", for: UIControlState())
        _quickBrowse.setTitle("browse answers", for: UIControlState())
        
        _addAnswer.titleLabel?.shadowColor = UIColor.black.withAlphaComponent(0.5)
        _quickBrowse.titleLabel?.shadowColor = UIColor.black.withAlphaComponent(0.5)
        _addAnswer.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        _quickBrowse.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        _addAnswer.titleLabel?.font = UIFont.systemFont(ofSize: FontSizes.caption.rawValue, weight: UIFontWeightMedium)
        _quickBrowse.titleLabel?.font = UIFont.systemFont(ofSize: FontSizes.caption.rawValue, weight: UIFontWeightMedium)
        _addAnswer.titleLabel?.textAlignment = .left
        _quickBrowse.titleLabel?.textAlignment = .left

        _addAnswer.setImage(UIImage(named: "add"), for: UIControlState())
        _addAnswer.imageView?.contentMode = .scaleAspectFit
        _addAnswer.imageEdgeInsets = UIEdgeInsetsMake(15, -10, 15, 15) //to better align both buttons

        _quickBrowse.setImage(UIImage(named: "browse"), for: UIControlState())
        _quickBrowse.imageView?.contentMode = .scaleAspectFit
        _quickBrowse.imageEdgeInsets = UIEdgeInsetsMake(15, -10, 15, 15)
        
        _addAnswer.contentHorizontalAlignment = .left
        _quickBrowse.contentHorizontalAlignment = .left

        
    }
    
    func getButton(_ buttonName : AnswerMenuButtonSelector) -> UIButton {
        switch buttonName {
        case .addAnswer: return _addAnswer
        case .browseAnswers: return _quickBrowse
        }
    }
}
