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
let blueColor = UIColor(red: 67/255, green: 217/255, blue: 253/255, alpha: 1.0)

let maxImgSize : Int64 = 1242 * 2208
let color1 = UIColor(red: 0/255, green: 84/255, blue: 166/255, alpha: 1.0)
let color2 = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 1.0)
let color3 = UIColor(red: 119/255, green: 4/255, blue: 37/255, alpha: 1.0)
let color4 = UIColor(red: 35/255, green: 31/255, blue: 32/255, alpha: 1.0)
let color5 = UIColor(red: 39/255, green: 73/255, blue: 46/255, alpha: 1.0)
let color6 = UIColor(red: 149/255, green: 149/255, blue: 149/255, alpha: 1.0)


let _backgroundColors = [color1, color2, color3, color4, color5, color6]

class GlobalFunctions {
    static func addBorders(_textField : UITextField) -> CAShapeLayer {
        let color = UIColor( red: 191/255, green: 191/255, blue:191/255, alpha: 1.0 )
        return addBorders(_textField, _color: color, thickness : 1.0)
    }
    
    static func addBorders(_textField : UITextField, _color : UIColor, thickness : CGFloat) -> CAShapeLayer {
        let _bottomBorder = CAShapeLayer()
        
        _bottomBorder.frame = CGRectMake(0, _textField.frame.size.height - thickness, _textField.frame.size.width, thickness);
        _bottomBorder.backgroundColor = _color.CGColor
        
        return _bottomBorder
    }

    static func addNewVC(newVC: UIViewController, parentVC: UIViewController) {
        parentVC.addChildViewController(newVC)
        parentVC.view.addSubview(newVC.view)
        newVC.didMoveToParentViewController(parentVC)
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
        currentVC.willMoveToParentViewController(nil)
        currentVC.view.removeFromSuperview()
        currentVC.removeFromParentViewController()
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
    
    static func createImageFromData(data : NSData) -> UIImage? {
        if let _image = UIImage(data: data, scale: 1.0) {
            let _orientatedImage = UIImage(CGImage: _image.CGImage!, scale: 1.0, orientation: .Up)
            return _orientatedImage
        } else {
            return nil
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
    
    static func showErrorBlock(erTitle: String, erMessage: String) {
        
        let alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (alertAction) -> Void in  }))

        if let topController = UIApplication.sharedApplication().keyWindow?.rootViewController {
            topController.presentViewController(alertController, animated: true, completion:nil)
        }
    }
    
    //rotate images if they are not correctly aligned
    static func fixOrientation(img:UIImage) -> UIImage {
        
        if (img.imageOrientation == UIImageOrientation.Up) {
            return img;
        }
        
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale);
        let rect = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
        img.drawInRect(rect)
        
        let normalizedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage
    }
    
    static func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRectMake(0.0, 0.0, 1.0, 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextFillRect(context, rect);
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image
    }
    
    /* NEED TO FIX */
    static func addHeader(parent : UIView, appTitle : String?, screenTitle : String?) -> LoginHeaderView {
        let _headerView = UIView()
        parent.addSubview(_headerView)
        
        _headerView.translatesAutoresizingMaskIntoConstraints = false
        parent.addConstraint(NSLayoutConstraint(item: _headerView, attribute: .Top, relatedBy: .Equal, toItem: parent, attribute: .TopMargin , multiplier: 2, constant: 0))
        _headerView.centerXAnchor.constraintEqualToAnchor(parent.centerXAnchor).active = true
        _headerView.heightAnchor.constraintEqualToAnchor(parent.heightAnchor, multiplier: 1/13).active = true
        _headerView.widthAnchor.constraintEqualToAnchor(parent.widthAnchor, multiplier: 1 - (Spacing.m.rawValue/parent.frame.width)).active = true
        _headerView.layoutIfNeeded()
        
        let _LoginHeader = LoginHeaderView(frame: _headerView.frame)
        appTitle != nil ? _LoginHeader.setAppTitleLabel(appTitle!) :
        screenTitle != nil ? _LoginHeader.setScreenTitleLabel(screenTitle!) :
        parent.addSubview(_LoginHeader)

        return _LoginHeader
    }
}