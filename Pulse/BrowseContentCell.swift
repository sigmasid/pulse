//
//  AnswerCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/19/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class BrowseContentCell: UICollectionViewCell {
    fileprivate lazy var titleLabel = UILabel()
    fileprivate lazy var subtitleLabel = UILabel()
    fileprivate lazy var previewImage = UIImageView()
    fileprivate lazy var titleStack = PulseMenu(_axis: .vertical, _spacing: 0)
    
    fileprivate lazy var preview : Preview = Preview()
    fileprivate var previewAdded = false
    fileprivate var reuseCell = false
    
    var showTapForMore = false {
        didSet {
            preview.showTapForMore = showTapForMore ? true : false
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        addShadow()
        setupAnswerPreview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        previewImage.image = nil
    }
    
    override func point(inside point : CGPoint, with event : UIEvent?) -> Bool {
        for _view in self.subviews {
            if _view.isUserInteractionEnabled == true && _view.point(inside: convert(point, to: _view) , with: event) {
                return true
            }
        }
        return false
    }
    
    func gestureRecognizer(_ gesture: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer : UIGestureRecognizer) -> Bool {
        return false
    }
    
    func updateLabel(_ _title : String?, _subtitle : String?) {
        if let _title = _title {
            titleLabel.isHidden = false
            titleLabel.text = _title
        } else {
            titleLabel.isHidden = true
            subtitleLabel.numberOfLines = 2
        }
        
        if let _subtitle = _subtitle {
            subtitleLabel.isHidden = false
            subtitleLabel.text = _subtitle
        } else {
            subtitleLabel.isHidden = true
            titleLabel.numberOfLines = 2
        }
        
        titleStack.layoutIfNeeded()
    }
    
    func updateLabel(_ _title : String?, _subtitle : String?, _image : UIImage?) {
        updateLabel(_title, _subtitle: _subtitle)
        previewImage.image = _image
        
        titleStack.layoutIfNeeded()
    }
    
    func updateImage( image : UIImage?) {
        if let image = image {
            previewImage.image = image
            
            previewImage.layer.cornerRadius = 0
            previewImage.layer.masksToBounds = true
            previewImage.clipsToBounds = true
        }
    }
    
    func showItemPreview(item : Item) {
        preview = Preview(frame: contentView.bounds)
        preview.currentItem = item
        previewImage.isHidden = true
        titleStack.isHidden = true
        
        UIView.transition( with: contentView,
                           duration: 0.5,
                           options: .transitionFlipFromLeft,
                           animations: {
                            _ in self.contentView.addSubview(self.preview)
        }, completion: nil)
        previewAdded = true
    }
    
    func removePreview() {
        preview.removeClip()
        preview.removeFromSuperview()
        
        previewImage.isHidden = false
        titleStack.isHidden = false
    }
    
    override func prepareForReuse() {
        if previewAdded {
            removePreview()
        }
        
        titleLabel.text = ""
        subtitleLabel.text = ""
        previewImage.image = nil
        
        previewImage.isHidden = false
        titleStack.isHidden = false
        
        super.prepareForReuse()
    }
    
    public func setNumberOfLines(titleNum : Int, subTitleNum : Int) {
        titleLabel.numberOfLines = titleNum
        subtitleLabel.numberOfLines = subTitleNum
    }
    
    fileprivate func setupAnswerPreview() {
        addSubview(previewImage)
        addSubview(titleStack)
        
        titleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightBold, color: .black, alignment: .left)
        subtitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .black, alignment: .left)
        
        titleLabel.numberOfLines = 1
        subtitleLabel.numberOfLines = 1
        
        titleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.lineBreakMode = .byTruncatingTail
        
        let fontAttributes = [ NSFontAttributeName : UIFont.pulseFont(ofWeight: UIFontWeightBold, size: titleLabel.font.pointSize)]
        let titleLableHeight = GlobalFunctions.getLabelSize(title: "label", width: contentView.frame.width, fontAttributes: fontAttributes)
        
        titleStack.translatesAutoresizingMaskIntoConstraints = false
        titleStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xxs.rawValue).isActive = true
        titleStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        titleStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        titleStack.heightAnchor.constraint(equalToConstant: titleLableHeight * 2).isActive = true
        
        titleStack.addArrangedSubview(titleLabel)
        titleStack.addArrangedSubview(subtitleLabel)
        
        previewImage.translatesAutoresizingMaskIntoConstraints = false
        previewImage.bottomAnchor.constraint(equalTo: titleStack.topAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        previewImage.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        previewImage.widthAnchor.constraint(equalTo: contentView.widthAnchor).isActive = true
        previewImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        
        previewImage.contentMode = UIViewContentMode.scaleAspectFill
        previewImage.clipsToBounds = true
        

    }
}
