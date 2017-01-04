//
//  PanPresentAnimationController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/2/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class PanAnimationController: BaseAnimator  {
    
    var initialFrame : CGRect!
    var exitFrame : CGRect!
    var tabIcons : UIStackView!
    var delegate : tabVCDelegate!
    
    override func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    override func animatePresentingInContext(_ transitionContext: UIViewControllerContextTransitioning, fromVC: UIViewController, toVC: UIViewController) {
        
        let containerView = transitionContext.containerView
        let fromVCRect = transitionContext.initialFrame(for: fromVC)
        toVC.view.frame = fromVCRect
        
        if let snapshot = toVC.view.resizableSnapshotView(from: toVC.view.frame, afterScreenUpdates: true, withCapInsets: UIEdgeInsets.zero) {
            toVC.view.isHidden = true
            snapshot.frame = initialFrame
            
            containerView.addSubview(fromVC.view)
            containerView.addSubview(toVC.view)
            containerView.addSubview(snapshot)
            
            let duration = transitionDuration(using: transitionContext)
            let animOptions: UIViewAnimationOptions = transitionContext.isInteractive ? [UIViewAnimationOptions.curveLinear] : []
            let xScaleUp = CGAffineTransform(scaleX: 1.2, y: 1.2)

            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: animOptions,
                animations: {
                    snapshot.frame = fromVCRect
                    fromVC.view.frame = self.exitFrame
                    
                    if self.tabIcons != nil {
                        self.tabIcons.transform = xScaleUp
                        self.tabIcons.alpha = 1.0
                    }
                }, completion: { _ in
                    toVC.view.isHidden = false
                    fromVC.view.frame = fromVCRect
                    snapshot.removeFromSuperview()
                    
                    UIView.animate(
                        withDuration: duration / 2,
                        delay: duration / 2,
                        options: animOptions,
                        animations: {
                            
                            if self.tabIcons != nil {
                                self.tabIcons.transform = CGAffineTransform.identity
                                self.tabIcons.alpha = 0.5
                            }
                    })
                    
                    if transitionContext.transitionWasCancelled {
                        self.delegate.cancelledTransition()
                    }

                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
    
    override func animateDismissingInContext(_ transitionContext: UIViewControllerContextTransitioning, fromVC: UIViewController, toVC: UIViewController) {
        let containerView = transitionContext.containerView
        
        let fromVCRect = transitionContext.initialFrame(for: fromVC)
        toVC.view.frame = fromVCRect
        
        if let snapshot = toVC.view.resizableSnapshotView(from: toVC.view.frame, afterScreenUpdates: true, withCapInsets: UIEdgeInsets.zero) {
            toVC.view.isHidden = true
            snapshot.frame = initialFrame
            
            containerView.insertSubview(toVC.view, at: 0)
            containerView.addSubview(snapshot)
            
            let duration = transitionDuration(using: transitionContext)
            let animOptions: UIViewAnimationOptions = transitionContext.isInteractive ? [UIViewAnimationOptions.curveLinear] : []
            let xScaleUp = CGAffineTransform(scaleX: 1.2, y: 1.2)

            UIView.animate(
                withDuration: duration / 2,
                delay: 0,
                options: animOptions,
                animations: {
                    snapshot.frame = fromVCRect
                    fromVC.view.frame = self.exitFrame
                    
                    if self.tabIcons != nil {
                        self.tabIcons.transform = xScaleUp
                        self.tabIcons.alpha = 1.0
                    }
                }, completion: { _ in
                    fromVC.view.frame = fromVCRect
                    toVC.view.isHidden = false
                    snapshot.removeFromSuperview()
                    
                    UIView.animate(
                        withDuration: duration / 2,
                        delay: duration / 2,
                        options: animOptions,
                        animations: {

                        if self.tabIcons != nil {
                            self.tabIcons.transform = CGAffineTransform.identity
                            self.tabIcons.alpha = 0.5
                        }
                    })
                
                    if transitionContext.transitionWasCancelled {
                        self.delegate.cancelledTransition()
                    }
                    
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
}

/* MORE RELIABLE SNAPSHOT */
//        UIGraphicsBeginImageContextWithOptions(toVC.view.bounds.size, true, 0.0)
//        toVC.view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
//        let snapshot = UIImageView(image: UIGraphicsGetImageFromCurrentImageContext())
//        UIGraphicsEndImageContext()
