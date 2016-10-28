//
//  LoadingView.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/19/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class LoadingView: UIView {
    
    fileprivate let _messageLabel = UILabel()
    fileprivate var _iconManager : Icon!

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
    
    func addMessage(_ _text : String?) {
        self.addSubview(_messageLabel)
        _messageLabel.text = _text
        _messageLabel.adjustsFontSizeToFitWidth = true
        _messageLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        _messageLabel.textAlignment = .center
        
        _messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        _messageLabel.topAnchor.constraint(equalTo: _iconManager.bottomAnchor, constant: 5).isActive = true
        _messageLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    }
    
    func addMessage(_ _text : String, _color : UIColor) {
        _messageLabel.textColor = _color
        addMessage(_text)
    }
    
    func addIcon(_ iconSize : IconSizes, _iconColor : UIColor, _iconBackgroundColor : UIColor?) {
        let _iconSize = iconSize.rawValue
        _iconManager = Icon(frame: CGRect(x: 0, y: 0, width: _iconSize, height: _iconSize))

        if let _iconBackgroundColor = _iconBackgroundColor {
            _iconManager.drawIconBackground(_iconBackgroundColor)
        }
        _iconManager.drawIcon(_iconColor, iconThickness: IconThickness.medium.rawValue)
        self.addSubview(_iconManager)
        
        _iconManager.translatesAutoresizingMaskIntoConstraints = false
        _iconManager.widthAnchor.constraint(equalToConstant: _iconSize).isActive = true
        _iconManager.heightAnchor.constraint(equalToConstant: _iconSize).isActive = true
        _iconManager.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        _iconManager.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
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
