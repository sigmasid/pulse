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
    
    private let _tagLabel = PaddingLabel()
    private let _questionLabel = PaddingLabel()
    
    private let _userNameLabel = UILabel()
    private let _userLocationLabel = UILabel()
    private lazy var _userShortBioLabel = UILabel()
    private var _userImage = UIImageView()
    private let _videoTimer = UIView()
    private var _pulseIcon = Icon()
    private var _showMenu : AnswerMenu!
    private var _isShowingMenu = false

    private let _footerHeight : CGFloat = Spacing.l.rawValue
    private var _countdownTimerRadiusStroke : CGFloat = 3
    private var _iconSize : CGFloat = Spacing.l.rawValue
    
    private lazy var upvote = UIImageView(image: UIImage(named: "upvote"))
    private lazy var downvote = UIImageView(image: UIImage(named: "downvote"))

    private var _timeLeftShapeLayer = CAShapeLayer()
    private var _bgShapeLayer = CAShapeLayer()
    
    weak var delegate : answerDetailDelegate!

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, iconColor: UIColor, iconBackground: UIColor) {
        self.init(frame: frame)
        addIcon(iconColor, backgroundColor: iconBackground)
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
        
        addQuestion()
        addTag()

    }
    
    private func addUserBackground() {
        addSubview(_userBackground)
        
//        _userBackground.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        _userBackground.translatesAutoresizingMaskIntoConstraints = false
        
        _userBackground.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
        _userBackground.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        _userBackground.leadingAnchor.constraintEqualToAnchor(leadingAnchor).active = true
        _userBackground.heightAnchor.constraintEqualToConstant(_footerHeight).active = true
        _userBackground.layoutIfNeeded()
        
        let userBackgroundTap = UITapGestureRecognizer(target: self, action: #selector(handleProfileTap))
        _userBackground.addGestureRecognizer(userBackgroundTap)
        
        addUserImage()
        addUserName()
        addLocation()
    }
    
    ///Update question text
    private func addQuestion() {
        _headerBackground.addSubview(_questionLabel)
        _questionLabel.adjustsFontSizeToFitWidth = true
        
        _questionLabel.textColor = UIColor.whiteColor()
        _questionLabel.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        _questionLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
        _questionLabel.textAlignment = .Left
        _questionLabel.numberOfLines = 0
        _questionLabel.lineBreakMode = .ByWordWrapping
        
        _questionLabel.translatesAutoresizingMaskIntoConstraints = false
        _questionLabel.topAnchor.constraintEqualToAnchor(_headerBackground.topAnchor, constant: _headerBackground.frame.height / 6).active = true
        _questionLabel.trailingAnchor.constraintEqualToAnchor(_headerBackground.trailingAnchor, constant: -Spacing.xs.rawValue).active = true
        _questionLabel.leadingAnchor.constraintEqualToAnchor(_pulseIcon.trailingAnchor, constant: Spacing.xs.rawValue).active = true
    
    }
    
    ///Update Tag in header
    private func addTag() {
        _headerBackground.addSubview(_tagLabel)
        
        _tagLabel.textColor = UIColor.whiteColor()
        _tagLabel.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        _tagLabel.font = UIFont.boldSystemFontOfSize(FontSizes.Caption.rawValue)
        _tagLabel.textAlignment = .Left
        
        _tagLabel.translatesAutoresizingMaskIntoConstraints = false
        _tagLabel.topAnchor.constraintEqualToAnchor(_questionLabel.bottomAnchor, constant: 1.0).active = true
        _tagLabel.heightAnchor.constraintEqualToAnchor(_headerBackground.heightAnchor, multiplier: 1/3).active = true
        _tagLabel.leadingAnchor.constraintEqualToAnchor(_pulseIcon.trailingAnchor, constant: Spacing.xs.rawValue).active = true
    }
    
    ///Add Icon in header
    func addIcon(iconColor: UIColor, backgroundColor : UIColor) {
        _pulseIcon = Icon(frame: CGRectMake(0,0, _iconSize, _iconSize))

        _pulseIcon.drawIconBackground(backgroundColor.colorWithAlphaComponent(0.7))
        _pulseIcon.drawIcon(iconColor, iconThickness: IconThickness.Medium.rawValue)

        _headerBackground.addSubview(_pulseIcon)
        
        _pulseIcon.translatesAutoresizingMaskIntoConstraints = false
        _pulseIcon.centerYAnchor.constraintEqualToAnchor(_headerBackground.centerYAnchor).active = true
        _pulseIcon.widthAnchor.constraintEqualToConstant(_iconSize).active = true
        _pulseIcon.heightAnchor.constraintEqualToAnchor(_pulseIcon.widthAnchor).active = true
        _pulseIcon.leadingAnchor.constraintEqualToAnchor(_headerBackground.leadingAnchor, constant: Spacing.xs.rawValue).active = true
        
        let exploreAnswersTap = UITapGestureRecognizer(target: self, action: #selector(handleShowMenu))
        _pulseIcon.addGestureRecognizer(exploreAnswersTap)
    }
    
    func handleProfileTap() {
        if delegate != nil {
            delegate.userClickedProfile()
        }
    }
    
    func handleShowMenu() {
        if delegate != nil {
            delegate.userClickedShowMenu()
        }
    }
    
    func handleExploreTap() {
        if delegate != nil {
            toggleMenu()
            delegate.userClickedExploreAnswers()
        }
    }
    
    func handleAddAnswerTap() {
        if delegate != nil {
            toggleMenu()
            delegate.userClickedAddAnswer()
        }
    }
    
    func getHeaderHeight() -> CGFloat {
        return _headerBackground.bounds.height  
    }
    
    private func addUserName() {
        _userBackground.addSubview(_userNameLabel)

        _userNameLabel.textColor = UIColor.whiteColor()
        _userNameLabel.shadowColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
        _userNameLabel.shadowOffset = CGSizeMake(1, 1)
        _userNameLabel.font = UIFont.systemFontOfSize(FontSizes.Caption.rawValue, weight: UIFontWeightBlack)
        
        _userNameLabel.translatesAutoresizingMaskIntoConstraints = false
        _userNameLabel.topAnchor.constraintEqualToAnchor(_userBackground.topAnchor, constant: _footerHeight / 6).active = true
        _userNameLabel.leadingAnchor.constraintEqualToAnchor(_userImage.trailingAnchor, constant: Spacing.xs.rawValue).active = true
    }
    
    private func addLocation() {
        _userLocationLabel.textColor = UIColor.whiteColor()
        _userLocationLabel.font = UIFont.systemFontOfSize(FontSizes.Caption.rawValue)
        _userLocationLabel.shadowColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
        _userLocationLabel.shadowOffset = CGSizeMake(1, 1)
        _userBackground.addSubview(_userLocationLabel)

        _userLocationLabel.translatesAutoresizingMaskIntoConstraints = false
        _userLocationLabel.bottomAnchor.constraintEqualToAnchor(_userBackground.bottomAnchor, constant: -_footerHeight / 6).active = true
        _userLocationLabel.leadingAnchor.constraintEqualToAnchor(_userNameLabel.leadingAnchor).active = true
    }
    
    private func addBio() {
        _userShortBioLabel.textColor = UIColor.whiteColor()
        _userShortBioLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        _userBackground.addSubview(_userShortBioLabel)
        
        _userShortBioLabel.translatesAutoresizingMaskIntoConstraints = false
        _userShortBioLabel.bottomAnchor.constraintEqualToAnchor(_userBackground.bottomAnchor, constant: -_footerHeight / 6).active = true
        _userShortBioLabel.leadingAnchor.constraintEqualToAnchor(_userNameLabel.leadingAnchor).active = true
    }
    
    private func addUserImage() {
        _userBackground.addSubview(_userImage)

        _userImage.translatesAutoresizingMaskIntoConstraints = false
        _userImage.contentMode = UIViewContentMode.ScaleAspectFill
        _userImage.clipsToBounds = true
        _userImage.image = nil
        
        _userImage.centerYAnchor.constraintEqualToAnchor(_userBackground.centerYAnchor).active = true
        _userImage.heightAnchor.constraintEqualToAnchor(_userBackground.heightAnchor, multiplier: 0.8).active = true
        _userImage.widthAnchor.constraintEqualToAnchor(_userImage.heightAnchor).active = true
        _userImage.leadingAnchor.constraintEqualToAnchor(_userBackground.leadingAnchor, constant: Spacing.xs.rawValue).active = true
        _userImage.layoutIfNeeded()
        
        _userImage.layer.cornerRadius = _userImage.bounds.height / 2
        _userImage.layer.masksToBounds = true
        _userImage.layer.shouldRasterize = true
        _userImage.layer.rasterizationScale = UIScreen.mainScreen().scale
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
    
    func toggleMenu() {
        if !_isShowingMenu {
            _showMenu = AnswerMenu()
            addSubview(_showMenu)
            
            _showMenu.translatesAutoresizingMaskIntoConstraints = false
            _showMenu.topAnchor.constraintEqualToAnchor(_headerBackground.bottomAnchor, constant: Spacing.s.rawValue).active = true
            _showMenu.widthAnchor.constraintEqualToAnchor(widthAnchor, multiplier: 2/5).active = true
            _showMenu.leadingAnchor.constraintEqualToAnchor(leadingAnchor).active = true
            _showMenu.heightAnchor.constraintEqualToAnchor(heightAnchor, multiplier: 1/4).active = true
            _showMenu.layoutIfNeeded()
            
            _showMenu.getButton(.AddAnswer).addTarget(self, action: #selector(handleAddAnswerTap), forControlEvents: UIControlEvents.TouchDown)
            _showMenu.getButton(.BrowseAnswers).addTarget(self, action: #selector(handleExploreTap), forControlEvents: UIControlEvents.TouchDown)
            
            _isShowingMenu = true

        } else {
            _showMenu.removeFromSuperview()
            _isShowingMenu = false
        }
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
        _bgShapeLayer = drawBgShape((_iconSize * 1.02) / 2, _stroke: _countdownTimerRadiusStroke)
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
