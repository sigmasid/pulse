//
//  CameraOverlayView.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import Foundation

class CameraOverlayView: UIView {

    internal var takeButton : UIButton!
    internal var flipCamera : UIButton!
    internal var questionBackground : UILabel!
    internal var flashMode : CameraFlashMode!
    internal var timeLeftShapeLayer : CAShapeLayer!
    
    /// Property to change camera flash mode.
    internal func flashCamera(mode : CameraFlashMode) -> UIButton! {
        return drawFlashCamera(mode)
    }
    
    /// Property to change camera flash mode.
    internal enum CameraFlashMode: Int {
        case Off, On, Auto
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
        self.takeButton = drawTakeButton()
        self.flipCamera = drawFlipCamera()
        self.questionBackground = drawQuestionBackground()
        self.flashMode = CameraFlashMode.Off
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func drawTakeButton() -> UIButton {
        let cameraButton = UIButton()
        let buttonRadius = frame.size.width/10
        
        cameraButton.frame = CGRectMake(frame.size.width / 2.0 - buttonRadius, frame.size.height - 100 - buttonRadius, buttonRadius * 2, buttonRadius * 2)
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: cameraButton.frame.size.width / 2.0, y: cameraButton.frame.size.height / 2), radius: buttonRadius, startAngle: 0.0, endAngle: CGFloat(M_PI * 2.0), clockwise: true)
        
        // Setup the CAShapeLayer with the path, colors, and line width
        let circleLayer = CAShapeLayer()
        circleLayer.path = circlePath.CGPath
        circleLayer.fillColor = UIColor.whiteColor().CGColor
        circleLayer.strokeColor = UIColor.grayColor().CGColor
        circleLayer.lineWidth = 4.0;
        circleLayer.opacity = 0.75
        
        cameraButton.layer.insertSublayer(circleLayer, atIndex: 0)
        return cameraButton
    }
    
    ///Icon to turn the camera from front to back
    private func drawFlipCamera() -> UIButton {
        let _flipButton = UIButton()
        
        _flipButton.frame = CGRectMake(frame.size.width - 40 , 20, 20, 20)
        _flipButton.setImage(UIImage(named: "cameraFlip"), forState: .Normal)
        
        return _flipButton
    }
    
    ///Adds the stripe for the question
    private func drawQuestionBackground() -> UILabel {
        let _questionBackground = UILabel()
        
        _questionBackground.frame = CGRectMake(0, 120, frame.width, 25)
        _questionBackground.backgroundColor = UIColor.blackColor()
        _questionBackground.alpha = 0.7
        _questionBackground.textColor = UIColor.whiteColor()
        _questionBackground.textAlignment = .Center
        
        return _questionBackground
    }
    
    ///Draws the camera flash icon based on current flash mode
    private func drawFlashCamera(flashMode : CameraFlashMode) -> UIButton {
        let _flashButton = UIButton()
        _flashButton.frame = CGRectMake(20, 20, 20, 20)
        
        switch flashMode {
        case .Off: _flashButton.setImage(UIImage(named: "cameraFlashOff"), forState: .Normal)
        case .On: _flashButton.setImage(UIImage(named: "cameraFlashOn"), forState: .Normal)
        case .Auto: _flashButton.setImage(UIImage(named: "cameraFlashOff"), forState: .Normal)
        }
        return _flashButton
    }
    
    func updateFlashImage(currentButton : UIButton, newFlashMode : CameraFlashMode) {
        switch newFlashMode {
        case .Off: currentButton.setImage(UIImage(named: "cameraFlashOff"), forState: .Normal)
        case .On: currentButton.setImage(UIImage(named: "cameraFlashOn"), forState: .Normal)
        case .Auto: currentButton.setImage(UIImage(named: ""), forState: .Normal)
        }
    }
    
    // Add Video Countdown Animation
    func countdownTimer(videoDuration : Double, size: CGFloat) -> CALayer {
        let cameraOverlay = CALayer()
        cameraOverlay.frame = CGRectMake(30, 80, size, size)
        
        
        // draw the countdown
        let bgShapeLayer = drawBgShape()
        timeLeftShapeLayer = drawTimeLeftShape()
        
        cameraOverlay.addSublayer(bgShapeLayer)
        cameraOverlay.addSublayer(timeLeftShapeLayer)
        
        // animation object to animate the strokeEnd
        let strokeIt = CABasicAnimation(keyPath: "strokeEnd")
        strokeIt.fromValue = 0.0
        strokeIt.toValue = 1.0
        strokeIt.duration = videoDuration
        
        timeLeftShapeLayer.addAnimation(strokeIt, forKey: nil)
        return cameraOverlay
    }
    
    func drawBgShape() -> CAShapeLayer {
        let bgShapeLayer = CAShapeLayer()
        bgShapeLayer.path = UIBezierPath(arcCenter: CGPoint(x: 0 , y: 0), radius:
            15, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).CGPath
        bgShapeLayer.strokeColor = UIColor.whiteColor().CGColor
        bgShapeLayer.fillColor = UIColor.clearColor().CGColor
        bgShapeLayer.opacity = 0.7
        bgShapeLayer.lineWidth = 5
        
        return bgShapeLayer
    }
    
    func drawTimeLeftShape() -> CAShapeLayer {
        let timeLeftShapeLayer = CAShapeLayer()
        timeLeftShapeLayer.path = UIBezierPath(arcCenter: CGPoint(x: 0, y: 0), radius:
            15, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).CGPath
        timeLeftShapeLayer.strokeColor = UIColor.redColor().CGColor
        timeLeftShapeLayer.fillColor = UIColor.clearColor().CGColor
        timeLeftShapeLayer.lineWidth = 5
        timeLeftShapeLayer.opacity = 0.7
        
        return timeLeftShapeLayer
    }
    
    func stopCountdown() {
        timeLeftShapeLayer.removeAllAnimations()
    }
}
