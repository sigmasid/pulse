//
//  PulseFlowLayout.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/3/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class PulseFlowLayout: UICollectionViewFlowLayout {
    static func configureLayout(collectionView: UICollectionView, minimumLineSpacing: CGFloat, itemSpacing: CGFloat, stickyHeader: Bool) -> PulseFlowLayout {
        let layout = PulseFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = minimumLineSpacing
        layout.minimumInteritemSpacing = itemSpacing
        layout.sectionHeadersPinToVisibleBounds = stickyHeader
        layout.estimatedItemSize = CGSize(width: collectionView.frame.width, height: 125)
        
        collectionView.collectionViewLayout = layout
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = UIColor.pulseGrey.withAlphaComponent(0.4)
        
        return layout
    }
    
    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
