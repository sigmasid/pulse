//
//  FiltersCellCollectionViewCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/22/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class FiltersCell: UICollectionViewCell {
    var filterImageView : UIImageView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        filterImageView = UIImageView(frame: CGRectMake(0,0,self.frame.width, self.frame.height))
        filterImageView?.contentMode = .ScaleAspectFill
        filterImageView?.clipsToBounds = true
        filterImageView?.alpha = 1.0
        
        self.addSubview(filterImageView!)
        
        contentView.layer.cornerRadius = 5
        contentView.layer.backgroundColor = UIColor.clearColor().CGColor
        contentView.layer.shouldRasterize = true
        contentView.layer.rasterizationScale = UIScreen.mainScreen().scale
        contentView.clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
}
