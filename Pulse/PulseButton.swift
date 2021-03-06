//
//  PulseButton.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/26/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import UIKit
import QuartzCore

enum ButtonType { case back, add, remove, close, settings, login, check, search, message, menu, save, blank, profile, browse, tabExplore, tabHome, tabProfile, addCircle, browseCircle, messageCircle, removeCircle, questionCircle, question, upvote, downvote, favorite, post, postCircle, fbCircle, inCircle, twtrCircle, checkCircle, searchCircle, shareCircle, refresh, answerCount, text, logo, logoCircle, ellipsis, camera, channels, ellipsisVertical, play, flashMode, flipCamera, showAlbum, upArrow, downArrow}
enum ButtonSizes { case xxSmall, xSmall, small, medium, large, xLarge }

@IBDesignable
open class PulseButton: UIButton {
    
    static var regularButtonHeight : CGFloat = IconSizes.medium.rawValue
    var size : ButtonSizes!
    @IBInspectable open var highlightedTint : UIColor! = .pulseBlue
    
    @IBInspectable open var regularTint : UIColor! = UIColor.white {
        didSet {
            tintColor = regularTint
        }
    }

    @IBInspectable open var ripplePercent: Float = 0.8 {
        didSet {
            setupRippleView()
        }
    }
    
    @IBInspectable open var rippleColor: UIColor! = UIColor(white: 0.9, alpha: 1) {
        didSet {
            rippleView.backgroundColor = rippleColor
        }
    }
    
    @IBInspectable open var rippleBackgroundColor: UIColor! = UIColor(white: 0.95, alpha: 1) {
        didSet {
            rippleBackgroundView.backgroundColor = rippleBackgroundColor
        }
    }
    
    @IBInspectable open var buttonCornerRadius: Float = 0 {
        didSet{
            layer.cornerRadius = CGFloat(buttonCornerRadius)
        }
    }
    
    open var downRect : CGRect!
    open var upRect : CGRect!

    /** A CGFLoat representing the opacity of the shadow of RAISED buttons when they are lowered (idle). Default is 0.5. */
    var loweredShadowOpacity : CGFloat!
    
    /** A CGFLoat representing the radius of the shadow of RAISED buttons when they are lowered (idle). Default is 1.5f. */
    var loweredShadowRadius : CGFloat!
    
    /** A CGSize representing the offset of the shadow of RAISED buttons when they are lowered (idle). Default is (0, 1). */
    var loweredShadowOffset : CGSize!
    
    /** A CGFLoat representing the opacity of the shadow of RAISED buttons when they are lifted (on touch down). Default is 0.5f. */
    var liftedShadowOpacity : CGFloat!
    
    /** A CGFLoat representing the radius of the shadow of RAISED buttons when they are lifted (on touch down). Default is 4.5f. */
    var liftedShadowRadius : CGFloat!
    
    /** A CGSize representing the offset of the shadow of RAISED buttons when they are lifted (on touch down). Default is (2, 4). */
    var liftedShadowOffset : CGSize!
    
    /** The UIColor for the shadow of a raised button. An alpha value of 1 is recommended as shadowOpacity overwrites the alpha of this color. */
    @IBInspectable var shadowColor : UIColor!

    
    @IBInspectable open var rippleOverBounds: Bool = false
    @IBInspectable open var shadowRippleRadius: Float = 1
    @IBInspectable open var shadowRippleEnable: Bool = true
    @IBInspectable open var trackTouchLocation: Bool = false
    @IBInspectable open var touchUpAnimationTime: Double = 0.6
    
    let rippleView = UIView()
    let rippleBackgroundView = UIView()
    
    fileprivate var tempShadowRadius: CGFloat = 0
    fileprivate var tempShadowOpacity: Float = 0
    fileprivate var touchCenterLocation: CGPoint?
    
    fileprivate var rippleMask: CAShapeLayer? {
        get {
            if !rippleOverBounds {
                let maskLayer = CAShapeLayer()
                maskLayer.path = UIBezierPath(roundedRect: bounds,
                                              cornerRadius: layer.cornerRadius).cgPath
                return maskLayer
            } else {
                return nil
            }
        }
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupRipple()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupRipple()
    }
    
