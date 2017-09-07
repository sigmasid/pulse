//
//  AnswerOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/5/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import UIKit

class ContentOverlay: UIView {
    
    public weak var delegate : ItemDetailDelegate!
    
    fileprivate var footerBackground = UIView()
    fileprivate var userTitles = PulseMenu(_axis: .vertical, _spacing: 0)
    fileprivate lazy var nextItemButton = PulseButton(title: "Skip", isRound: false, hasShadow: false, buttonColor: UIColor.white, textColor: .black)

    fileprivate var menu = PulseMenu(_axis: .horizontal, _spacing: Spacing.s.rawValue)
    fileprivate lazy var upVoteButton : PulseButton = PulseButton(size: .xSmall, type: .upvote, isRound: false, hasBackground: false)
    fileprivate lazy var downVoteButton : PulseButton = PulseButton(size: .xSmall, type: .downvote, isRound: false, hasBackground: false)
    fileprivate lazy var saveButton : PulseButton = PulseButton(size: .xSmall, type: .favorite, isRound: false, hasBackground: false)
    
    fileprivate var sticker : PulseButton = PulseButton(size: .large, type: .blank, isRound: false, hasBackground: false)
    fileprivate let itemTitleLabel = PaddingLabel()
    
    fileprivate var headerBackground = UIView()
    fileprivate let userTitleLabel = UILabel()
    fileprivate let userSubtitleLabel = UILabel()
    fileprivate var userImage = PulseButton(size: .small, type: .profile, isRound: true, hasBackground: false, tint: .black)
    fileprivate let headerMenu = PulseButton(size: .small, type: .ellipsis, isRound: false, hasBackground: false, tint: .white)

    fileprivate var browseButton = PulseButton()
    fileprivate var messageButton = PulseButton()
    
    fileprivate var countdownTimerRadiusStroke : CGFloat = 3
    fileprivate let videoTimer = UIView()
    fileprivate var timeLeftShapeLayer = CAShapeLayer()
    fileprivate var bgShapeLayer = CAShapeLayer()
    
    fileprivate var pagers = [UIView]()
    fileprivate lazy var pagersStack = UIStackView()
    
    fileprivate var headerBackgroundTap : UITapGestureRecognizer!
    
    internal enum AnswersButtonSelector: Int {
        case upvote, downvote, save, album
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, iconColor: UIColor, iconBackground: UIColor) {
        self.init(frame: frame)
        setupFooterButton()
        setupHeader()
        setupFooter()
        setupNextButton()
        setupPagers()
        setupChoices()
    }
    
