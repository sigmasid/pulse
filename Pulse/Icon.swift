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
    let heartLine = CAShapeLayer()
    let pulseDot = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 6, height: 6))

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    func drawLongIcon(_ color : UIColor, iconThickness : CGFloat) {
        let _flatLine = bounds.width - bounds.height
        _drawIcon(color, iconThickness: iconThickness, flatLine: _flatLine)
    }
    
    func drawLineOnly(_ color : UIColor, iconThickness : CGFloat) {
        let _flatLine = bounds.width - IconSizes.large.rawValue
        let startX = CGFloat(0)
        let startY = frame.height / 2
        
        heartLine.strokeColor = color.cgColor
        heartLine.lineWidth = iconThickness
        
        let heartLineBezier = UIBezierPath()
        heartLineBezier.move(to: CGPoint(x: startX, y: startY))
        heartLineBezier.addLine(to: CGPoint(x: startX + _flatLine, y: startY)) //15

        heartLine.fillColor = UIColor.clear.cgColor
        heartLine.path = heartLineBezier.cgPath
        
        let heartLineStroke = CABasicAnimation(keyPath: "strokeEnd")
        heartLineStroke.fromValue = 0.0
        heartLineStroke.toValue = 1.0
        heartLineStroke.duration = Double(2)
        
        heartLine.add(heartLineStroke, forKey: nil)
        layer.addSublayer(heartLine)
    }
    
    func drawIcon(_ color : UIColor, iconThickness : CGFloat) {
        _drawIcon(color, iconThickness: iconThickness, flatLine: 0)
    }

    fileprivate func _drawIcon(_ color : UIColor, iconThickness : CGFloat, flatLine : CGFloat) {
        let startX = CGFloat(0)
        let startY = frame.height / 2
        let firstXStep = bounds.height / 4  //15, 20,
        let restXStep = frame.height / 12 //12.9
        
        let yStep = startY / 5
        
        heartLine.strokeColor = color.cgColor
        
        let heartLineBezier = UIBezierPath()
        heartLineBezier.move(to: CGPoint(x: startX, y: startY)) // 0
        heartLineBezier.addLine(to: CGPoint(x: startX + flatLine + firstXStep, y: startY)) //15
        heartLineBezier.addLine(to: CGPoint(x: startX + flatLine + firstXStep + 1 * restXStep, y: startY - yStep)) //20
        heartLineBezier.addLine(to: CGPoint(x: startX + flatLine + firstXStep + 2 * restXStep, y: startY)) // 25
        heartLineBezier.addLine(to: CGPoint(x: startX + flatLine + firstXStep + 3 * restXStep, y: startY - yStep * 3)) //30
        heartLineBezier.addLine(to: CGPoint(x: startX + flatLine + firstXStep + 4 * restXStep, y: startY + yStep * 2)) //35
        heartLineBezier.addLine(to: CGPoint(x: startX + flatLine + firstXStep + 5 * restXStep, y: startY - yStep * 2)) //40
        heartLineBezier.addLine(to: CGPoint(x: startX + flatLine + firstXStep + 6 * restXStep, y: startY)) //45
        heartLineBezier.addLine(to: CGPoint(x: startX + flatLine + 2 * firstXStep + 6 * restXStep, y: startY)) //60

        heartLine.lineWidth = iconThickness
        heartLine.fillColor = UIColor.clear.cgColor
        heartLine.path = heartLineBezier.cgPath
        
        pulseDot.layer.cornerRadius = 3
        pulseDot.backgroundColor = UIColor.white
        
        let pulseDotBezier = UIBezierPath()
        pulseDotBezier.move(to: CGPoint(x: startX, y: startY))
        pulseDotBezier.addLine(to: CGPoint(x: startX, y: startY))
        pulseDotBezier.addLine(to: CGPoint(x: startX + flatLine + firstXStep, y: startY))
        pulseDotBezier.addLine(to: CGPoint(x: startX + flatLine + firstXStep + 1 * restXStep, y: startY - yStep))
        pulseDotBezier.addLine(to: CGPoint(x: startX + flatLine + firstXStep + 2 * restXStep, y: startY))
        pulseDotBezier.addLine(to: CGPoint(x: startX + flatLine + firstXStep + 3 * restXStep, y: startY - yStep * 3))
        pulseDotBezier.addLine(to: CGPoint(x: startX + flatLine + firstXStep + 4 * restXStep, y: startY + yStep * 2))
        pulseDotBezier.addLine(to: CGPoint(x: startX + flatLine + firstXStep + 5 * restXStep, y: startY - yStep * 2))
        pulseDotBezier.addLine(to: CGPoint(x: startX + flatLine + firstXStep + 6 * restXStep, y: startY))
        pulseDotBezier.addLine(to: CGPoint(x: startX + flatLine + (firstXStep * 2) + 6 * restXStep, y: startY))
        
        //Animations
        let heartLineOpactiy = CABasicAnimation(keyPath: "opacity")
        heartLineOpactiy.fromValue = 0.5
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
        dotOpacity.isRemovedOnCompletion = false
        dotOpacity.duration = Double(0.5)
        
        let dotMotion = CAKeyframeAnimation(keyPath: "position")
        dotMotion.path = pulseDotBezier.cgPath
        dotMotion.duration = Double(2.05)
        dotMotion.fillMode = kCAFillModeForwards
        dotMotion.isRemovedOnCompletion = false
        dotMotion.repeatCount = FLT_MAX
        
        heartLine.add(heartLineStroke, forKey: nil)
        heartLine.add(heartLineOpactiy, forKey: nil)
        
        pulseDot.layer.add(dotMotion, forKey: nil)
        pulseDot.layer.add(dotOpacity, forKey: nil)
        
        layer.addSublayer(heartLine)
        addSubview(pulseDot)
    }
    
    ///Draw background circle behind logo with parameter color - should be contrasting color
    func drawIconBackground(_ color: UIColor) {
        let circleShape = CAShapeLayer()
        
        if frame.height == frame.width {
            circleShape.path = UIBezierPath(arcCenter: CGPoint(x: frame.midX , y: frame.midY), radius: (frame.height / 2) * 0.9, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).cgPath
        } else {
            circleShape.path = UIBezierPath(arcCenter: CGPoint(x: frame.maxX - (frame.height / 2), y: frame.midY), radius: (frame.height / 2) * 0.9, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).cgPath
        }
        circleShape.fillColor = color.cgColor
        layer.addSublayer(circleShape)
    }
}
