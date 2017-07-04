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
    fileprivate var shouldCompleteTransition = false
    fileprivate var tabBarController : UITabBarController!
    
    fileprivate var rightToLeftPan : Bool = false
    
    public weak var delegate : ContentDelegate!
    private var panGesture : UIPanGestureRecognizer!
    
    func wireToViewController(_ tabBarController : UITabBarController) {
        self.tabBarController = tabBarController
        
        prepareGestureRecognizerInView(tabBarController.view)
    }
    
    fileprivate func prepareGestureRecognizerInView(_ view: UIView) {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        view.addGestureRecognizer(panGesture)
    }
    
    deinit {
        delegate = nil
        tabBarController = nil
        panGesture = nil
    }
    
    
    func handleGesture(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {        
        //Represents the percentage of the transition that must be completed before allowing to complete.
        let percentThreshold: CGFloat = 0.3
        
        let screenWidth: CGFloat = UIScreen.main.bounds.size.width
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view!.superview!)
        
        var progress: CGFloat = translation.x / screenWidth
        
        rightToLeftPan = progress < 0
        
        progress = abs(progress)
        progress = fmax(progress, 0)
        progress = fmin(progress, 1)
        
        switch gestureRecognizer.state {
            
        case .began:
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
            
        default:
            return
        }
    }
}
