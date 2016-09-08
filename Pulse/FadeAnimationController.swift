//
//  FadeAnimationController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/8/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class FadeAnimationController: BaseAnimator {

    override func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }
    
    override func animatePresentingInContext(transitionContext: UIViewControllerContextTransitioning, fromVC: UIViewController, toVC: UIViewController) {
        
        guard let containerView = transitionContext.containerView() else {
            return
        }
        
        containerView.insertSubview(toVC.view, aboveSubview: fromVC.view)
        toVC.view.alpha = 0
        
        let duration = transitionDuration(transitionContext)
        let animOptions: UIViewAnimationOptions = transitionContext.isInteractive() ? [UIViewAnimationOptions.CurveLinear] : []
        
        UIView.animateWithDuration(
            duration,
            delay: 0,
            options: animOptions,
            animations: {
                toVC.view.alpha = 1.0
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        })
    }
    
    override func animateDismissingInContext(transitionContext: UIViewControllerContextTransitioning, fromVC: UIViewController, toVC: UIViewController) {
        guard let containerView = transitionContext.containerView() else {
            return
        }
        
        containerView.insertSubview(toVC.view, aboveSubview: fromVC.view)
        toVC.view.alpha = 0
        
        let duration = transitionDuration(transitionContext)
        let animOptions: UIViewAnimationOptions = transitionContext.isInteractive() ? [UIViewAnimationOptions.CurveLinear] : []
        
        UIView.animateWithDuration(
            duration,
            delay: 0,
            options: animOptions,
            animations: {
                toVC.view.alpha = 1.0
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        })
    }
}
