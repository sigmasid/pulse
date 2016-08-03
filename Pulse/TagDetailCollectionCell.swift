//
//  TagDetailCollectionCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/2/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class TagDetailCollectionCell: UICollectionViewCell {
    weak var questionLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        questionLabel = UILabel(frame: CGRectMake(0, 0, self.bounds.width, self.bounds.width))
        self.addSubview(questionLabel)
        contentView.backgroundColor = UIColor.redColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
