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

    fileprivate var shutterButton = UIButton()
    fileprivate var flipCameraButton = UIButton()
    fileprivate var flashModeButton = UIButton()
    fileprivate var titleBackground = UILabel()
    fileprivate var countdownTimer = UILabel()
    fileprivate var showAlbumPicker = UIButton()
    
    var _flashMode : CameraFlashMode! {
        didSet {
            updateFlashMode(_flashMode)
        }
    }
    
    fileprivate var timeLeftShapeLayer : CAShapeLayer!
    fileprivate var titleBackgroundHeight : CGFloat = 40
    fileprivate var shutterButtonRadius : CGFloat!
    fileprivate var iconSize : CGFloat = IconSizes.xxSmall.rawValue
    fileprivate var elementSpacing : CGFloat = Spacing.s.rawValue
    fileprivate var elementOpacity : Float = 0.7
    fileprivate var countdownTimerRadius : CGFloat = 10
    fileprivate var countdownTimerRadiusStroke : CGFloat = IconThickness.thick.rawValue
    
    /// Property to change camera flash mode.
    internal enum CameraFlashMode: Int {
        case off, on, auto
    }
    
    internal enum CameraButtonSelector: Int {
        case shutter, flash, flip, album
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        shutterButtonRadius = frame.size.width / 11
        drawAlbumPicker()
        drawShutterButton()
        drawTitleBackground()
        drawFlashCamera()
        drawFlipCamera()

    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        if timeLeftShapeLayer != nil {
            timeLeftShapeLayer.removeFromSuperlayer()
            timeLeftShapeLayer = nil
        }
        
    }
    
    /* PUBLIC ACCESSIBLE FUNCTIONS */
    
    ///Update question text
    public func updateTitle(_ title : String?) {
        titleBackground.text = title
    }
    
    public func stopCountdown() {
        timeLeftShapeLayer.removeAllAnimations()
    }
    
    // Add Video Countdown Animation
    public func countdownTimer(_ videoDuration : Double) {
        // draw the countdown
        let bgShapeLayer = drawBgShape()
        timeLeftShapeLayer = drawTimeLeftShape()
        
        countdownTimer.layer.addSublayer(bgShapeLayer)
        countdownTimer.layer.addSublayer(timeLeftShapeLayer)
        
        // animation object to animate the strokeEnd
        let strokeIt = CABasicAnimation(keyPath: "strokeEnd")
        strokeIt.fromValue = 0.0
        strokeIt.toValue = 1.0
        strokeIt.duration = videoDuration
        
        timeLeftShapeLayer.add(strokeIt, forKey: nil)
        addSubview(countdownTimer)
        
        countdownTimer.translatesAutoresizingMaskIntoConstraints = false
        
        countdownTimer.topAnchor.constraint(equalTo: titleBackground.bottomAnchor, constant: elementSpacing + countdownTimerRadius).isActive = true
        countdownTimer.widthAnchor.constraint(equalToConstant: countdownTimerRadius * 2 + countdownTimerRadiusStroke).isActive = true
        countdownTimer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: elementSpacing + countdownTimerRadius).isActive = true
        countdownTimer.heightAnchor.constraint(equalToConstant: countdownTimerRadius * 2 + countdownTimerRadiusStroke).isActive = true
    }
    
    public func getButton(_ buttonName : CameraButtonSelector) -> UIButton {
        switch buttonName {
            case .flash: return flashModeButton
            case .flip: return flipCameraButton
            case .shutter: return shutterButton
            case .album: return showAlbumPicker
        }
    }
    
    /* PRIVATE FUNCTIONS */
    ///Draws the camera shutter button
    fileprivate func drawShutterButton() {
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: shutterButtonRadius, y: shutterButtonRadius),
                                      radius: shutterButtonRadius, startAngle: 0.0, endAngle: CGFloat(Double.pi * 2.0), clockwise: true)
        
        // Setup the CAShapeLayer with the path, colors, and line width
        let circleLayer = CAShapeLayer()
        circleLayer.frame = CGRect(x: 0,y: 0,width: shutterButtonRadius * 2,height: shutterButtonRadius * 2)
        circleLayer.path = circlePath.cgPath
        circleLayer.fillColor = UIColor.iconBackgroundColor.withAlphaComponent(0.5).cgColor
        circleLayer.strokeColor = UIColor.white.cgColor
        circleLayer.lineWidth = 4.0
        
        shutterButton.layer.insertSublayer(circleLayer, at: 0)
        shutterButton.alpha = CGFloat(elementOpacity)
        addSubview(shutterButton)
        
        shutterButton.translatesAutoresizingMaskIntoConstraints = false
        
        shutterButton.bottomAnchor.constraint(equalTo: showAlbumPicker.bottomAnchor, constant: -Spacing.xl.rawValue).isActive = true
        shutterButton.widthAnchor.constraint(equalToConstant: shutterButtonRadius * 2).isActive = true
        shutterButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        shutterButton.heightAnchor.constraint(equalToConstant: shutterButtonRadius * 2).isActive = true
        
    }
    
    ///Draws the camera flash icon frame
    fileprivate func drawFlashCamera() {
        addSubview(flashModeButton)
        flashModeButton.alpha = 0.7
        
        flashModeButton.translatesAutoresizingMaskIntoConstraints = false
        flashModeButton.topAnchor.constraint(equalTo: titleBackground.bottomAnchor, constant: elementSpacing).isActive = true
        flashModeButton.widthAnchor.constraint(equalToConstant: iconSize).isActive = true
        flashModeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -elementSpacing).isActive = true
        flashModeButton.heightAnchor.constraint(equalToConstant: iconSize).isActive = true
    }
    
    ///Adds the image for camera based on current mode
    fileprivate func updateFlashMode(_ newFlashMode : CameraFlashMode) {
        switch newFlashMode {
        case .off: flashModeButton.setImage(UIImage(named: "flash-off"), for: UIControlState())
        case .on: flashModeButton.setImage(UIImage(named: "flash-on"), for: UIControlState())
        case .auto: flashModeButton.setImage(UIImage(named: "flash-auto"), for: UIControlState())
        }
    }
    
    ///Icon to turn the camera from front to back
    fileprivate func drawFlipCamera() {
        addSubview(flipCameraButton)
        
        flipCameraButton.setImage(UIImage(named: "flip-camera"), for: UIControlState())
        flipCameraButton.alpha = CGFloat(elementOpacity)
        
        flipCameraButton.translatesAutoresizingMaskIntoConstraints = false
        
        flipCameraButton.topAnchor.constraint(equalTo: flashModeButton.bottomAnchor, constant: elementSpacing).isActive = true
        flipCameraButton.widthAnchor.constraint(equalToConstant: iconSize).isActive = true
        flipCameraButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -elementSpacing).isActive = true
        flipCameraButton.heightAnchor.constraint(equalToConstant: iconSize).isActive = true
    }
    
    ///Icon to turn the bring up photo album
    fileprivate func drawAlbumPicker() {
        addSubview(showAlbumPicker)
        
        showAlbumPicker.setImage(UIImage(named: "down-arrow"), for: UIControlState())
        showAlbumPicker.backgroundColor = UIColor.white.withAlphaComponent(0.01)
        showAlbumPicker.alpha = CGFloat(elementOpacity)
        
        showAlbumPicker.translatesAutoresizingMaskIntoConstraints = false
        
        showAlbumPicker.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -elementSpacing).isActive = true
        showAlbumPicker.widthAnchor.constraint(equalToConstant: iconSize).isActive = true
        showAlbumPicker.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        showAlbumPicker.heightAnchor.constraint(equalToConstant: iconSize).isActive = true
    }
    
    ///Adds the stripe for the question
    fileprivate func drawTitleBackground() {
        addSubview(titleBackground)
        titleBackground.translatesAutoresizingMaskIntoConstraints = false
        
        titleBackground.topAnchor.constraint(equalTo: topAnchor).isActive = true
        titleBackground.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0).isActive = true
        titleBackground.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        titleBackground.heightAnchor.constraint(equalToConstant: titleBackgroundHeight).isActive = true
        
        titleBackground.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        titleBackground.textColor = UIColor.white
        titleBackground.textAlignment = .center
        titleBackground.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        titleBackground.numberOfLines = 2
        titleBackground.adjustsFontSizeToFitWidth = true
        titleBackground.minimumScaleFactor = 0.3
    }
    
    fileprivate func drawBgShape() -> CAShapeLayer {
        let bgShapeLayer = CAShapeLayer()
        bgShapeLayer.path = UIBezierPath(arcCenter: CGPoint(x: 0 , y: 0), radius: countdownTimerRadius, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).cgPath
        bgShapeLayer.strokeColor = UIColor.pulseGrey.cgColor
        bgShapeLayer.fillColor = UIColor.clear.cgColor
        bgShapeLayer.opacity = elementOpacity
        bgShapeLayer.lineWidth = countdownTimerRadiusStroke
        
        return bgShapeLayer
    }
    
    fileprivate func drawTimeLeftShape() -> CAShapeLayer {
        let timeLeftShapeLayer = CAShapeLayer()
        timeLeftShapeLayer.path = UIBezierPath(arcCenter: CGPoint(x: 0, y: 0), radius: countdownTimerRadius, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).cgPath
        timeLeftShapeLayer.strokeColor = UIColor.red.cgColor
        timeLeftShapeLayer.fillColor = UIColor.clear.cgColor
        timeLeftShapeLayer.lineWidth = countdownTimerRadiusStroke
        timeLeftShapeLayer.opacity = elementOpacity
        
        return timeLeftShapeLayer
    }

}
