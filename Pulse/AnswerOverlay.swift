//
//  AnswerOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/5/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AnswerOverlay: UIView {

    private var _headerBackground = UIView()
    private var _userBackground = UIView()
    
    private let _questionLabel = UILabel()
    private let _userNameLabel = UILabel()
    private let _userLocationLabel = UILabel()
    private var _userImage = UIImageView()
    private let _videoTimer = UIView()

    private let _tagLabel = UILabel()
    private var _pulseIcon = Icon()

    private let _bottomDimension : CGFloat = 50
    private var _countdownTimerRadiusStroke : CGFloat = 3
    private var _iconSize : CGFloat = 40
    
    private lazy var upvote = UIImageView(image: UIImage(named: "upvote"))
    private lazy var downvote = UIImageView(image: UIImage(named: "downvote"))

    private var _timeLeftShapeLayer = CAShapeLayer()
    private var _bgShapeLayer = CAShapeLayer()
    
    var delegate : showProfileDelegate!

    override init(frame: CGRect) {
        super.init(frame: frame)
        addUserBackground()
        addHeaderBackground()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func addHeaderBackground() {
        addSubview(_headerBackground)
        _headerBackground.translatesAutoresizingMaskIntoConstraints = false
        
        _headerBackground.topAnchor.constraintEqualToAnchor(topAnchor, constant: 0.0).active = true
        _headerBackground.widthAnchor.constraintEqualToAnchor(widthAnchor, multiplier: 1.0).active = true
        _headerBackground.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: 0.0).active = true
        _headerBackground.heightAnchor.constraintEqualToAnchor(heightAnchor, multiplier: 0.1).active = true
        _headerBackground.layoutIfNeeded()
        
        _headerBackground.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(1.0)
        
        addTag()
        addQuestion()
    }
    
    private func addUserBackground() {
        addSubview(_userBackground)
        
        _userBackground.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        _userBackground.translatesAutoresizingMaskIntoConstraints = false
        
        _userBackground.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
        _userBackground.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        _userBackground.leadingAnchor.constraintEqualToAnchor(leadingAnchor).active = true
        _userBackground.heightAnchor.constraintEqualToConstant(_bottomDimension).active = true
        _userBackground.layoutIfNeeded()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleProfileTap))
        _userBackground.addGestureRecognizer(tap)
        
        addUserName()
        addUserImage()
        addLocation()
        
    }
    
    ///Update question text
    private func addQuestion() {
        _headerBackground.addSubview(_questionLabel)
        _questionLabel.adjustsFontSizeToFitWidth = true
        
        _questionLabel.textColor = UIColor.blackColor()
        _questionLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        _questionLabel.textAlignment = .Left
        
        _questionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        _questionLabel.bottomAnchor.constraintEqualToAnchor(_headerBackground.bottomAnchor, constant: -_headerBackground.frame.height / 6).active = true
        _questionLabel.widthAnchor.constraintEqualToAnchor(_headerBackground.widthAnchor, multiplier: 0.8).active = true
        _questionLabel.heightAnchor.constraintEqualToAnchor(_headerBackground.heightAnchor, multiplier: 1/3).active = true
        _questionLabel.leadingAnchor.constraintEqualToAnchor(_headerBackground.leadingAnchor, constant: Spacing.xs.rawValue).active = true
    }
    
    ///Update Tag in header
    private func addTag() {
        _headerBackground.addSubview(_tagLabel)
        
        _tagLabel.textColor = UIColor.blackColor()
        _tagLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        _tagLabel.textAlignment = .Left
        
        _tagLabel.translatesAutoresizingMaskIntoConstraints = false
        
        _tagLabel.topAnchor.constraintEqualToAnchor(_headerBackground.topAnchor, constant: _headerBackground.frame.height / 6).active = true
        _tagLabel.widthAnchor.constraintEqualToAnchor(_headerBackground.widthAnchor, multiplier: 0.8).active = true
        _tagLabel.heightAnchor.constraintEqualToAnchor(_headerBackground.heightAnchor, multiplier: 1/3).active = true
        _tagLabel.leadingAnchor.constraintEqualToAnchor(_headerBackground.leadingAnchor, constant: Spacing.xs.rawValue).active = true
    }
    
    ///Add Icon in header
    func addIcon(iconColor: UIColor, backgroundColor : UIColor) {
        _pulseIcon = Icon(frame: CGRectMake(0,0, _iconSize, _iconSize))

        _pulseIcon.drawIconBackground(backgroundColor)
        _pulseIcon.drawIcon(iconColor, iconThickness: 2)

        _headerBackground.addSubview(_pulseIcon)
        
        _pulseIcon.translatesAutoresizingMaskIntoConstraints = false
        
        _pulseIcon.centerYAnchor.constraintEqualToAnchor(_headerBackground.centerYAnchor, constant: 0).active = true
        _pulseIcon.widthAnchor.constraintEqualToConstant(_iconSize).active = true
        _pulseIcon.heightAnchor.constraintEqualToAnchor(_pulseIcon.widthAnchor).active = true
        
        _pulseIcon.trailingAnchor.constraintEqualToAnchor(_headerBackground.trailingAnchor, constant: -Spacing.xs.rawValue).active = true
    }
    
    func handleProfileTap() {
        if delegate != nil {
            delegate.userClickedProfile()
        }
    }
    
    private func addUserName() {
        _userBackground.addSubview(_userNameLabel)

        _userNameLabel.textColor = UIColor.whiteColor()
        _userNameLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        
        _userNameLabel.translatesAutoresizingMaskIntoConstraints = false
        _userNameLabel.topAnchor.constraintEqualToAnchor(_userBackground.topAnchor, constant: _bottomDimension / 6).active = true
        _userNameLabel.widthAnchor.constraintEqualToAnchor(_userBackground.widthAnchor, constant: -Spacing.xs.rawValue - _bottomDimension).active = true
        _userNameLabel.trailingAnchor.constraintEqualToAnchor(_userBackground.trailingAnchor).active = true
    }
    
    private func addLocation() {
        _userLocationLabel.textColor = UIColor.whiteColor()
        _userLocationLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        _userBackground.addSubview(_userLocationLabel)

        _userLocationLabel.translatesAutoresizingMaskIntoConstraints = false
        _userLocationLabel.bottomAnchor.constraintEqualToAnchor(_userBackground.bottomAnchor, constant: -_bottomDimension / 6).active = true
        _userLocationLabel.widthAnchor.constraintEqualToAnchor(_userBackground.widthAnchor, constant: -Spacing.xs.rawValue - _bottomDimension).active = true
        _userLocationLabel.trailingAnchor.constraintEqualToAnchor(_userBackground.trailingAnchor).active = true
    }
    
    private func addUserImage() {
        _userBackground.addSubview(_userImage)
        _userImage.translatesAutoresizingMaskIntoConstraints = false
        _userImage.contentMode = UIViewContentMode.ScaleAspectFill
        _userImage.clipsToBounds = true
        
        _userImage.topAnchor.constraintEqualToAnchor(_userBackground.topAnchor).active = true
        _userImage.widthAnchor.constraintEqualToConstant(_bottomDimension).active = true
        _userImage.heightAnchor.constraintEqualToConstant(_bottomDimension).active = true
        _userImage.leadingAnchor.constraintEqualToAnchor(_userBackground.leadingAnchor).active = true
        
    }
    
    
    /* PUBLIC SETTER FUNCTIONS */
    func setUserName(_userName : String?) {
        _userNameLabel.text = _userName
    }
    
    func setUserLocation(_userLocation : String?) {
        _userLocationLabel.text = _userLocation
    }
    
    func setUserImage(image : UIImage?) {
         _userImage.image = image
    }
    
    func getUserBackground() -> UIView {
        return _userBackground
    }
    
    func setQuestion(question : String) {
        _questionLabel.text = question
    }
    
    func setTagName(tagName : String) {
        _tagLabel.text = "#" + tagName.uppercaseString
    }
    
    /// Add video countdown
    func addVideoTimerCountdown() {
        addSubview(_videoTimer)
        
        _videoTimer.translatesAutoresizingMaskIntoConstraints = false

        _videoTimer.centerXAnchor.constraintEqualToAnchor(_pulseIcon.centerXAnchor, constant: _iconSize / 2).active = true
        _videoTimer.widthAnchor.constraintEqualToConstant(_iconSize).active = true
        _videoTimer.centerYAnchor.constraintEqualToAnchor(_pulseIcon.centerYAnchor, constant: _iconSize / 2).active = true
        _videoTimer.heightAnchor.constraintEqualToConstant(_iconSize).active = true
        
        // draw the countdown
        _bgShapeLayer = drawBgShape(_iconSize / 2, _stroke: _countdownTimerRadiusStroke)
        _timeLeftShapeLayer = drawTimeLeftShape()
        
        _videoTimer.layer.addSublayer(_bgShapeLayer)
        _videoTimer.layer.addSublayer(_timeLeftShapeLayer)
    }
    
    func startTimer(videoDuration : Double) {
        let strokeIt = CABasicAnimation(keyPath: "strokeEnd")
        strokeIt.fromValue = 0.0
        strokeIt.toValue = 1.0
        strokeIt.duration = videoDuration
        
        _timeLeftShapeLayer.addAnimation(strokeIt, forKey: "stroke")
    }
    
    func resetTimer() {
        _timeLeftShapeLayer.strokeStart = 0.0
    }
    
    func drawBgShape(_radius : CGFloat, _stroke : CGFloat) -> CAShapeLayer {
        let bgShapeLayer = CAShapeLayer()
        bgShapeLayer.path = UIBezierPath(arcCenter: CGPoint(x: 0 , y: 0), radius:
            _radius, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).CGPath
        bgShapeLayer.strokeColor = UIColor.whiteColor().CGColor
        bgShapeLayer.fillColor = UIColor.clearColor().CGColor
        bgShapeLayer.opacity = 0.7
        bgShapeLayer.lineWidth = _stroke
        
        return bgShapeLayer
    }
    
    func drawTimeLeftShape() -> CAShapeLayer {
        let timeLeftShapeLayer = CAShapeLayer()
        timeLeftShapeLayer.path = UIBezierPath(arcCenter: CGPoint(x: 0, y: 0), radius:
            _iconSize / 2, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).CGPath
        timeLeftShapeLayer.strokeColor = UIColor.lightGrayColor().CGColor
        timeLeftShapeLayer.fillColor = UIColor.clearColor().CGColor
        timeLeftShapeLayer.lineWidth = _countdownTimerRadiusStroke
        timeLeftShapeLayer.opacity = 0.7
        
        return timeLeftShapeLayer
    }
    
    /* ADD VOTE ANIMATION */
    func addVote(_vote : AnswerVoteType) {
        let _voteImage : UIImageView!
        
        switch _vote {
        case .Upvote: _voteImage = UIImageView(image: UIImage(named: "upvote"))
        case .Downvote: _voteImage = UIImageView(image: UIImage(named: "downvote"))
        }
        
        addSubview(_voteImage)
        _voteImage.alpha = 1.0

        _voteImage.translatesAutoresizingMaskIntoConstraints = false
        
        _voteImage.topAnchor.constraintEqualToAnchor(_headerBackground.bottomAnchor, constant: Spacing.l.rawValue).active = true
        _voteImage.trailingAnchor.constraintEqualToAnchor(_headerBackground.trailingAnchor, constant: -Spacing.l.rawValue).active = true
        _voteImage.widthAnchor.constraintEqualToConstant(IconSizes.Small.rawValue).active = true
        _voteImage.heightAnchor.constraintEqualToAnchor(_voteImage.widthAnchor).active = true
        
        let xForm = CGAffineTransformScale(CGAffineTransformIdentity, 3.0, 3.0)
        UIView.animateWithDuration(0.5, animations: { _voteImage.transform = xForm; _voteImage.alpha = 0 } , completion: {(value: Bool) in
            _voteImage.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0)
            _voteImage.removeFromSuperview()
        })
    }
}
