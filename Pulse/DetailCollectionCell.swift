//
//  DetailCollectionCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/2/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class DetailCollectionCell: UICollectionViewCell {
    var titleLabel: UILabel!
    var subtitleLabel: UILabel!
    var previewImage : UIImageView!
    
    private var previewVC : PreviewVC?
    private var previewAdded = false
    private var reuseCell = false
    
    var itemType : Item? {
        didSet {
            switch itemType! {
            case .Questions:
                if !reuseCell {
                    setupQuestionPreview()
                    reuseCell = true
                }
            case .Answers:
                if !reuseCell {
                    setupAnswerPreview()
                    reuseCell = true
                }
            case .Tags: return
            default: return
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
        titleLabel?.hidden = true
        UIView.transitionWithView( contentView, duration: 0.5, options: .TransitionFlipFromLeft, animations: { _ in self.contentView.addSubview(self.previewVC!) }, completion: nil)
        previewAdded = true
    }
    
    func showAnswer(_answerID : String) {
        previewVC = PreviewVC(frame: contentView.bounds)
        previewVC!.currentAnswerID = _answerID
        previewImage?.hidden = true
        titleLabel?.hidden = true
        subtitleLabel?.hidden = true
        UIView.transitionWithView( contentView, duration: 0.5, options: .TransitionFlipFromLeft, animations: { _ in self.contentView.addSubview(self.previewVC!) }, completion: nil)
        previewAdded = true
    }
    
    func removeAnswer() {
        if itemType == .Questions {
             titleLabel?.hidden = false
        } else if itemType == .Answers {
            previewImage?.hidden = false
            titleLabel?.hidden = false
            subtitleLabel?.hidden = false
        }
        previewVC?.removeFromSuperview()
    }
    
    override func prepareForReuse() {
        if previewAdded {
            removeAnswer()
        }
    }
    
    func setupAnswerPreview() {
        previewImage = UIImageView()
        addSubview(previewImage)
        
        titleLabel = UILabel()
        titleLabel?.font = UIFont.systemFontOfSize(FontSizes.Caption2.rawValue, weight: UIFontWeightBold)
        addSubview(titleLabel!)
        
        subtitleLabel = UILabel()
        subtitleLabel?.font = UIFont.systemFontOfSize(FontSizes.Caption2.rawValue, weight: UIFontWeightRegular)
        addSubview(subtitleLabel!)
        
        subtitleLabel!.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel?.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: Spacing.xxs.rawValue).active = true
        subtitleLabel?.bottomAnchor.constraintEqualToAnchor(bottomAnchor, constant: -Spacing.xxs.rawValue).active = true
        subtitleLabel?.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        subtitleLabel?.layoutIfNeeded()
        
        titleLabel!.translatesAutoresizingMaskIntoConstraints = false
        titleLabel?.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: Spacing.xxs.rawValue).active = true
        titleLabel?.bottomAnchor.constraintEqualToAnchor(subtitleLabel.topAnchor).active = true
        titleLabel?.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        titleLabel?.layoutIfNeeded()
        
        previewImage.translatesAutoresizingMaskIntoConstraints = false
        previewImage.bottomAnchor.constraintEqualToAnchor(titleLabel.topAnchor, constant: -Spacing.xxs.rawValue).active = true
        previewImage.topAnchor.constraintEqualToAnchor(topAnchor).active = true
        previewImage.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        previewImage.contentMode = UIViewContentMode.ScaleAspectFill
        previewImage.clipsToBounds = true
        previewImage.layoutIfNeeded()

    }
    
    func setupQuestionPreview() {
        titleLabel = UILabel()
        titleLabel?.setPreferredFont(UIColor.whiteColor(), alignment : .Center)
        addSubview(titleLabel!)
        
        titleLabel!.translatesAutoresizingMaskIntoConstraints = false
        titleLabel?.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        titleLabel?.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
        titleLabel?.heightAnchor.constraintEqualToAnchor(heightAnchor).active = true
        titleLabel?.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        titleLabel?.layoutIfNeeded()
    }
}
