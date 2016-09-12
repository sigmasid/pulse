//
//  PanInteraction.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/7/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class PanHorizontalInteractionController: UIPercentDrivenInteractiveTransition {
    var interactionInProgress = false
    private var shouldCompleteTransition = false
    private var fromViewController: UIViewController?
    private var toViewController: UIViewController?
    private var lastProgress: CGFloat?
    
    var delegate : childVCDelegate!
    
    func wireToViewController(fromViewController: UIViewController, toViewController: UIViewController?) {
        self.fromViewController = fromViewController
        self.toViewController = toViewController
        prepareGestureRecognizerInView(fromViewController.view)
    }
    
    private func prepareGestureRecognizerInView(view: UIView) {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        view.addGestureRecognizer(gesture)
    }
    
    func handleGesture(gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        print("pan happened")
        //Represents the percentage of the transition that must be completed before allowing to complete.
        let percentThreshold: CGFloat = 0.3
        
        let screenHeight: CGFloat = UIScreen.mainScreen().bounds.size.height
        let translation = gestureRecognizer.translationInView(gestureRecognizer.view!.superview!)
        var progress: CGFloat = translation.y / screenHeight
        
        progress = fmax(progress, 0)
        progress = fmin(progress, 1)
        print("progress is \(progress)")
        switch gestureRecognizer.state {
            
        case .Began:
            interactionInProgress = true
            if let toViewController = toViewController {
                fromViewController?.presentViewController(toViewController, animated: true, completion: nil)
            } else {
                fromViewController?.dismissViewControllerAnimated(true, completion: {
                    if self.delegate != nil {
                        self.delegate.userDismissedCamera()
                    }
                })
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
                shouldCompleteTransition = false
                finishInteractiveTransition()
            }
            
        default:
            print("Unsupported")
        }
    }
}