    deinit {
        rippleView.removeFromSuperview()
        rippleBackgroundView.removeFromSuperview()
        shadowColor = nil
        regularTint = nil
        highlightedTint = nil
        rippleColor = nil
        rippleBackgroundColor = nil
        downRect = nil
        upRect = nil
        setImage(nil, for: .normal)
    }
    
    convenience init(title: String, isRound : Bool, hasShadow : Bool = true, buttonColor: UIColor = UIColor.pulseRed, textColor: UIColor = UIColor.white) {
        self.init(frame: CGRect.zero)
        
        setupRipple()
        setTitle(title, for: UIControlState())
        
        buttonCornerRadius = isRound ? 5 : 0
        backgroundColor = buttonColor
        setButtonFont(FontSizes.body2.rawValue, weight: UIFontWeightBold, color: textColor, alignment: .center)
        
        // Shadow (for raised views) - Up:
        if hasShadow {
            shadowColor = UIColor.init(white: 0.2, alpha: 1.0)

            liftedShadowOpacity = 0.5
            liftedShadowRadius  = 4.5
            liftedShadowOffset  = CGSize(width: 2, height: 4)

            layer.shadowColor = shadowColor.cgColor
            layer.shadowOpacity = Float(liftedShadowOpacity)
            layer.shadowRadius = liftedShadowRadius
            layer.shadowOffset = liftedShadowOffset
        }
    }
    
    convenience init(size: ButtonSizes, type : ButtonType, isRound : Bool, background : UIColor, tint: UIColor) {
        var frame = CGRect()
        
        switch size {
        case .xxSmall: frame = CGRect(x: 0, y: 0, width: IconSizes.xxSmall.rawValue, height: IconSizes.xxSmall.rawValue)
        case .xSmall: frame = CGRect(x: 0, y: 0, width: IconSizes.xSmall.rawValue, height: IconSizes.xSmall.rawValue)
        case .small: frame = CGRect(x: 0, y: 0, width: IconSizes.small.rawValue, height: IconSizes.small.rawValue)
        case .medium: frame = CGRect(x: 0, y: 0, width: IconSizes.medium.rawValue, height: IconSizes.medium.rawValue)
        case .large: frame = CGRect(x: 0, y: 0, width: IconSizes.large.rawValue, height: IconSizes.large.rawValue)
        case .xLarge: frame = CGRect(x: 0, y: 0, width: IconSizes.xLarge.rawValue, height: IconSizes.xLarge.rawValue)
        }
        self.init(frame: frame)
        
        setupRipple()
        setupButtonType(size: size, type: type)
        adjustsImageWhenHighlighted = false
        self.size = size
        
        if isRound {
            makeRound()
        }
    
        backgroundColor = background.withAlphaComponent(0.7)
        rippleBackgroundColor = background
        
        setupRaised(isRaised: true, hasBackground: true)
        regularTint = tint
        tintColor = tint
        
    }
    
    convenience init(size: ButtonSizes, type : ButtonType, isRound : Bool, hasBackground : Bool, tint: UIColor) {
        self.init(size: size, type: type, isRound : isRound, hasBackground: hasBackground)
        regularTint = tint
        tintColor = tint
    }
    
    convenience init(size: ButtonSizes, type : ButtonType, isRound : Bool, hasBackground : Bool) {
        var frame = CGRect()
        
        switch size {
        case .xxSmall: frame = CGRect(x: 0, y: 0, width: IconSizes.xxSmall.rawValue, height: IconSizes.xxSmall.rawValue)
        case .xSmall: frame = CGRect(x: 0, y: 0, width: IconSizes.xSmall.rawValue, height: IconSizes.xSmall.rawValue)
        case .small: frame = CGRect(x: 0, y: 0, width: IconSizes.small.rawValue, height: IconSizes.small.rawValue)
        case .medium: frame = CGRect(x: 0, y: 0, width: IconSizes.medium.rawValue, height: IconSizes.medium.rawValue)
        case .large: frame = CGRect(x: 0, y: 0, width: IconSizes.large.rawValue, height: IconSizes.large.rawValue)
        case .xLarge: frame = CGRect(x: 0, y: 0, width: IconSizes.xLarge.rawValue, height: IconSizes.xLarge.rawValue)
        }
        self.init(frame: frame)
        
        setupRipple()
        setupButtonType(size: size, type: type)
        adjustsImageWhenHighlighted = false
        self.size = size
        
        if isRound {
            makeRound()
        }
        
        if hasBackground {
            backgroundColor = .pulseBlue
        } else {
            rippleBackgroundColor = .pulseBlue
        }
        
        setupRaised(isRaised: true, hasBackground: hasBackground)
        tintColor = regularTint
    }
    
