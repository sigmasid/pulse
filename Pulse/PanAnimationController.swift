//
//  PanPresentAnimationController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/2/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import UIKit

class PanAnimationController: BaseAnimator  {
    
    var initialFrame : CGRect!
    var exitFrame : CGRect!
    
    deinit {
        initialFrame = nil
        exitFrame = nil
    }
    
    override func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    override func animatePresentingInContext(_ transitionContext: UIViewControllerContextTransitioning,
                                             fromVC: UIViewController, toVC: UIViewController) {

        let containerView = transitionContext.containerView
        let fromVCRect = transitionContext.initialFrame(for: fromVC)
        toVC.view.frame = fromVCRect
        
        if let snapshot = toVC.view.resizableSnapshotView(from: toVC.view.frame,
                                                          afterScreenUpdates: true,
                                                          withCapInsets: UIEdgeInsets.zero) {
            toVC.view.isHidden = true
            snapshot.frame = initialFrame
            
            containerView.addSubview(fromVC.view)
            containerView.addSubview(toVC.view)
            containerView.addSubview(snapshot)
            
            let duration = transitionDuration(using: transitionContext)
            let animOptions: UIViewAnimationOptions = transitionContext.isInteractive ?
                [UIViewAnimationOptions.curveLinear] : []

            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: animOptions,
                animations: {
                    snapshot.frame = fromVCRect
                    fromVC.view.frame = self.exitFrame
                    
                }, completion: { _ in
                    toVC.view.isHidden = false
                    fromVC.view.frame = fromVCRect
                    snapshot.removeFromSuperview()
                    
                    UIView.animate(
                        withDuration: duration / 2,
                        delay: duration / 2,
                        options: animOptions,
                        animations: {
                    })

                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        } else {
            transitionContext.completeTransition(false)
        }
    }
    
    //not used but here just to fulfill protocol reqs
    override func animateDismissingInContext(_ transitionContext: UIViewControllerContextTransitioning,
                                             fromVC: UIViewController, toVC: UIViewController) {
        
        let containerView = transitionContext.containerView
        let fromVCRect = transitionContext.initialFrame(for: fromVC)
        toVC.view.frame = fromVCRect
        
        if let snapshot = toVC.view.resizableSnapshotView(from: toVC.view.frame,
                                                          afterScreenUpdates: true,
                                                          withCapInsets: UIEdgeInsets.zero) {
            toVC.view.isHidden = true
            snapshot.frame = initialFrame
            
            containerView.addSubview(fromVC.view)
            containerView.addSubview(toVC.view)
            containerView.addSubview(snapshot)
            
            let duration = transitionDuration(using: transitionContext)
            let animOptions: UIViewAnimationOptions = transitionContext.isInteractive ?
                [UIViewAnimationOptions.curveLinear] : []
            
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: animOptions,
                animations: {
                    snapshot.frame = fromVCRect
                    fromVC.view.frame = self.exitFrame
                    
            }, completion: { _ in
                toVC.view.isHidden = false
                fromVC.view.frame = fromVCRect
                snapshot.removeFromSuperview()
                
                UIView.animate(
                    withDuration: duration / 2,
                    delay: duration / 2,
                    options: animOptions,
                    animations: {

                })
                
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        } else {
            transitionContext.completeTransition(false)
        }
    }
}

/* MORE RELIABLE SNAPSHOT */
//        UIGraphicsBeginImageContextWithOptions(toVC.view.bounds.size, true, 0.0)
//        toVC.view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
//        let snapshot = UIImageView(image: UIGraphicsGetImageFromCurrentImageContext())
//        UIGraphicsEndImageContext()
