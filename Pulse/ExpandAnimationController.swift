//
//  ExpandAnimationController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/6/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class ExpandAnimationController: BaseAnimator {
    
    var initialFrame : CGRect!
    var exitFrame : CGRect!
    
    override func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.2
    }
    
    override func animatePresentingInContext(transitionContext: UIViewControllerContextTransitioning, fromVC: UIViewController, toVC: UIViewController) {
        guard let containerView = transitionContext.containerView() else {
            return
        }
        
        let fromVCRect = transitionContext.initialFrameForViewController(fromVC)
        toVC.view.frame = fromVCRect
        
        let snapshot = toVC.view.resizableSnapshotViewFromRect(toVC.view.frame, afterScreenUpdates: true, withCapInsets: UIEdgeInsetsZero)
        toVC.view.alpha = 0
        snapshot.frame = initialFrame
        
        containerView.addSubview(fromVC.view)
        containerView.addSubview(toVC.view)
        containerView.addSubview(snapshot)
        
        let duration = transitionDuration(transitionContext)
        
        UIView.animateKeyframesWithDuration(
            duration,
            delay: 0,
            options: .CalculationModeCubic,
            animations: {
                
                UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 1, animations: {
                    snapshot.frame = fromVCRect
                    toVC.view.alpha = 1.0
                })
                
//                UIView.addKeyframeWithRelativeStartTime(4/5, relativeDuration: 1/5, animations: {
//                    snapshot.frame = self.exitFrame
//                    toVC.view.alpha = 1.0
//                })
            },
            completion: { _ in
                snapshot.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        })
    }
}
