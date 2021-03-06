//
//  PanEdgeInteractionController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/2/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import UIKit

class PanEdgeInteractionController: UIPercentDrivenInteractiveTransition {
    
    var interactionInProgress = false
    fileprivate var shouldCompleteTransition = false
    fileprivate var fromViewController: UIViewController?
    fileprivate var toViewController: UIViewController?
    fileprivate weak var gesture : UIScreenEdgePanGestureRecognizer!
    fileprivate var lastProgress: CGFloat?
    
    func wireToViewController(_ _fromViewController: UIViewController, _toViewController: UIViewController?, edge : UIRectEdge) {
        fromViewController = _fromViewController
        toViewController = _toViewController
        prepareGestureRecognizerInView(_fromViewController.view, edge: edge)
    }
    
    deinit {
        fromViewController = nil
        toViewController = nil
        fromViewController?.view.removeGestureRecognizer(gesture)
        gesture = nil
    }
    
    fileprivate func prepareGestureRecognizerInView(_ view: UIView, edge : UIRectEdge) {
        gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        gesture.edges = edge
        view.addGestureRecognizer(gesture)
    }
    
    func handleGesture(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        //Represents the percentage of the transition that must be completed before allowing to complete.
        let percentThreshold: CGFloat = 0.3
        
        let screenWidth: CGFloat = UIScreen.main.bounds.size.width
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view!.superview!)
        var progress: CGFloat = abs(translation.x) / screenWidth
        
        progress = fmax(progress, 0)
        progress = fmin(progress, 1)
        
        switch gestureRecognizer.state {
            
        case .began:
            interactionInProgress = true
            if let toViewController = toViewController {
                fromViewController?.present(toViewController, animated: true, completion: nil)
            } else {
                fromViewController?.dismiss(animated: true, completion: nil)
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
            } else {
                shouldCompleteTransition = false
                finish()
            }
            
        default: return
        }
    }
}
