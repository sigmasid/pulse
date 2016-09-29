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
        
        contentView.layer.backgroundColor = UIColor.clear.cgColor
        contentView.layer.shouldRasterize = true
        contentView.layer.rasterizationScale = UIScreen.main.scale
        contentView.clipsToBounds = true
        contentView.layer.borderColor = UIColor.white.cgColor
        contentView.layer.borderWidth = IconThickness.medium.rawValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupCell() {
        answerPreviewName = UILabel()
        addSubview(answerPreviewName!)
        answerPreviewName!.translatesAutoresizingMaskIntoConstraints = false
        answerPreviewName?.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.s.rawValue).isActive = true
        answerPreviewName?.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.85).isActive = true
        answerPreviewName?.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        answerPreviewName?.setPreferredFont(UIColor.white, alignment : .left)
        answerPreviewName?.layoutIfNeeded()
        
        answerPreviewBio = UILabel()
        addSubview(answerPreviewBio!)
        answerPreviewBio!.translatesAutoresizingMaskIntoConstraints = false
        answerPreviewBio?.leadingAnchor.constraint(equalTo: (answerPreviewName?.leadingAnchor)!).isActive = true
        answerPreviewBio?.topAnchor.constraint(equalTo: (answerPreviewName?.bottomAnchor)!).isActive = true
        answerPreviewBio?.setPreferredFont(UIColor.white, alignment : .left)
        answerPreviewBio?.layoutIfNeeded()
        
        answerPreviewImage = UIImageView()
        addSubview(answerPreviewImage!)

        answerPreviewImage!.translatesAutoresizingMaskIntoConstraints = false
        answerPreviewImage?.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        answerPreviewImage?.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.s.rawValue).isActive = true
        answerPreviewImage?.topAnchor.constraint(equalTo: (answerPreviewBio?.bottomAnchor)!, constant: Spacing.s.rawValue).isActive = true
        answerPreviewImage?.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.85).isActive = true
        answerPreviewImage?.contentMode = UIViewContentMode.scaleAspectFill
        answerPreviewImage?.clipsToBounds = true
        answerPreviewImage?.layoutIfNeeded()
    }
}