    override open var isHighlighted: Bool {
        didSet {
            tintColor = isHighlighted ? highlightedTint : regularTint
        }
    }
    
    public func setVerticalTitle(_ title: String?, for state: UIControlState) {
        setTitle(title, for: state)
        setButtonFont(FontSizes.caption2.rawValue, weight: UIFontWeightMedium, color: .black, alignment: .center)
        
        setTitleColor(.pulseBlue, for: UIControlState.highlighted)
        setTitleColor(.pulseBlue, for: UIControlState.selected)
        switch size! {
        case .xxSmall, .xSmall, .small:
            let imageInset = UIEdgeInsetsMake(Spacing.xxs.rawValue, Spacing.xs.rawValue, Spacing.xxs.rawValue, 0)
            imageEdgeInsets = imageInset
            
            let titleInset = UIEdgeInsetsMake(imageView!.frame.height + Spacing.s.rawValue, -imageView!.frame.width, 0, 0)
            titleEdgeInsets = titleInset
        case .medium, .large, .xLarge:
            let imageInset = UIEdgeInsetsMake(Spacing.xxs.rawValue, Spacing.xs.rawValue, Spacing.xxs.rawValue, 0)
            imageEdgeInsets = imageInset
            
            let titleInset = UIEdgeInsetsMake(imageView!.frame.height + Spacing.l.rawValue, -imageView!.frame.width, 0, 0)
            titleEdgeInsets = titleInset
        }

        imageView?.contentMode = .scaleAspectFit
    }
    
    public func setReversedTitle(_ title: String, for state: UIControlState) {
        guard titleLabel != nil, imageView != nil else { return }
        
        contentHorizontalAlignment = .right

        setTitle(title, for: state)
        setButtonFont(FontSizes.caption.rawValue, weight: UIFontWeightMedium, color: .white, alignment: .center)
        
        setTitleColor(.pulseBlue, for: UIControlState.highlighted)
        setTitleColor(.pulseBlue, for: UIControlState.selected)
        
        let fontAttributes = [ NSFontAttributeName : UIFont.pulseFont(ofWeight: UIFontWeightMedium, size:  FontSizes.caption.rawValue)]
        let labelTextWidth = GlobalFunctions.getLabelWidth(title: title,
                                                           fontAttributes: fontAttributes)

        let imageInset = UIEdgeInsetsMake(5, labelTextWidth, 5, -labelTextWidth)
        imageEdgeInsets = imageInset
        
        if let imageSize = imageView!.image?.size {
            let titleInset = UIEdgeInsetsMake(0, -imageSize.width, 0, imageSize.width + Spacing.xxs.rawValue)
            titleEdgeInsets = titleInset
        }
        
        imageView?.contentMode = .scaleAspectFit
        titleLabel?.setBlurredBackground()
        layoutIfNeeded()
        
        let shadowRect = CGRect(x: labelTextWidth,
                          y: bounds.origin.y + loweredShadowOffset.height,
                          width: imageView!.bounds.size.width,
                          height: imageView!.bounds.size.height)
        
        imageView?.layer.shadowPath = UIBezierPath.init(roundedRect: shadowRect, cornerRadius: self.layer.cornerRadius).cgPath
    }
    
