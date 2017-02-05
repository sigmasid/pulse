//
//  PulseCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/3/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class PulseCell: UICollectionViewCell {

    @IBInspectable public var maskEnabled: Bool = true {
        didSet {
            pulseLayer.maskEnabled = maskEnabled
        }
    }
    @IBInspectable public var cornerRadius: CGFloat = 0 {
        didSet {
            self.layer.cornerRadius = self.cornerRadius
            pulseLayer.superLayerDidResize()
        }
    }
    @IBInspectable public var elevation: CGFloat = 0 {
        didSet {
            pulseLayer.elevation = elevation
        }
    }
    @IBInspectable public var shadowOffset: CGSize = CGSize.zero {
        didSet {
            pulseLayer.shadowOffset = shadowOffset
        }
    }
    @IBInspectable public var roundingCorners: UIRectCorner = UIRectCorner.allCorners {
        didSet {
            pulseLayer.roundingCorners = roundingCorners
        }
    }
    @IBInspectable public var rippleEnabled: Bool = true {
        didSet {
            pulseLayer.rippleEnabled = rippleEnabled
        }
    }
    @IBInspectable public var rippleDuration: CFTimeInterval = 0.35 {
        didSet {
            pulseLayer.rippleDuration = rippleDuration
        }
    }
    @IBInspectable public var rippleScaleRatio: CGFloat = 1.0 {
        didSet {
            pulseLayer.rippleScaleRatio = rippleScaleRatio
        }
    }
    @IBInspectable public var rippleLayerColor: UIColor = pulseBlue {
        didSet {
            pulseLayer.setRippleColor(color: rippleLayerColor)
        }
    }
    @IBInspectable public var backgroundAnimationEnabled: Bool = true {
        didSet {
            pulseLayer.backgroundAnimationEnabled = backgroundAnimationEnabled
        }
    }
    
    private lazy var pulseLayer: PulseLayer = PulseLayer(withView: self.contentView)
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayer()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    // MARK: Setup
    private func setupLayer() {
        pulseLayer.elevation = self.elevation
        self.layer.cornerRadius = self.cornerRadius
        pulseLayer.elevationOffset = self.shadowOffset
        pulseLayer.roundingCorners = self.roundingCorners
        pulseLayer.maskEnabled = self.maskEnabled
        pulseLayer.rippleScaleRatio = self.rippleScaleRatio
        pulseLayer.rippleDuration = self.rippleDuration
        pulseLayer.rippleEnabled = self.rippleEnabled
        pulseLayer.backgroundAnimationEnabled = self.backgroundAnimationEnabled
        pulseLayer.setRippleColor(color: self.rippleLayerColor)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        pulseLayer.touchesBegan(touches: touches, withEvent: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        pulseLayer.touchesEnded(touches: touches, withEvent: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        pulseLayer.touchesCancelled(touches: touches, withEvent: event)

    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        pulseLayer.touchesMoved(touches: touches, withEvent: event)
    }
}
