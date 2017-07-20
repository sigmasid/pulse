//
//  FadeAnimationController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/8/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import UIKit

class FadeAnimationController: BaseAnimator {

    override func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    override func animatePresentingInContext(_ transitionContext: UIViewControllerContextTransitioning, fromVC: UIViewController, toVC: UIViewController) {
        
        let containerView = transitionContext.containerView
        
        containerView.insertSubview(toVC.view, aboveSubview: fromVC.view)
        toVC.view.alpha = 0
        
        let duration = transitionDuration(using: transitionContext)
        let animOptions: UIViewAnimationOptions = transitionContext.isInteractive ? [UIViewAnimationOptions.curveLinear] : []
        
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: animOptions,
            animations: {
                toVC.view.alpha = 1.0
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
    override func animateDismissingInContext(_ transitionContext: UIViewControllerContextTransitioning, fromVC: UIViewController, toVC: UIViewController) {
        let containerView = transitionContext.containerView
        
        containerView.insertSubview(toVC.view, aboveSubview: fromVC.view)
        toVC.view.alpha = 0
        
        let duration = transitionDuration(using: transitionContext)
        let animOptions: UIViewAnimationOptions = transitionContext.isInteractive ? [UIViewAnimationOptions.curveLinear] : []
        
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: animOptions,
            animations: {
                toVC.view.alpha = 1.0
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
