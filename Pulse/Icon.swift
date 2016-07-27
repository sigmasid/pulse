//
//  Icon.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import UIKit

class Icon : UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    func drawLongIcon(color : UIColor, iconThickness : CGFloat) {
        let _flatLine = self.frame.width - self.frame.height
        _drawIcon(color, iconThickness: iconThickness, flatLine: _flatLine)
    }
    
    func drawIcon(color : UIColor, iconThickness : CGFloat) {
        _drawIcon(color, iconThickness: iconThickness, flatLine: 0)
    }
    
    private func _drawIcon(color : UIColor, iconThickness : CGFloat, flatLine : CGFloat) {
        let startX = CGFloat(0)
        let startY = self.frame.height / 2
        
        let firstXStep = flatLine + (self.frame.height / 4)  //15, 20,
        let restXStep = self.frame.height / 12 //12.9
        
        let yStep = startY / 5
        
        let heartLine = CAShapeLayer()
        heartLine.strokeColor = color.CGColor
        
        let heartLineBezier = UIBezierPath()
        heartLineBezier.moveToPoint(CGPoint(x: startX, y: startY)) // 0
        heartLineBezier.addLineToPoint(CGPoint(x: startX + firstXStep, y: startY)) //15
        heartLineBezier.addLineToPoint(CGPoint(x: startX + firstXStep + 1 * restXStep, y: startY - yStep)) //20
        heartLineBezier.addLineToPoint(CGPoint(x: startX + firstXStep + 2 * restXStep, y: startY)) // 25
        heartLineBezier.addLineToPoint(CGPoint(x: startX + firstXStep + 3 * restXStep, y: startY - yStep * 3)) //30
        heartLineBezier.addLineToPoint(CGPoint(x: startX + firstXStep + 4 * restXStep, y: startY + yStep * 2)) //35
        heartLineBezier.addLineToPoint(CGPoint(x: startX + firstXStep + 5 * restXStep, y: startY - yStep * 2)) //40
        heartLineBezier.addLineToPoint(CGPoint(x: startX + firstXStep + 6 * restXStep, y: startY)) //45
        heartLineBezier.addLineToPoint(CGPoint(x: startX + (firstXStep * 2) + 6 * restXStep, y: startY)) //60
        
        heartLine.lineWidth = iconThickness
        heartLine.fillColor = UIColor.clearColor().CGColor
        heartLine.path = heartLineBezier.CGPath
        
        let pulseDot = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 6, height: 6))
        pulseDot.layer.cornerRadius = 3
        pulseDot.backgroundColor = UIColor.whiteColor()
        
        let pulseDotBezier = UIBezierPath()
        pulseDotBezier.moveToPoint(CGPoint(x: startX, y: startY))
        pulseDotBezier.addLineToPoint(CGPoint(x: startX, y: startY))
        pulseDotBezier.addLineToPoint(CGPoint(x: startX + firstXStep, y: startY))
        pulseDotBezier.addLineToPoint(CGPoint(x: startX + firstXStep + 1 * restXStep, y: startY - yStep))
        pulseDotBezier.addLineToPoint(CGPoint(x: startX + firstXStep + 2 * restXStep, y: startY))
        pulseDotBezier.addLineToPoint(CGPoint(x: startX + firstXStep + 3 * restXStep, y: startY - yStep * 3))
        pulseDotBezier.addLineToPoint(CGPoint(x: startX + firstXStep + 4 * restXStep, y: startY + yStep * 2))
        pulseDotBezier.addLineToPoint(CGPoint(x: startX + firstXStep + 5 * restXStep, y: startY - yStep * 2))
        pulseDotBezier.addLineToPoint(CGPoint(x: startX + firstXStep + 6 * restXStep, y: startY))
        pulseDotBezier.addLineToPoint(CGPoint(x: startX + (firstXStep * 2) + 6 * restXStep, y: startY))
        
        //Animations
        
        let heartLineOpactiy = CABasicAnimation(keyPath: "opacity")
        heartLineOpactiy.fromValue = 0.6
        heartLineOpactiy.toValue = 1.0
        heartLineOpactiy.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        heartLineOpactiy.autoreverses = true
        heartLineOpactiy.repeatCount = FLT_MAX
        heartLineOpactiy.duration = Double(0.75)
        
        let heartLineStroke = CABasicAnimation(keyPath: "strokeEnd")
        heartLineStroke.fromValue = 0.0
        heartLineStroke.toValue = 1.0
        heartLineStroke.duration = Double(2)
        
        let dotOpacity = CABasicAnimation(keyPath: "opacity")
        dotOpacity.fromValue = 0.3
        dotOpacity.toValue = 1.0
        dotOpacity.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        dotOpacity.repeatCount = FLT_MAX
        dotOpacity.removedOnCompletion = false
        dotOpacity.duration = Double(0.5)
        
        let dotMotion = CAKeyframeAnimation(keyPath: "position")
        dotMotion.path = pulseDotBezier.CGPath
        dotMotion.duration = Double(2.05)
        dotMotion.fillMode = kCAFillModeForwards
        dotMotion.removedOnCompletion = false
        dotMotion.repeatCount = FLT_MAX
        
        heartLine.addAnimation(heartLineStroke, forKey: nil)
        heartLine.addAnimation(heartLineOpactiy, forKey: nil)
        
        pulseDot.layer.addAnimation(dotMotion, forKey: nil)
        pulseDot.layer.addAnimation(dotOpacity, forKey: nil)
        
        layer.addSublayer(heartLine)
        addSubview(pulseDot)
    }
    
    ///Draw background circle behind logo with parameter color - should be contrasting color
    func drawIconBackground(color: UIColor) {
        let circleShape = CAShapeLayer()
        
        if frame.height == frame.width {
            circleShape.path = UIBezierPath(arcCenter: CGPoint(x: frame.midX , y: frame.midY), radius: (frame.height / 2) * 0.9, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).CGPath
        } else {
            circleShape.path = UIBezierPath(arcCenter: CGPoint(x: frame.maxX - (frame.height / 2), y: frame.midY), radius: (frame.height / 2) * 0.9, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).CGPath
        }
        circleShape.fillColor = color.CGColor
        layer.addSublayer(circleShape)
    }
}