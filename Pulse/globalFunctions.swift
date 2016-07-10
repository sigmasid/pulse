//
//  globalFunctions.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/9/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import UIKit

func addBorders(_textField : UITextField) -> CAShapeLayer {
    let _bottomBorder = CAShapeLayer()
    
    _bottomBorder.frame = CGRectMake(0.0, _textField.frame.size.height - 1, _textField.frame.size.width, 1.0);
    _bottomBorder.backgroundColor = UIColor( red: 191/255, green: 191/255, blue:191/255, alpha: 1.0 ).CGColor
    
    return _bottomBorder
}
