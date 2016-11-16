//
//  AnswerMenu.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/12/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AnswerMenu: UIStackView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupMenu()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(frame: CGRect, buttons : [PulseButton]) {
        self.init(frame: frame)
        
        addButtons(buttons: buttons)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if  isHidden {
            return false
        } else {
            let expandedBounds = bounds.insetBy(dx: -50, dy: -50)
            return expandedBounds.contains(point)
        }
    }
    
    public func addButtons(buttons : [PulseButton]) {
        for button in buttons {
            addArrangedSubview(button)
        }
    }
    
    fileprivate func setupMenu() {
        axis = .vertical
        alignment = .fill
        distribution = .fill
        spacing = Spacing.s.rawValue
    }
}