    deinit {
        delegate = nil
        pagers = []
        headerBackgroundTap = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func point(inside point : CGPoint, with event : UIEvent?) -> Bool {
        for _view in subviews {
            
            if _view.isUserInteractionEnabled == true && _view.point(inside: convert(point, to: _view) , with: event) {
                return true
            }
        }
        return false
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
    
    func handleBrowseTap() {
        if delegate != nil {
            delegate.userClickedBrowseItems()
        }
    }
    
    func handleHeaderMenuTap() {
        if delegate != nil {
            delegate.userClickedHeaderMenu()
        }
    }
    
    func handleNextItemTap() {
        if delegate != nil {
            delegate.userClickedNextItem()
            hideExploreDetail()
        }
    }
    
    func handleSendMessage() {
        if delegate != nil {
            delegate.userClickedSendMessage()
        }
    }
    
    func itemSaved(type : VoteType) {
        switch type {
        case .downvote: downVoteButton.imageView?.tintColor = .pulseRed
        case .upvote: upVoteButton.imageView?.tintColor = .pulseRed
        case .favorite: saveButton.imageView?.tintColor = .pulseRed
        }
    }
    
    //EXPLORE DETAIL + PAGERS
    public func showChoices(image: UIImage?) {
        if let image = image {
            sticker.setImage(image, for: .normal)
            sticker.isHidden = false
        } else {
            sticker.isHidden = true
            sticker.setImage(nil, for: .normal)
        }
    }
    
    public func highlightExploreDetail() {
        nextItemButton.isHidden = false
        pagersStack.isHidden = false
        
        UIView.animate(withDuration: 0.2, animations: {
            self.nextItemButton.alpha = 0.7
            self.pagersStack.alpha = 1.0
        })
    }

    
    public func dimExploreDetail() {
        nextItemButton.isHidden = false
        pagersStack.isHidden = false
        
        UIView.animate(withDuration: 0.3, animations: {
            self.nextItemButton.alpha = 0.3
        })
    }
    
    public func hideExploreDetail() {
        nextItemButton.alpha = 0.0
        pagersStack.alpha = 0.0
        clearPagers()
    }
    
    public func clearPagers() {
        for currentView in pagersStack.arrangedSubviews {
            pagersStack.removeArrangedSubview(currentView)
            currentView.removeFromSuperview()
        }
    }
    
    public func updateSelectedPager(num: Int) {
        pagersStack.arrangedSubviews[num].backgroundColor = UIColor.white
        pagersStack.arrangedSubviews[num].addShadow()
        
        if num > 0 {
            pagersStack.arrangedSubviews[num - 1].backgroundColor = UIColor.white
            pagersStack.arrangedSubviews[num - 1].addShadow()
        }
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
        userImage.setImage(image, for: .normal)
    }
    
    func setTitle(_ title : String) {
        itemTitleLabel.text = title
        itemTitleLabel.backgroundColor = title == "" ? UIColor.clear : UIColor.black.withAlphaComponent(0.3)
    }
    
    func updateButtons(color: UIColor) {
        upVoteButton.imageView?.tintColor = .white
        downVoteButton.imageView?.tintColor = .white
        saveButton.imageView?.tintColor = .white
        
        headerMenu.imageView?.tintColor = color
        userTitleLabel.textColor = color
        userSubtitleLabel.textColor = color
        
        if color == .black {
            footerBackground.backgroundColor = .black
            userTitleLabel.removeShadow()
            userSubtitleLabel.removeShadow()
        } else {
            footerBackground.backgroundColor = .clear
            userTitleLabel.setBlurredBackground()
            userSubtitleLabel.setBlurredBackground()
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
        var voteImage : UIImageView!
        
        switch _vote {
        case .favorite:
            voteImage = UIImageView(image: UIImage(named: "save"))
            addSubview(voteImage)
            voteImage.translatesAutoresizingMaskIntoConstraints = false
            voteImage.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor).isActive = true
            voteImage.centerXAnchor.constraint(equalTo: saveButton.centerXAnchor).isActive = true
        case .upvote:
            voteImage = UIImageView(image: UIImage(named: "upvote"))
            addSubview(voteImage)
            voteImage.translatesAutoresizingMaskIntoConstraints = false
            voteImage.centerYAnchor.constraint(equalTo: upVoteButton.centerYAnchor).isActive = true
            voteImage.centerXAnchor.constraint(equalTo: upVoteButton.centerXAnchor).isActive = true
        case .downvote:
            voteImage = UIImageView(image: UIImage(named: "downvote"))
            addSubview(voteImage)
            voteImage.translatesAutoresizingMaskIntoConstraints = false
            
            voteImage.centerYAnchor.constraint(equalTo: downVoteButton.centerYAnchor).isActive = true
            voteImage.centerXAnchor.constraint(equalTo: downVoteButton.centerXAnchor).isActive = true
        }
        
        voteImage.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        voteImage.heightAnchor.constraint(equalTo: voteImage.widthAnchor).isActive = true
        
        let xForm = CGAffineTransform.identity.scaledBy(x: 3.0, y: 3.0)
        UIView.animate(withDuration: 0.5, animations: { voteImage.transform = xForm; voteImage.alpha = 0 } , completion: {(value: Bool) in
            voteImage.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
            voteImage.removeFromSuperview()
        })
    }
    
    public func addPagers(num: Int) {
        for _ in 1...num {
            let _pager = UIView()
            _pager.backgroundColor = UIColor.white.withAlphaComponent(0.5)
            pagersStack.addArrangedSubview(_pager)
        }
    }
}

/** Layout Sections **/
extension ContentOverlay {
    fileprivate func setupPagers() {
        addSubview(pagersStack)
        
        pagersStack.translatesAutoresizingMaskIntoConstraints = false
        pagersStack.heightAnchor.constraint(equalToConstant: 2.5).isActive = true
        pagersStack.topAnchor.constraint(equalTo: topAnchor, constant: 2.5).isActive = true
        pagersStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2.5).isActive = true
        pagersStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2.5).isActive = true
        
        pagersStack.axis = .horizontal
        pagersStack.distribution = .fillEqually
        pagersStack.spacing = Spacing.xxs.rawValue
        
        pagersStack.isHidden = true
    }
    
