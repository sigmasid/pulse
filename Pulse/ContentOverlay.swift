//
//  AnswerOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/5/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class ContentOverlay: UIView {

    fileprivate var footerBackground = UIView()
    fileprivate var userTitles = PulseMenu(_axis: .vertical, _spacing: 0)
    
    fileprivate lazy var exploreAnswer = PulseButton()
    
    fileprivate var menu = PulseMenu(_axis: .horizontal, _spacing: Spacing.s.rawValue)
    fileprivate lazy var upVoteButton : PulseButton = PulseButton(size: .xSmall, type: .upvote, isRound: true, hasBackground: false)
    fileprivate lazy var downVoteButton : PulseButton = PulseButton(size: .xSmall, type: .downvote, isRound: true, hasBackground: false)
    fileprivate lazy var saveButton : PulseButton = PulseButton(size: .xSmall, type: .favorite, isRound: true, hasBackground: false)
    
    fileprivate let itemTagLabel = PaddingLabel()
    fileprivate let itemTitleLabel = PaddingLabel()
    
    fileprivate let userTitleLabel = UILabel()
    fileprivate let userSubtitleLabel = UILabel()
    fileprivate var userImage = PulseButton(size: .small, type: .blank, isRound: true, hasBackground: false, tint: .white)
    
    fileprivate var browseButton = PulseButton()
    fileprivate var messageButton = PulseButton()

    fileprivate let footerHeight : CGFloat = Spacing.xl.rawValue
    
    fileprivate var countdownTimerRadiusStroke : CGFloat = 3
    fileprivate let videoTimer = UIView()
    fileprivate var timeLeftShapeLayer = CAShapeLayer()
    fileprivate var bgShapeLayer = CAShapeLayer()
    
    weak var delegate : ItemDetailDelegate!
    
    internal enum AnswersButtonSelector: Int {
        case upvote, downvote, save, album
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, iconColor: UIColor, iconBackground: UIColor) {
        self.init(frame: frame)
        addFooterButton()
        addheaderBackground()
        addFooterBackground()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func point(inside point : CGPoint, with event : UIEvent?) -> Bool {
        for _view in self.subviews {
            
            if _view.isUserInteractionEnabled == true && _view.point(inside: convert(point, to: _view) , with: event) {
                return true
            }
        }
        return false
    }
    
    fileprivate func addFooterBackground() {
        addSubview(footerBackground)
        footerBackground.translatesAutoresizingMaskIntoConstraints = false
        
        footerBackground.bottomAnchor.constraint(equalTo: bottomAnchor, constant: Spacing.xxs.rawValue).isActive = true
        footerBackground.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        footerBackground.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        footerBackground.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        footerBackground.layoutIfNeeded()
        
        addFooterButton()
        addTitle()
    }
    
    fileprivate func addheaderBackground() {
        addSubview(userImage)
        addSubview(userTitles)
        addSubview(itemTagLabel)

        userImage.center = CGPoint(x: userImage.frame.width / 2 + Spacing.xs.rawValue,
                                   y: userImage.frame.width / 2 + Spacing.xs.rawValue)
        userImage.addTarget(self, action: #selector(handleProfileTap), for: .touchUpInside)
        userImage.contentMode = .scaleAspectFill
        userImage.clipsToBounds = true
        
        userTitles.translatesAutoresizingMaskIntoConstraints = false
        
        userTitles.centerYAnchor.constraint(equalTo: userImage.centerYAnchor).isActive = true
        userTitles.leadingAnchor.constraint(equalTo: userImage.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
        userTitles.layoutIfNeeded()
        
        let headerBackgroundTap = UITapGestureRecognizer(target: self, action: #selector(handleProfileTap))
        userTitles.addGestureRecognizer(headerBackgroundTap)
        
        userTitles.addArrangedSubview(userTitleLabel)
        userTitles.addArrangedSubview(userSubtitleLabel)

        userTitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .white, alignment: .left)
        userTitleLabel.setBlurredBackground()
        
        userSubtitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .white, alignment: .left)
        userSubtitleLabel.setBlurredBackground()
        
        itemTagLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightMedium, color: .white, alignment: .left)
        itemTagLabel.setBlurredBackground()
        
        itemTagLabel.translatesAutoresizingMaskIntoConstraints = false
        itemTagLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        itemTagLabel.centerYAnchor.constraint(equalTo: userImage.centerYAnchor).isActive = true
        itemTagLabel.layoutIfNeeded()
        
        addExploreAnswer()
    }
    
    fileprivate func addExploreAnswer() {
        
        exploreAnswer.isHidden = true
        
        addSubview(exploreAnswer)
        
        exploreAnswer.setTitle("Explore", for: .normal)
        exploreAnswer.setButtonFont(FontSizes.body2.rawValue, weight: UIFontWeightBold, color: .white, alignment: .right)
        exploreAnswer.titleLabel?.setBlurredBackground()
        
        exploreAnswer.translatesAutoresizingMaskIntoConstraints = false
        exploreAnswer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        exploreAnswer.centerYAnchor.constraint(equalTo: userImage.centerYAnchor).isActive = true
        
        let fontAttributes = [ NSFontAttributeName : UIFont.systemFont(ofSize: browseButton.titleLabel!.font.pointSize, weight: UIFontWeightBold)]
        let width = GlobalFunctions.getLabelWidth(title: exploreAnswer.titleLabel!.text!, fontAttributes: fontAttributes)
        exploreAnswer.widthAnchor.constraint(equalToConstant: width).isActive = true
        exploreAnswer.layoutIfNeeded()
        
        exploreAnswer.addTarget(self, action: #selector(handleExploreAnswerTap), for: UIControlEvents.touchDown)
    }
    
    ///Update question text
    fileprivate func addTitle() {
        addSubview(itemTitleLabel)
        
        itemTitleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        itemTitleLabel.setFont(FontSizes.body.rawValue, weight: UIFontWeightMedium, color: .white, alignment: .left)

        itemTitleLabel.numberOfLines = 0
        itemTitleLabel.lineBreakMode = .byWordWrapping
        
        itemTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        itemTitleLabel.bottomAnchor.constraint(equalTo: footerBackground.topAnchor).isActive = true
        itemTitleLabel.trailingAnchor.constraint(equalTo: footerBackground.trailingAnchor).isActive = true
        itemTitleLabel.leadingAnchor.constraint(equalTo: footerBackground.leadingAnchor).isActive = true
    }
    
    ///Add Icon in header
    func addFooterButton() {
        
        browseButton.setTitle("Browse", for: .normal)
        browseButton.setButtonFont(FontSizes.body2.rawValue, weight: UIFontWeightBold, color: .white, alignment: .right)
        browseButton.titleLabel?.setBlurredBackground()
        
        messageButton.setTitle("Message", for: .normal)
        messageButton.setButtonFont(FontSizes.body2.rawValue, weight: UIFontWeightBold, color: .white, alignment: .left)
        messageButton.titleLabel?.setBlurredBackground()
        
        footerBackground.addSubview(browseButton)
        footerBackground.addSubview(messageButton)
        
        browseButton.translatesAutoresizingMaskIntoConstraints = false
        browseButton.bottomAnchor.constraint(equalTo: footerBackground.bottomAnchor).isActive = true
        browseButton.heightAnchor.constraint(equalTo: footerBackground.heightAnchor).isActive = true
        browseButton.trailingAnchor.constraint(equalTo: footerBackground.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true

        let fontAttributes = [ NSFontAttributeName : UIFont.systemFont(ofSize: browseButton.titleLabel!.font.pointSize, weight: UIFontWeightBold)]
        let width = GlobalFunctions.getLabelWidth(title: browseButton.titleLabel!.text!, fontAttributes: fontAttributes)
        browseButton.widthAnchor.constraint(equalToConstant: width).isActive = true
        browseButton.layoutIfNeeded()

        messageButton.translatesAutoresizingMaskIntoConstraints = false
        messageButton.bottomAnchor.constraint(equalTo: footerBackground.bottomAnchor).isActive = true
        messageButton.heightAnchor.constraint(equalTo: footerBackground.heightAnchor).isActive = true
        messageButton.leadingAnchor.constraint(equalTo: footerBackground.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true

        let messageAttributes = [ NSFontAttributeName : UIFont.systemFont(ofSize: messageButton.titleLabel!.font.pointSize, weight: UIFontWeightBold)]
        let messageWidth = GlobalFunctions.getLabelWidth(title: messageButton.titleLabel!.text!, fontAttributes: messageAttributes)
        messageButton.widthAnchor.constraint(equalToConstant: messageWidth).isActive = true
        messageButton.layoutIfNeeded()
        
        browseButton.addTarget(self, action: #selector(handleExploreTap), for: .touchUpInside)
        browseButton.isExclusiveTouch = true
        
        messageButton.addTarget(self, action: #selector(handleSendMessage), for: .touchUpInside)
        messageButton.isExclusiveTouch = true
        
        addRestIcons()
    }
    
    fileprivate func addRestIcons() {
        footerBackground.addSubview(menu)
        
        menu.distribution = .fillEqually
        
        menu.translatesAutoresizingMaskIntoConstraints = false
        menu.centerYAnchor.constraint(equalTo: footerBackground.centerYAnchor).isActive = true
        menu.centerXAnchor.constraint(equalTo: footerBackground.centerXAnchor).isActive = true
        menu.widthAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue * 3 + Spacing.s.rawValue * 2).isActive = true
        menu.heightAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true

        menu.layoutIfNeeded()
        
        menu.addArrangedSubview(saveButton)
        menu.addArrangedSubview(upVoteButton)
        menu.addArrangedSubview(downVoteButton)
        
        downVoteButton.addTarget(self, action: #selector(handleDownvote), for: UIControlEvents.touchDown)
        upVoteButton.addTarget(self, action: #selector(handleUpvote), for: UIControlEvents.touchDown)
        saveButton.addTarget(self, action: #selector(handleFavorite), for: UIControlEvents.touchDown)
        
        menu.alpha = 0.7
    }
    
    func handleFavorite() {
        if delegate != nil {
            delegate.votedItem(.favorite)
            addVote(.favorite)
        }
    }
    
    func handleUpvote() {
        if delegate != nil {
            delegate.votedItem(.upvote)
            addVote(.upvote)
        }
    }
    
    func handleDownvote() {
        if delegate != nil {
            delegate.votedItem(.downvote)
            addVote(.downvote)
        }
    }
    
    func handleProfileTap() {
        if delegate != nil {
            delegate.userClickedProfile()
        }
    }
    
    func handleExploreTap() {
        if delegate != nil {
            delegate.userClickedBrowseItems()
        }
    }
    
    func handleExploreAnswerTap() {
        if delegate != nil {
            delegate.userClickedExpandItem()
        }
    }
    
    func handleSendMessage() {
        if delegate != nil {
            delegate.userClickedSendMessage()
        }
    }
    
    func itemSaved(type : VoteType) {
        switch type {
        case .downvote: downVoteButton.imageView?.tintColor = pulseRed
        case .upvote: upVoteButton.imageView?.tintColor = pulseRed
        case .favorite: saveButton.imageView?.tintColor = pulseRed
        }
    }
    
    
    
    func showExploreDetail() {
        exploreAnswer.setTitle("Explore", for: UIControlState())
        exploreAnswer.setEnabled()
        exploreAnswer.isHidden = false
    }
    
    func hideExploreDetail() {
        exploreAnswer.isHidden = true
    }
    
    func updateExploreDetail() {
        exploreAnswer.setTitle("Explore", for: .disabled)
        exploreAnswer.setDisabled()
    }
    
    /* PUBLIC SETTER FUNCTIONS */
    func setUserName(_ _userName : String?) {
        if let name = _userName {
            userTitleLabel.text = name.capitalized
        }
    }
    
    func setUserSubtitle(_ _userSubtitle : String?) {
        if let subtitle = _userSubtitle {
            userSubtitleLabel.text = subtitle.capitalized
        }
    }
    
    func setUserImage(_ image : UIImage?) {
        userImage.setBackgroundImage(image, for: .normal)
    }
    
    func setTitle(_ title : String) {
        itemTitleLabel.text = title
    }
    
    func clearButtons() {
        upVoteButton.imageView?.tintColor = .white
        downVoteButton.imageView?.tintColor = .white
        saveButton.imageView?.tintColor = .white
    }
    
    func setTagName(_ tagName : String?) {
        if let tagName = tagName {
            itemTagLabel.text = "#" + tagName.lowercased()
        }
    }
    
    /// Add clip countdown
    func addClipTimerCountdown() {
        let iconSize : CGFloat = IconSizes.small.rawValue

        addSubview(videoTimer)
        
        videoTimer.translatesAutoresizingMaskIntoConstraints = false
        videoTimer.centerYAnchor.constraint(equalTo: userImage.centerYAnchor, constant: iconSize / 2).isActive = true
        videoTimer.centerXAnchor.constraint(equalTo: userImage.centerXAnchor, constant: iconSize / 2).isActive = true
        videoTimer.widthAnchor.constraint(equalToConstant: iconSize).isActive = true
        videoTimer.heightAnchor.constraint(equalToConstant: iconSize).isActive = true
        
        // draw the countdown
        bgShapeLayer = drawBgShape(iconSize / 2, _stroke: countdownTimerRadiusStroke)
        timeLeftShapeLayer = drawTimeLeftShape(iconSize: iconSize)
        
        videoTimer.layer.addSublayer(bgShapeLayer)
        videoTimer.layer.addSublayer(timeLeftShapeLayer)
    }
    
    func startTimer(_ videoDuration : Double) {
        let strokeIt = CABasicAnimation(keyPath: "strokeEnd")
        strokeIt.fromValue = 0.0
        strokeIt.toValue = 1.0
        strokeIt.duration = videoDuration
        
        timeLeftShapeLayer.strokeColor = UIColor.white.cgColor
        timeLeftShapeLayer.add(strokeIt, forKey: "stroke")
    }
    
    func resetTimer() {
        timeLeftShapeLayer.strokeColor = UIColor.clear.cgColor
        timeLeftShapeLayer.strokeStart = 0.0
    }
    
    func drawBgShape(_ _radius : CGFloat, _stroke : CGFloat) -> CAShapeLayer {
        let bgShapeLayer = CAShapeLayer()
        bgShapeLayer.path = UIBezierPath(arcCenter: CGPoint(x: 0 , y: 0), radius:
            _radius, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).cgPath
        bgShapeLayer.strokeColor = UIColor.clear.cgColor
        bgShapeLayer.fillColor = UIColor.clear.cgColor
        bgShapeLayer.opacity = 0.5
        bgShapeLayer.lineWidth = _stroke
        
        return bgShapeLayer
    }
    
    func drawTimeLeftShape(iconSize : CGFloat) -> CAShapeLayer {
        let timeLeftShapeLayer = CAShapeLayer()
        timeLeftShapeLayer.path = UIBezierPath(arcCenter: CGPoint(x: 0, y: 0),
                                               radius: iconSize / 2, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).cgPath
        timeLeftShapeLayer.strokeColor = UIColor.clear.cgColor
        timeLeftShapeLayer.fillColor = UIColor.clear.cgColor
        timeLeftShapeLayer.lineWidth = countdownTimerRadiusStroke
        //timeLeftShapeLayer.opacity = 0.7
        
        return timeLeftShapeLayer
    }
    
    /* ADD VOTE ANIMATION */
    func addVote(_ _vote : VoteType) {
        var _voteImage : UIImageView!
        
        switch _vote {
        case .favorite:
            _voteImage = UIImageView(image: UIImage(named: "save"))
            addSubview(_voteImage)
            _voteImage.translatesAutoresizingMaskIntoConstraints = false
            _voteImage.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor).isActive = true
            _voteImage.centerXAnchor.constraint(equalTo: saveButton.centerXAnchor).isActive = true
        case .upvote:
            _voteImage = UIImageView(image: UIImage(named: "upvote"))
            addSubview(_voteImage)
            _voteImage.translatesAutoresizingMaskIntoConstraints = false
            _voteImage.centerYAnchor.constraint(equalTo: upVoteButton.centerYAnchor).isActive = true
            _voteImage.centerXAnchor.constraint(equalTo: upVoteButton.centerXAnchor).isActive = true
        case .downvote:
            _voteImage = UIImageView(image: UIImage(named: "downvote"))
            addSubview(_voteImage)
            _voteImage.translatesAutoresizingMaskIntoConstraints = false
            
            _voteImage.centerYAnchor.constraint(equalTo: downVoteButton.centerYAnchor).isActive = true
            _voteImage.centerXAnchor.constraint(equalTo: downVoteButton.centerXAnchor).isActive = true
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
