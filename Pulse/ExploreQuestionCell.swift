//
//  ExploreQuestionCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/30/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class ExploreQuestionCell: UICollectionViewCell {
    
    @IBOutlet weak var qTitle: UILabel!
    private var saveIcon : Save?
    
    func toggleSaveIcon(mode : SaveType) {
        saveIcon = Save(frame: CGRectMake(0, 0, IconSizes.XSmall.rawValue / 2, IconSizes.XSmall.rawValue / 2))
        saveIcon?.toggle(mode)
        addSubview(saveIcon!)

        saveIcon!.translatesAutoresizingMaskIntoConstraints = false
        saveIcon!.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: -Spacing.s.rawValue).active = true
        saveIcon!.topAnchor.constraintEqualToAnchor(topAnchor, constant: Spacing.xs.rawValue).active = true
        saveIcon?.layoutIfNeeded()
    }
    
    
    func keepSaveHidden() {
        if saveIcon != nil {
            saveIcon!.removeFromSuperview()
        }
    }
}
