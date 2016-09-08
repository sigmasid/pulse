//
//  ShrinkDismissAnimationController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/7/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class ShrinkDismissController: BaseAnimator {
    var shrinkToView : UIView!
    
    override func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.5
    }

    override func animateDismissingInContext(transitionContext: UIViewControllerContextTransitioning, fromVC: UIViewController, toVC: UIViewController) {
        guard let containerView = transitionContext.containerView() else {
            return
        }
        
        let fromVCRect = transitionContext.initialFrameForViewController(fromVC)
        containerView.addSubview(toVC.view)

        let snapshot = fromVC.view.resizableSnapshotViewFromRect(fromVC.view.frame, afterScreenUpdates: false, withCapInsets: UIEdgeInsetsZero)
        snapshot.frame = fromVCRect
        
//        containerView.addSubview(fromVC.view)
        containerView.addSubview(snapshot)
        
        let duration = transitionDuration(transitionContext)        
        let initialFrame = CGRectMake(-fromVC.view.frame.size.width/2,0, fromVC.view.frame.size.height, fromVC.view.frame.size.height )
        let endFrame     = shrinkToView.frame
        
        let maskPath : UIBezierPath = UIBezierPath(ovalInRect: initialFrame)
        let maskLayer = CAShapeLayer()
        maskLayer.frame = toVC.view.frame
        maskLayer.path = maskPath.CGPath
        
        let smallCirclePath = UIBezierPath(ovalInRect: endFrame)
        maskLayer.path = smallCirclePath.CGPath
        snapshot.layer.mask = maskLayer
        
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = maskPath.CGPath
        pathAnimation.toValue   = smallCirclePath
        pathAnimation.duration  = duration
        
        let opacityAnimation = CABasicAnimation(keyPath:"opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.5
        opacityAnimation.duration = duration
        
        CATransaction.begin()

        CATransaction.setCompletionBlock {
            toVC.view.layer.mask = nil
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            snapshot.removeFromSuperview()
        }
            
        maskLayer.addAnimation(pathAnimation, forKey:"pathAnimation")
        maskLayer.addAnimation(opacityAnimation, forKey:"opacityAnimation")
            
        CATransaction.commit()
    }
}