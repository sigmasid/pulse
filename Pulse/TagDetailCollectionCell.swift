//
//  TagDetailCollectionCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/2/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class TagDetailCollectionCell: UICollectionViewCell {
    var questionLabel: UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        questionLabel = UILabel()
        questionLabel?.setPreferredFont(UIColor.whiteColor())
        
        self.addSubview(questionLabel!)
        
        questionLabel!.translatesAutoresizingMaskIntoConstraints = false
        questionLabel?.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        questionLabel?.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
        questionLabel?.heightAnchor.constraintEqualToAnchor(heightAnchor).active = true
        questionLabel?.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        questionLabel?.layoutIfNeeded()
        
        contentView.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.5)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
