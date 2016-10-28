//
//  PulseButton.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/26/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import QuartzCore

enum ButtonType { case back, add, remove, close, settings, login, check, search, message, menu, save, blank }
enum ButtonSizes { case xSmall, small, medium, large }

@IBDesignable
open class PulseButton: UIButton {
    
    var size : ButtonSizes!
    
    @IBInspectable open var ripplePercent: Float = 0.8 {
        didSet {
            setupRippleView()
        }
    }
    
    @IBInspectable open var rippleColor: UIColor = UIColor(white: 0.9, alpha: 1) {
        didSet {
            rippleView.backgroundColor = rippleColor
        }
    }
    
    @IBInspectable open var rippleBackgroundColor: UIColor = UIColor(white: 0.95, alpha: 1) {
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
    @IBInspectable var loweredShadowOpacity : CGFloat!
    
    /** A CGFLoat representing the radius of the shadow of RAISED buttons when they are lowered (idle). Default is 1.5f. */
    @IBInspectable var loweredShadowRadius : CGFloat!
    
    /** A CGSize representing the offset of the shadow of RAISED buttons when they are lowered (idle). Default is (0, 1). */
    @IBInspectable var loweredShadowOffset : CGSize!
    
    /** A CGFLoat representing the opacity of the shadow of RAISED buttons when they are lifted (on touch down). Default is 0.5f. */
    @IBInspectable var liftedShadowOpacity : CGFloat!
    
    /** A CGFLoat representing the radius of the shadow of RAISED buttons when they are lifted (on touch down). Default is 4.5f. */
    @IBInspectable var liftedShadowRadius : CGFloat!
    
    /** A CGSize representing the offset of the shadow of RAISED buttons when they are lifted (on touch down). Default is (2, 4). */
    @IBInspectable var liftedShadowOffset : CGSize!
    
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
    
    convenience init(size: ButtonSizes, type : ButtonType, isRound : Bool, hasBackground : Bool) {
        var frame = CGRect()
        
        switch size {
        case .xSmall: frame = CGRect(x: 0, y: 0, width: IconSizes.xSmall.rawValue, height: IconSizes.xSmall.rawValue)
        case .small: frame = CGRect(x: 0, y: 0, width: IconSizes.small.rawValue, height: IconSizes.small.rawValue)
        case .medium: frame = CGRect(x: 0, y: 0, width: IconSizes.medium.rawValue, height: IconSizes.medium.rawValue)
        case .large: frame = CGRect(x: 0, y: 0, width: IconSizes.large.rawValue, height: IconSizes.large.rawValue)
        }
        self.init(frame: frame)
        
        setupRipple()
        setupButtonType(size: size, type: type)
        
        if isRound {
            makeRound()
        }
        
        if hasBackground {
            backgroundColor = pulseBlue
        } else {
            rippleBackgroundColor = pulseBlue
        }
        
        setupRaised(isRaised: true)
    }
    
    fileprivate func setupRaised(isRaised : Bool) {
        if (isRaised) {
            self.shadowColor = UIColor.init(white: 0.2, alpha: 1.0)
            
            self.loweredShadowOpacity = 0.5
            self.loweredShadowRadius  = 1.5
            self.loweredShadowOffset  = CGSize(width: 0, height: 1)
            
            // Shadow (for raised views) - Up:
            self.liftedShadowOpacity = 0.5
            self.liftedShadowRadius  = 4.5
            self.liftedShadowOffset  = CGSize(width: 2, height: 4)
            
            // Draw shadow
            self.downRect = CGRect(x: bounds.origin.x - loweredShadowOffset.width,
                                   y: bounds.origin.y + loweredShadowOffset.height,
                                   width: bounds.size.width + (2 * loweredShadowOffset.width),
                                   height: bounds.size.height + loweredShadowOffset.height);
            
            self.upRect = CGRect(x: bounds.origin.x - self.liftedShadowOffset.width,
                                 y: bounds.origin.y + self.liftedShadowOffset.height,
                                 width: bounds.size.width + (2 * liftedShadowOffset.width),
                                 height: bounds.size.height + self.liftedShadowOffset.height);
            
            layer.shadowColor = shadowColor.cgColor
            layer.shadowOpacity = Float(loweredShadowOpacity)
            layer.shadowRadius = loweredShadowRadius
            
            layer.shadowPath = UIBezierPath.init(roundedRect: self.downRect, cornerRadius: self.layer.cornerRadius).cgPath
            layer.shadowOffset = loweredShadowOffset
        }
        else {
            // Erase shadow:
            self.layer.shadowOpacity = 0.0
        }
    }
    
    fileprivate func setupButtonType(size: ButtonSizes, type : ButtonType) {
        
        switch size {
        case .xSmall: imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5) //smaller insets for xSmall button
        default: imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10) //standard insets
        }
        
