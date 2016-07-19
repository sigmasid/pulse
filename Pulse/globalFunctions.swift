//
//  globalFunctions.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/9/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import UIKit

let iconColor = UIColor( red: 255/255, green: 255/255, blue:255/255, alpha: 1.0 )
let iconBackgroundColor = UIColor( red: 237/255, green: 19/255, blue:90/255, alpha: 1.0 )
let buttonCornerRadius : CGFloat = 20

let maxImgSize : Int64 = 1242 * 2208
let iconThickness : Int = 2

class GlobalFunctions {
    static func addBorders(_textField : UITextField) -> CAShapeLayer {
        let _bottomBorder = CAShapeLayer()
        
        _bottomBorder.frame = CGRectMake(0.0, _textField.frame.size.height - 1, _textField.frame.size.width, 1.0);
        _bottomBorder.backgroundColor = UIColor( red: 191/255, green: 191/255, blue:191/255, alpha: 1.0 ).CGColor
        
        return _bottomBorder
    }

    static func addNewVC(newVC: UIViewController, parentVC: UIViewController) {
        UIView.animateWithDuration(0.35, animations: { newVC.view.alpha = 1.0 } , completion: {(value: Bool) in
            parentVC.addChildViewController(newVC)
            parentVC.view.addSubview(newVC.view)
            newVC.didMoveToParentViewController(parentVC)
        })
    }

    static func cycleBetweenVC(oldVC: UIViewController, newVC: UIViewController, parentVC: UIViewController) {
        parentVC.addChildViewController(newVC)
        
        parentVC.transitionFromViewController(oldVC, toViewController: newVC, duration: 0.35, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: nil, completion: { (finished) in
            if finished {
                oldVC.removeFromParentViewController()
                newVC.didMoveToParentViewController(parentVC)
            }
        })
    }

    static func dismissVC(currentVC : UIViewController) {
        let xForm = CGAffineTransformMakeTranslation(currentVC.view.frame.width, 0)
        UIView.animateWithDuration(0.25, animations: { currentVC.view.transform = xForm } , completion: {(value: Bool) in
            currentVC.willMoveToParentViewController(nil)
            currentVC.view.removeFromSuperview()
            currentVC.removeFromParentViewController()
        })
    }
    
    static func dismissVC(currentVC : UIViewController, _animationStyle : AnimationStyle) {
        switch _animationStyle {
        case .VerticalDown:
            let xForm = CGAffineTransformMakeTranslation(0, currentVC.view.frame.height)
            UIView.animateWithDuration(0.25, animations: { currentVC.view.transform = xForm } , completion: {(value: Bool) in
                currentVC.willMoveToParentViewController(nil)
                currentVC.view.removeFromSuperview()
                currentVC.removeFromParentViewController()
            })
        default: dismissVC(currentVC)
        }
    }
    
    static func moveView(newView : UIView, animationStyle : AnimationStyle, parentView : UIView) {
        switch animationStyle {
        case .VerticalUp:
            UIView.animateWithDuration(0.25) {
                newView.frame.origin.y = -parentView.frame.height
            }
        case .VerticalDown:
            UIView.animateWithDuration(0.25) {
                newView.frame.origin.y = parentView.frame.origin.y
            }
        default: print("unhandled move")
        }
    }
    
    ///Validate email
    static func validateEmail(enteredEmail:String?, completion: (verified: Bool, error: NSError?) -> Void) {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        
        if emailPredicate.evaluateWithObject(enteredEmail) {
            completion(verified: true, error: nil)
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "please enter a valid email" ]
            completion(verified: false, error: NSError.init(domain: "Invalid", code: 200, userInfo: userInfo))
        }
    }
    
    ///Validate password returns true if validated, error otherwise
    static func validatePassword(enteredPassword:String?, completion: (verified: Bool, error: NSError?) -> Void) {
        let passwordFormat = "^(?=.*?[a-z]).{8,}$"
        let passwordPredicate = NSPredicate(format:"SELF MATCHES %@", passwordFormat)
        
        if passwordPredicate.evaluateWithObject(enteredPassword) {
            completion(verified: true, error: nil)
            return
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "password must be 8 characters in length" ]
            completion(verified: false, error: NSError.init(domain: "Invalid", code: 200, userInfo: userInfo))
            return
        }
        //        let passwordFormat = "^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{8,}$"
        //        let passwordPredicate = NSPredicate(format:"SELF MATCHES %@", passwordFormat)
    }
    
    
    ///Validate name
    static func validateName(enteredName:String?, completion: (verified: Bool, error: NSError?) -> Void) {
        let nameFormat = "[A-Za-z\\s]{2,64}"
        let namePredicate = NSPredicate(format:"SELF MATCHES %@", nameFormat)
        
        if namePredicate.evaluateWithObject(enteredName) {
            completion(verified: true, error: nil)
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "this doesn't look right" ]
            completion(verified: false, error: NSError.init(domain: "Invalid", code: 200, userInfo: userInfo))
        }
    }
}