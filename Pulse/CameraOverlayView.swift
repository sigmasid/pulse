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

    fileprivate var _shutterButton = UIButton()
    fileprivate var _flipCameraButton = UIButton()
    fileprivate var _flashModeButton = UIButton()
    fileprivate var _questionBackground = UILabel()
    fileprivate var _countdownTimer = UILabel()
    fileprivate var _showAlbumPicker = UIButton()
    
    var _flashMode : CameraFlashMode! {
        didSet {
            updateFlashMode(_flashMode)
        }
    }
    
    fileprivate var timeLeftShapeLayer : CAShapeLayer!
    fileprivate var _questionBackgroundHeight : CGFloat = 40
    fileprivate var _shutterButtonRadius : CGFloat!
    fileprivate var _iconSize : CGFloat = IconSizes.xSmall.rawValue
    fileprivate var _elementSpacing : CGFloat = Spacing.s.rawValue
    fileprivate var _elementOpacity : Float = 0.7
    fileprivate var _countdownTimerRadius : CGFloat = 10
    fileprivate var _countdownTimerRadiusStroke : CGFloat = IconThickness.thick.rawValue
    
    /// Property to change camera flash mode.
    internal enum CameraFlashMode: Int {
        case off, on, auto
    }
    
    internal enum CameraButtonSelector: Int {
        case shutter, flash, flip, album
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        _shutterButtonRadius = frame.size.width / 11
        drawAlbumPicker()
        drawShutterButton()
        drawQuestionBackground()
        drawFlashCamera()
        drawFlipCamera()

    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /* PUBLIC ACCESSIBLE FUNCTIONS */
    
    ///Update question text
    public func updateTitle(_ title : String?) {
        _questionBackground.text = title
    }
    
    public func stopCountdown() {
        timeLeftShapeLayer.removeAllAnimations()
    }
    
    // Add Video Countdown Animation
    public func countdownTimer(_ videoDuration : Double) {
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
        
        timeLeftShapeLayer.add(strokeIt, forKey: nil)
        addSubview(_countdownTimer)
        
        _countdownTimer.translatesAutoresizingMaskIntoConstraints = false
        
        _countdownTimer.topAnchor.constraint(equalTo: _questionBackground.bottomAnchor, constant: _elementSpacing + _countdownTimerRadius).isActive = true
        _countdownTimer.widthAnchor.constraint(equalToConstant: _countdownTimerRadius * 2 + _countdownTimerRadiusStroke).isActive = true
        _countdownTimer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: _elementSpacing + _countdownTimerRadius).isActive = true
        _countdownTimer.heightAnchor.constraint(equalToConstant: _countdownTimerRadius * 2 + _countdownTimerRadiusStroke).isActive = true
    }
    
    public func getButton(_ buttonName : CameraButtonSelector) -> UIButton {
        switch buttonName {
            case .flash: return _flashModeButton
            case .flip: return _flipCameraButton
            case .shutter: return _shutterButton
            case .album: return _showAlbumPicker
        }
    }
    
    /* PRIVATE FUNCTIONS */
    ///Draws the camera shutter button
    fileprivate func drawShutterButton() {
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: _shutterButtonRadius, y: _shutterButtonRadius), radius: _shutterButtonRadius, startAngle: 0.0, endAngle: CGFloat(M_PI * 2.0), clockwise: true)
        
        // Setup the CAShapeLayer with the path, colors, and line width
        let circleLayer = CAShapeLayer()
        circleLayer.frame = CGRect(x: 0,y: 0,width: _shutterButtonRadius * 2,height: _shutterButtonRadius * 2)
        circleLayer.path = circlePath.cgPath
        circleLayer.fillColor = UIColor.iconBackgroundColor.withAlphaComponent(0.5).cgColor
        circleLayer.strokeColor = UIColor.white.cgColor
        circleLayer.lineWidth = 4.0
        
        _shutterButton.layer.insertSublayer(circleLayer, at: 0)
        _shutterButton.alpha = CGFloat(_elementOpacity)
        addSubview(_shutterButton)
        
        _shutterButton.translatesAutoresizingMaskIntoConstraints = false
        
        _shutterButton.bottomAnchor.constraint(equalTo: _showAlbumPicker.bottomAnchor, constant: -Spacing.xl.rawValue).isActive = true
        _shutterButton.widthAnchor.constraint(equalToConstant: _shutterButtonRadius * 2).isActive = true
        _shutterButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        _shutterButton.heightAnchor.constraint(equalToConstant: _shutterButtonRadius * 2).isActive = true
        
    }
    
    ///Draws the camera flash icon frame
    fileprivate func drawFlashCamera() {
        addSubview(_flashModeButton)
        _flashModeButton.alpha = 0.7
        
        _flashModeButton.translatesAutoresizingMaskIntoConstraints = false
        _flashModeButton.topAnchor.constraint(equalTo: _questionBackground.bottomAnchor, constant: _elementSpacing).isActive = true
        _flashModeButton.widthAnchor.constraint(equalToConstant: _iconSize).isActive = true
        _flashModeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -_elementSpacing).isActive = true
        _flashModeButton.heightAnchor.constraint(equalToConstant: _iconSize).isActive = true
    }
    
    ///Adds the image for camera based on current mode
    fileprivate func updateFlashMode(_ newFlashMode : CameraFlashMode) {
        switch newFlashMode {
        case .off: _flashModeButton.setImage(UIImage(named: "flash-off"), for: UIControlState())
        case .on: _flashModeButton.setImage(UIImage(named: "flash-on"), for: UIControlState())
        case .auto: _flashModeButton.setImage(UIImage(named: "flash-auto"), for: UIControlState())
        }
    }
    
    ///Icon to turn the camera from front to back
    fileprivate func drawFlipCamera() {
        addSubview(_flipCameraButton)
        
        _flipCameraButton.setImage(UIImage(named: "flip-camera"), for: UIControlState())
        _flipCameraButton.alpha = CGFloat(_elementOpacity)
        
        _flipCameraButton.translatesAutoresizingMaskIntoConstraints = false
        
        _flipCameraButton.topAnchor.constraint(equalTo: _flashModeButton.bottomAnchor, constant: _elementSpacing).isActive = true
        _flipCameraButton.widthAnchor.constraint(equalToConstant: _iconSize).isActive = true
        _flipCameraButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -_elementSpacing).isActive = true
        _flipCameraButton.heightAnchor.constraint(equalToConstant: _iconSize).isActive = true
    }
    
    ///Icon to turn the bring up photo album
    fileprivate func drawAlbumPicker() {
        addSubview(_showAlbumPicker)
        
        _showAlbumPicker.setImage(UIImage(named: "down-arrow"), for: UIControlState())
        _showAlbumPicker.backgroundColor = UIColor.white.withAlphaComponent(0.01)
        _showAlbumPicker.alpha = CGFloat(_elementOpacity)
        
        _showAlbumPicker.translatesAutoresizingMaskIntoConstraints = false
        
        _showAlbumPicker.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -_elementSpacing).isActive = true
        _showAlbumPicker.widthAnchor.constraint(equalToConstant: _iconSize).isActive = true
        _showAlbumPicker.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        _showAlbumPicker.heightAnchor.constraint(equalToConstant: _iconSize).isActive = true
    }
    
    ///Adds the stripe for the question
    fileprivate func drawQuestionBackground() {
        addSubview(_questionBackground)
        _questionBackground.translatesAutoresizingMaskIntoConstraints = false
        
        _questionBackground.topAnchor.constraint(equalTo: topAnchor).isActive = true
        _questionBackground.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0).isActive = true
        _questionBackground.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        _questionBackground.heightAnchor.constraint(equalToConstant: _questionBackgroundHeight).isActive = true
        
        _questionBackground.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        _questionBackground.textColor = UIColor.white
        _questionBackground.textAlignment = .center
        _questionBackground.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        _questionBackground.sizeToFit()
    }
    
    fileprivate func drawBgShape() -> CAShapeLayer {
        let bgShapeLayer = CAShapeLayer()
        bgShapeLayer.path = UIBezierPath(arcCenter: CGPoint(x: 0 , y: 0), radius: _countdownTimerRadius, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).cgPath
        bgShapeLayer.strokeColor = UIColor.white.cgColor
        bgShapeLayer.fillColor = UIColor.clear.cgColor
        bgShapeLayer.opacity = _elementOpacity
        bgShapeLayer.lineWidth = _countdownTimerRadiusStroke
        
        return bgShapeLayer
    }
    
    fileprivate func drawTimeLeftShape() -> CAShapeLayer {
        let timeLeftShapeLayer = CAShapeLayer()
        timeLeftShapeLayer.path = UIBezierPath(arcCenter: CGPoint(x: 0, y: 0), radius: _countdownTimerRadius, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).cgPath
        timeLeftShapeLayer.strokeColor = UIColor.red.cgColor
        timeLeftShapeLayer.fillColor = UIColor.clear.cgColor
        timeLeftShapeLayer.lineWidth = _countdownTimerRadiusStroke
        timeLeftShapeLayer.opacity = _elementOpacity
        
        return timeLeftShapeLayer
    }

}
