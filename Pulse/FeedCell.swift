//
//  FeedCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class FeedCell: UICollectionViewCell {
    lazy var titleLabel = UILabel()
    lazy var subtitleLabel = UILabel()
    lazy var answerCount = UIButton()
    fileprivate var previewImage : UIImageView?
    
    fileprivate var previewVC : PreviewVC?
    fileprivate var previewAdded = false
    fileprivate var reuseCell = false
    
    fileprivate var titleLabelConstraint1 : NSLayoutConstraint!
    fileprivate var titleLabelConstraint2 : NSLayoutConstraint!
    fileprivate var titleLabelConstraint3 : NSLayoutConstraint!
    fileprivate var titleLabelConstraint4 : NSLayoutConstraint!
    
    fileprivate var subtitleLabelConstraint1 : NSLayoutConstraint!
    fileprivate var subtitleLabelConstraint2 : NSLayoutConstraint!
    fileprivate var subtitleLabelConstraint3 : NSLayoutConstraint!
    fileprivate var subtitleLabelConstraint4 : NSLayoutConstraint!
    
    fileprivate var previewImageConstraint1 : NSLayoutConstraint!
    fileprivate var previewImageConstraint2 : NSLayoutConstraint!
    fileprivate var previewImageConstraint3 : NSLayoutConstraint!
    fileprivate var previewImageConstraint4 : NSLayoutConstraint!
    
    fileprivate var showPreviewImage = false

    var itemType : FeedItemType? {
        didSet {
            switch itemType! {
            case .question:
                setupQuestionPreview()
                reuseCell = true
            case .answer:
                setupAnswerPreview()
                reuseCell = true
            case .tag:
                setupTagPreview()
                reuseCell = true
            case .people:
                setupUserPreview()
                reuseCell = true
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func showQuestion(_ _question : Question) {
        previewVC = PreviewVC(frame: contentView.bounds)
        previewVC?.currentQuestion = _question
        titleLabel.isHidden = true
        subtitleLabel.isHidden = true

        UIView.transition( with: contentView, duration: 0.5, options: .transitionFlipFromLeft, animations: { _ in self.contentView.addSubview(self.previewVC!) }, completion: nil)
        previewAdded = true
    }
    
    func showAnswer(_ _answerID : String) {
        previewVC = PreviewVC(frame: contentView.bounds)
        previewVC!.currentAnswerID = _answerID
        if previewImage != nil { previewImage!.isHidden = true }
        titleLabel.isHidden = true
        subtitleLabel.isHidden = true
        UIView.transition( with: contentView, duration: 0.5, options: .transitionFlipFromLeft, animations: { _ in self.contentView.addSubview(self.previewVC!) }, completion: nil)
        previewAdded = true
    }
    
    func removeAnswer() {
        if itemType == .question {
            titleLabel.isHidden = false
            subtitleLabel.isHidden = false
        } else if itemType == .answer {
            previewImage!.isHidden = false
            titleLabel.isHidden = false
            subtitleLabel.isHidden = false
        }
        previewVC?.removeFromSuperview()
    }
    
    func updateLabel(_ _title : String?, _subtitle : String?) {
        titleLabel.text = _title
        subtitleLabel.text = _subtitle
    }
    
    func updateImage( image : UIImage?) {
        if let image = image {
            previewImage!.image = image
            previewImage!.layer.cornerRadius = previewImage!.bounds.height / 2
            previewImage!.layer.masksToBounds = true
            previewImage!.clipsToBounds = true
        }
    }
    
    func hideAnswerCount() {
        answerCount.isHidden = true
    }
    
    func showAnswerCount() {
        answerCount.isHidden = false
    }
    
    override func prepareForReuse() {
        if previewAdded {
            removeAnswer()
        }
    }
    
    func deactivateConstraints() {
        titleLabelConstraint1.isActive = false
        titleLabelConstraint2.isActive = false
        titleLabelConstraint3.isActive = false
        titleLabelConstraint4.isActive = false
        
        subtitleLabelConstraint1.isActive = false
        subtitleLabelConstraint2.isActive = false
        subtitleLabelConstraint3.isActive = false
        subtitleLabelConstraint4.isActive = false
        
        if showPreviewImage {
            if previewImageConstraint1 != nil { previewImageConstraint1.isActive = false }
            if previewImageConstraint2 != nil { previewImageConstraint2.isActive = false }
            if previewImageConstraint3 != nil { previewImageConstraint3.isActive = false }
            if previewImageConstraint4 != nil { previewImageConstraint4.isActive = false }
        } else if previewImage != nil {
            previewImage!.removeFromSuperview()
            previewImage = nil
        }
    }
    
    func activateConstraints() {
        titleLabelConstraint1.isActive = true
        titleLabelConstraint2.isActive = true
        titleLabelConstraint3.isActive = true
        titleLabelConstraint4.isActive = true
        
        subtitleLabelConstraint1.isActive = true
        subtitleLabelConstraint2.isActive = true
        subtitleLabelConstraint3.isActive = true
        subtitleLabelConstraint4.isActive = true
        
        if showPreviewImage {
            previewImageConstraint1.isActive = true
            previewImageConstraint2.isActive = true
            previewImageConstraint3.isActive = true
            previewImageConstraint4.isActive = true
        }
    }
    
    fileprivate func setupAnswerPreview() {
        showPreviewImage = true
        
        previewImage = UIImageView()
        addSubview(previewImage!)
        addSubview(titleLabel)
        addSubview(subtitleLabel)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabelConstraint1 = subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xxs.rawValue)
        subtitleLabelConstraint2 = subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.xxs.rawValue)
        subtitleLabelConstraint3 = subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        subtitleLabelConstraint4 = subtitleLabel.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabelConstraint1 = titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xxs.rawValue)
        titleLabelConstraint2 = titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor)
        titleLabelConstraint3 = titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        titleLabelConstraint4 = titleLabel.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue)
        
        previewImage!.translatesAutoresizingMaskIntoConstraints = false
        previewImage!.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        previewImage!.topAnchor.constraint(equalTo: topAnchor).isActive = true
        previewImage!.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        previewImage!.contentMode = UIViewContentMode.scaleAspectFill
        previewImage!.clipsToBounds = true
        previewImage!.layoutIfNeeded()
        
        titleLabel.font = UIFont.systemFont(ofSize: FontSizes.caption2.rawValue, weight: UIFontWeightBold)
        subtitleLabel.font = UIFont.systemFont(ofSize: FontSizes.caption2.rawValue, weight: UIFontWeightRegular)
    }
    
    fileprivate func setupUserPreview() {
        
        showPreviewImage = true
        
        previewImage = UIImageView()
        if reuseCell {
            deactivateConstraints()
        }

        addSubview(previewImage!)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        
        previewImage!.translatesAutoresizingMaskIntoConstraints = false
        previewImageConstraint1 = previewImage!.topAnchor.constraint(equalTo: contentView.topAnchor, constant : Spacing.m.rawValue)
        previewImageConstraint2 = previewImage!.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue)
        previewImageConstraint3 = previewImage!.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        previewImageConstraint4 = previewImage!.heightAnchor.constraint(equalTo: previewImage!.widthAnchor)
        previewImage!.layoutIfNeeded()
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabelConstraint1 = titleLabel.topAnchor.constraint(equalTo: previewImage!.bottomAnchor, constant: Spacing.s.rawValue)
        titleLabelConstraint2 = titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        titleLabelConstraint3 = titleLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.8)
        titleLabelConstraint4 = titleLabel.heightAnchor.constraint(equalToConstant: Spacing.m.rawValue)
        titleLabel.layoutIfNeeded()
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabelConstraint1 = subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor)
        subtitleLabelConstraint2 = subtitleLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.8)
        subtitleLabelConstraint3 = subtitleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        subtitleLabelConstraint4 = subtitleLabel.heightAnchor.constraint(equalTo: titleLabel.heightAnchor)
        subtitleLabel.layoutIfNeeded()
        
        titleLabel.setFont(FontSizes.title.rawValue, weight: UIFontWeightBold, color: .black, alignment: .center)
        subtitleLabel.setFont(FontSizes.body.rawValue, weight: UIFontWeightRegular, color: .black, alignment: .center)
        subtitleLabel.numberOfLines =  3
        
        previewImage!.contentMode = UIViewContentMode.scaleAspectFill
        activateConstraints()
    }
    
    fileprivate func setupQuestionPreview() {
        
        showPreviewImage = false

        if reuseCell {
            deactivateConstraints()
        }
        
        addSubview(titleLabel)
        addSubview(answerCount)
        addSubview(subtitleLabel)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabelConstraint1 = titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.xs.rawValue)
        titleLabelConstraint2 = titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        titleLabelConstraint3 = titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.xs.rawValue)
        titleLabelConstraint4 = titleLabel.heightAnchor.constraint(equalTo: heightAnchor)

        titleLabel.setFont(FontSizes.title.rawValue, weight: UIFontWeightMedium, color: UIColor.white, alignment: .left)
        titleLabel.layoutIfNeeded()

        answerCount.translatesAutoresizingMaskIntoConstraints = false
        answerCount.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.15).isActive = true
        answerCount.heightAnchor.constraint(equalTo: answerCount.widthAnchor).isActive = true
        answerCount.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.xs.rawValue).isActive = true
        answerCount.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        
        answerCount.titleEdgeInsets = UIEdgeInsetsMake(0, 0, answerCount.frame.height / 4, 0)
        answerCount.titleLabel!.font = UIFont.systemFont(ofSize: FontSizes.caption.rawValue, weight: UIFontWeightHeavy)
        answerCount.titleLabel!.textColor = UIColor.white
        answerCount.titleLabel!.textAlignment = .center
        answerCount.setBackgroundImage(UIImage(named: "count-label"), for: UIControlState())
        answerCount.imageView?.contentMode = .scaleAspectFit
        answerCount.layoutIfNeeded()
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabelConstraint1 = subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.xs.rawValue)
        subtitleLabelConstraint2 = subtitleLabel.centerYAnchor.constraint(equalTo: answerCount.centerYAnchor)
        subtitleLabelConstraint3 = subtitleLabel.trailingAnchor.constraint(equalTo: answerCount.leadingAnchor)
        subtitleLabelConstraint4 = subtitleLabel.heightAnchor.constraint(equalTo: answerCount.heightAnchor)
        
        subtitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightHeavy, color: UIColor.white, alignment: .left)
        subtitleLabel.numberOfLines =  2
        subtitleLabel.lineBreakMode =  .byTruncatingTail
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.minimumScaleFactor = 0.4
        subtitleLabel.layoutIfNeeded()
        
        activateConstraints()
    }
    
    fileprivate func setupTagPreview() {
        showPreviewImage = false
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(answerCount)
        
        if reuseCell {
            deactivateConstraints()
        }
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabelConstraint1 = titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.xs.rawValue)
        titleLabelConstraint2 = titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        titleLabelConstraint3 = titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.xs.rawValue)
        titleLabelConstraint4 = titleLabel.heightAnchor.constraint(equalTo: heightAnchor)
        
        titleLabel.setFont(FontSizes.headline.rawValue, weight: UIFontWeightHeavy, color: UIColor.white, alignment: .left)
        titleLabel.layoutIfNeeded()
        
        answerCount.translatesAutoresizingMaskIntoConstraints = false
        answerCount.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.15).isActive = true
        answerCount.heightAnchor.constraint(equalTo: answerCount.widthAnchor).isActive = true
        answerCount.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.xs.rawValue).isActive = true
        answerCount.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        answerCount.layoutIfNeeded()
        
        answerCount.titleEdgeInsets = UIEdgeInsetsMake(0, 0, answerCount.frame.height / 4, 0)
        answerCount.titleLabel!.font = UIFont.systemFont(ofSize: FontSizes.caption.rawValue, weight: UIFontWeightHeavy)
        answerCount.titleLabel!.textColor = UIColor.white
        answerCount.titleLabel!.textAlignment = .center
        answerCount.setBackgroundImage(UIImage(named: "count-label"), for: UIControlState())
        answerCount.imageView?.contentMode = .scaleAspectFit
        answerCount.layoutIfNeeded()
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        subtitleLabelConstraint1 = subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.xs.rawValue)
        subtitleLabelConstraint2 = subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.xs.rawValue)
        subtitleLabelConstraint3 = subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.xs.rawValue)
        subtitleLabelConstraint4 = subtitleLabel.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.3)
        
        activateConstraints()

        subtitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: UIColor.white, alignment: .left)
        subtitleLabel.numberOfLines = 2
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.minimumScaleFactor = 0.4
        subtitleLabel.layoutIfNeeded()
    }
}
