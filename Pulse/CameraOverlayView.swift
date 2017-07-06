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
    
    public var countdownTimer = UILabel()
    public var _flashMode : CameraFlashMode! {
        didSet {
            updateFlashMode(_flashMode)
        }
    }
    fileprivate var shutterButton = UIButton()
    fileprivate var closeButton = PulseButton(size: .xSmall, type: .close, isRound : true, background: UIColor.white.withAlphaComponent(0.3), tint: .black)
    fileprivate var flipCameraButton = PulseButton(size: .xSmall, type: .flipCamera, isRound : true, background: UIColor.white.withAlphaComponent(0.3), tint: .black)
    fileprivate var flashModeButton = PulseButton(size: .xSmall, type: .flashMode, isRound : true, background: UIColor.white.withAlphaComponent(0.3), tint: .black)
    
    fileprivate var showAlbumPicker = PulseButton(size: .small, type: .showAlbum, isRound : true, background: UIColor.white.withAlphaComponent(0.3), tint: .black)
    fileprivate var titleBackground = UILabel()
    
    fileprivate var timeLeftShapeLayer : CAShapeLayer!
    fileprivate var titleBackgroundHeight : CGFloat = scopeBarHeight
    fileprivate var shutterButtonRadius : CGFloat!
    fileprivate var iconSize : CGFloat = IconSizes.xSmall.rawValue
    fileprivate var elementSpacing : CGFloat = Spacing.s.rawValue
    fileprivate var elementOpacity : Float = 0.7
    fileprivate var radiusStroke : CGFloat = IconThickness.extraThick.rawValue
    
    /// Property to change camera flash mode.
    internal enum CameraFlashMode: Int {
        case off, on, auto
    }
    
    internal enum CameraButtonSelector: Int {
        case shutter, flash, flip, album, close
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        shutterButtonRadius = frame.size.width / 11
        drawShutterButton()
        drawAlbumPicker()
        drawTitleBackground()
        drawCloseButton()
        drawFlashCamera()
        drawFlipCamera()

    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        if timeLeftShapeLayer != nil {
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
        timeLeftShapeLayer.removeFromSuperlayer()
        
    }
    
    // Add Video Countdown Animation
    public func countdownTimer(_ videoDuration : Double) {
        if countdownTimer.superview != self {
            addSubview(countdownTimer)
        }
        
        countdownTimer.translatesAutoresizingMaskIntoConstraints = false
        
        countdownTimer.centerXAnchor.constraint(equalTo: shutterButton.centerXAnchor).isActive = true
        countdownTimer.widthAnchor.constraint(equalTo: shutterButton.widthAnchor).isActive = true
        countdownTimer.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor).isActive = true
        countdownTimer.heightAnchor.constraint(equalTo: shutterButton.heightAnchor).isActive = true
        countdownTimer.layoutIfNeeded()
        
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
    }
    
    public func getButton(_ buttonName : CameraButtonSelector) -> UIButton {
        switch buttonName {
            case .flash: return flashModeButton
            case .flip: return flipCameraButton
            case .shutter: return shutterButton
            case .album: return showAlbumPicker
            case .close: return closeButton
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for view in subviews {
            if !view.isHidden && view.point(inside: self.convert(point, to: view), with: event) {
                return true
            }
        }
        return false
    }
    
    /* PRIVATE FUNCTIONS */
    ///Draws the camera shutter button
    fileprivate func drawShutterButton() {
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: shutterButtonRadius, y: shutterButtonRadius),
                                      radius: shutterButtonRadius, startAngle: 0.0, endAngle: CGFloat(Double.pi * 2.0), clockwise: true)
        
        // Setup the CAShapeLayer with the path, colors, and line width
        let circleLayer = CAShapeLayer()
        circleLayer.frame = CGRect(x: 0,y: 0,width: shutterButtonRadius * 2 + 2,height: shutterButtonRadius * 2 + 2)
        circleLayer.path = circlePath.cgPath
        circleLayer.fillColor = UIColor.white.withAlphaComponent(0.8).cgColor
        circleLayer.strokeColor = UIColor.white.cgColor
        circleLayer.lineWidth = radiusStroke
        
        shutterButton.layer.insertSublayer(circleLayer, at: 0)
        shutterButton.alpha = CGFloat(elementOpacity)
        addSubview(shutterButton)
        
        shutterButton.translatesAutoresizingMaskIntoConstraints = false
        
        shutterButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.l.rawValue).isActive = true
        shutterButton.widthAnchor.constraint(equalToConstant: shutterButtonRadius * 2).isActive = true
        shutterButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        shutterButton.heightAnchor.constraint(equalToConstant: shutterButtonRadius * 2).isActive = true
        
    }
    
    private func drawCloseButton() {
        addSubview(closeButton)
        closeButton.alpha = CGFloat(elementOpacity)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.topAnchor.constraint(equalTo: titleBackground.bottomAnchor, constant: elementSpacing).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: iconSize).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: iconSize).isActive = true
        closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: elementSpacing).isActive = true
        closeButton.removeShadow()
    }
    
    ///Draws the camera flash icon frame
    fileprivate func drawFlashCamera() {
        addSubview(flashModeButton)
        flashModeButton.alpha = CGFloat(elementOpacity)
        
        flashModeButton.translatesAutoresizingMaskIntoConstraints = false
        flashModeButton.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: elementSpacing).isActive = true
        flashModeButton.widthAnchor.constraint(equalToConstant: iconSize).isActive = true
        flashModeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: elementSpacing).isActive = true
        flashModeButton.heightAnchor.constraint(equalToConstant: iconSize).isActive = true
        flashModeButton.removeShadow()
        
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
        flipCameraButton.alpha = CGFloat(elementOpacity)
        
        flipCameraButton.translatesAutoresizingMaskIntoConstraints = false
        flipCameraButton.topAnchor.constraint(equalTo: flashModeButton.bottomAnchor, constant: elementSpacing).isActive = true
        flipCameraButton.widthAnchor.constraint(equalToConstant: iconSize).isActive = true
        flipCameraButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: elementSpacing).isActive = true
        flipCameraButton.heightAnchor.constraint(equalToConstant: iconSize).isActive = true
        flipCameraButton.removeShadow()
    }
    
    ///Icon to turn the bring up photo album
    fileprivate func drawAlbumPicker() {
        addSubview(showAlbumPicker)
        showAlbumPicker.alpha = CGFloat(elementOpacity)
        showAlbumPicker.translatesAutoresizingMaskIntoConstraints = false
        showAlbumPicker.bottomAnchor.constraint(equalTo: shutterButton.bottomAnchor).isActive = true
        showAlbumPicker.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        showAlbumPicker.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.m.rawValue).isActive = true
        showAlbumPicker.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        showAlbumPicker.removeShadow()
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
        titleBackground.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .white, alignment: .center)        
        titleBackground.numberOfLines = 2
        titleBackground.adjustsFontSizeToFitWidth = true
        titleBackground.minimumScaleFactor = 0.3
    }
    
    fileprivate func drawBgShape() -> CAShapeLayer {
        let bgShapeLayer = CAShapeLayer()
        bgShapeLayer.path = UIBezierPath(arcCenter: CGPoint(x: countdownTimer.frame.width / 2 , y: countdownTimer.frame.height / 2),
                                         radius: shutterButtonRadius, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).cgPath
        bgShapeLayer.strokeColor = UIColor.pulseGrey.cgColor
        bgShapeLayer.fillColor = UIColor.clear.cgColor
        bgShapeLayer.opacity = elementOpacity
        bgShapeLayer.lineWidth = radiusStroke
        
        return bgShapeLayer
    }
    
    fileprivate func drawTimeLeftShape() -> CAShapeLayer {
        let timeLeftShapeLayer = CAShapeLayer()
        timeLeftShapeLayer.path = UIBezierPath(arcCenter: CGPoint(x: countdownTimer.frame.width / 2 , y: countdownTimer.frame.height / 2),
                                               radius: shutterButtonRadius, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians,
                                               clockwise: true).cgPath
        timeLeftShapeLayer.strokeColor = UIColor.red.cgColor
        timeLeftShapeLayer.fillColor = UIColor.clear.cgColor
        timeLeftShapeLayer.lineWidth = radiusStroke
        timeLeftShapeLayer.opacity = elementOpacity
        
        return timeLeftShapeLayer
    }

}
