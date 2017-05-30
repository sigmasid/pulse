//
//  EmptyCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/10/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class EmptyCell: UICollectionViewCell {
    
    var loadingView : LoadingView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        setupCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    internal func setupCell() {
        loadingView = LoadingView(frame: contentView.frame, backgroundColor: .clear)
        addSubview(loadingView!)        
    }
    
    public func setMessage(message : String, color: UIColor) {
        loadingView.addMessage(message, _color: color)
    }
}
