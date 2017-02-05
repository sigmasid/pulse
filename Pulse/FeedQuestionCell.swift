//
//  FeedQuestionCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 12/12/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class FeedQuestionCell: PulseCell {
    fileprivate lazy var titleLabel = UILabel()
    fileprivate lazy var subtitleLabel = UILabel()
    lazy var answerCount = UIButton()

    fileprivate var reuseCell = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupQuestionPreview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateLabel(_ _title : String?, _subtitle : String?) {
        self.titleLabel.text = _title
        self.subtitleLabel.text = _subtitle
    }
    
    override func prepareForReuse() {
        titleLabel.text = ""
        subtitleLabel.text = ""
        answerCount.setTitle("", for: UIControlState())
        
        super.prepareForReuse()
    }
    
    fileprivate func setupQuestionPreview() {
        
        addSubview(titleLabel)
        addSubview(answerCount)
        addSubview(subtitleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.heightAnchor.constraint(equalTo: titleLabel.heightAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        
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
        subtitleLabel.heightAnchor.constraint(equalTo: answerCount.heightAnchor).isActive = true
        subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        subtitleLabel.centerYAnchor.constraint(equalTo: answerCount.centerYAnchor).isActive = true
        subtitleLabel.trailingAnchor.constraint(equalTo: answerCount.leadingAnchor).isActive = true
        
        titleLabel.setFont(FontSizes.title.rawValue, weight: UIFontWeightRegular, color: UIColor.white, alignment: .left)
        subtitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightHeavy, color: UIColor.white, alignment: .left)
        
        subtitleLabel.numberOfLines =  2
        subtitleLabel.lineBreakMode =  .byTruncatingTail
        
        answerCount.setNeedsLayout()
        subtitleLabel.setNeedsLayout()
        titleLabel.setNeedsLayout()
    }
}
