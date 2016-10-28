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
    
    override func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }
    
    override func animatePresentingInContext(_ transitionContext: UIViewControllerContextTransitioning, fromVC: UIViewController, toVC: UIViewController) {
        let containerView = transitionContext.containerView
        
        let fromVCRect = transitionContext.initialFrame(for: fromVC)
        toVC.view.frame = fromVCRect
        
        let snapshot = toVC.view.resizableSnapshotView(from: toVC.view.frame, afterScreenUpdates: true, withCapInsets: UIEdgeInsets.zero)
        toVC.view.alpha = 0
        snapshot?.frame = initialFrame
        
        containerView.addSubview(fromVC.view)
        containerView.addSubview(toVC.view)
        containerView.addSubview(snapshot!)
        
        let duration = transitionDuration(using: transitionContext)
        
        UIView.animateKeyframes(
            withDuration: duration,
            delay: 0,
            options: .calculationModeCubic,
            animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1, animations: {
                    snapshot?.frame = fromVCRect
                    toVC.view.alpha = 1.0
                })
            },
            completion: { _ in
                snapshot?.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
