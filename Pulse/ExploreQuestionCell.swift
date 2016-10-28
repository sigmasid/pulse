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
    var saveIcon : Save?
    
    func toggleSaveIcon(_ mode : SaveType) {
        saveIcon = Save(frame: CGRect(x: 0, y: 0, width: IconSizes.xSmall.rawValue / 2, height: IconSizes.xSmall.rawValue / 2))
        saveIcon?.toggle(mode)
        addSubview(saveIcon!)

        saveIcon!.translatesAutoresizingMaskIntoConstraints = false
        saveIcon!.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        saveIcon!.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.xs.rawValue).isActive = true
        saveIcon?.layoutIfNeeded()
    }
    
    
    func keepSaveHidden() {
        if saveIcon != nil {
            saveIcon!.removeFromSuperview()
        }
    }
}
