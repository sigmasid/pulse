//
//  PanPresentAnimationController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/2/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class PanPresentAnimationController: BaseAnimator  {
    
    /* set by master */
    override func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.5
    }
    
    override func animatePresentingInContext(transitionContext: UIViewControllerContextTransitioning, fromVC: UIViewController, toVC: UIViewController) {
        
        guard let containerView = transitionContext.containerView() else {
            return
        }
        
        let fromVCRect = transitionContext.initialFrameForViewController(fromVC)
        var toVCRect = fromVCRect
        toVCRect.origin.x = fromVCRect.minX - toVCRect.size.width
        toVC.view.frame = fromVCRect
        
        let snapshot = toVC.view.resizableSnapshotViewFromRect(toVC.view.frame, afterScreenUpdates: true, withCapInsets: UIEdgeInsetsZero)
        toVC.view.hidden = true
        snapshot.frame = toVCRect
        
        containerView.addSubview(fromVC.view)
        containerView.addSubview(toVC.view)
        containerView.addSubview(snapshot)
        
        let duration = transitionDuration(transitionContext)
        let animOptions: UIViewAnimationOptions = transitionContext.isInteractive() ? [UIViewAnimationOptions.CurveLinear] : []

        UIView.animateWithDuration(
            duration,
            delay: 0,
            options: animOptions,
            animations: {
                snapshot.frame = fromVCRect
            }, completion: { _ in
                toVC.view.hidden = false
                snapshot.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        })
    }
    
    override func animateDismissingInContext(transitionContext: UIViewControllerContextTransitioning, fromVC: UIViewController, toVC: UIViewController) {
        
        guard let containerView = transitionContext.containerView() else {
            return
        }
        
        let fromVCRect = transitionContext.initialFrameForViewController(fromVC)
        var toVCRect = fromVCRect
        toVCRect.origin.x = fromVCRect.maxX
        toVC.view.frame = fromVCRect
        
        let snapshot = toVC.view.resizableSnapshotViewFromRect(toVC.view.frame, afterScreenUpdates: true, withCapInsets: UIEdgeInsetsZero)
        toVC.view.hidden = true
        snapshot.frame = toVCRect
        
        containerView.addSubview(fromVC.view)
        containerView.addSubview(toVC.view)
        containerView.addSubview(snapshot)
        
        let duration = transitionDuration(transitionContext)
        let animOptions: UIViewAnimationOptions = transitionContext.isInteractive() ? [UIViewAnimationOptions.CurveLinear] : []
        
        UIView.animateWithDuration(
            duration,
            delay: 0,
            options: animOptions,
            animations: {
                snapshot.frame = fromVCRect
            }, completion: { _ in
                toVC.view.hidden = false
                snapshot.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        })
    }
}

/* MORE RELIABLE SNAPSHOT */
//        UIGraphicsBeginImageContextWithOptions(toVC.view.bounds.size, true, 0.0)
//        toVC.view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
//        let snapshot = UIImageView(image: UIGraphicsGetImageFromCurrentImageContext())
//        UIGraphicsEndImageContext()
