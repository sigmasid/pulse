//
//  AnswerOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/5/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AnswerOverlay: UIView {

    fileprivate var _questionBackground = UIView()
    fileprivate var _userBackground = UIView()
    
    fileprivate var _exploreAnswer = UIButton()
    fileprivate var _upvoteButton = UIButton()
    fileprivate var _downvoteButton = UIButton()
    fileprivate var _saveButton = UIButton()
    
    fileprivate let _tagLabel = PaddingLabel()
    fileprivate let _questionLabel = PaddingLabel()
    
    fileprivate let _userTitleLabel = UILabel()
    fileprivate let _userSubtitleLabel = UILabel()
    fileprivate var _userImage = UIImageView()
    
    fileprivate var _showMenu : PulseMenu!
    fileprivate var _isShowingMenu = false
    fileprivate var _iconContainer : IconContainer!
    
    fileprivate var addAnswer : PulseButton!
    fileprivate var browseAnswers : PulseButton!

    fileprivate let _footerHeight : CGFloat = Spacing.xl.rawValue
    fileprivate var _iconSize : CGFloat = IconSizes.medium.rawValue
    
    fileprivate var _countdownTimerRadiusStroke : CGFloat = 3
    fileprivate let _videoTimer = UIView()
    fileprivate var _timeLeftShapeLayer = CAShapeLayer()
    fileprivate var _bgShapeLayer = CAShapeLayer()
    
    weak var delegate : answerDetailDelegate!
    
    internal enum AnswersButtonSelector: Int {
        case upvote, downvote, save, album
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
    
    fileprivate func addQuestionBackground() {
        addSubview(_questionBackground)
        _questionBackground.translatesAutoresizingMaskIntoConstraints = false
        
        _questionBackground.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0.0).isActive = true
        _questionBackground.trailingAnchor.constraint(equalTo: _iconContainer.leadingAnchor).isActive = true
        _questionBackground.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0.0).isActive = true
        _questionBackground.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.1).isActive = true
        _questionBackground.layoutIfNeeded()
        
        addTag()
        addQuestion()

    }
    
    fileprivate func addUserBackground() {
        addSubview(_userBackground)
        
        _userBackground.translatesAutoresizingMaskIntoConstraints = false
        
        _userBackground.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.xs.rawValue).isActive = true
        _userBackground.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        _userBackground.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        _userBackground.heightAnchor.constraint(equalToConstant: _footerHeight).isActive = true
        _userBackground.layoutIfNeeded()
        
        let userBackgroundTap = UITapGestureRecognizer(target: self, action: #selector(handleProfileTap))
        _userBackground.addGestureRecognizer(userBackgroundTap)
        
        addUserImage()
        addUserTitle()
        addUserSubtitle()
        addExploreAnswer()
    }
    
    fileprivate func addUserTitle() {
        _userBackground.addSubview(_userTitleLabel)
        
        _userTitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .white, alignment: .left)
        _userTitleLabel.setBlurredBackground()

        _userTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        _userTitleLabel.topAnchor.constraint(equalTo: _userBackground.topAnchor, constant: _footerHeight / 5).isActive = true
        _userTitleLabel.leadingAnchor.constraint(equalTo: _userImage.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
    }
    
    fileprivate func addUserSubtitle() {
        _userBackground.addSubview(_userSubtitleLabel)
        
        _userSubtitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .white, alignment: .left)
        _userSubtitleLabel.setBlurredBackground()
        
        _userSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        _userSubtitleLabel.bottomAnchor.constraint(equalTo: _userBackground.bottomAnchor, constant: -_footerHeight / 5).isActive = true
        _userSubtitleLabel.leadingAnchor.constraint(equalTo: _userTitleLabel.leadingAnchor).isActive = true
    }
    
    fileprivate func addUserImage() {
        _userBackground.addSubview(_userImage)
        
        _userImage.translatesAutoresizingMaskIntoConstraints = false
        _userImage.contentMode = UIViewContentMode.scaleAspectFill
        _userImage.clipsToBounds = true
        _userImage.image = nil
        
        _userImage.centerYAnchor.constraint(equalTo: _userBackground.centerYAnchor).isActive = true
        _userImage.heightAnchor.constraint(equalTo: _userBackground.heightAnchor, multiplier: 0.8).isActive = true
        _userImage.widthAnchor.constraint(equalTo: _userImage.heightAnchor).isActive = true
        _userImage.leadingAnchor.constraint(equalTo: _userBackground.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        _userImage.layoutIfNeeded()
        
        _userImage.layer.cornerRadius = _userImage.bounds.height / 2
        _userImage.layer.masksToBounds = true
        _userImage.layer.shouldRasterize = true
        _userImage.layer.rasterizationScale = UIScreen.main.scale
    }

    
    fileprivate func addExploreAnswer() {
        _exploreAnswer.isHidden = true
        addSubview(_exploreAnswer)
        
        _exploreAnswer.translatesAutoresizingMaskIntoConstraints = false
        _exploreAnswer.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.xs.rawValue).isActive = true
        _exploreAnswer.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        _exploreAnswer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        _exploreAnswer.heightAnchor.constraint(equalTo: _exploreAnswer.widthAnchor).isActive = true
        _exploreAnswer.layoutIfNeeded()
        
        _exploreAnswer.makeRound()
        _exploreAnswer.titleLabel?.lineBreakMode = .byWordWrapping
        _exploreAnswer.titleLabel?.font = UIFont.systemFont(ofSize: FontSizes.caption2.rawValue, weight: UIFontWeightBold)
        
        _exploreAnswer.addTarget(self, action: #selector(handleExploreAnswerTap), for: UIControlEvents.touchDown)
    }
    
    ///Update question text
    fileprivate func addQuestion() {
        _questionBackground.addSubview(_questionLabel)
        _questionLabel.adjustsFontSizeToFitWidth = true
        _questionLabel.setFont(FontSizes.body.rawValue, weight: UIFontWeightMedium, color: .white, alignment: .left)
        _questionLabel.setBlurredBackground()

        _questionLabel.numberOfLines = 0
        _questionLabel.lineBreakMode = .byWordWrapping
        
        _questionLabel.translatesAutoresizingMaskIntoConstraints = false
        _questionLabel.bottomAnchor.constraint(equalTo: _tagLabel.topAnchor).isActive = true
        _questionLabel.trailingAnchor.constraint(equalTo: _questionBackground.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        _questionLabel.leadingAnchor.constraint(equalTo: _tagLabel.leadingAnchor).isActive = true
    
    }
    
    ///Update Tag in header
    fileprivate func addTag() {
        _questionBackground.addSubview(_tagLabel)
        _tagLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightMedium, color: .white, alignment: .left)
        _tagLabel.setBlurredBackground()
        
        _tagLabel.translatesAutoresizingMaskIntoConstraints = false
        _tagLabel.centerYAnchor.constraint(equalTo: _questionBackground.centerYAnchor, constant: _questionBackground.frame.size.height * (1/6)).isActive = true
        _tagLabel.leadingAnchor.constraint(equalTo: _questionBackground.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        _tagLabel.layoutIfNeeded()
    }
    
    ///Add Icon in header
    func addIcon(_ iconColor: UIColor, backgroundColor : UIColor) {
        _iconContainer = IconContainer(frame: CGRect(x: 0,y: 0,width: IconSizes.medium.rawValue, height: IconSizes.medium.rawValue + Spacing.m.rawValue), iconColor: iconColor, iconBackgroundColor: backgroundColor.withAlphaComponent(0.7))
        addSubview(_iconContainer)
        
        _iconContainer.translatesAutoresizingMaskIntoConstraints = false
        _iconContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.s.rawValue).isActive = true
        _iconContainer.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue + Spacing.m.rawValue).isActive = true
        _iconContainer.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        _iconContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        _iconContainer.layoutIfNeeded()

        let iconTap = UITapGestureRecognizer(target: self, action: #selector(handleShowMenu))
        _iconContainer.addGestureRecognizer(iconTap)
        
        addRestIcons()
    }
    
    fileprivate func addRestIcons() {
        addSubview(_upvoteButton)
        addSubview(_downvoteButton)
        addSubview(_saveButton)
        
        _upvoteButton.setImage(UIImage(named: "upvote"), for: UIControlState())
        _downvoteButton.setImage(UIImage(named: "downvote"), for: UIControlState())
        _saveButton.setImage(UIImage(named: "save"), for: UIControlState())
        
        _upvoteButton.alpha = 0.5
        _downvoteButton.alpha = 0.5
        _saveButton.alpha = 0.5
        
        _downvoteButton.translatesAutoresizingMaskIntoConstraints = false
        _downvoteButton.bottomAnchor.constraint(equalTo: _iconContainer.topAnchor).isActive = true
        _downvoteButton.centerXAnchor.constraint(equalTo: _iconContainer.centerXAnchor).isActive = true
        _downvoteButton.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        _downvoteButton.heightAnchor.constraint(equalTo: _downvoteButton.widthAnchor).isActive = true
        
        _upvoteButton.translatesAutoresizingMaskIntoConstraints = false
        _upvoteButton.bottomAnchor.constraint(equalTo: _downvoteButton.topAnchor, constant: -Spacing.s.rawValue).isActive = true
        _upvoteButton.centerXAnchor.constraint(equalTo: _iconContainer.centerXAnchor).isActive = true
        _upvoteButton.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        _upvoteButton.heightAnchor.constraint(equalTo: _upvoteButton.widthAnchor).isActive = true
        
        _saveButton.translatesAutoresizingMaskIntoConstraints = false
        _saveButton.bottomAnchor.constraint(equalTo: _upvoteButton.topAnchor, constant: -Spacing.s.rawValue).isActive = true
        _saveButton.centerXAnchor.constraint(equalTo: _iconContainer.centerXAnchor).isActive = true
        _saveButton.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        _saveButton.heightAnchor.constraint(equalTo: _saveButton.widthAnchor).isActive = true
        
        _downvoteButton.addTarget(self, action: #selector(handleDownvote), for: UIControlEvents.touchDown)
        _upvoteButton.addTarget(self, action: #selector(handleUpvote), for: UIControlEvents.touchDown)
        _saveButton.addTarget(self, action: #selector(handleSave), for: UIControlEvents.touchDown)
    }
    
    func handleSave() {

    }
    
    func handleUpvote() {
        if delegate != nil {
            delegate.votedAnswer(.upvote)
            addVote(.upvote)
        }
    }
    
    func handleDownvote() {
        if delegate != nil {
            delegate.votedAnswer(.downvote)
            addVote(.downvote)
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
        _exploreAnswer.setTitle("EXPLORE ANSWER", for: UIControlState())
        _exploreAnswer.setEnabled()
        _exploreAnswer.isHidden = false
    }
    
    func hideExploreAnswerDetail() {
        _exploreAnswer.isHidden = true
    }
    
    func updateExploreAnswerDetail() {
        _exploreAnswer.setTitle("EXPLORING", for: .disabled)
        _exploreAnswer.setDisabled()
    }
    
    /* PUBLIC SETTER FUNCTIONS */
    func setUserName(_ _userName : String?) {
        _userTitleLabel.text = _userName
    }
    
    func setUserSubtitle(_ _userSubtitle : String?) {
        _userSubtitleLabel.text = _userSubtitle
    }
    
    func setUserImage(_ image : UIImage?) {
        _userImage.image = image
    }
    
    func getUserBackground() -> UIView {
        return _userBackground
    }
    
    func setQuestion(_ question : String) {
        _questionLabel.text = question
    }
    
    func setTagName(_ tagName : String) {
        _tagLabel.text = "#" + tagName.uppercased()
    }
    
    func toggleMenu() {
        if !_isShowingMenu {
            _showMenu = PulseMenu()
            
            addAnswer = PulseButton(size: ButtonSizes.small, type: .addCircle, isRound: false, hasBackground: false)
            browseAnswers = PulseButton(size: ButtonSizes.small, type: .browseCircle, isRound: false, hasBackground: false)
            addAnswer.tintColor = pulseBlue
            browseAnswers.tintColor = pulseBlue
            
            addSubview(_showMenu)

            _showMenu.translatesAutoresizingMaskIntoConstraints = false
            _showMenu.bottomAnchor.constraint(equalTo: _iconContainer.topAnchor).isActive = true
            _showMenu.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 2/5).isActive = true
            _showMenu.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
            _showMenu.layoutIfNeeded()
            
            _showMenu.addArrangedSubview(addAnswer)
            _showMenu.addArrangedSubview(browseAnswers)
            
            addAnswer.setReversedTitle("Add Answer", for: UIControlState())
            browseAnswers.setReversedTitle("Browse Answers", for: UIControlState())

            addAnswer.addTarget(self, action: #selector(handleAddAnswerTap), for: UIControlEvents.touchDown)
            browseAnswers.addTarget(self, action: #selector(handleExploreTap), for: UIControlEvents.touchDown)
            
            _isShowingMenu = true

        } else {
            _showMenu.removeFromSuperview()
            addAnswer.removeFromSuperview()
            browseAnswers.removeFromSuperview()
            
            _isShowingMenu = false
        }
    }
    
    /// Add clip countdown
    func addClipTimerCountdown() {
        addSubview(_videoTimer)
        
        _videoTimer.translatesAutoresizingMaskIntoConstraints = false
        _videoTimer.centerXAnchor.constraint(equalTo: _iconContainer.centerXAnchor, constant: _iconSize / 2).isActive = true
        _videoTimer.widthAnchor.constraint(equalToConstant: _iconSize).isActive = true
        _videoTimer.centerYAnchor.constraint(equalTo: _iconContainer.centerYAnchor, constant: _iconSize / 2 + Spacing.m.rawValue / 2).isActive = true
        _videoTimer.heightAnchor.constraint(equalToConstant: _iconSize).isActive = true
        
        // draw the countdown
        _bgShapeLayer = drawBgShape((_iconSize * 1.02) / 2, _stroke: _countdownTimerRadiusStroke)
        _timeLeftShapeLayer = drawTimeLeftShape()
        
        _videoTimer.layer.addSublayer(_bgShapeLayer)
        _videoTimer.layer.addSublayer(_timeLeftShapeLayer)
    }
    
    func startTimer(_ videoDuration : Double) {
        let strokeIt = CABasicAnimation(keyPath: "strokeEnd")
        strokeIt.fromValue = 0.0
        strokeIt.toValue = 1.0
        strokeIt.duration = videoDuration
        
        _timeLeftShapeLayer.add(strokeIt, forKey: "stroke")
    }
    
    func resetTimer() {
        _timeLeftShapeLayer.strokeStart = 0.0
    }
    
    func drawBgShape(_ _radius : CGFloat, _stroke : CGFloat) -> CAShapeLayer {
        let bgShapeLayer = CAShapeLayer()
        bgShapeLayer.path = UIBezierPath(arcCenter: CGPoint(x: 0 , y: 0), radius:
            _radius, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).cgPath
        bgShapeLayer.strokeColor = UIColor.white.cgColor
        bgShapeLayer.fillColor = UIColor.clear.cgColor
        //bgShapeLayer.opacity = 0.7
        bgShapeLayer.lineWidth = _stroke
        
        return bgShapeLayer
    }
    
    func drawTimeLeftShape() -> CAShapeLayer {
        let timeLeftShapeLayer = CAShapeLayer()
        timeLeftShapeLayer.path = UIBezierPath(arcCenter: CGPoint(x: 0, y: 0), radius:
            _iconSize / 2, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).cgPath
        timeLeftShapeLayer.strokeColor = pulseBlue.cgColor
        timeLeftShapeLayer.fillColor = UIColor.clear.cgColor
        timeLeftShapeLayer.lineWidth = _countdownTimerRadiusStroke
        //timeLeftShapeLayer.opacity = 0.7
        
        return timeLeftShapeLayer
    }
    
    /* ADD VOTE ANIMATION */
    func addVote(_ _vote : AnswerVoteType) {
        var _voteImage : UIImageView!
        
        switch _vote {
        case .upvote:
            print("case upvote")
            _voteImage = UIImageView(image: UIImage(named: "upvote"))
            addSubview(_voteImage)
            _voteImage.translatesAutoresizingMaskIntoConstraints = false
            _voteImage.centerYAnchor.constraint(equalTo: _upvoteButton.centerYAnchor).isActive = true
            _voteImage.centerXAnchor.constraint(equalTo: _upvoteButton.centerXAnchor).isActive = true
        case .downvote:
            _voteImage = UIImageView(image: UIImage(named: "downvote"))
            addSubview(_voteImage)
            _voteImage.translatesAutoresizingMaskIntoConstraints = false
            
            _voteImage.centerYAnchor.constraint(equalTo: _downvoteButton.centerYAnchor).isActive = true
            _voteImage.centerXAnchor.constraint(equalTo: _downvoteButton.centerXAnchor).isActive = true
        }
        
        _voteImage.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        _voteImage.heightAnchor.constraint(equalTo: _voteImage.widthAnchor).isActive = true
        
        let xForm = CGAffineTransform.identity.scaledBy(x: 3.0, y: 3.0)
        UIView.animate(withDuration: 0.5, animations: { _voteImage.transform = xForm; _voteImage.alpha = 0 } , completion: {(value: Bool) in
            _voteImage.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
            _voteImage.removeFromSuperview()
        })
    }
}