    fileprivate func setupFooter() {
        addSubview(footerBackground)
        footerBackground.translatesAutoresizingMaskIntoConstraints = false
        
        footerBackground.bottomAnchor.constraint(equalTo: bottomAnchor, constant: Spacing.xxs.rawValue).isActive = true
        footerBackground.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        footerBackground.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        footerBackground.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        footerBackground.layoutIfNeeded()
        
        setupFooterButton()
        addTitle()
    }
    
    fileprivate func setupHeader() {
        headerBackground.frame = CGRect(x: 0, y: 0, width: bounds.width, height: userImage.frame.width + Spacing.s.rawValue)
        addSubview(headerBackground)
        headerBackground.addSubview(userImage)
        headerBackground.addSubview(userTitles)
        headerBackground.addSubview(headerMenu)
        
        userImage.center = CGPoint(x: userImage.frame.width / 2 + Spacing.xs.rawValue,
                                   y: userImage.frame.width / 2 + Spacing.xs.rawValue)
        userImage.addTarget(self, action: #selector(handleProfileTap), for: .touchUpInside)
        
        userImage.imageView?.contentMode = .scaleAspectFill
        userImage.imageView?.frame = userImage.bounds
        userImage.imageView?.clipsToBounds = true
        userImage.contentMode = .scaleAspectFill
        userImage.clipsToBounds = true

        userTitles.translatesAutoresizingMaskIntoConstraints = false
        
        userTitles.centerYAnchor.constraint(equalTo: userImage.centerYAnchor).isActive = true
        userTitles.leadingAnchor.constraint(equalTo: userImage.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
        userTitles.layoutIfNeeded()
        
        headerBackgroundTap = UITapGestureRecognizer(target: self, action: #selector(handleProfileTap))
        userTitles.addGestureRecognizer(headerBackgroundTap)
        
        userTitles.addArrangedSubview(userTitleLabel)
        userTitles.addArrangedSubview(userSubtitleLabel)
        
        userTitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightBold, color: .white, alignment: .left)
        userTitleLabel.setBlurredBackground()
        
        userSubtitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightBold, color: .white, alignment: .left)
        userSubtitleLabel.setBlurredBackground()
        
        headerMenu.translatesAutoresizingMaskIntoConstraints = false
        headerMenu.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        headerMenu.centerYAnchor.constraint(equalTo: userImage.centerYAnchor).isActive = true
        headerMenu.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        headerMenu.heightAnchor.constraint(equalTo: headerMenu.widthAnchor).isActive = true
        headerMenu.layoutIfNeeded()
        
        headerMenu.addTarget(self, action: #selector(handleHeaderMenuTap), for: .touchUpInside)
        headerMenu.removeShadow()
    }
    
    fileprivate func setupNextButton() {
        nextItemButton.isHidden = true
        addSubview(nextItemButton)
        
        nextItemButton.translatesAutoresizingMaskIntoConstraints = false
        nextItemButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: IconSizes.xSmall.rawValue / 2).isActive = true
        nextItemButton.bottomAnchor.constraint(equalTo: itemTitleLabel.topAnchor, constant: -Spacing.s.rawValue).isActive = true
        nextItemButton.widthAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        nextItemButton.heightAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
        
        nextItemButton.layoutIfNeeded()
        nextItemButton.backgroundColor = .white
        nextItemButton.setButtonFont(FontSizes.body2.rawValue, weight: UIFontWeightBold, color: .black, alignment: .center)
        nextItemButton.addTarget(self, action: #selector(handleNextItemTap), for: UIControlEvents.touchUpInside)
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
        itemTitleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: IconSizes.xxSmall.rawValue).isActive = true
    }
    
    ///Add Icon in header
    func setupFooterButton() {
        
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
        
        let fontAttributes = [ NSFontAttributeName : UIFont.pulseFont(ofWeight: UIFontWeightBold, size: browseButton.titleLabel!.font.pointSize)]
        let width = GlobalFunctions.getLabelWidth(title: browseButton.titleLabel!.text!, fontAttributes: fontAttributes)
        browseButton.widthAnchor.constraint(equalToConstant: width).isActive = true
        browseButton.layoutIfNeeded()
        
        messageButton.translatesAutoresizingMaskIntoConstraints = false
        messageButton.bottomAnchor.constraint(equalTo: footerBackground.bottomAnchor).isActive = true
        messageButton.heightAnchor.constraint(equalTo: footerBackground.heightAnchor).isActive = true
        messageButton.leadingAnchor.constraint(equalTo: footerBackground.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        
        let messageAttributes = [ NSFontAttributeName : UIFont.pulseFont(ofWeight: UIFontWeightBold, size: messageButton.titleLabel!.font.pointSize)]
        let messageWidth = GlobalFunctions.getLabelWidth(title: messageButton.titleLabel!.text!, fontAttributes: messageAttributes)
        messageButton.widthAnchor.constraint(equalToConstant: messageWidth).isActive = true
        messageButton.layoutIfNeeded()
        
        browseButton.addTarget(self, action: #selector(handleBrowseTap), for: .touchUpInside)
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
        menu.widthAnchor.constraint(equalToConstant: IconSizes.xxSmall.rawValue * 3 + Spacing.s.rawValue * 2).isActive = true
        menu.heightAnchor.constraint(equalToConstant: IconSizes.xxSmall.rawValue).isActive = true
        
        menu.layoutIfNeeded()
        
        menu.addArrangedSubview(saveButton)
        menu.addArrangedSubview(upVoteButton)
        menu.addArrangedSubview(downVoteButton)
        
        downVoteButton.addTarget(self, action: #selector(handleDownvote), for: UIControlEvents.touchDown)
        upVoteButton.addTarget(self, action: #selector(handleUpvote), for: UIControlEvents.touchDown)
        saveButton.addTarget(self, action: #selector(handleFavorite), for: UIControlEvents.touchDown)
        
        menu.alpha = 0.7
    }
    
    fileprivate func setupChoices() {
        addSubview(sticker)
        
        sticker.translatesAutoresizingMaskIntoConstraints = false
        sticker.bottomAnchor.constraint(equalTo: itemTitleLabel.topAnchor, constant: -Spacing.xs.rawValue).isActive = true
        sticker.leadingAnchor.constraint(equalTo: itemTitleLabel.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        sticker.heightAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        sticker.widthAnchor.constraint(equalTo: sticker.heightAnchor).isActive = true
        sticker.layoutIfNeeded()
        sticker.makeRound()
        sticker.addBorder(color: .white, thickness: 2.0)
        
        sticker.isHidden = true
        sticker.isEnabled = false
    }
}
