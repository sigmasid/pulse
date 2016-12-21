//
//  FeedCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class FeedTagCell: UICollectionViewCell {
    lazy var titleLabel = UILabel()
    lazy var subtitleLabel = UILabel()
    lazy var answerCount = UIButton()
    
    fileprivate var cellSetupComplete = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTagPreview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateLabel(_ _title : String?, _subtitle : String?) {
        titleLabel.text = _title
        subtitleLabel.text = _subtitle
    }
    
    func hideAnswerCount() {
        answerCount.isHidden = true
    }
    
    func showAnswerCount() {
        answerCount.isHidden = false
        answerCount.setTitle(nil, for: UIControlState())
    }
    
    override func prepareForReuse() {
        answerCount.setTitle(nil, for: UIControlState())
        titleLabel.text = ""
        subtitleLabel.text = ""
        super.prepareForReuse()
    }
    
    fileprivate func setupTagPreview() {
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(answerCount)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        titleLabel.setFont(FontSizes.headline.rawValue, weight: UIFontWeightHeavy, color: UIColor.white, alignment: .left)
        
        answerCount.translatesAutoresizingMaskIntoConstraints = false
        answerCount.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.15).isActive = true
        answerCount.heightAnchor.constraint(equalTo: answerCount.widthAnchor).isActive = true
        answerCount.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.xs.rawValue).isActive = true
        answerCount.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        
        answerCount.titleEdgeInsets = UIEdgeInsetsMake(0, 0, answerCount.frame.height / 4, 0)
        answerCount.titleLabel!.setFont(FontSizes.caption.rawValue, weight: UIFontWeightHeavy, color: .white, alignment: .center)
        answerCount.setBackgroundImage(UIImage(named: "count-label"), for: UIControlState())
        answerCount.imageView?.contentMode = .scaleAspectFit
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.xs.rawValue).isActive = true
        subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        
        subtitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: UIColor.white, alignment: .left)
        
        titleLabel.layoutIfNeeded()
        answerCount.layoutIfNeeded()
        subtitleLabel.layoutIfNeeded()
        
        titleLabel.numberOfLines = 0
        subtitleLabel.numberOfLines = 0
    }
}

/** OLD WAY TO GET HEIGHT
 if _title != nil {
 let fontAttributes = [ NSFontAttributeName : UIFont.systemFont(ofSize: titleLabel.font.pointSize, weight: UIFontWeightHeavy)]
 let titleHeight = GlobalFunctions.getLabelSize(title: _title!, width: titleLabel.frame.width, fontAttributes: fontAttributes)
 
 titleHeightConstraint.constant = titleHeight
 titleLabel.layoutIfNeeded()
 } else {
 titleHeightConstraint.constant = 0
 }
 
 if _subtitle != nil {
 let fontAttributes = [ NSFontAttributeName : UIFont.systemFont(ofSize: subtitleLabel.font.pointSize, weight: UIFontWeightHeavy)]
 let subtitleHeight = GlobalFunctions.getLabelSize(title: _subtitle!, width: subtitleLabel.frame.width, fontAttributes: fontAttributes)
 
 subtitleHeightConstraint.constant = subtitleHeight
 subtitleLabel.layoutIfNeeded()
 } else {
 subtitleHeightConstraint.constant = 0
 } **/
