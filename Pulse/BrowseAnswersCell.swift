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
        
        contentView.layer.backgroundColor = UIColor.clearColor().CGColor
        contentView.layer.shouldRasterize = true
        contentView.layer.rasterizationScale = UIScreen.mainScreen().scale
        contentView.clipsToBounds = true
        contentView.layer.borderColor = UIColor.whiteColor().CGColor
        contentView.layer.borderWidth = IconThickness.Medium.rawValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupCell() {
        answerPreviewImage = UIImageView()
        addSubview(answerPreviewImage!)

        answerPreviewImage!.translatesAutoresizingMaskIntoConstraints = false
        answerPreviewImage?.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        answerPreviewImage?.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
        answerPreviewImage?.heightAnchor.constraintEqualToAnchor(heightAnchor, multiplier: 0.7).active = true
        answerPreviewImage?.widthAnchor.constraintEqualToAnchor(widthAnchor, multiplier: 0.85).active = true
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
