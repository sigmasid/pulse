//
//  PanContainerInteractionController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/9/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class PanContainerInteractionController: UIPercentDrivenInteractiveTransition {
    
    var interactionInProgress = false
    private var shouldCompleteTransition = false
    private var fromViewController: UIViewController?
    private var toViewController: UIViewController?
    private var parentViewController : UINavigationController!
    
    private var lastProgress: CGFloat?
    
    var delegate : childVCDelegate!
    
    func wireToViewController(fromViewController: UIViewController, toViewController: UIViewController?, parentViewController: UINavigationController) {
        self.fromViewController = fromViewController
        self.toViewController = toViewController
        self.parentViewController = parentViewController
        prepareGestureRecognizerInView(fromViewController.view)
    }
    
    private func prepareGestureRecognizerInView(view: UIView) {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        view.addGestureRecognizer(gesture)
    }
    
    func handleGesture(gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        //Represents the percentage of the transition that must be completed before allowing to complete.
        let percentThreshold: CGFloat = 0.3
        
        let screenWidth: CGFloat = UIScreen.mainScreen().bounds.size.width
        let translation = gestureRecognizer.translationInView(gestureRecognizer.view!.superview!)
        var progress: CGFloat = abs(translation.y) / screenWidth
        
        progress = fmax(progress, 0)
        progress = fmin(progress, 1)
        
        switch gestureRecognizer.state {
            
        case .Began:
            interactionInProgress = true
            if let toViewController = toViewController {
                parentViewController.pushViewController(toViewController, animated: true)
            } else {
                parentViewController.popViewControllerAnimated(true)
            }
            
        case .Changed:
            shouldCompleteTransition = progress > percentThreshold
            updateInteractiveTransition(progress)
            
        case .Cancelled:
            interactionInProgress = false
            cancelInteractiveTransition()
            
        case .Ended:
            interactionInProgress = false
            
            if !shouldCompleteTransition {
                cancelInteractiveTransition()
            } else {
                finishInteractiveTransition()
                shouldCompleteTransition = false
                delegate.userDismissedCamera()
            }
            
        default:
            print("Unsupported")
        }
    }
}
