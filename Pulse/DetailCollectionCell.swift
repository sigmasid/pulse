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
    
    fileprivate var previewVC : PreviewVC?
    fileprivate var previewAdded = false
    fileprivate var reuseCell = false
    
    var feedItemType : FeedItemType? {
        didSet {
            switch feedItemType! {
            case .question:
                if !reuseCell {
                    setupQuestionPreview()
                    reuseCell = true
                }
            case .answer:
                if !reuseCell {
                    setupAnswerPreview()
                    reuseCell = true
                }
            case .tag: return
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
        titleLabel?.isHidden = true
        UIView.transition( with: contentView, duration: 0.5, options: .transitionFlipFromLeft, animations: { _ in self.contentView.addSubview(self.previewVC!) }, completion: nil)
        previewAdded = true
    }
    
    func showAnswer(_ _answerID : String) {
        previewVC = PreviewVC(frame: contentView.bounds)
        previewVC!.currentAnswerID = _answerID
        previewImage?.isHidden = true
        titleLabel?.isHidden = true
        subtitleLabel?.isHidden = true
        UIView.transition( with: contentView, duration: 0.5, options: .transitionFlipFromLeft, animations: { _ in self.contentView.addSubview(self.previewVC!) }, completion: nil)
        previewAdded = true
    }
    
    func removeAnswer() {
        if feedItemType == .question {
             titleLabel?.isHidden = false
        } else if feedItemType == .answer {
            previewImage?.isHidden = false
            titleLabel?.isHidden = false
            subtitleLabel?.isHidden = false
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
        titleLabel?.font = UIFont.systemFont(ofSize: FontSizes.caption2.rawValue, weight: UIFontWeightBold)
        addSubview(titleLabel!)
        
        subtitleLabel = UILabel()
        subtitleLabel?.font = UIFont.systemFont(ofSize: FontSizes.caption2.rawValue, weight: UIFontWeightRegular)
        addSubview(subtitleLabel!)
        
        subtitleLabel!.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel?.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.xxs.rawValue).isActive = true
        subtitleLabel?.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        subtitleLabel?.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        subtitleLabel?.layoutIfNeeded()
        
        titleLabel!.translatesAutoresizingMaskIntoConstraints = false
        titleLabel?.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.xxs.rawValue).isActive = true
        titleLabel?.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor).isActive = true
        titleLabel?.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        titleLabel?.layoutIfNeeded()
        
        previewImage.translatesAutoresizingMaskIntoConstraints = false
        previewImage.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        previewImage.topAnchor.constraint(equalTo: topAnchor).isActive = true
        previewImage.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        previewImage.contentMode = UIViewContentMode.scaleAspectFill
        previewImage.clipsToBounds = true
        previewImage.layoutIfNeeded()

    }
    
    func setupQuestionPreview() {
        titleLabel = UILabel()
        titleLabel?.setPreferredFont(UIColor.white, alignment : .center)
        addSubview(titleLabel!)
        
        titleLabel!.translatesAutoresizingMaskIntoConstraints = false
        titleLabel?.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        titleLabel?.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        titleLabel?.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        titleLabel?.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        titleLabel?.layoutIfNeeded()
    }
}
