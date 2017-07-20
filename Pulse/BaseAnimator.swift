//
//  BaseAnimator.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/2/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import UIKit

enum ModalAnimatedTransitioningType {
    case present
    case dismiss
}

class BaseAnimator: NSObject {
    
    var transitionType: ModalAnimatedTransitioningType = .present
    
    func animatePresentingInContext(_ transitionContext: UIViewControllerContextTransitioning, fromVC: UIViewController, toVC: UIViewController) {
        NSException(name:NSExceptionName.internalInconsistencyException, reason:"\(#function) must be overridden in a subclass/category", userInfo:nil).raise()
    }
    
    func animateDismissingInContext(_ transitionContext: UIViewControllerContextTransitioning, fromVC: UIViewController, toVC: UIViewController) {
        NSException(name:NSExceptionName.internalInconsistencyException, reason:"\(#function) must be overridden in a subclass/category", userInfo:nil).raise()
    }
}

extension BaseAnimator: UIViewControllerAnimatedTransitioning {
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let from = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)
        let to = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
        
        if let from = from, let to = to {
            switch transitionType {
            case .present:
                animatePresentingInContext(transitionContext, fromVC: from, toVC: to)
            case .dismiss:
                //not using dismiss as it causes an animation bug
                animateDismissingInContext(transitionContext, fromVC: from, toVC: to)
            }
        }
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        NSException(name:NSExceptionName.internalInconsistencyException, reason:"\(#function) must be overridden in a subclass/category", userInfo:nil).raise()
        return 0
    }
}
