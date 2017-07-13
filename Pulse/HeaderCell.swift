//
//  HeaderCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/16/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class HeaderCell: UICollectionViewCell, UIScrollViewDelegate {
    fileprivate lazy var titleLabel = UILabel()
    fileprivate lazy var previewButton = PulseButton(size: .medium, type: .blank, isRound: true, background: .white, tint: .clear)
    fileprivate var titleHeightAnchor: NSLayoutConstraint!
    
    public weak var delegate : SelectionDelegate!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        delegate = nil
        previewButton.removeFromSuperview()
        titleLabel.removeFromSuperview()
    }
    
    public func updateTitle(title: String? ) {
        let fontAttributes = [ NSFontAttributeName : UIFont.pulseFont(ofWeight: UIFontWeightThin, size: titleLabel.font.pointSize)]
        let titleLabelHeight = GlobalFunctions.getLabelSize(title: title ?? "", width: titleLabel.frame.width, fontAttributes: fontAttributes)
        titleHeightAnchor.constant = titleLabelHeight
        
        titleLabel.text = title
    }
    
    func updateCell(_ _title : String?, _image : UIImage?) {
        let fontAttributes = [ NSFontAttributeName : UIFont.pulseFont(ofWeight: UIFontWeightThin, size: titleLabel.font.pointSize)]
        let titleLabelHeight = GlobalFunctions.getLabelSize(title: _title ?? "", width: titleLabel.frame.width, fontAttributes: fontAttributes)
        titleHeightAnchor.constant = titleLabelHeight
        
        titleLabel.text = _title
        previewButton.setImage(_image, for: .normal)
    }
    
    func updateImage(image : UIImage?) {
        previewButton.setImage(image, for: .normal)
    }
    
    override func prepareForReuse() {
        titleLabel.text = ""
        previewButton.setImage(nil, for: .normal)
        
        super.prepareForReuse()
    }
    
    internal func clickedSelect() {
        if delegate != nil {
            delegate.userSelected(item: self.tag)
        }
    }
    
    fileprivate func setupCell() {
        addSubview(previewButton)
        addSubview(titleLabel)
        
        previewButton.translatesAutoresizingMaskIntoConstraints = false
        previewButton.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        previewButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        previewButton.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        previewButton.widthAnchor.constraint(equalTo: previewButton.heightAnchor).isActive = true
        previewButton.layoutIfNeeded()
        
        previewButton.imageView?.contentMode = .scaleAspectFill
        previewButton.imageView?.frame = previewButton.bounds
        previewButton.imageView?.clipsToBounds = true
        previewButton.contentMode = .scaleAspectFill
        previewButton.clipsToBounds = true
        
        previewButton.addTarget(self, action: #selector(clickedSelect), for: .touchUpInside)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xxs.rawValue).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        titleLabel.topAnchor.constraint(equalTo: previewButton.bottomAnchor, constant: Spacing.xxs.rawValue).isActive = true
        titleLabel.layoutIfNeeded()
        titleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightThin, color: .black, alignment: .center)
        
        let fontAttributes = [ NSFontAttributeName : UIFont.pulseFont(ofWeight: UIFontWeightThin, size: titleLabel.font.pointSize)]
        let titleLabelHeight = GlobalFunctions.getLabelSize(title: "Very Long Name That Goes Forever", width: titleLabel.frame.width, fontAttributes: fontAttributes)
        titleHeightAnchor = titleLabel.heightAnchor.constraint(equalToConstant: titleLabelHeight)
        titleHeightAnchor.isActive = true
        
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail
    }
}
