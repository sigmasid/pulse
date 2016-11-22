//
//  FeedPeopleCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 11/22/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class FeedPeopleCell: UICollectionViewCell {
    
    lazy var titleLabel = UILabel()
    lazy var subtitleLabel = UILabel()
    lazy var answerCount = PulseButton()
    fileprivate var previewImage = UIImageView()
    
    fileprivate var previewVC : PreviewVC?
    fileprivate var previewAdded = false
    fileprivate var reuseCell = false
    
    fileprivate var titleHeightConstraint : NSLayoutConstraint!
    fileprivate var subtitleHeightConstraint : NSLayoutConstraint!

    fileprivate var showPreviewImage = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUserPreview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func showAnswer(answer : Answer) {
        previewVC = PreviewVC(frame: contentView.bounds)
        previewVC!.currentAnswer = answer
        previewImage.isHidden = true
        
        titleLabel.isHidden = true
        subtitleLabel.isHidden = true
        
        UIView.transition( with: contentView, duration: 0.5, options: .transitionFlipFromLeft, animations: { _ in self.contentView.addSubview(self.previewVC!) }, completion: nil)
        previewAdded = true
    }
    
    func removeAnswer() {
        previewImage.isHidden = false
        titleLabel.isHidden = false
        subtitleLabel.isHidden = false
        previewVC?.removeFromSuperview()
    }
    
    func updateLabel(_ _title : String?, _subtitle : String?) {
        
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
        }
        
        
        titleLabel.text = _title
        subtitleLabel.text = _subtitle
    }
    
    func updateLabel(_ _title : String?, _subtitle : String?, _image : UIImage?) {
        updateLabel(_title, _subtitle: _subtitle)
        previewImage.image = _image
    }
    
    func updateImage( image : UIImage?) {
        if let image = image {
            previewImage.image = image
            
            previewImage.layer.cornerRadius = 0
            previewImage.layer.masksToBounds = true
            previewImage.clipsToBounds = true
        }
    }
    
    func hideAnswerCount() {
        answerCount.isHidden = true
    }
    
    func showAnswerCount() {
        answerCount.isHidden = false
        answerCount.setTitle(nil, for: UIControlState())
    }
    
    override func prepareForReuse() {
        if previewAdded {
            removeAnswer()
        }
        
        previewImage.image = nil
        super.prepareForReuse()
    }
    
    fileprivate func setupUserPreview() {
        
        previewImage.image = nil
        
        addSubview(previewImage)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        
        previewImage.frame = contentView.frame
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleHeightConstraint = titleLabel.heightAnchor.constraint(equalToConstant: titleLabel.intrinsicContentSize.height)
        titleHeightConstraint.isActive = true
        
        titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.xs.rawValue).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        titleLabel.setBlurredBackground()
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleHeightConstraint = subtitleLabel.heightAnchor.constraint(equalToConstant: subtitleLabel.intrinsicContentSize.height)
        subtitleHeightConstraint.isActive = true
        
        subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
        subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true
        subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor).isActive = true
        subtitleLabel.setBlurredBackground()

        titleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightBlack, color: .white, alignment: .left)
        subtitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .white, alignment: .left)
        subtitleLabel.numberOfLines =  3
        
        previewImage.contentMode = UIViewContentMode.scaleAspectFill
        
        previewImage.setNeedsLayout()
        titleLabel.setNeedsLayout()
        subtitleLabel.setNeedsLayout()
    }
}
