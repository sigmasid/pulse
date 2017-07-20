//
//  PanContainerInteractionController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/9/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import UIKit

class PanContainerInteractionController: UIPercentDrivenInteractiveTransition {
    
    var interactionInProgress = false
    fileprivate var shouldCompleteTransition = false
    fileprivate var fromViewController: UIViewController?
    fileprivate var toViewController: UIViewController?
    fileprivate var parentViewController : UINavigationController!
    
    fileprivate var lastProgress: CGFloat?
    fileprivate var isModal = false
    
    weak var delegate : PanAnimationDelegate!
    private var panGesture : UIPanGestureRecognizer!
    
    deinit {
        delegate = nil
        parentViewController = nil
        fromViewController = nil
        toViewController = nil
        panGesture = nil
    }
    
    func wireToViewController(_ fromViewController: UIViewController, toViewController: UIViewController?, parentViewController: UINavigationController, modal: Bool) {
        isModal = modal ? true : false
        wireToViewController(fromViewController, toViewController: toViewController, parentViewController: parentViewController)
    }
    
    func wireToViewController(_ fromViewController: UIViewController, toViewController: UIViewController?, parentViewController: UINavigationController) {
        self.fromViewController = fromViewController
        self.toViewController = toViewController
        self.parentViewController = parentViewController
        prepareGestureRecognizerInView(fromViewController.view)
    }
    
    fileprivate func prepareGestureRecognizerInView(_ view: UIView) {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        view.addGestureRecognizer(panGesture)
    }
    
    func handleGesture(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        //Represents the percentage of the transition that must be completed before allowing to complete.
        let percentThreshold: CGFloat = 0.3
        
        let screenWidth: CGFloat = UIScreen.main.bounds.size.width
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view!.superview!)
        var progress: CGFloat = abs(translation.y) / screenWidth
        
        progress = fmax(progress, 0)
        progress = fmin(progress, 1)
        
        switch gestureRecognizer.state {
            
        case .began:
            interactionInProgress = true
            if isModal {
                if let toViewController = toViewController {
                    parentViewController.present(toViewController, animated: true, completion: { _ in })
                } else {
                    parentViewController.dismiss(animated: true, completion: { _ in })
                }
            } else {
                if let toViewController = toViewController {
                    parentViewController.pushViewController(toViewController, animated: true)
                } else {
                    parentViewController.popViewController(animated: true)
                }
            }
            
        case .changed:
            shouldCompleteTransition = progress > percentThreshold
            update(progress)
            
        case .cancelled:            
            interactionInProgress = false
            cancel()
            
        case .ended:
            interactionInProgress = false
            
            if !shouldCompleteTransition {
                cancel()
                if delegate != nil {
                    delegate.panCompleted(success: false, fromVC: fromViewController)
                }
            } else {
                finish()
                shouldCompleteTransition = false
                if delegate != nil {
                    delegate.panCompleted(success: true, fromVC: fromViewController)
                }
            }
        case .failed:
            interactionInProgress = false
            cancel()
            
        default: return
        }
    }
}
