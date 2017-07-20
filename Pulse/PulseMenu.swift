//
//  AnswerMenu.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/12/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import UIKit

class PulseMenu: UIStackView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)        
    }
    
    convenience init(_axis : UILayoutConstraintAxis, _spacing: CGFloat ) {
        self.init()
        
        axis = _axis
        spacing = _spacing
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if  isHidden {
            return false
        } else {
            let expandedBounds = bounds.insetBy(dx: -50, dy: -50)
            return expandedBounds.contains(point)
        }
    }

}
