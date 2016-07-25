//
//  AnswerFiltersCollectionViewLayout.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/20/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AnswerFiltersCollectionViewLayout: UICollectionViewLayout {
    let itemSize = CGSize(width: 133, height: 173)
    
    var radius: CGFloat = 500 {
        didSet {
            invalidateLayout()
        }
    }
    
    var anglePerItem: CGFloat {
        return atan(itemSize.width / radius)
    }
    
    override func collectionViewContentSize() -> CGSize {
        return CGSize(width: CGFloat(collectionView!.numberOfItemsInSection(0)) * itemSize.width,
                      height: CGRectGetHeight(collectionView!.bounds))
    }
}