    fileprivate func setupRaised(isRaised : Bool, hasBackground : Bool) {
        if (isRaised) {
            shadowColor = UIColor.init(white: 0.2, alpha: 1.0)
            
            loweredShadowOpacity = 0.3
            loweredShadowRadius  = 1.5
            loweredShadowOffset  = CGSize(width: 0, height: 1)
            
            // Shadow (for raised views) - Up:
            liftedShadowOpacity = 0.5
            liftedShadowRadius  = 4.5
            liftedShadowOffset  = CGSize(width: 2, height: 4)
            
            // Draw shadow
            if hasBackground {
                downRect = CGRect(x: bounds.origin.x - loweredShadowOffset.width,
                                       y: bounds.origin.y + loweredShadowOffset.height,
                                       width: bounds.size.width + (2 * loweredShadowOffset.width),
                                       height: bounds.size.height + loweredShadowOffset.height)
                
            } else if let imageView = imageView {
                upRect = CGRect(x: imageView.bounds.origin.x + liftedShadowOffset.width,
                                       y: imageView.bounds.origin.y + liftedShadowOffset.height,
                                       width: imageView.bounds.size.width + (2 * liftedShadowOffset.width),
                                       height: imageView.bounds.size.height + liftedShadowOffset.height)
            } else {
                upRect = CGRect(x: bounds.origin.x - loweredShadowOffset.width,
                                y: bounds.origin.y + loweredShadowOffset.height,
                                width: bounds.size.width + (2 * loweredShadowOffset.width),
                                height: bounds.size.height + loweredShadowOffset.height)
            }
            
            layer.shadowColor = shadowColor.cgColor
            layer.shadowOpacity = Float(loweredShadowOpacity)
            layer.shadowRadius = hasBackground ? loweredShadowRadius : liftedShadowRadius
            
            layer.shadowPath = UIBezierPath.init(roundedRect: hasBackground ? downRect : upRect , cornerRadius: self.layer.cornerRadius).cgPath
            layer.shadowOffset = hasBackground ? loweredShadowOffset : liftedShadowOffset
        }
        else {
            // Erase shadow:
            layer.shadowOpacity = 0.0
        }
    }
    
    fileprivate func setupButtonType(size: ButtonSizes, type : ButtonType) {
        
        switch size {
        case .xxSmall: imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        case .xSmall: imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        case .medium: imageEdgeInsets = UIEdgeInsetsMake(15, 15, 15, 15)
        case .large: imageEdgeInsets = UIEdgeInsetsMake(22.5, 22.5, 22.5, 22.5)
        case .xLarge: imageEdgeInsets = UIEdgeInsetsMake(35, 35, 35, 35)

        default: imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10) //standard insets
        }
        
        switch type {
        case .search:
            let tintedTimage = UIImage(named: "search")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
        
        case .back:
            let tintedTimage = UIImage(named: "back")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
        
        case .add:
            let tintedTimage = UIImage(named: "add")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            
        case .question:
            let tintedTimage = UIImage(named: "question")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
        
        case.remove:
            let tintedTimage = UIImage(named: "remove")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
        
        case .close:
            setImage(UIImage(named: "close"), for: UIControlState.normal)
            
        case .play:
            setImage(UIImage(named: "play"), for: UIControlState.normal)

        case .settings:
            let tintedTimage = UIImage(named: "settings")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(7, 7, 7, 7)

        case .login:
            let tintedTimage = UIImage(named: "login")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
        
        case .check:
            let tintedTimage = UIImage(named: "check")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            
        case .message:
            let tintedTimage = UIImage(named: "message")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            
        case .flipCamera:
            setImage(UIImage(named: "flip-camera"), for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(imageEdgeInsets.top / 1.25, imageEdgeInsets.left / 1.25, imageEdgeInsets.bottom / 1.25, imageEdgeInsets.right / 1.25)
            
        case .flashMode:
            setImage(UIImage(named: "flash-off"), for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(imageEdgeInsets.top / 1.25, imageEdgeInsets.left / 1.25, imageEdgeInsets.bottom / 1.25, imageEdgeInsets.right / 1.25)
            
        case .camera:
            setImage(UIImage(named: "camera"), for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(imageEdgeInsets.top / 1.25, imageEdgeInsets.left / 1.25, imageEdgeInsets.bottom / 1.25, imageEdgeInsets.right / 1.25)
            
        case .showAlbum:
            setImage(UIImage(named: "library"), for: UIControlState.normal)
            
        case .refresh:
            let tintedTimage = UIImage(named: "refresh")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
        
        case .menu:
            let tintedTimage = UIImage(named: "table-list")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            
        case .post:
            let tintedTimage = UIImage(named: "post")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(7.5, 7.5, 7.5, 7.5)

        case .channels:
            let tintedTimage = UIImage(named: "channels")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            
        case .save:
            let tintedTimage = UIImage(named: "download-to-disk")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)

        case .profile:
            let tintedTimage = UIImage(named: "default-profile")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)

        case .browse:
            let tintedTimage = UIImage(named: "browse")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            
        case .tabExplore:
            let tintedTimage = UIImage(named: "tab-explore")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)

        case .tabHome:
            let tintedTimage = UIImage(named: "tab-home")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)

