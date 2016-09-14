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
    lazy var previewImage = UIImageView()
    lazy var answerCount = UIButton()
    
    private var previewVC : PreviewVC?
    private var previewAdded = false
    private var reuseCell = false
    
    private var titleLabelConstraint1 : NSLayoutConstraint!
    private var titleLabelConstraint2 : NSLayoutConstraint!
    private var titleLabelConstraint3 : NSLayoutConstraint!
    private var titleLabelConstraint4 : NSLayoutConstraint!
    
    private var subtitleLabelConstraint1 : NSLayoutConstraint!
    private var subtitleLabelConstraint2 : NSLayoutConstraint!
    private var subtitleLabelConstraint3 : NSLayoutConstraint!
    private var subtitleLabelConstraint4 : NSLayoutConstraint!

    var itemType : FeedItemType? {
        didSet {
            switch itemType! {
            case .Question:
                setupQuestionPreview()
                reuseCell = true
            case .Answer:
                setupAnswerPreview()
                reuseCell = true
            case .Tag:
                setupTagPreview()
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
    
    func showQuestion(_question : Question) {
        previewVC = PreviewVC(frame: contentView.bounds)
        previewVC?.currentQuestion = _question
        titleLabel.hidden = true
        subtitleLabel.hidden = true

        UIView.transitionWithView( contentView, duration: 0.5, options: .TransitionFlipFromLeft, animations: { _ in self.contentView.addSubview(self.previewVC!) }, completion: nil)
        previewAdded = true
    }
    
    func showAnswer(_answerID : String) {
        previewVC = PreviewVC(frame: contentView.bounds)
        previewVC!.currentAnswerID = _answerID
        previewImage.hidden = true
        titleLabel.hidden = true
        subtitleLabel.hidden = true
        UIView.transitionWithView( contentView, duration: 0.5, options: .TransitionFlipFromLeft, animations: { _ in self.contentView.addSubview(self.previewVC!) }, completion: nil)
        previewAdded = true
    }
    
    func removeAnswer() {
        if itemType == .Question {
            titleLabel.hidden = false
            subtitleLabel.hidden = false
        } else if itemType == .Answer {
            previewImage.hidden = false
            titleLabel.hidden = false
            subtitleLabel.hidden = false
        }
        previewVC?.removeFromSuperview()
    }
    
    override func prepareForReuse() {
        if previewAdded {
            removeAnswer()
        }
    }
    
    private func setupAnswerPreview() {
        addSubview(previewImage)
        
        titleLabel.font = UIFont.systemFontOfSize(FontSizes.Caption2.rawValue, weight: UIFontWeightBold)
        addSubview(titleLabel)
        
        subtitleLabel.font = UIFont.systemFontOfSize(FontSizes.Caption2.rawValue, weight: UIFontWeightRegular)
        addSubview(subtitleLabel)
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: Spacing.xxs.rawValue).active = true
        subtitleLabel.bottomAnchor.constraintEqualToAnchor(bottomAnchor, constant: -Spacing.xxs.rawValue).active = true
        subtitleLabel.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        subtitleLabel.layoutIfNeeded()
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: Spacing.xxs.rawValue).active = true
        titleLabel.bottomAnchor.constraintEqualToAnchor(subtitleLabel.topAnchor).active = true
        titleLabel.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        titleLabel.layoutIfNeeded()
        
        previewImage.translatesAutoresizingMaskIntoConstraints = false
        previewImage.bottomAnchor.constraintEqualToAnchor(titleLabel.topAnchor, constant: -Spacing.xxs.rawValue).active = true
        previewImage.topAnchor.constraintEqualToAnchor(topAnchor).active = true
        previewImage.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        previewImage.contentMode = UIViewContentMode.ScaleAspectFill
        previewImage.clipsToBounds = true
        previewImage.layoutIfNeeded()
    }
    
    private func setupQuestionPreview() {
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        if reuseCell {
            deactivateConstraints()
        }

        titleLabelConstraint1 = titleLabel.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: Spacing.xs.rawValue)
        titleLabelConstraint2 = titleLabel.centerYAnchor.constraintEqualToAnchor(centerYAnchor)
        titleLabelConstraint3 = titleLabel.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: -Spacing.xs.rawValue)
        titleLabelConstraint4 = titleLabel.heightAnchor.constraintEqualToAnchor(heightAnchor)

        titleLabel.setFont(FontSizes.Body.rawValue, weight: UIFontWeightRegular, color: UIColor.whiteColor(), alignment: .Left)
        titleLabel.layoutIfNeeded()
        addSubview(titleLabel)

        addSubview(answerCount)
        answerCount.translatesAutoresizingMaskIntoConstraints = false
        answerCount.widthAnchor.constraintEqualToAnchor(widthAnchor, multiplier: 0.15).active = true
        answerCount.heightAnchor.constraintEqualToAnchor(answerCount.widthAnchor).active = true
        answerCount.topAnchor.constraintEqualToAnchor(topAnchor, constant: Spacing.xs.rawValue).active = true
        answerCount.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: -Spacing.xs.rawValue).active = true
        answerCount.layoutIfNeeded()
        
        answerCount.titleEdgeInsets = UIEdgeInsetsMake(0, 0, answerCount.frame.height / 4, 0)
        answerCount.titleLabel!.font = UIFont.systemFontOfSize(FontSizes.Caption.rawValue, weight: UIFontWeightHeavy)
        answerCount.titleLabel!.textColor = UIColor.whiteColor()
        answerCount.titleLabel!.textAlignment = .Center
        answerCount.setBackgroundImage(UIImage(named: "count-label"), forState: .Normal)
        answerCount.imageView?.contentMode = .ScaleAspectFit
        answerCount.layoutIfNeeded()
        
        addSubview(subtitleLabel)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        subtitleLabelConstraint1 = subtitleLabel.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: Spacing.xs.rawValue)
        subtitleLabelConstraint2 = subtitleLabel.centerYAnchor.constraintEqualToAnchor(answerCount.centerYAnchor)
        subtitleLabelConstraint3 = subtitleLabel.trailingAnchor.constraintEqualToAnchor(answerCount.leadingAnchor)
        subtitleLabelConstraint4 = subtitleLabel.heightAnchor.constraintEqualToAnchor(answerCount.heightAnchor)
        
        activateConstraints()
        
        subtitleLabel.setFont(FontSizes.Caption.rawValue, weight: UIFontWeightHeavy, color: UIColor.whiteColor(), alignment: .Left)
        subtitleLabel.numberOfLines =  2
        subtitleLabel.lineBreakMode =  .ByTruncatingTail
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.minimumScaleFactor = 0.4
        subtitleLabel.layoutIfNeeded()
    }
    
    private func setupTagPreview() {
        addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        if reuseCell {
            deactivateConstraints()
        }
        
        titleLabelConstraint1 = titleLabel.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: Spacing.xs.rawValue)
        titleLabelConstraint2 = titleLabel.centerYAnchor.constraintEqualToAnchor(centerYAnchor, constant: -Spacing.s.rawValue)
        titleLabelConstraint3 = titleLabel.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: -Spacing.xs.rawValue)
        titleLabelConstraint4 = titleLabel.heightAnchor.constraintEqualToAnchor(heightAnchor, multiplier: 0.3)
        
        titleLabel.setFont(FontSizes.Body.rawValue, weight: UIFontWeightHeavy, color: UIColor.whiteColor(), alignment: .Left)
        titleLabel.layoutIfNeeded()
        addSubview(titleLabel)
        
        addSubview(answerCount)
        answerCount.translatesAutoresizingMaskIntoConstraints = false
        answerCount.widthAnchor.constraintEqualToAnchor(widthAnchor, multiplier: 0.15).active = true
        answerCount.heightAnchor.constraintEqualToAnchor(answerCount.widthAnchor).active = true
        answerCount.topAnchor.constraintEqualToAnchor(topAnchor, constant: Spacing.xs.rawValue).active = true
        answerCount.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: -Spacing.xs.rawValue).active = true
        answerCount.layoutIfNeeded()
        
        answerCount.titleEdgeInsets = UIEdgeInsetsMake(0, 0, answerCount.frame.height / 4, 0)
        answerCount.titleLabel!.font = UIFont.systemFontOfSize(FontSizes.Caption.rawValue, weight: UIFontWeightHeavy)
        answerCount.titleLabel!.textColor = UIColor.whiteColor()
        answerCount.titleLabel!.textAlignment = .Center
        answerCount.setBackgroundImage(UIImage(named: "count-label"), forState: .Normal)
        answerCount.imageView?.contentMode = .ScaleAspectFit
        answerCount.layoutIfNeeded()
        
        addSubview(subtitleLabel)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        subtitleLabelConstraint1 = subtitleLabel.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: Spacing.xs.rawValue)
        subtitleLabelConstraint2 = subtitleLabel.topAnchor.constraintEqualToAnchor(titleLabel.bottomAnchor)
        subtitleLabelConstraint3 = subtitleLabel.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: -Spacing.xs.rawValue)
        subtitleLabelConstraint4 = subtitleLabel.heightAnchor.constraintEqualToAnchor(heightAnchor, multiplier: 0.3)
        
        activateConstraints()

        subtitleLabel.setFont(FontSizes.Caption2.rawValue, weight: UIFontWeightRegular, color: UIColor.whiteColor(), alignment: .Left)
        subtitleLabel.numberOfLines =  2
        subtitleLabel.lineBreakMode =  .ByTruncatingTail
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.minimumScaleFactor = 0.4
        subtitleLabel.layoutIfNeeded()
    }
    
    func deactivateConstraints() {
        titleLabelConstraint1.active = false
        titleLabelConstraint2.active = false
        titleLabelConstraint3.active = false
        titleLabelConstraint4.active = false

        subtitleLabelConstraint1.active = false
        subtitleLabelConstraint2.active = false
        subtitleLabelConstraint3.active = false
        subtitleLabelConstraint4.active = false
    }
    
    func activateConstraints() {
        titleLabelConstraint1.active = true
        titleLabelConstraint2.active = true
        titleLabelConstraint3.active = true
        titleLabelConstraint4.active = true
        
        subtitleLabelConstraint1.active = true
        subtitleLabelConstraint2.active = true
        subtitleLabelConstraint3.active = true
        subtitleLabelConstraint4.active = true

    }
    
    func updateLabel(_title : String?, _subtitle : String?) {
//        if let _title = _title {
            titleLabel.text = _title
//        }
//
//        if let _subtitle = _subtitle {
            subtitleLabel.text = _subtitle
//        } else {
//            
//        }
    }
}
