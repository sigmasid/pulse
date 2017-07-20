//
//  ShrinkDismissAnimationController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/7/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import UIKit

class ShrinkDismissController: BaseAnimator {
    var shrinkToView : UIView!
    
    override func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    override func animateDismissingInContext(_ transitionContext: UIViewControllerContextTransitioning, fromVC: UIViewController, toVC: UIViewController) {
        let containerView = transitionContext.containerView
        
        let fromVCRect = transitionContext.initialFrame(for: fromVC)
        let snapshot = fromVC.view.resizableSnapshotView(from: fromVC.view.frame, afterScreenUpdates: false, withCapInsets: UIEdgeInsets.zero)
        let blankView = UIView(frame: fromVCRect)
        blankView.backgroundColor = UIColor.white
        
        snapshot?.frame = fromVCRect
        toVC.view.frame = fromVCRect
        
        containerView.addSubview(fromVC.view)
        containerView.addSubview(toVC.view)
        containerView.addSubview(blankView)
        containerView.addSubview(snapshot!)
        
        let duration = transitionDuration(using: transitionContext)        
        let initialFrame = CGRect(x: -fromVC.view.frame.size.width/2,y: 0, width: fromVC.view.frame.size.height, height: fromVC.view.frame.size.height )
        let endFrame     = shrinkToView != nil ? shrinkToView.frame : CGRect.zero
        
        let maskPath : UIBezierPath = UIBezierPath(ovalIn: initialFrame)
        let maskLayer = CAShapeLayer()
        maskLayer.frame = toVC.view.frame
        maskLayer.path = maskPath.cgPath
        
        let smallCirclePath = UIBezierPath(ovalIn: endFrame)
        maskLayer.path = smallCirclePath.cgPath
        snapshot?.layer.mask = maskLayer
        
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = maskPath.cgPath
        pathAnimation.toValue   = smallCirclePath
        pathAnimation.duration  = duration
        
        let opacityAnimation = CABasicAnimation(keyPath:"opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.5
        opacityAnimation.duration = duration
        
        CATransaction.begin()

        CATransaction.setCompletionBlock {
            toVC.view.layer.mask = nil
            
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            
            snapshot?.removeFromSuperview()
            blankView.removeFromSuperview()
        }
            
        maskLayer.add(pathAnimation, forKey:"pathAnimation")
        maskLayer.add(opacityAnimation, forKey:"opacityAnimation")
            
        CATransaction.commit()
    }
    
    deinit {
        shrinkToView = nil
    }
}
