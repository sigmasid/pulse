//
//  AnswerOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/5/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AnswerOverlay: UIView {

    fileprivate var questionBackground = UIView()
    fileprivate var userBackground = UIView()
    
    fileprivate var exploreAnswer : PulseButton!
    
    fileprivate var answerMenu = PulseMenu(_axis: .vertical, _spacing: Spacing.s.rawValue)
    fileprivate lazy var upVoteButton : PulseButton = PulseButton(size: .small, type: .upvote, isRound: true, hasBackground: false)
    fileprivate lazy var downVoteButton : PulseButton = PulseButton(size: .small, type: .downvote, isRound: true, hasBackground: false)
    fileprivate lazy var saveButton : PulseButton = PulseButton(size: .small, type: .favorite, isRound: true, hasBackground: false)
    
    fileprivate let tagLabel = PaddingLabel()
    fileprivate let questionLabel = PaddingLabel()
    
    fileprivate let userTitleLabel = UILabel()
    fileprivate let userSubtitleLabel = UILabel()
    fileprivate var userImage = UIImageView()
    
    fileprivate var iconContainer : IconContainer!

    fileprivate let footerHeight : CGFloat = Spacing.xl.rawValue
    fileprivate var iconSize : CGFloat = IconSizes.medium.rawValue
    
    fileprivate var countdownTimerRadiusStroke : CGFloat = 3
    fileprivate let videoTimer = UIView()
    fileprivate var timeLeftShapeLayer = CAShapeLayer()
    fileprivate var bgShapeLayer = CAShapeLayer()
    
    weak var delegate : answerDetailDelegate!
    
    /** VARS FOR SIDE MENU **/
    fileprivate var detailMenu = PulseMenu(_axis: .vertical, _spacing: Spacing.s.rawValue)
    fileprivate var isShowingMenu = false
    fileprivate var showMenuCreated = false

    fileprivate lazy var addAnswer : PulseButton = PulseButton(size: ButtonSizes.medium, type: .addCircle, isRound: true, hasBackground: false, tint: .black)
    fileprivate lazy var addAnswerLabel = PulseButton(title: "Add Answer", isRound: false)
    fileprivate lazy var addAnswerStack = UIStackView()
    
    fileprivate lazy var browseAnswers : PulseButton = PulseButton(size: ButtonSizes.medium, type: .browseCircle, isRound: true, hasBackground: false, tint: .black)
    fileprivate lazy var browseAnswersLabel = PulseButton(title: "Browse Answers", isRound: false)
    fileprivate lazy var browseAnswersStack = UIStackView()
    /** END VARS FOR SIDE MENU **/

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
        addSubview(questionBackground)
        questionBackground.translatesAutoresizingMaskIntoConstraints = false
        
        questionBackground.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0.0).isActive = true
        questionBackground.trailingAnchor.constraint(equalTo: iconContainer.leadingAnchor).isActive = true
        questionBackground.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0.0).isActive = true
        questionBackground.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.1).isActive = true
        questionBackground.layoutIfNeeded()
        
        addTag()
        addQuestion()
    }
    
    fileprivate func addUserBackground() {
        addSubview(userBackground)
        
        userBackground.translatesAutoresizingMaskIntoConstraints = false
        
        userBackground.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.xs.rawValue).isActive = true
        userBackground.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        userBackground.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        userBackground.heightAnchor.constraint(equalToConstant: footerHeight).isActive = true
        userBackground.layoutIfNeeded()
        
        let userBackgroundTap = UITapGestureRecognizer(target: self, action: #selector(handleProfileTap))
        userBackground.addGestureRecognizer(userBackgroundTap)
        
        addUserImage()
        addUserTitle()
        addUserSubtitle()
        addExploreAnswer()
    }
    
    fileprivate func addUserTitle() {
        userBackground.addSubview(userTitleLabel)
        
        userTitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .white, alignment: .left)
        userTitleLabel.setBlurredBackground()

        userTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        userTitleLabel.topAnchor.constraint(equalTo: userBackground.topAnchor, constant: footerHeight / 5).isActive = true
        userTitleLabel.leadingAnchor.constraint(equalTo: userImage.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
    }
    
    fileprivate func addUserSubtitle() {
        userBackground.addSubview(userSubtitleLabel)
        
        userSubtitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .white, alignment: .left)
        userSubtitleLabel.setBlurredBackground()
        
        userSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        userSubtitleLabel.bottomAnchor.constraint(equalTo: userBackground.bottomAnchor, constant: -footerHeight / 5).isActive = true
        userSubtitleLabel.leadingAnchor.constraint(equalTo: userTitleLabel.leadingAnchor).isActive = true
    }
    
    fileprivate func addUserImage() {
        userBackground.addSubview(userImage)
        
        userImage.translatesAutoresizingMaskIntoConstraints = false
        userImage.contentMode = UIViewContentMode.scaleAspectFill
        //userImage.clipsToBounds = true
        userImage.image = nil
        
        userImage.centerYAnchor.constraint(equalTo: userBackground.centerYAnchor).isActive = true
        userImage.heightAnchor.constraint(equalTo: userBackground.heightAnchor, multiplier: 0.8).isActive = true
        userImage.widthAnchor.constraint(equalTo: userImage.heightAnchor).isActive = true
        userImage.leadingAnchor.constraint(equalTo: userBackground.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        userImage.layoutIfNeeded()
        
        userImage.layer.cornerRadius = userImage.bounds.height / 2
        userImage.layer.masksToBounds = true
        userImage.layer.shouldRasterize = true
        userImage.layer.rasterizationScale = UIScreen.main.scale
        
        
        // Shadow (for raised views) - Up:
        let liftedShadowOffset  = CGSize(width: 2, height: 4)
        
        let downRect = CGRect(x: userImage.bounds.origin.x - liftedShadowOffset.width,
                          y: userImage.bounds.origin.y + liftedShadowOffset.height,
                          width: userImage.bounds.size.width + (2 * liftedShadowOffset.width),
                          height: userImage.bounds.size.height + liftedShadowOffset.height)

        userImage.layer.shadowPath = UIBezierPath.init(roundedRect: downRect , cornerRadius: userImage.layer.cornerRadius).cgPath
        userImage.layer.shadowOffset = liftedShadowOffset
        
        userImage.layer.shadowColor = pulseBlue.cgColor
        userImage.layer.shadowOpacity = 0.5
        userImage.layer.shadowRadius = 4.5
    }

    
    fileprivate func addExploreAnswer() {
        
        exploreAnswer = PulseButton(size: .medium, type: .blank, isRound: true, hasBackground: true)
        exploreAnswer.isHidden = true
        
        addSubview(exploreAnswer)
        
        exploreAnswer.translatesAutoresizingMaskIntoConstraints = false
        exploreAnswer.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.xs.rawValue).isActive = true
        exploreAnswer.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        exploreAnswer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        exploreAnswer.heightAnchor.constraint(equalTo: exploreAnswer.widthAnchor).isActive = true
        exploreAnswer.layoutIfNeeded()
        
        exploreAnswer.titleLabel?.lineBreakMode = .byWordWrapping
        exploreAnswer.titleLabel?.font = UIFont.systemFont(ofSize: FontSizes.caption2.rawValue, weight: UIFontWeightBold)
        
        exploreAnswer.addTarget(self, action: #selector(handleExploreAnswerTap), for: UIControlEvents.touchDown)
    }
    
    ///Update question text
    fileprivate func addQuestion() {
        questionBackground.addSubview(questionLabel)
        questionLabel.adjustsFontSizeToFitWidth = true
        questionLabel.setFont(FontSizes.body.rawValue, weight: UIFontWeightMedium, color: .white, alignment: .left)
        questionLabel.setBlurredBackground()

        questionLabel.numberOfLines = 0
        questionLabel.lineBreakMode = .byWordWrapping
        
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        questionLabel.bottomAnchor.constraint(equalTo: tagLabel.topAnchor).isActive = true
        questionLabel.trailingAnchor.constraint(equalTo: questionBackground.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        questionLabel.leadingAnchor.constraint(equalTo: tagLabel.leadingAnchor).isActive = true
    
    }
    
    ///Update Tag in header
    fileprivate func addTag() {
        questionBackground.addSubview(tagLabel)
        tagLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightMedium, color: .white, alignment: .left)
        tagLabel.setBlurredBackground()
        
        tagLabel.translatesAutoresizingMaskIntoConstraints = false
        tagLabel.centerYAnchor.constraint(equalTo: questionBackground.centerYAnchor, constant: questionBackground.frame.size.height * (1/6)).isActive = true
        tagLabel.leadingAnchor.constraint(equalTo: questionBackground.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        tagLabel.layoutIfNeeded()
    }
    
    ///Add Icon in header
    func addIcon(_ iconColor: UIColor, backgroundColor : UIColor) {
        iconContainer = IconContainer(frame: CGRect(x: 0,y: 0,width: IconSizes.medium.rawValue, height: IconSizes.medium.rawValue + Spacing.m.rawValue), iconColor: iconColor, iconBackgroundColor: backgroundColor.withAlphaComponent(0.7))
        addSubview(iconContainer)
        
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.s.rawValue).isActive = true
        iconContainer.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue + Spacing.m.rawValue).isActive = true
        iconContainer.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        iconContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        iconContainer.layoutIfNeeded()

        let iconTap = UITapGestureRecognizer(target: self, action: #selector(handleShowMenu))
        iconContainer.addGestureRecognizer(iconTap)
        
        addRestIcons()
    }
    
    fileprivate func addRestIcons() {
        addSubview(answerMenu)
        
        answerMenu.translatesAutoresizingMaskIntoConstraints = false
        answerMenu.bottomAnchor.constraint(equalTo: iconContainer.topAnchor).isActive = true
        answerMenu.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        answerMenu.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        answerMenu.layoutIfNeeded()
        
        answerMenu.addArrangedSubview(saveButton)
        answerMenu.addArrangedSubview(upVoteButton)
        answerMenu.addArrangedSubview(downVoteButton)
        
        downVoteButton.addTarget(self, action: #selector(handleDownvote), for: UIControlEvents.touchDown)
        upVoteButton.addTarget(self, action: #selector(handleUpvote), for: UIControlEvents.touchDown)
        saveButton.addTarget(self, action: #selector(handleFavorite), for: UIControlEvents.touchDown)
        
        answerMenu.alpha = 0.7
    }
    
    func handleFavorite() {

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
            toggleMenu(show: false)
            delegate.userClickedExploreAnswers()
        }
    }
    
    func handleAddAnswerTap() {
        if delegate != nil {
            toggleMenu(show: false)
            delegate.userClickedAddAnswer()
        }
    }
    
    func handleExploreAnswerTap() {
        if delegate != nil {
            delegate.userClickedExpandAnswer()
        }
    }
    
    func getHeaderHeight() -> CGFloat {
        return questionBackground.bounds.height
    }
    
    func showExploreAnswerDetail() {
        exploreAnswer.setTitle("EXPLORE ANSWER", for: UIControlState())
        exploreAnswer.setEnabled()
        exploreAnswer.isHidden = false
    }
    
    func hideExploreAnswerDetail() {
        exploreAnswer.isHidden = true
    }
    
    func updateExploreAnswerDetail() {
        exploreAnswer.setTitle("EXPLORING", for: .disabled)
        exploreAnswer.setDisabled()
    }
    
    /* PUBLIC SETTER FUNCTIONS */
    func setUserName(_ _userName : String?) {
        userTitleLabel.text = _userName
    }
    
    func setUserSubtitle(_ _userSubtitle : String?) {
        userSubtitleLabel.text = _userSubtitle
    }
    
    func setUserImage(_ image : UIImage?) {
        userImage.image = image
    }
    
    func getUserBackground() -> UIView {
        return userBackground
    }
    
    func setQuestion(_ question : String) {
        questionLabel.text = question
    }
    
    func setTagName(_ tagName : String) {
        tagLabel.text = "#" + tagName.uppercased()
    }
    
    func createMenu() {
        addSubview(detailMenu)
        
        detailMenu.translatesAutoresizingMaskIntoConstraints = false
        detailMenu.bottomAnchor.constraint(equalTo: iconContainer.topAnchor).isActive = true
        detailMenu.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1/2).isActive = true
        detailMenu.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        detailMenu.layoutIfNeeded()
        
        addAnswerStack.spacing = Spacing.s.rawValue
        browseAnswersStack.spacing = Spacing.s.rawValue
        
        addAnswerStack.addArrangedSubview(addAnswerLabel)
        addAnswerStack.addArrangedSubview(addAnswer)
        
        browseAnswersStack.addArrangedSubview(browseAnswersLabel)
        browseAnswersStack.addArrangedSubview(browseAnswers)
        
        detailMenu.addArrangedSubview(addAnswerStack)
        detailMenu.addArrangedSubview(browseAnswersStack)
        
        addAnswer.addTarget(self, action: #selector(handleAddAnswerTap), for: UIControlEvents.touchUpInside)
        addAnswerLabel.addTarget(self, action: #selector(handleAddAnswerTap), for: UIControlEvents.touchUpInside)
        
        browseAnswers.addTarget(self, action: #selector(handleExploreTap), for: UIControlEvents.touchUpInside)
        browseAnswersLabel.addTarget(self, action: #selector(handleExploreTap), for: UIControlEvents.touchUpInside)
        
        showMenuCreated = true
        detailMenu.isHidden = true
    }
    
    func toggleMenu(show : Bool) {
        if show && !showMenuCreated {
            createMenu()
            detailMenu.isHidden = false
            answerMenu.isHidden = true
        } else if show {
            detailMenu.isHidden = false
            answerMenu.isHidden = true
        } else if !show {
            detailMenu.isHidden = true
            answerMenu.isHidden = false
        }
    }
    
    /// Add clip countdown
    func addClipTimerCountdown() {
        addSubview(videoTimer)
        
        videoTimer.translatesAutoresizingMaskIntoConstraints = false
        videoTimer.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor, constant: iconSize / 2).isActive = true
        videoTimer.widthAnchor.constraint(equalToConstant: iconSize).isActive = true
        videoTimer.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor, constant: iconSize / 2 + Spacing.m.rawValue / 2).isActive = true
        videoTimer.heightAnchor.constraint(equalToConstant: iconSize).isActive = true
        
        // draw the countdown
        bgShapeLayer = drawBgShape((iconSize * 1.02) / 2, _stroke: countdownTimerRadiusStroke)
        timeLeftShapeLayer = drawTimeLeftShape()
        
        videoTimer.layer.addSublayer(bgShapeLayer)
        videoTimer.layer.addSublayer(timeLeftShapeLayer)
    }
    
    func startTimer(_ videoDuration : Double) {
        let strokeIt = CABasicAnimation(keyPath: "strokeEnd")
        strokeIt.fromValue = 0.0
        strokeIt.toValue = 1.0
        strokeIt.duration = videoDuration
        
        timeLeftShapeLayer.add(strokeIt, forKey: "stroke")
    }
    
    func resetTimer() {
        timeLeftShapeLayer.strokeStart = 0.0
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
            iconSize / 2, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).cgPath
        timeLeftShapeLayer.strokeColor = pulseBlue.cgColor
        timeLeftShapeLayer.fillColor = UIColor.clear.cgColor
        timeLeftShapeLayer.lineWidth = countdownTimerRadiusStroke
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
