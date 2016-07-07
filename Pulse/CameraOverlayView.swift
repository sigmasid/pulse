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

    private var _shutterButton = UIButton()
    private var _flipCameraButton = UIButton()
    private var _flashModeButton = UIButton()
    private var _questionBackground = UILabel()
    
    var _flashMode : CameraFlashMode! {
        didSet {
            updateFlashMode(_flashMode)
        }
    }
    
    private var timeLeftShapeLayer : CAShapeLayer!
    private var _questionBackgroundHeight : CGFloat = 40
    private var _shutterButtonRadius : CGFloat!
    private var _iconSize : CGFloat = 20
    private var _elementSpacing : CGFloat = 20
    
    /// Property to change camera flash mode.
    internal enum CameraFlashMode: Int {
        case Off, On, Auto
    }
    
    internal enum CameraButtonSelector: Int {
        case Shutter, Flash, Flip
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        self._shutterButtonRadius = frame.size.width / 11
        self.drawShutterButton()
        self.drawFlipCamera()
        self.drawQuestionBackground()
        self.drawFlashCamera()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /* PUBLIC ACCESSIBLE FUNCTIONS */
    
    ///Update question text
    func updateQuestion(question : String) {
        _questionBackground.text = question
    }
    
    
    func stopCountdown() {
        timeLeftShapeLayer.removeAllAnimations()
    }
    
    // Add Video Countdown Animation
    func countdownTimer(videoDuration : Double, size: CGFloat) -> CALayer {
        let cameraOverlay = CALayer()
        cameraOverlay.frame = CGRectMake(_elementSpacing, _questionBackgroundHeight + _elementSpacing, size, size)
        
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
    
    func getButton(buttonName : CameraButtonSelector) -> UIButton {
        switch buttonName {
        case .Flash: return _flashModeButton
        case .Flip: return _flipCameraButton
        case .Shutter: return _shutterButton
        }
    }
    
    /* PRIVATE FUNCTIONS */
    ///Draws the camera shutter button
    private func drawShutterButton() {
        _shutterButton.frame = CGRectMake(frame.midX - _shutterButtonRadius, frame.maxY - 100 - _shutterButtonRadius, _shutterButtonRadius * 2, _shutterButtonRadius * 2)
        print("shutter button radius \(_shutterButtonRadius) and shutter button frame is \(_shutterButton.frame)")
        
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: _shutterButtonRadius, y: _shutterButtonRadius), radius: _shutterButtonRadius, startAngle: 0.0, endAngle: CGFloat(M_PI * 2.0), clockwise: true)
        
        // Setup the CAShapeLayer with the path, colors, and line width
        let circleLayer = CAShapeLayer()
        circleLayer.frame = CGRectMake(0,0,_shutterButton.frame.width,_shutterButton.frame.height)
        circleLayer.path = circlePath.CGPath
        circleLayer.fillColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.3 ).CGColor
        circleLayer.strokeColor = UIColor.whiteColor().CGColor
        circleLayer.lineWidth = 4.0
        
        _shutterButton.layer.insertSublayer(circleLayer, atIndex: 0)
        _shutterButton.alpha = 0.7
        self.addSubview(_shutterButton)
        
    }
    
    ///Draws the camera flash icon frame
    private func drawFlashCamera() {
        _flashModeButton.frame = CGRectMake(frame.size.width - _iconSize - _elementSpacing , _questionBackgroundHeight + _elementSpacing, _iconSize, _iconSize)
        _flashModeButton.alpha = 0.7
        self.addSubview(_flashModeButton)
    }
    
    ///Adds the image for camera based on current mode
    private func updateFlashMode(newFlashMode : CameraFlashMode) {
        switch newFlashMode {
        case .Off: _flashModeButton.setImage(UIImage(named: "flash-off"), forState: .Normal)
        case .On: _flashModeButton.setImage(UIImage(named: "flash-on"), forState: .Normal)
        case .Auto: _flashModeButton.setImage(UIImage(named: "flash-auto"), forState: .Normal)
        }
    }
    
    ///Icon to turn the camera from front to back
    private func drawFlipCamera() {
        _flipCameraButton.frame = CGRectMake(frame.size.width - _iconSize - _elementSpacing , _questionBackgroundHeight + _elementSpacing + _iconSize + _elementSpacing, _iconSize, _iconSize)
        
        _flipCameraButton.setImage(UIImage(named: "flip-camera"), forState: .Normal)
        _flipCameraButton.alpha = 0.7
        self.addSubview(_flipCameraButton)
    }
    
    ///Adds the stripe for the question
    private func drawQuestionBackground() {        
        _questionBackground.frame = CGRectMake(0, 0, frame.width, _questionBackgroundHeight)
        _questionBackground.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        _questionBackground.textColor = UIColor.whiteColor()
        _questionBackground.textAlignment = .Center
        
        self.addSubview(_questionBackground)
    }
    
    private func drawBgShape() -> CAShapeLayer {
        let bgShapeLayer = CAShapeLayer()
        bgShapeLayer.path = UIBezierPath(arcCenter: CGPoint(x: 0 , y: 0), radius:
            15, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).CGPath
        bgShapeLayer.strokeColor = UIColor.whiteColor().CGColor
        bgShapeLayer.fillColor = UIColor.clearColor().CGColor
        bgShapeLayer.opacity = 0.7
        bgShapeLayer.lineWidth = 5
        
        return bgShapeLayer
    }
    
    private func drawTimeLeftShape() -> CAShapeLayer {
        let timeLeftShapeLayer = CAShapeLayer()
        timeLeftShapeLayer.path = UIBezierPath(arcCenter: CGPoint(x: 0, y: 0), radius:
            15, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).CGPath
        timeLeftShapeLayer.strokeColor = UIColor.redColor().CGColor
        timeLeftShapeLayer.fillColor = UIColor.clearColor().CGColor
        timeLeftShapeLayer.lineWidth = 5
        timeLeftShapeLayer.opacity = 0.7
        
        return timeLeftShapeLayer
    }

}
