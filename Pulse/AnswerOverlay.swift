//
//  AnswerOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/5/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AnswerOverlay: UIView {

    private var _questionBackground = UIView()
    private var _userBackground = UIView()
    
    private var _exploreAnswer = UIButton()
    private var _upvoteButton = UIButton()
    private var _downvoteButton = UIButton()
    private var _saveButton = UIButton()
    
    private let _tagLabel = PaddingLabel()
    private let _questionLabel = PaddingLabel()
    
    private let _userTitleLabel = UILabel()
    private let _userSubtitleLabel = UILabel()
    private var _userImage = UIImageView()
    
    private var _showMenu : AnswerMenu!
    private var _isShowingMenu = false
    private var _iconContainer : IconContainer!

    private let _footerHeight : CGFloat = Spacing.xl.rawValue
    private var _iconSize : CGFloat = IconSizes.Medium.rawValue
    
    private var _countdownTimerRadiusStroke : CGFloat = 3
    private let _videoTimer = UIView()
    private var _timeLeftShapeLayer = CAShapeLayer()
    private var _bgShapeLayer = CAShapeLayer()
    
    weak var delegate : answerDetailDelegate!
    
    internal enum AnswersButtonSelector: Int {
        case Upvote, Downvote, Save, Album
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, iconColor: UIColor, iconBackground: UIColor) {
        self.init(frame: frame)
        addIcon(iconColor, backgroundColor: iconBackground)
        addUserBackground()
        addQuestionBackground()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func addQuestionBackground() {
        addSubview(_questionBackground)
        _questionBackground.translatesAutoresizingMaskIntoConstraints = false
        
        _questionBackground.bottomAnchor.constraintEqualToAnchor(bottomAnchor, constant: 0.0).active = true
        _questionBackground.trailingAnchor.constraintEqualToAnchor(_iconContainer.leadingAnchor).active = true
        _questionBackground.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: 0.0).active = true
        _questionBackground.heightAnchor.constraintEqualToAnchor(heightAnchor, multiplier: 0.1).active = true
        _questionBackground.layoutIfNeeded()
        
        addTag()
        addQuestion()

    }
    
    private func addUserBackground() {
        addSubview(_userBackground)
        
        _userBackground.translatesAutoresizingMaskIntoConstraints = false
        
        _userBackground.topAnchor.constraintEqualToAnchor(topAnchor, constant: Spacing.xs.rawValue).active = true
        _userBackground.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        _userBackground.leadingAnchor.constraintEqualToAnchor(leadingAnchor).active = true
        _userBackground.heightAnchor.constraintEqualToConstant(_footerHeight).active = true
        _userBackground.layoutIfNeeded()
        
        let userBackgroundTap = UITapGestureRecognizer(target: self, action: #selector(handleProfileTap))
        _userBackground.addGestureRecognizer(userBackgroundTap)
        
        addUserImage()
        addUserTitle()
        addUserSubtitle()
        addExploreAnswer()
    }
    
    private func addUserTitle() {
        _userBackground.addSubview(_userTitleLabel)
        
        _userTitleLabel.textColor = UIColor.whiteColor()
        _userTitleLabel.shadowColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
        _userTitleLabel.shadowOffset = CGSizeMake(1, 1)
        _userTitleLabel.font = UIFont.systemFontOfSize(FontSizes.Caption.rawValue, weight: UIFontWeightBlack)
        
        _userTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        _userTitleLabel.topAnchor.constraintEqualToAnchor(_userBackground.topAnchor, constant: _footerHeight / 5).active = true
        _userTitleLabel.leadingAnchor.constraintEqualToAnchor(_userImage.trailingAnchor, constant: Spacing.xs.rawValue).active = true
    }
    
    private func addUserSubtitle() {
        _userSubtitleLabel.textColor = UIColor.whiteColor()
        _userSubtitleLabel.font = UIFont.systemFontOfSize(FontSizes.Caption.rawValue)
        _userSubtitleLabel.shadowColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
        _userSubtitleLabel.shadowOffset = CGSizeMake(1, 1)
        _userBackground.addSubview(_userSubtitleLabel)
        
        _userSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        _userSubtitleLabel.bottomAnchor.constraintEqualToAnchor(_userBackground.bottomAnchor, constant: -_footerHeight / 5).active = true
        _userSubtitleLabel.leadingAnchor.constraintEqualToAnchor(_userTitleLabel.leadingAnchor).active = true
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

    
    private func addExploreAnswer() {
        _exploreAnswer.hidden = true
        addSubview(_exploreAnswer)
        
        _exploreAnswer.translatesAutoresizingMaskIntoConstraints = false
        _exploreAnswer.topAnchor.constraintEqualToAnchor(topAnchor, constant: Spacing.xs.rawValue).active = true
        _exploreAnswer.widthAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue).active = true
        _exploreAnswer.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: -Spacing.xs.rawValue).active = true
        _exploreAnswer.heightAnchor.constraintEqualToAnchor(_exploreAnswer.widthAnchor).active = true
        _exploreAnswer.layoutIfNeeded()
        
        _exploreAnswer.makeRound()
        _exploreAnswer.titleLabel?.lineBreakMode = .ByWordWrapping
        _exploreAnswer.titleLabel?.font = UIFont.systemFontOfSize(FontSizes.Caption2.rawValue, weight: UIFontWeightBold)
        
        _exploreAnswer.addTarget(self, action: #selector(handleExploreAnswerTap), forControlEvents: UIControlEvents.TouchDown)
    }
    
    ///Update question text
    private func addQuestion() {
        _questionBackground.addSubview(_questionLabel)
        _questionLabel.adjustsFontSizeToFitWidth = true
        
        _questionLabel.textColor = UIColor.whiteColor()
        _questionLabel.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        _questionLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
        _questionLabel.textAlignment = .Left
        _questionLabel.numberOfLines = 0
        _questionLabel.lineBreakMode = .ByWordWrapping
        
        _questionLabel.translatesAutoresizingMaskIntoConstraints = false
        _questionLabel.bottomAnchor.constraintEqualToAnchor(_tagLabel.topAnchor, constant: 1.0).active = true
        _questionLabel.trailingAnchor.constraintEqualToAnchor(_questionBackground.trailingAnchor, constant: -Spacing.xs.rawValue).active = true
        _questionLabel.leadingAnchor.constraintEqualToAnchor(_tagLabel.leadingAnchor).active = true
    
    }
    
    ///Update Tag in header
    private func addTag() {
        _questionBackground.addSubview(_tagLabel)
        
        _tagLabel.textColor = UIColor.whiteColor()
        _tagLabel.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        _tagLabel.font = UIFont.boldSystemFontOfSize(FontSizes.Caption.rawValue)
        _tagLabel.textAlignment = .Left
        
        _tagLabel.translatesAutoresizingMaskIntoConstraints = false
        _tagLabel.centerYAnchor.constraintEqualToAnchor(_questionBackground.centerYAnchor, constant: _questionBackground.frame.size.height * (1/6)).active = true
        _tagLabel.leadingAnchor.constraintEqualToAnchor(_questionBackground.leadingAnchor, constant: Spacing.xs.rawValue).active = true
        _tagLabel.layoutIfNeeded()
    }
    
    ///Add Icon in header
    func addIcon(iconColor: UIColor, backgroundColor : UIColor) {
        _iconContainer = IconContainer(frame: CGRectMake(0,0,IconSizes.Medium.rawValue, IconSizes.Medium.rawValue + Spacing.m.rawValue), iconColor: iconColor, iconBackgroundColor: backgroundColor.colorWithAlphaComponent(0.7))
        addSubview(_iconContainer)
        
        _iconContainer.translatesAutoresizingMaskIntoConstraints = false
        _iconContainer.bottomAnchor.constraintEqualToAnchor(bottomAnchor, constant: -Spacing.s.rawValue).active = true
        _iconContainer.heightAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue + Spacing.m.rawValue).active = true
        _iconContainer.widthAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue).active = true
        _iconContainer.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: -Spacing.xs.rawValue).active = true
        _iconContainer.layoutIfNeeded()

        let iconTap = UITapGestureRecognizer(target: self, action: #selector(handleShowMenu))
        _iconContainer.addGestureRecognizer(iconTap)
        
        addRestIcons()
    }
    
    private func addRestIcons() {
        addSubview(_upvoteButton)
        addSubview(_downvoteButton)
        addSubview(_saveButton)
        
        _upvoteButton.setImage(UIImage(named: "upvote"), forState: .Normal)
        _downvoteButton.setImage(UIImage(named: "downvote"), forState: .Normal)
        _saveButton.setImage(UIImage(named: "save"), forState: .Normal)
        
        _upvoteButton.alpha = 0.5
        _downvoteButton.alpha = 0.5
        _saveButton.alpha = 0.5
        
        _downvoteButton.translatesAutoresizingMaskIntoConstraints = false
        _downvoteButton.bottomAnchor.constraintEqualToAnchor(_iconContainer.topAnchor).active = true
        _downvoteButton.centerXAnchor.constraintEqualToAnchor(_iconContainer.centerXAnchor).active = true
        _downvoteButton.widthAnchor.constraintEqualToConstant(IconSizes.Small.rawValue).active = true
        _downvoteButton.heightAnchor.constraintEqualToAnchor(_downvoteButton.widthAnchor).active = true
        
        _upvoteButton.translatesAutoresizingMaskIntoConstraints = false
        _upvoteButton.bottomAnchor.constraintEqualToAnchor(_downvoteButton.topAnchor, constant: -Spacing.s.rawValue).active = true
        _upvoteButton.centerXAnchor.constraintEqualToAnchor(_iconContainer.centerXAnchor).active = true
        _upvoteButton.widthAnchor.constraintEqualToConstant(IconSizes.Small.rawValue).active = true
        _upvoteButton.heightAnchor.constraintEqualToAnchor(_upvoteButton.widthAnchor).active = true
        
        _saveButton.translatesAutoresizingMaskIntoConstraints = false
        _saveButton.bottomAnchor.constraintEqualToAnchor(_upvoteButton.topAnchor, constant: -Spacing.s.rawValue).active = true
        _saveButton.centerXAnchor.constraintEqualToAnchor(_iconContainer.centerXAnchor).active = true
        _saveButton.widthAnchor.constraintEqualToConstant(IconSizes.Small.rawValue).active = true
        _saveButton.heightAnchor.constraintEqualToAnchor(_saveButton.widthAnchor).active = true
        
        _downvoteButton.addTarget(self, action: #selector(handleDownvote), forControlEvents: UIControlEvents.TouchDown)
        _upvoteButton.addTarget(self, action: #selector(handleUpvote), forControlEvents: UIControlEvents.TouchDown)
        _saveButton.addTarget(self, action: #selector(handleSave), forControlEvents: UIControlEvents.TouchDown)
    }
    
    func handleSave() {

    }
    
    func handleUpvote() {
        if delegate != nil {
            delegate.votedAnswer(.Upvote)
            addVote(.Upvote)
        }
    }
    
    func handleDownvote() {
        if delegate != nil {
            delegate.votedAnswer(.Downvote)
            addVote(.Downvote)
        }
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
    
    func handleExploreAnswerTap() {
        if delegate != nil {
            delegate.userClickedExpandAnswer()
        }
    }
    
    func getHeaderHeight() -> CGFloat {
        return _questionBackground.bounds.height
    }
    
    func showExploreAnswerDetail() {
        _exploreAnswer.setTitle("EXPLORE ANSWER", forState: .Normal)
        _exploreAnswer.setEnabled()
        _exploreAnswer.hidden = false
    }
    
    func hideExploreAnswerDetail() {
        _exploreAnswer.hidden = true
    }
    
    func updateExploreAnswerDetail() {
        _exploreAnswer.setTitle("EXPLORING", forState: .Disabled)
        _exploreAnswer.setDisabled()
    }
    
    /* PUBLIC SETTER FUNCTIONS */
    func setUserName(_userName : String?) {
        _userTitleLabel.text = _userName
    }
    
    func setUserSubtitle(_userSubtitle : String?) {
        _userSubtitleLabel.text = _userSubtitle
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
            _showMenu.bottomAnchor.constraintEqualToAnchor(_iconContainer.topAnchor).active = true
            _showMenu.widthAnchor.constraintEqualToAnchor(widthAnchor, multiplier: 2/5).active = true
            _showMenu.trailingAnchor.constraintEqualToAnchor(trailingAnchor).active = true
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
    
    /// Add clip countdown
    func addClipTimerCountdown() {
        addSubview(_videoTimer)
        
        _videoTimer.translatesAutoresizingMaskIntoConstraints = false
        _videoTimer.centerXAnchor.constraintEqualToAnchor(_iconContainer.centerXAnchor, constant: _iconSize / 2).active = true
        _videoTimer.widthAnchor.constraintEqualToConstant(_iconSize).active = true
        _videoTimer.centerYAnchor.constraintEqualToAnchor(_iconContainer.centerYAnchor, constant: _iconSize / 2 + Spacing.m.rawValue / 2).active = true
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
        var _voteImage : UIImageView!
        
        switch _vote {
        case .Upvote:
            print("case upvote")
            _voteImage = UIImageView(image: UIImage(named: "upvote"))
            addSubview(_voteImage)
            _voteImage.translatesAutoresizingMaskIntoConstraints = false
            _voteImage.centerYAnchor.constraintEqualToAnchor(_upvoteButton.centerYAnchor).active = true
            _voteImage.centerXAnchor.constraintEqualToAnchor(_upvoteButton.centerXAnchor).active = true
        case .Downvote:
            _voteImage = UIImageView(image: UIImage(named: "downvote"))
            addSubview(_voteImage)
            _voteImage.translatesAutoresizingMaskIntoConstraints = false
            
            _voteImage.centerYAnchor.constraintEqualToAnchor(_downvoteButton.centerYAnchor).active = true
            _voteImage.centerXAnchor.constraintEqualToAnchor(_downvoteButton.centerXAnchor).active = true
        }
        
        _voteImage.widthAnchor.constraintEqualToConstant(IconSizes.Small.rawValue).active = true
        _voteImage.heightAnchor.constraintEqualToAnchor(_voteImage.widthAnchor).active = true
        
        let xForm = CGAffineTransformScale(CGAffineTransformIdentity, 3.0, 3.0)
        UIView.animateWithDuration(0.5, animations: { _voteImage.transform = xForm; _voteImage.alpha = 0 } , completion: {(value: Bool) in
            _voteImage.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0)
            _voteImage.removeFromSuperview()
        })
    }
}
