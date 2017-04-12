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
    
    fileprivate lazy var previewVC : Preview = Preview()
    fileprivate var reuseCell = false
    
    public var delegate : SelectionDelegate!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateCell(_ _title : String?, _image : UIImage?) {
        titleLabel.text = _title
        previewButton.setImage(_image, for: .normal)
    }
    
    func updateImage( image : UIImage?) {
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
        
        previewButton.addTarget(self, action: #selector(clickedSelect), for: .touchUpInside)

        previewButton.contentMode = .scaleAspectFill
        previewButton.clipsToBounds = true
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.centerXAnchor.constraint(equalTo: previewButton.centerXAnchor).isActive = true
        titleLabel.widthAnchor.constraint(equalTo: previewButton.widthAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: previewButton.bottomAnchor, constant: Spacing.xxs.rawValue).isActive = true
        titleLabel.layoutIfNeeded()
        titleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightThin, color: .black, alignment: .center)

        let fontAttributes = [ NSFontAttributeName : UIFont.systemFont(ofSize: titleLabel.font.pointSize, weight: UIFontWeightThin)]
        let titleLabelHeight = GlobalFunctions.getLabelSize(title: "Very Long Name", width: titleLabel.frame.width, fontAttributes: fontAttributes)
        titleLabel.heightAnchor.constraint(equalToConstant: titleLabelHeight).isActive = true
        
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byTruncatingTail
    }
}
