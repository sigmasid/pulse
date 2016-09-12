//
//  PanInteraction.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/7/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class PanHorizonInteractionController: UIPercentDrivenInteractiveTransition {
    var interactionInProgress = false
    private var shouldCompleteTransition = false
    private var tabBarController : UITabBarController!
    
    private var rightToLeftPan : Bool = false
    
    var delegate : childVCDelegate!
    
    func wireToViewController(tabBarController : UITabBarController) {
        self.tabBarController = tabBarController
        
        prepareGestureRecognizerInView(tabBarController.view)
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
        
        var progress: CGFloat = translation.x / screenWidth
        
        rightToLeftPan = progress < 0
        
        progress = abs(progress)
        progress = fmax(progress, 0)
        progress = fmin(progress, 1)
        
        switch gestureRecognizer.state {
            
        case .Began:
            interactionInProgress = true
            if rightToLeftPan {
                if (tabBarController.selectedIndex < tabBarController.viewControllers!.count - 1) {
                    tabBarController.selectedIndex += 1
                }
            } else {
                if (tabBarController.selectedIndex > 0) {
                    tabBarController.selectedIndex -= 1
                }
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
