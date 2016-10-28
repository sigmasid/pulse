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
        filterImageView = UIImageView(frame: CGRect(x: 0,y: 0,width: self.frame.width, height: self.frame.height))
        filterImageView?.contentMode = .scaleAspectFill
        filterImageView?.clipsToBounds = true
        filterImageView?.alpha = 1.0
        
        self.addSubview(filterImageView!)
        
        contentView.layer.cornerRadius = 5
        contentView.layer.backgroundColor = UIColor.clear.cgColor
        contentView.layer.shouldRasterize = true
        contentView.layer.rasterizationScale = UIScreen.main.scale
        contentView.clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
}
