//
//  FeedAnswerCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 12/8/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class FeedAnswerCell: UICollectionViewCell, previewDelegate {
    var delegate : previewDelegate!
    
    fileprivate lazy var titleLabel = UILabel()
    fileprivate lazy var subtitleLabel = UILabel()
    fileprivate lazy var previewImage = UIImageView()
    fileprivate lazy var titleStack = PulseMenu(_axis: .vertical, _spacing: 0)
    
    fileprivate lazy var previewVC : PreviewVC = PreviewVC()
    fileprivate var previewAdded = false
    fileprivate var reuseCell = false
    
    //Delegate PreviewVC var - if user watches full preview then go to index 1 vs. index 0 in full screen
    var watchedFullPreview: Bool = false {
        didSet {
            if delegate != nil {
                delegate.watchedFullPreview = watchedFullPreview
            }
        }
    }

    var showTapForMore = false {
        didSet {
            previewVC.showTapForMore = showTapForMore ? true : false
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupAnswerPreview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateLabel(_ _title : String?, _subtitle : String?) {
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
    
    func showAnswer(answer : Answer) {
        previewVC = PreviewVC(frame: contentView.bounds)
        previewVC.delegate = self
        previewVC.currentAnswer = answer
        previewImage.isHidden = true
        
        UIView.transition( with: contentView,
                           duration: 0.5,
                           options: .transitionFlipFromLeft,
                           animations: {
                                _ in self.contentView.addSubview(self.previewVC)
                            }, completion: nil)
        previewAdded = true
    }
    
    func removeAnswer() {        
        previewVC.removeClip()
        previewVC.removeFromSuperview()
    }
    
    override func prepareForReuse() {
        if previewAdded {
            removeAnswer()
        }
        
        titleLabel.text = ""
        subtitleLabel.text = ""
        previewImage.image = nil
        
        previewImage.isHidden = false
        titleLabel.isHidden = false
        subtitleLabel.isHidden = false
        
        super.prepareForReuse()
    }
    
    fileprivate func setupAnswerPreview() {
        addSubview(previewImage)
        addSubview(titleStack)

        previewImage.translatesAutoresizingMaskIntoConstraints = false
        previewImage.heightAnchor.constraint(equalTo: contentView.heightAnchor).isActive = true
        previewImage.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        previewImage.widthAnchor.constraint(equalTo: contentView.widthAnchor).isActive = true
        previewImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        
        titleStack.translatesAutoresizingMaskIntoConstraints = false
        titleStack.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.125).isActive = true
        titleStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xxs.rawValue).isActive = true
        titleStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        titleStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        
        titleStack.addArrangedSubview(titleLabel)
        titleStack.addArrangedSubview(subtitleLabel)
        
        previewImage.contentMode = UIViewContentMode.scaleAspectFill
        previewImage.clipsToBounds = true
        
        titleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightBold, color: .white, alignment: .left)
        subtitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .white, alignment: .left)
        
        titleLabel.setBlurredBackground()
        subtitleLabel.setBlurredBackground()

    }
}
