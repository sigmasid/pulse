//
//  PanInteractionController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/2/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class PanInteractionController: UIPercentDrivenInteractiveTransition {
    
    var interactionInProgress = false
    private var shouldCompleteTransition = false
    private var fromViewController: UIViewController?
    private var toViewController: UIViewController?
    
    private var lastProgress: CGFloat?
    
    func wireToViewController(fromViewController: UIViewController, toViewController: UIViewController?, edge : UIRectEdge) {
        self.fromViewController = fromViewController
        self.toViewController = toViewController
        prepareGestureRecognizerInView(fromViewController.view, edge: edge)
    }
    
    private func prepareGestureRecognizerInView(view: UIView, edge : UIRectEdge) {
        let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        gesture.edges = edge
        view.addGestureRecognizer(gesture)
    }
    
    func handleGesture(gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        //Represents the percentage of the transition that must be completed before allowing to complete.
        let percentThreshold: CGFloat = 0.3
        
        let screenWidth: CGFloat = UIScreen.mainScreen().bounds.size.width
        let translation = gestureRecognizer.translationInView(gestureRecognizer.view!.superview!)
        var progress: CGFloat = abs(translation.x) / screenWidth
        
        progress = fmax(progress, 0)
        progress = fmin(progress, 1)
        
        switch gestureRecognizer.state {
            
        case .Began:
            interactionInProgress = true
            if let toViewController = toViewController {
                fromViewController?.presentViewController(toViewController, animated: true, completion: nil)
            } else {
                print("dismiss in switch fired")
                fromViewController?.dismissViewControllerAnimated(true, completion: nil)
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
                print("canceled transition")
                cancelInteractiveTransition()
            } else {
                print("completed transition")
                finishInteractiveTransition()
            }
            
        default:
            print("Unsupported")
        }
    }
}
