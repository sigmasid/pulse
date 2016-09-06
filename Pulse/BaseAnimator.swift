//
//  BaseAnimator.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/2/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

enum ModalAnimatedTransitioningType {
    case Present
    case Dismiss
}

class BaseAnimator: NSObject {
    var transitionType: ModalAnimatedTransitioningType = .Present
    
    func animatePresentingInContext(transitionContext: UIViewControllerContextTransitioning, fromVC: UIViewController, toVC: UIViewController) {
        NSException(name:NSInternalInconsistencyException, reason:"\(#function) must be overridden in a subclass/category", userInfo:nil).raise()
    }
    
    func animateDismissingInContext(transitionContext: UIViewControllerContextTransitioning, fromVC: UIViewController, toVC: UIViewController) {
        NSException(name:NSInternalInconsistencyException, reason:"\(#function) must be overridden in a subclass/category", userInfo:nil).raise()
    }
}

extension BaseAnimator: UIViewControllerAnimatedTransitioning {
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let from = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
        let to = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)
        
        if let from = from, to = to {
            switch transitionType {
            case .Present:
                animatePresentingInContext(transitionContext, fromVC: from, toVC: to)
            case .Dismiss:
                print("dismiss case in base animator fired")
                animateDismissingInContext(transitionContext, fromVC: from, toVC: to)
            }
        }
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        NSException(name:NSInternalInconsistencyException, reason:"\(#function) must be overridden in a subclass/category", userInfo:nil).raise()
        return 0
    }
}
