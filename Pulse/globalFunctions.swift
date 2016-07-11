//
//  globalFunctions.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/9/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import UIKit

let iconColor = UIColor( red: 255/255, green: 255/255, blue:255/255, alpha: 1.0 )
let iconBackgroundColor = UIColor( red: 237/255, green: 19/255, blue:90/255, alpha: 1.0 )
let buttonCornerRadius : CGFloat = 20

func addBorders(_textField : UITextField) -> CAShapeLayer {
    let _bottomBorder = CAShapeLayer()
    
    _bottomBorder.frame = CGRectMake(0.0, _textField.frame.size.height - 1, _textField.frame.size.width, 1.0);
    _bottomBorder.backgroundColor = UIColor( red: 191/255, green: 191/255, blue:191/255, alpha: 1.0 ).CGColor
    
    return _bottomBorder
}
