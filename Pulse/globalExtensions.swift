//
//  globalExtensions.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import UIKit

let iconColor = UIColor( red: 255/255, green: 255/255, blue:255/255, alpha: 1.0 )
let iconBackgroundColor = UIColor( red: 237/255, green: 19/255, blue:90/255, alpha: 1.0 )

// To dismiss keyboard when needed
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}

class LCTextLayer : CATextLayer {
    // USAGE: To fix the vertical alignment issue that currently exists within the CATextLayer class. Change made to the yDiff calculation.
    
    override init() {
        super.init()
    }
    
    override init(layer: AnyObject) {
        super.init(layer: layer)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(layer: aDecoder)
    }
    
    override func drawInContext(ctx: CGContext) {
        let height = self.bounds.size.height
        let fontSize = self.fontSize
        let yDiff = (height-fontSize)/2 - fontSize/10
        
        CGContextSaveGState(ctx)
        CGContextTranslateCTM(ctx, 0.0, yDiff)
        super.drawInContext(ctx)
        CGContextRestoreGState(ctx)
    }
}

extension Double {
    var degreesToRadians : CGFloat {
        return CGFloat(self) * CGFloat(M_PI) / 180.0
    }
}

extension NSTimeInterval {
    var time:String {
        return String(format:"%02d:%02d", Int(self/60.0),  Int(ceil(self%60)) )
    }
}

enum LoadMoreStatus{
    case Loading
    case Finished
    case haveMore
}