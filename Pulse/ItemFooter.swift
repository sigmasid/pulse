//
//  ItemFooter.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/2/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ItemFooter: UICollectionReusableView {
    lazy var seeMore = PulseButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupFooter()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func userClickedSeeMore() {

    }
    
    fileprivate func setupFooter() {
        addSubview(seeMore)
        seeMore.addTarget(self, action: #selector(userClickedSeeMore), for: .touchUpInside)
        seeMore.frame = frame
        seeMore.setTitle("See More", for: .normal)
        seeMore.setButtonFont(FontSizes.caption.rawValue, weight: UIFontWeightBold, color: .white, alignment: .center)
        seeMore.removeShadow()
    }
}
