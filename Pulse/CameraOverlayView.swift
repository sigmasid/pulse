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
    private var _countdownTimer = UILabel()
    
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
    private var _elementOpacity : Float = 0.7
    private var _countdownTimerRadius : CGFloat = 10
    private var _countdownTimerRadiusStroke : CGFloat = 3
    
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
        self.drawQuestionBackground()
        self.drawFlashCamera()
        self.drawFlipCamera()

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
    func countdownTimer(videoDuration : Double) {
        // draw the countdown
        let bgShapeLayer = drawBgShape()
        timeLeftShapeLayer = drawTimeLeftShape()
        
        _countdownTimer.layer.addSublayer(bgShapeLayer)
        _countdownTimer.layer.addSublayer(timeLeftShapeLayer)
        
        // animation object to animate the strokeEnd
        let strokeIt = CABasicAnimation(keyPath: "strokeEnd")
        strokeIt.fromValue = 0.0
        strokeIt.toValue = 1.0
        strokeIt.duration = videoDuration
        
        timeLeftShapeLayer.addAnimation(strokeIt, forKey: nil)
        self.addSubview(_countdownTimer)
        
        _countdownTimer.translatesAutoresizingMaskIntoConstraints = false
        
        _countdownTimer.topAnchor.constraintEqualToAnchor(_questionBackground.bottomAnchor, constant: _elementSpacing + _countdownTimerRadius).active = true
        _countdownTimer.widthAnchor.constraintEqualToConstant(_countdownTimerRadius * 2 + _countdownTimerRadiusStroke).active = true
        _countdownTimer.leadingAnchor.constraintEqualToAnchor(self.leadingAnchor, constant: _elementSpacing + _countdownTimerRadius).active = true
        _countdownTimer.heightAnchor.constraintEqualToConstant(_countdownTimerRadius * 2 + _countdownTimerRadiusStroke).active = true
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
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: _shutterButtonRadius, y: _shutterButtonRadius), radius: _shutterButtonRadius, startAngle: 0.0, endAngle: CGFloat(M_PI * 2.0), clockwise: true)
        
        // Setup the CAShapeLayer with the path, colors, and line width
        let circleLayer = CAShapeLayer()
        circleLayer.frame = CGRectMake(0,0,_shutterButtonRadius * 2,_shutterButtonRadius * 2)
        circleLayer.path = circlePath.CGPath
        circleLayer.fillColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.3 ).CGColor
        circleLayer.strokeColor = UIColor.whiteColor().CGColor
        circleLayer.lineWidth = 4.0
        
        _shutterButton.layer.insertSublayer(circleLayer, atIndex: 0)
        _shutterButton.alpha = CGFloat(_elementOpacity)
        self.addSubview(_shutterButton)
        
        _shutterButton.translatesAutoresizingMaskIntoConstraints = false
        
        _shutterButton.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor, constant: -100).active = true
        _shutterButton.widthAnchor.constraintEqualToConstant(_shutterButtonRadius * 2).active = true
        _shutterButton.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor).active = true
        _shutterButton.heightAnchor.constraintEqualToConstant(_shutterButtonRadius * 2).active = true
        
    }
    
    ///Draws the camera flash icon frame
    private func drawFlashCamera() {
       self.addSubview(_flashModeButton)
        _flashModeButton.alpha = 0.7
        
        _flashModeButton.translatesAutoresizingMaskIntoConstraints = false
        
        _flashModeButton.topAnchor.constraintEqualToAnchor(_questionBackground.bottomAnchor, constant: _elementSpacing).active = true
        _flashModeButton.widthAnchor.constraintEqualToConstant(_iconSize).active = true
        _flashModeButton.trailingAnchor.constraintEqualToAnchor(self.trailingAnchor, constant: -_elementSpacing).active = true
        _flashModeButton.heightAnchor.constraintEqualToConstant(_iconSize).active = true
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
        self.addSubview(_flipCameraButton)
        
        _flipCameraButton.setImage(UIImage(named: "flip-camera"), forState: .Normal)
        _flipCameraButton.alpha = CGFloat(_elementOpacity)
        
        _flipCameraButton.translatesAutoresizingMaskIntoConstraints = false
        
        _flipCameraButton.topAnchor.constraintEqualToAnchor(_flashModeButton.bottomAnchor, constant: _elementSpacing).active = true
        _flipCameraButton.widthAnchor.constraintEqualToConstant(_iconSize).active = true
        _flipCameraButton.trailingAnchor.constraintEqualToAnchor(self.trailingAnchor, constant: -_elementSpacing).active = true
        _flipCameraButton.heightAnchor.constraintEqualToConstant(_iconSize).active = true
    }
    
    ///Adds the stripe for the question
    private func drawQuestionBackground() {
        self.addSubview(_questionBackground)
        _questionBackground.translatesAutoresizingMaskIntoConstraints = false
        
        _questionBackground.topAnchor.constraintEqualToAnchor(self.topAnchor, constant: 0.0).active = true
        _questionBackground.widthAnchor.constraintEqualToAnchor(self.widthAnchor, multiplier: 1.0).active = true
        _questionBackground.leadingAnchor.constraintEqualToAnchor(self.leadingAnchor, constant: 0.0).active = true
        _questionBackground.heightAnchor.constraintEqualToConstant(_questionBackgroundHeight).active = true
        
        _questionBackground.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        _questionBackground.textColor = UIColor.whiteColor()
        _questionBackground.textAlignment = .Center
        _questionBackground.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        _questionBackground.sizeToFit()
    }
    
    private func drawBgShape() -> CAShapeLayer {
        let bgShapeLayer = CAShapeLayer()
        bgShapeLayer.path = UIBezierPath(arcCenter: CGPoint(x: 0 , y: 0), radius: _countdownTimerRadius, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).CGPath
        bgShapeLayer.strokeColor = UIColor.whiteColor().CGColor
        bgShapeLayer.fillColor = UIColor.clearColor().CGColor
        bgShapeLayer.opacity = _elementOpacity
        bgShapeLayer.lineWidth = _countdownTimerRadiusStroke
        
        return bgShapeLayer
    }
    
    private func drawTimeLeftShape() -> CAShapeLayer {
        let timeLeftShapeLayer = CAShapeLayer()
        timeLeftShapeLayer.path = UIBezierPath(arcCenter: CGPoint(x: 0, y: 0), radius: _countdownTimerRadius, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).CGPath
        timeLeftShapeLayer.strokeColor = UIColor.redColor().CGColor
        timeLeftShapeLayer.fillColor = UIColor.clearColor().CGColor
        timeLeftShapeLayer.lineWidth = _countdownTimerRadiusStroke
        timeLeftShapeLayer.opacity = _elementOpacity
        
        return timeLeftShapeLayer
    }

}