        case .tabProfile:
            let tintedTimage = UIImage(named: "tab-profile")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)

        case .addCircle:
            let tintedTimage = UIImage(named: "add-circle")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)

        case .browseCircle:
            let tintedTimage = UIImage(named: "browse-circle")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)

        case .messageCircle:
            let tintedTimage = UIImage(named: "message-circle")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)

        case .removeCircle:
            let tintedTimage = UIImage(named: "remove-circle")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)

        case .questionCircle:
            let tintedTimage = UIImage(named: "question-circle")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
            
        case .postCircle:
            let tintedTimage = UIImage(named: "post-circle")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
            
        case .upArrow:
            setImage(UIImage(named: "up-arrow"), for: UIControlState.normal)
            
        case .downArrow:
            setImage(UIImage(named: "down-arrow"), for: UIControlState.normal)
            
        case .upvote:
            let tintedTimage = UIImage(named: "upvote")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)

        case .downvote:
            let tintedTimage = UIImage(named: "downvote")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)

        case .favorite:
            let tintedTimage = UIImage(named: "save")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)

        case .fbCircle:
            let tintedTimage = UIImage(named: "facebook-circle")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
            
        case .inCircle:
            let tintedTimage = UIImage(named: "linkedin-circle")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
            
        case .twtrCircle:
            let tintedTimage = UIImage(named: "twitter-circle")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
            
        case .checkCircle:
            let tintedTimage = UIImage(named: "check-circle")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)

        case .searchCircle:
            let tintedTimage = UIImage(named: "tab-explore")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
            
        case .shareCircle:
            let tintedTimage = UIImage(named: "share-circle")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
            
        case .ellipsis:
            let tintedTimage = UIImage(named: "ellipsis")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            
        case .ellipsisVertical:
            let tintedTimage = UIImage(named: "ellipsis-vertical")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)
            
        case .logo:
            setBackgroundImage(UIImage(named: "pulse-logo"), for: .normal)
            imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
            
        case .logoCircle:
            setImage(UIImage(named: "pulse-logo"), for: .normal)
            imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
            
        case .text:
            let tintedTimage = UIImage(named: "text")?.withRenderingMode(.alwaysTemplate)
            setImage(tintedTimage, for: UIControlState.normal)

        case .answerCount:
            titleEdgeInsets = UIEdgeInsetsMake(0, 0, frame.height / 4, 0)
            frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            titleLabel!.setFont(FontSizes.caption.rawValue, weight: UIFontWeightHeavy, color: .white, alignment: .center)
            setBackgroundImage(UIImage(named: "count-label"), for: UIControlState())
            imageView?.contentMode = .scaleAspectFit
            
        case . blank:
            setImage(nil, for: UIControlState.normal)
            imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
        }
    }
    
    func removeShadow() {
        layer.shadowRadius = 0
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowColor = UIColor.clear.cgColor
        layer.shadowOpacity = 0
    }
    
    override func addShadow(cornerRadius: CGFloat) {
        if cornerRadius > 0 {
            shadowColor = UIColor.init(white: 0.2, alpha: 1.0)
            
            layer.shadowColor = shadowColor.cgColor
            layer.shadowOpacity = 0.3
            
            let loweredShadowOffset  = CGSize(width: 0.5, height: 0.5)
            let downRect = CGRect(x: bounds.origin.x - loweredShadowOffset.width,
                                  y: bounds.origin.y + loweredShadowOffset.height,
                                  width: bounds.size.width + loweredShadowOffset.width,
                                  height: bounds.size.height + loweredShadowOffset.height)
            
            layer.shadowRadius = 0.5
            layer.shadowPath = UIBezierPath.init(roundedRect: downRect , cornerRadius: cornerRadius).cgPath
            layer.shadowOffset = loweredShadowOffset
            layoutIfNeeded()
            
        } else {
            layer.addBorder(edge: .bottom, color: .pulseGrey, thickness: 1.0)
            
            layer.shadowColor = UIColor.lightGray.cgColor
            layer.shadowOffset = CGSize(width: 1, height: 2)
            layer.shadowRadius = 2.0
            layer.shadowOpacity = 0.5
        }
        
        layer.masksToBounds = false
    }

    fileprivate func setupRipple() {
        setupRippleView()
        
        rippleBackgroundView.backgroundColor = rippleBackgroundColor
        rippleBackgroundView.frame = bounds
        rippleBackgroundView.addSubview(rippleView)
        rippleBackgroundView.alpha = 0
        addSubview(rippleBackgroundView)
        
        layer.shadowRadius = 0
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowColor = UIColor(white: 0.0, alpha: 0.5).cgColor
    }

    fileprivate func setupRippleView() {
        let size: CGFloat = bounds.width * CGFloat(ripplePercent)
        let x: CGFloat = (bounds.width/2) - (size/2)
        let y: CGFloat = (bounds.height/2) - (size/2)
        let corner: CGFloat = size/2
        
        rippleView.backgroundColor = rippleColor
        rippleView.frame = CGRect(x: x, y: y, width: size, height: size)
        rippleView.layer.cornerRadius = corner
    }
    
    override open func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if trackTouchLocation {
            touchCenterLocation = touch.location(in: self)
        } else {
            touchCenterLocation = nil
        }
        
        UIView.animate(withDuration: 0.1, delay: 0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
            self.rippleBackgroundView.alpha = 1
        }, completion: nil)
        
        rippleView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [UIViewAnimationOptions.curveEaseOut, UIViewAnimationOptions.allowUserInteraction],
                       animations: {
                        self.rippleView.transform = CGAffineTransform.identity
        }, completion: nil)
        
        if shadowRippleEnable {
            tempShadowRadius = layer.shadowRadius
            tempShadowOpacity = layer.shadowOpacity
            
            let shadowAnim = CABasicAnimation(keyPath:"shadowRadius")
            shadowAnim.toValue = shadowRippleRadius
            
            let opacityAnim = CABasicAnimation(keyPath:"shadowOpacity")
            opacityAnim.toValue = 1
            
            let groupAnim = CAAnimationGroup()
            groupAnim.duration = 0.3
            groupAnim.fillMode = kCAFillModeForwards
            groupAnim.isRemovedOnCompletion = false
            groupAnim.animations = [shadowAnim, opacityAnim]
            
            layer.add(groupAnim, forKey:"shadow")
        }
        return super.beginTracking(touch, with: event)
    }
    
    override open func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
        animateToNormal()
    }
    
    override open func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        animateToNormal()
    }
    
    fileprivate func animateToNormal() {
        UIView.animate(withDuration: 0.1, delay: 0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
            self.rippleBackgroundView.alpha = 1
        }, completion: {(success: Bool) -> () in
            UIView.animate(withDuration: self.touchUpAnimationTime, delay: 0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
                self.rippleBackgroundView.alpha = 0
            }, completion: nil)
        })
        
        
        UIView.animate(withDuration: 0.3, delay: 0,
                       options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction],
                       animations: {
                        self.rippleView.transform = CGAffineTransform.identity
                        
                        let shadowAnim = CABasicAnimation(keyPath:"shadowRadius")
                        shadowAnim.toValue = self.tempShadowRadius
                        
                        let opacityAnim = CABasicAnimation(keyPath:"shadowOpacity")
                        opacityAnim.toValue = self.tempShadowOpacity
                        
                        let groupAnim = CAAnimationGroup()
                        groupAnim.duration = 0.3
                        groupAnim.fillMode = kCAFillModeForwards
                        groupAnim.isRemovedOnCompletion = false
                        groupAnim.animations = [shadowAnim, opacityAnim]
                        
                        self.layer.add(groupAnim, forKey:"shadowBack")
        }, completion: nil)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        setupRippleView()
        if let knownTouchCenterLocation = touchCenterLocation {
            rippleView.center = knownTouchCenterLocation
        }
        
        rippleBackgroundView.layer.frame = bounds
        rippleBackgroundView.layer.mask = rippleMask
    }
}
