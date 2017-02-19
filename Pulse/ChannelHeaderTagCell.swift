//
//  ChannelHeaderTagCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/18/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ChannelHeaderTagCell: UICollectionViewCell {
    fileprivate lazy var titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 232/255, green: 249/255, blue: 254/255, alpha: 1.0)
        setupCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateCell(title : String?) {
        if let title = title {
            titleLabel.text = "# \(title)"
        }
    }
    
    override func prepareForReuse() {
        titleLabel.text = ""
        super.prepareForReuse()
    }
    
    fileprivate func setupCell() {
        titleLabel.frame = contentView.frame
        addSubview(titleLabel)
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .black, alignment: .center)
    }

}
