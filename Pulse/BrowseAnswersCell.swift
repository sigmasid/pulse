//
//  BrowseAnswersCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/8/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class BrowseAnswersCell: UICollectionViewCell {
    
    var answerPreviewImage : UIImageView?
    var answerPreviewName : UILabel?
    var answerPreviewBio : UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupCell()
        
        contentView.layer.cornerRadius = 5
        contentView.layer.backgroundColor = UIColor.clearColor().CGColor
        contentView.layer.shouldRasterize = true
        contentView.layer.rasterizationScale = UIScreen.mainScreen().scale
        contentView.clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        super.applyLayoutAttributes(layoutAttributes)
        let browseAnswersAttributes = layoutAttributes as! BrowseAnswersLayoutAttributes
        
        layer.anchorPoint = browseAnswersAttributes.anchorPoint
        center.y += (browseAnswersAttributes.anchorPoint.y - 0.5) * CGRectGetHeight(bounds) * 0.5
    }
    
    func setupCell() {
        answerPreviewImage = UIImageView()
        addSubview(answerPreviewImage!)

        answerPreviewImage!.translatesAutoresizingMaskIntoConstraints = false
        answerPreviewImage?.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        answerPreviewImage?.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
        answerPreviewImage?.heightAnchor.constraintEqualToAnchor(heightAnchor, multiplier: 0.8).active = true
        answerPreviewImage?.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        answerPreviewImage?.contentMode = UIViewContentMode.ScaleAspectFill
        answerPreviewImage?.layoutIfNeeded()
        
        answerPreviewBio = UILabel()
        addSubview(answerPreviewBio!)
        answerPreviewBio!.translatesAutoresizingMaskIntoConstraints = false
        answerPreviewBio?.leadingAnchor.constraintEqualToAnchor(answerPreviewImage?.leadingAnchor).active = true
        answerPreviewBio?.bottomAnchor.constraintEqualToAnchor(answerPreviewImage?.topAnchor, constant: -Spacing.s.rawValue).active = true
        answerPreviewBio?.setPreferredFont(UIColor.whiteColor())
        
        answerPreviewName = UILabel()
        addSubview(answerPreviewName!)
        answerPreviewName!.translatesAutoresizingMaskIntoConstraints = false
        answerPreviewName?.leadingAnchor.constraintEqualToAnchor(answerPreviewImage?.leadingAnchor).active = true
        answerPreviewName?.bottomAnchor.constraintEqualToAnchor(answerPreviewBio?.topAnchor).active = true
        answerPreviewName?.setPreferredFont(UIColor.whiteColor())
    }
}
