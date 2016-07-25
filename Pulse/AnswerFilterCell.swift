//
//  AnswerFilterCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/20/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AnswerFilterCell: UICollectionViewCell {
    
    var filterImageView : UIImageView?
    
    var imageName = "" {
        didSet {
            filterImageView!.image = UIImage(named: imageName)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        filterImageView = UIImageView(frame: CGRectMake(0,0,self.frame.width, self.frame.height))
        filterImageView?.contentMode = .ScaleAspectFill
        filterImageView?.clipsToBounds = true
        filterImageView?.alpha = 0.7
        
        self.addSubview(filterImageView!)
        
        contentView.layer.cornerRadius = 5
        contentView.layer.backgroundColor = UIColor.whiteColor().CGColor
        contentView.layer.borderColor = UIColor.blackColor().CGColor
        contentView.layer.borderWidth = 1
        contentView.layer.shouldRasterize = true
        contentView.layer.rasterizationScale = UIScreen.mainScreen().scale
        contentView.clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        super.applyLayoutAttributes(layoutAttributes)
        let answerFiltersAttributes = layoutAttributes as! AnswerFiltersViewLayoutAttributes
        self.layer.anchorPoint = answerFiltersAttributes.anchorPoint
        self.center.y += (answerFiltersAttributes.anchorPoint.y - 0.5)*CGRectGetHeight(self.bounds)
    }
}
