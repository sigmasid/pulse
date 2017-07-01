//
//  HandlerView.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/27/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import Foundation
import UIKit

class HandlerView: UIView {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitFrame = bounds.insetBy(dx: -20, dy: -20)
        return hitFrame.contains(point) ? self : nil
    }
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let hitFrame = bounds.insetBy(dx: -20, dy: -20)
        return hitFrame.contains(point)
    }
}
