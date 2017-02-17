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
        
        addShadow()
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
        
        answerCount.translatesAutoresizingMaskIntoConstraints = false
        answerCount.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.075).isActive = true
        answerCount.heightAnchor.constraint(equalTo: answerCount.widthAnchor).isActive = true
        answerCount.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        answerCount.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        answerCount.layoutIfNeeded()

        answerCount.titleEdgeInsets = UIEdgeInsetsMake(0, 0, answerCount.frame.height / 4, 0)
        answerCount.titleLabel!.setFont(FontSizes.caption.rawValue, weight: UIFontWeightHeavy, color: .white, alignment: .center)
        answerCount.setBackgroundImage(UIImage(named: "count-label"), for: UIControlState())
        answerCount.imageView?.contentMode = .scaleAspectFit
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: answerCount.trailingAnchor, constant: Spacing.s.rawValue).isActive = true
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.heightAnchor.constraint(equalTo: answerCount.heightAnchor).isActive = true
        subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true
        subtitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.xxs.rawValue).isActive = true
        
        titleLabel.setFont(FontSizes.title.rawValue, weight: UIFontWeightRegular, color: UIColor.black, alignment: .left)
        subtitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightHeavy, color: UIColor.black, alignment: .left)
        
        subtitleLabel.numberOfLines =  2
        subtitleLabel.lineBreakMode =  .byTruncatingTail
        
        subtitleLabel.setNeedsLayout()
        titleLabel.setNeedsLayout()
    }
}
