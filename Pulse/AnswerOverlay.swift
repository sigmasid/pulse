//
//  AnswerOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/5/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AnswerOverlay: UIView {

    internal var userBackground : UIView!
    internal var userName : UILabel?
    internal var userLocation : UILabel?
    internal var userImage : UIImageView?
    internal var bottomPanel : CGFloat = 50
    
    internal var videoTimer : UIView!
    internal var videoTimerDimensions : CGFloat = 40
    internal var timeLeftShapeLayer = CAShapeLayer()
    internal var bgShapeLayer = CAShapeLayer()

    override init(frame: CGRect) {
        self.userBackground = UIView(frame: CGRectMake(0, frame.size.height - self.bottomPanel, frame.size.width, self.bottomPanel))
        self.userBackground.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        
        self.videoTimer = UIView(frame: CGRectMake(frame.size.width - self.videoTimerDimensions, frame.size.height - self.bottomPanel - self.videoTimerDimensions, self.videoTimerDimensions, self.videoTimerDimensions))
        
        self.userName = nil
        self.userLocation = nil
        self.userImage = nil

        super.init(frame: frame)
        self.addSubview(self.userBackground)
        self.addSubview(self.videoTimer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func addUserName(_userName : String) {
        userName = UILabel(frame: CGRectMake(bottomPanel + 10, userBackground.frame.height / 6, userBackground.frame.width - bottomPanel - 10, userBackground.frame.height / 3))
    
        userName?.text = _userName
        userName?.textColor = UIColor.whiteColor()
        
        userBackground.addSubview(userName!)
    }
    
    func addLocation(_userLocation : String) {
        userLocation = UILabel(frame: CGRectMake(bottomPanel + 10, userBackground.frame.height / 2, userBackground.frame.width - bottomPanel - 10, userBackground.frame.height / 3))
        
        userLocation?.text = _userLocation
        userLocation?.textColor = UIColor.whiteColor()

        userBackground.addSubview(userLocation!)
    }
    
    func addUserImage(_userImageURL : NSURL?) {
        userImage = UIImageView(frame: CGRectMake(0, 0, bottomPanel, bottomPanel))
        
        if let _ = _userImageURL {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let _userImage = NSData(contentsOfURL: _userImageURL!)
                dispatch_async(dispatch_get_main_queue(), {
                    self.userImage!.image = UIImage(data: _userImage!)
                });
            }
            userBackground.addSubview(userImage!)
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
