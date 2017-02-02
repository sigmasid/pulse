//
//  LoadingView.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/19/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

protocol LoadingDelegate : class {
    func clickedRefresh()
}

class LoadingView: UIView {
    
    fileprivate let messageLabel = UILabel()
    fileprivate var iconManager : Icon!
    fileprivate lazy var refreshButton = PulseButton(size: .small, type: .add, isRound: true, hasBackground: true)
    var loadingDelegate : LoadingDelegate!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, backgroundColor : UIColor) {
        self.init(frame: frame)
        self.backgroundColor = backgroundColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func addMessage(_ _text : String?) {
        addSubview(messageLabel)
        messageLabel.text = _text
        messageLabel.adjustsFontSizeToFitWidth = true
        messageLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        messageLabel.textAlignment = .center
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        if iconManager != nil {
            messageLabel.topAnchor.constraint(equalTo: iconManager.bottomAnchor, constant: Spacing.xxs.rawValue).isActive = true
        } else {
            messageLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        }
        
        messageLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }
    
    public func addMessage(_ _text : String?, _color : UIColor) {
        messageLabel.textColor = _color
        addMessage(_text)
    }
    
    public func addIcon(_ iconSize : IconSizes, _iconColor : UIColor, _iconBackgroundColor : UIColor?) {
        let _iconSize = iconSize.rawValue
        iconManager = Icon(frame: CGRect(x: 0, y: 0, width: _iconSize, height: _iconSize))

        if let _iconBackgroundColor = _iconBackgroundColor {
            iconManager.drawIconBackground(_iconBackgroundColor)
        }
        iconManager.drawIcon(_iconColor, iconThickness: IconThickness.medium.rawValue)
        addSubview(iconManager)
        
        iconManager.translatesAutoresizingMaskIntoConstraints = false
        iconManager.widthAnchor.constraint(equalToConstant: _iconSize).isActive = true
        iconManager.heightAnchor.constraint(equalToConstant: _iconSize).isActive = true
        iconManager.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        iconManager.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        iconManager.layoutIfNeeded()
    }
    
    public func addLongIcon(_ iconSize : IconSizes, _iconColor : UIColor, _iconBackgroundColor : UIColor?) {
        let _iconSize = iconSize.rawValue
        iconManager = Icon(frame: CGRect(x: 0, y: 0, width: frame.width, height: _iconSize))
        addSubview(iconManager)
        
        iconManager.translatesAutoresizingMaskIntoConstraints = false
        iconManager.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        iconManager.heightAnchor.constraint(equalToConstant: _iconSize).isActive = true
        iconManager.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        iconManager.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        iconManager.layoutIfNeeded()

        iconManager.drawLongIcon(.black, iconThickness: IconThickness.medium.rawValue, tillEnd : true)

    }
    
    public func addRefreshButton() {
        addSubview(refreshButton)
        
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        refreshButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        refreshButton.topAnchor.constraint(equalTo: iconManager.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        refreshButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        refreshButton.layoutIfNeeded()
        
        refreshButton.addTarget(self, action: #selector(refreshButtonTapped), for: .touchUpInside)
    }
    
    func refreshButtonTapped() {
        refreshButton.removeFromSuperview()
        
        guard let loadingDelegate = loadingDelegate else { return }
        loadingDelegate.clickedRefresh()
    }
}

class LoadingIndicatorView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, color : UIColor) {
        self.init(frame: frame)
        setUpAnimation(layer, size: CGSize(width: bounds.width / 2, height: bounds.height / 2 ), color: color)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func setUpAnimation(_ layer: CALayer, size: CGSize, color: UIColor) {
        let circleSpacing: CGFloat = 2
        let circleSize = (size.width - circleSpacing * 2) / 3
        let x = (layer.bounds.size.width - size.width) / 2
        let y = (layer.bounds.size.height - circleSize) / 2
        let deltaY = (size.height / 2 - circleSize / 2) / 2
        let duration: CFTimeInterval = 0.6
        let beginTime = CACurrentMediaTime()
        let beginTimes: [CFTimeInterval] = [0.07, 0.14, 0.21]
        let timingFunciton = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        // Animation
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        
        animation.keyTimes = [0, 0.33, 0.66, 1]
        animation.timingFunctions = [timingFunciton, timingFunciton, timingFunciton]
        animation.values = [0, deltaY, -deltaY, 0]
        animation.duration = duration
        animation.repeatCount = HUGE
        animation.isRemovedOnCompletion = false
        
        // Draw circles
        for i in 0 ..< 3 {
            let circle = createLayerWith(CGSize(width: circleSize, height: circleSize), color: color)
            let frame = CGRect(x: x + circleSize * CGFloat(i) + circleSpacing * CGFloat(i),
                               y: y,
                               width: circleSize,
                               height: circleSize)
            
            animation.beginTime = beginTime + beginTimes[i]
            circle.frame = frame
            circle.add(animation, forKey: "animation")
            layer.addSublayer(circle)
        }
    }
    
    fileprivate func createLayerWith(_ size: CGSize, color: UIColor) -> CALayer {
        let layer: CAShapeLayer = CAShapeLayer()
        let path: UIBezierPath = UIBezierPath()
        path.addArc(withCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                              radius: size.width / 2,
                              startAngle: 0,
                              endAngle: CGFloat(2 * M_PI),
                              clockwise: false);
        layer.fillColor = color.cgColor
        layer.backgroundColor = nil
        layer.path = path.cgPath
        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        return layer
    }
}
