//
//  BrowseAnswersLayoutAttributes.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/8/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class BrowseAnswersLayoutAttributes: UICollectionViewLayoutAttributes {
    
    var anchorPoint = CGPoint(x: 0.5, y: 50)
    
    var angle: CGFloat = 0 {
        didSet {
            zIndex = Int(angle*1000000)
            transform = CGAffineTransformMakeRotation(angle)
        }
    }
    
    override func copyWithZone(zone: NSZone) -> AnyObject {
        let copiedAttributes: BrowseAnswersLayoutAttributes = super.copyWithZone(zone) as! BrowseAnswersLayoutAttributes
        
        copiedAttributes.anchorPoint = anchorPoint
        copiedAttributes.angle = angle
        return copiedAttributes
    }
    
}

class BrowseAnswersLayout: UICollectionViewLayout {
    var itemSize : CGSize!
    
    var angleAtExtreme: CGFloat {
        return collectionView!.numberOfItemsInSection(0) > 0 ? -CGFloat(collectionView!.numberOfItemsInSection(0)-1)*anglePerItem : 0
    }
    
    var angle: CGFloat {
        return angleAtExtreme * collectionView!.contentOffset.x / (collectionViewContentSize().width - CGRectGetWidth(collectionView!.bounds))
    }
    
    var radius: CGFloat! {
        didSet {
            invalidateLayout()
        }
    }
    
    var anglePerItem: CGFloat {
        return atan(itemSize.width/radius)
    }
    
    var attributesList = [BrowseAnswersLayoutAttributes]()
    
    override func collectionViewContentSize() -> CGSize {
        return CGSize(width: CGFloat(collectionView!.numberOfItemsInSection(0)) * itemSize.width,
                      height: CGRectGetHeight(collectionView!.bounds))
    }
    
    override class func layoutAttributesClass() -> AnyClass {
        return BrowseAnswersLayoutAttributes.self
    }
    
    override func prepareLayout() {
        super.prepareLayout()
        
        let centerX = collectionView!.contentOffset.x + (CGRectGetWidth(collectionView!.bounds) / 2.0)
        let anchorPointY = ((itemSize.height / 2.0) + radius) / itemSize.height
        //1
        let theta = atan2(CGRectGetWidth(collectionView!.bounds)/2.0, radius + (itemSize.height/2.0) - (CGRectGetHeight(collectionView!.bounds)/2.0)) //1
        //2
        var startIndex = 0
        var endIndex = collectionView!.numberOfItemsInSection(0) - 1
        //3
        if (angle < -theta) {
            startIndex = Int(floor((-theta - angle)/anglePerItem))
        }
        //4
        endIndex = min(endIndex, Int(ceil((theta - angle)/anglePerItem)))
        //5
        if (endIndex < startIndex) {
            endIndex = 0
            startIndex = 0
        }
        attributesList = (startIndex...endIndex).map { (i) -> BrowseAnswersLayoutAttributes in
            let attributes = BrowseAnswersLayoutAttributes(forCellWithIndexPath: NSIndexPath(forItem: i, inSection: 0))
            attributes.size = itemSize
            attributes.center = CGPoint(x: centerX, y: CGRectGetMaxY(collectionView!.bounds))
            attributes.angle = angle + (anglePerItem * CGFloat(i))
            attributes.anchorPoint = CGPoint(x: 0.5, y: anchorPointY)
            return attributes
        }
    }
    
    
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return attributesList
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return attributesList[indexPath.row]
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    
    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        var finalContentOffset = proposedContentOffset
        let factor = -angleAtExtreme/(collectionViewContentSize().width - CGRectGetWidth(collectionView!.bounds))
        let proposedAngle = proposedContentOffset.x*factor
        let ratio = proposedAngle/anglePerItem
        var multiplier: CGFloat
        if (velocity.x > 0) {
            multiplier = ceil(ratio)
        } else if (velocity.x < 0) {
            multiplier = floor(ratio)
        } else {
            multiplier = round(ratio)
        }
        finalContentOffset.x = multiplier*anglePerItem/factor
        
        return finalContentOffset
    }
    
}
