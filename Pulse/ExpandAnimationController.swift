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
        toVC.view.hidden = true
        snapshot.frame = initialFrame
        print("snapshot frame is \(snapshot.frame)")
        
        containerView.addSubview(fromVC.view)
        containerView.addSubview(toVC.view)
        containerView.addSubview(snapshot)
        
        let duration = transitionDuration(transitionContext)
        
        UIView.animateWithDuration(
            duration,
            delay: 0.0,
            options: UIViewAnimationOptions.CurveEaseInOut,
            animations: {
                snapshot.frame = fromVCRect
            }, completion: { finished in
                toVC.view.hidden = false
                snapshot.removeFromSuperview()
                transitionContext.completeTransition(true)
        })
    }
}
