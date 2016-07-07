//
//  AnswerOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/5/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AnswerOverlay: UIView {

    internal var _userBackground = UIView()
    internal var _userNameLabel : UILabel?
    internal var _userLocationLabel : UILabel?
    internal var _userImage : UIImageView?
    internal var _bottomDimension : CGFloat = 50
    internal var _elementSpacer : CGFloat = 10
    
    internal var videoTimer : UIView!
    internal var videoTimerDimensions : CGFloat = 40
    internal var timeLeftShapeLayer = CAShapeLayer()
    internal var bgShapeLayer = CAShapeLayer()

    override init(frame: CGRect) {
        self.videoTimer = UIView(frame: CGRectMake(frame.size.width - self.videoTimerDimensions, frame.size.height - self._bottomDimension - self.videoTimerDimensions, self.videoTimerDimensions, self.videoTimerDimensions))
        
        super.init(frame: frame)
        self.addUserBackground()
        self.addSubview(self.videoTimer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func addUserBackground() {
        self.addSubview(self._userBackground)
        
        _userBackground.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        _userBackground.translatesAutoresizingMaskIntoConstraints = false
        
        _userBackground.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor).active = true
        _userBackground.widthAnchor.constraintEqualToAnchor(self.widthAnchor).active = true
        _userBackground.leadingAnchor.constraintEqualToAnchor(self.leadingAnchor).active = true
        _userBackground.heightAnchor.constraintEqualToConstant(_bottomDimension).active = true
    }
    
    func addUserName(_userName : String) {
//        _userName = UILabel(frame: CGRectMake(bottomPanel + 10, userBackground.frame.height / 6, userBackground.frame.width - bottomPanel - 10, _userBackground.frame.height / 3))
        _userNameLabel = UILabel()
        _userNameLabel?.text = _userName
        _userNameLabel?.textColor = UIColor.whiteColor()
        _userNameLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        
        _userBackground.addSubview(_userNameLabel!)
        
        _userNameLabel!.translatesAutoresizingMaskIntoConstraints = false
        
        _userNameLabel!.topAnchor.constraintEqualToAnchor(_userBackground.topAnchor, constant: _bottomDimension / 6).active = true
        _userNameLabel!.widthAnchor.constraintEqualToAnchor(_userBackground.widthAnchor, constant: -_elementSpacer - _bottomDimension).active = true
        _userNameLabel!.trailingAnchor.constraintEqualToAnchor(_userBackground.trailingAnchor).active = true
    }
    
    func addLocation(_userLocation : String) {
//        userLocation = UILabel(frame: CGRectMake(bottomPanel + 10, userBackground.frame.height / 2, userBackground.frame.width - bottomPanel - 10, userBackground.frame.height / 3))
        _userLocationLabel = UILabel()
        _userLocationLabel?.text = _userLocation
        _userLocationLabel?.textColor = UIColor.whiteColor()
        _userLocationLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)


        _userBackground.addSubview(_userLocationLabel!)
        
        _userLocationLabel!.translatesAutoresizingMaskIntoConstraints = false
        
        _userLocationLabel!.bottomAnchor.constraintEqualToAnchor(_userBackground.bottomAnchor, constant: -_bottomDimension / 6).active = true
        _userLocationLabel!.widthAnchor.constraintEqualToAnchor(_userBackground.widthAnchor, constant: -_elementSpacer - _bottomDimension).active = true
        _userLocationLabel!.trailingAnchor.constraintEqualToAnchor(_userBackground.trailingAnchor).active = true
    }
    
    func addUserImage(_userImageURL : NSURL?) {
//        _userImage = UIImageView(frame: CGRectMake(0, 0, bottomPanel, bottomPanel))
        _userImage = UIImageView()
        
        if let _ = _userImageURL {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let _userImage = NSData(contentsOfURL: _userImageURL!)
                dispatch_async(dispatch_get_main_queue(), {
                    self._userImage!.image = UIImage(data: _userImage!)
                });
            }
            _userBackground.addSubview(_userImage!)
            
            _userImage!.translatesAutoresizingMaskIntoConstraints = false
            
            _userImage!.topAnchor.constraintEqualToAnchor(_userBackground.topAnchor).active = true
            _userImage!.widthAnchor.constraintEqualToConstant(_bottomDimension).active = true
            _userImage!.heightAnchor.constraintEqualToConstant(_bottomDimension).active = true
            _userImage!.leadingAnchor.constraintEqualToAnchor(_userBackground.leadingAnchor).active = true
        }
    }
    
    /// Add video countdown
    func addVideoTimerCountdown() {
        
        // draw the countdown
        bgShapeLayer = drawBgShape()
        timeLeftShapeLayer = drawTimeLeftShape()
        
        videoTimer.layer.addSublayer(bgShapeLayer)
        videoTimer.layer.addSublayer(timeLeftShapeLayer)
    }
    
    func startTimer(videoDuration : Double) {
        print("started timer")
        let strokeIt = CABasicAnimation(keyPath: "strokeEnd")
        strokeIt.fromValue = 0.0
        strokeIt.toValue = 1.0
        strokeIt.duration = videoDuration
        
        timeLeftShapeLayer.addAnimation(strokeIt, forKey: "stroke")
    }
    
    func resetTimer() {
        print("reset timer")
        timeLeftShapeLayer.strokeStart = 0.0
//        timeLeftShapeLayer.removeAnimationForKey("stroke")
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
        timeLeftShapeLayer.strokeColor = UIColor.darkGrayColor().CGColor
        timeLeftShapeLayer.fillColor = UIColor.clearColor().CGColor
        timeLeftShapeLayer.lineWidth = 5
        timeLeftShapeLayer.opacity = 0.7
        
        return timeLeftShapeLayer
    }

    
}
