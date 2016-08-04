//
//  TagDetailQuestionCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/11/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class TagDetailQuestionCell: UITableViewCell {
    
    var separatorView: UIView!
    var questionLabel: UILabel!
    var leftSeparatorView: UIView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCellLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    private func setupCellLayout() {
        /*TOP SEPARATOR VIEW*/
        separatorView = UIView()
        addSubview(separatorView!)
        
        separatorView!.translatesAutoresizingMaskIntoConstraints = false
        separatorView?.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        separatorView?.topAnchor.constraintEqualToAnchor(topAnchor).active = true
        separatorView?.heightAnchor.constraintEqualToAnchor(heightAnchor, multiplier: 0.2).active = true
        separatorView?.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        separatorView.layoutIfNeeded()
        
        /*LEFT SEPARATOR VIEW*/
        leftSeparatorView = UIView()
        addSubview(leftSeparatorView!)
        
        leftSeparatorView!.translatesAutoresizingMaskIntoConstraints = false
        leftSeparatorView?.leadingAnchor.constraintEqualToAnchor(leadingAnchor).active = true
        leftSeparatorView?.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
        leftSeparatorView?.topAnchor.constraintEqualToAnchor(separatorView.bottomAnchor).active = true
        leftSeparatorView?.widthAnchor.constraintEqualToConstant(Spacing.s.rawValue).active = true
        leftSeparatorView.layoutIfNeeded()
        
        /*QUESTION LABEL*/
        questionLabel = UILabel()
        questionLabel?.setPreferredFont(UIColor.whiteColor())
        questionLabel.textAlignment = .Left
        
        addSubview(questionLabel!)
        
        questionLabel!.translatesAutoresizingMaskIntoConstraints = false
        questionLabel?.leadingAnchor.constraintEqualToAnchor(leftSeparatorView.trailingAnchor).active = true
        questionLabel?.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
        questionLabel?.topAnchor.constraintEqualToAnchor(separatorView.bottomAnchor).active = true
        questionLabel?.trailingAnchor.constraintEqualToAnchor(trailingAnchor).active = true
        questionLabel.layoutIfNeeded()

        let _color = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.3 )
        leftSeparatorView.backgroundColor = _color
        questionLabel.backgroundColor = _color
        questionLabel.numberOfLines = 0
        
        
    }
}