        switch type {
        case .search:
        let tintedTimage = UIImage(named: "search")?.withRenderingMode(.alwaysTemplate)
        setImage(tintedTimage, for: UIControlState())
        
        case .back:
        let tintedTimage = UIImage(named: "back")?.withRenderingMode(.alwaysTemplate)
        setImage(tintedTimage, for: UIControlState())
        tintColor = .black
        
        case .add:
        let tintedTimage = UIImage(named: "add")?.withRenderingMode(.alwaysTemplate)
        setImage(tintedTimage, for: UIControlState())
        
        case.remove:
        let tintedTimage = UIImage(named: "remove")?.withRenderingMode(.alwaysTemplate)
        setImage(tintedTimage, for: UIControlState())
        
        case .close:
        let tintedTimage = UIImage(named: "close")?.withRenderingMode(.alwaysTemplate)
        setImage(tintedTimage, for: UIControlState())
        
        case .settings:
        let tintedTimage = UIImage(named: "settings")?.withRenderingMode(.alwaysTemplate)
        setImage(tintedTimage, for: UIControlState())
        imageEdgeInsets = UIEdgeInsetsMake(7, 7, 7, 7)

        case .login:
        let tintedTimage = UIImage(named: "login")?.withRenderingMode(.alwaysTemplate)
        setImage(tintedTimage, for: UIControlState())
        
        case .check:
        let tintedTimage = UIImage(named: "check")?.withRenderingMode(.alwaysTemplate)
        setImage(tintedTimage, for: UIControlState())
        imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
            
        case .message:
        let tintedTimage = UIImage(named: "message")?.withRenderingMode(.alwaysTemplate)
        setImage(tintedTimage, for: UIControlState())
        
        case .menu:
        let tintedTimage = UIImage(named: "table-list")?.withRenderingMode(.alwaysTemplate)
        setImage(tintedTimage, for: UIControlState())
        
        case .save:
        let tintedTimage = UIImage(named: "download-to-disk")?.withRenderingMode(.alwaysTemplate)
        setImage(tintedTimage, for: UIControlState())

        case . blank:
        setImage(nil, for: UIControlState())
        }
        
        
        tintColor = UIColor.black
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
        
        
        UIView.animate(withDuration: 0.7, delay: 0, options: [UIViewAnimationOptions.curveEaseOut, UIViewAnimationOptions.allowUserInteraction],
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
            groupAnim.duration = 0.7
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
        
        
        UIView.animate(withDuration: 0.7, delay: 0,
                       options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction],
                       animations: {
                        self.rippleView.transform = CGAffineTransform.identity
                        
                        let shadowAnim = CABasicAnimation(keyPath:"shadowRadius")
                        shadowAnim.toValue = self.tempShadowRadius
                        
                        let opacityAnim = CABasicAnimation(keyPath:"shadowOpacity")
                        opacityAnim.toValue = self.tempShadowOpacity
                        
                        let groupAnim = CAAnimationGroup()
                        groupAnim.duration = 0.7
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
