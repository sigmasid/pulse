//
//  QuickBrowseLayout.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/1/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class QuickBrowseLayout: UICollectionViewFlowLayout {
    private var lastCollectionViewSize: CGSize = CGSize.zero
    
    public var scalingOffset: CGFloat = 200 //for offsets >= scalingOffset scale factor is minimumScaleFactor
    public var minimumScaleFactor: CGFloat = 0.7
    public var scaleItems: Bool = true
    
    static func configureLayout(collectionView: UICollectionView, itemSize: CGSize, minimumLineSpacing: CGFloat) -> QuickBrowseLayout {
        let layout = QuickBrowseLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = minimumLineSpacing
        layout.itemSize = itemSize
        
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        collectionView.collectionViewLayout = layout
        collectionView.showsHorizontalScrollIndicator = false
        
        return layout
    }
    
    override public func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        super.invalidateLayout(with: context)
        
        if collectionView == nil {
            return
        }
        
        let currentCollectionViewSize = collectionView!.bounds.size
        
        if !currentCollectionViewSize.equalTo(lastCollectionViewSize) {
            configureInset()
            lastCollectionViewSize = currentCollectionViewSize
        }
    }
    
    private func configureInset() -> Void {
        if collectionView == nil {
            return
        }
        
        let inset = collectionView!.bounds.size.width / 2 - itemSize.width / 2
        collectionView!.contentInset = UIEdgeInsetsMake(0, inset, 0, inset)
        collectionView!.contentOffset = CGPoint(x: -inset, y: 0)
    }
    
    public override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        if collectionView == nil {
            return proposedContentOffset
        }
        
        let collectionViewSize = collectionView!.bounds.size
        let proposedRect = CGRect(x: proposedContentOffset.x, y: 0, width: collectionViewSize.width, height: collectionViewSize.height)
        
        let layoutAttributes = layoutAttributesForElements(in: proposedRect)
        
        if layoutAttributes == nil {
            return proposedContentOffset
        }
        
        var candidateAttributes: UICollectionViewLayoutAttributes?
        let proposedContentOffsetCenterX = proposedContentOffset.x + collectionViewSize.width / 2
        
        for attributes: UICollectionViewLayoutAttributes in layoutAttributes! {
            if attributes.representedElementCategory != .cell, attributes.representedElementCategory != .supplementaryView {
                continue
            }
            
            if candidateAttributes == nil {
                candidateAttributes = attributes
                continue
            }
            
            if fabs(attributes.center.x - proposedContentOffsetCenterX) < fabs(candidateAttributes!.center.x - proposedContentOffsetCenterX) {
                candidateAttributes = attributes
            }
        }
        
        if candidateAttributes == nil {
            return proposedContentOffset
        }
        
        var newOffsetX = candidateAttributes!.center.x - collectionView!.bounds.size.width / 2
        
        let offset = newOffsetX - collectionView!.contentOffset.x
        
        if (velocity.x < 0 && offset > 0) || (velocity.x > 0 && offset < 0) {
            let pageWidth = itemSize.width + minimumLineSpacing
            newOffsetX += velocity.x > 0 ? pageWidth : -pageWidth
        }
        
        return CGPoint(x: newOffsetX, y: proposedContentOffset.y)
    }
    
    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        if !scaleItems || collectionView == nil {
            return super.layoutAttributesForElements(in: rect)
        }
        
        let superAttributes = super.layoutAttributesForElements(in: rect)
        
        if superAttributes == nil {
            return nil
        }
        
        let contentOffset = collectionView!.contentOffset
        let size = collectionView!.bounds.size
        
        let visibleRect = CGRect(x: contentOffset.x, y: contentOffset.y, width: size.width, height: size.height)
        let visibleCenterX = visibleRect.midX
        
        var newAttributesArray = Array<UICollectionViewLayoutAttributes>()
        
        for (_, attributes) in superAttributes!.enumerated() {
            let newAttributes = attributes.copy() as! UICollectionViewLayoutAttributes
            newAttributesArray.append(newAttributes)
            let distanceFromCenter = visibleCenterX - newAttributes.center.x
            let absDistanceFromCenter = min(abs(distanceFromCenter), scalingOffset)
            let scale = absDistanceFromCenter * (minimumScaleFactor - 1) / scalingOffset + 1
            newAttributes.transform3D = CATransform3DScale(CATransform3DIdentity, scale, scale, 1)
        }
        
        return newAttributesArray;
    }
}
