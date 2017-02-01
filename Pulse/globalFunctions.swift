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
let pulseBlue = UIColor(red: 67/255, green: 217/255, blue: 253/255, alpha: 1.0)
let highlightedColor = UIColor(red: 0/255, green: 233/255, blue: 178/255, alpha: 1.0)

let maxImgSize : Int64 = 1242 * 2208
let color1 = UIColor(red: 0/255, green: 84/255, blue: 166/255, alpha: 1.0)
let color2 = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 1.0)
let color3 = UIColor(red: 22/255, green: 69/255, blue: 99/255, alpha: 1.0)
let color4 = UIColor(red: 35/255, green: 31/255, blue: 32/255, alpha: 1.0)
let color5 = UIColor(red: 55/255, green: 71/255, blue: 79/255, alpha: 1.0)
let color6 = UIColor(red: 149/255, green: 149/255, blue: 149/255, alpha: 1.0)
let color7 = UIColor(red: 38/255, green: 58/255, blue: 69/255, alpha: 1.0)
let color8 = UIColor(red: 97/255, green: 101/255, blue: 111/255, alpha: 1.0)

let minCellHeight : CGFloat = 225
let searchBarHeight : CGFloat = 44
let statusBarHeight : CGFloat = UIApplication.shared.statusBarFrame.size.height
let bottomLogoLayoutHeight : CGFloat = IconSizes.medium.rawValue + Spacing.xs.rawValue + Spacing.m.rawValue

let _backgroundColors = [color1, color2, color3, color4, color5, color6, color7, color8]

class GlobalFunctions {
    static func addBorders(_ _textField : UITextField) -> CAShapeLayer {
        let color = UIColor( red: 191/255, green: 191/255, blue:191/255, alpha: 1.0 )
        return addBorders(_textField, _color: color, thickness : 1.0)
    }
    
    static func addBorders(_ _textField : UITextField, _color : UIColor, thickness : CGFloat) -> CAShapeLayer {
        let _bottomBorder = CAShapeLayer()
        
        _bottomBorder.frame = CGRect(x: 0, y: _textField.frame.size.height - thickness, width: _textField.frame.size.width, height: thickness);
        _bottomBorder.backgroundColor = _color.cgColor
        
        return _bottomBorder
    }

    static func addNewVC(_ newVC: UIViewController, parentVC: UIViewController) {
        parentVC.addChildViewController(newVC)
        parentVC.view.addSubview(newVC.view)
        newVC.didMove(toParentViewController: parentVC)
    }
    
    static func addNewVC(_ newVC: UIViewController, toView : UIView, parentVC: UIViewController) {
        parentVC.addChildViewController(newVC)
        toView.addSubview(newVC.view)
        newVC.didMove(toParentViewController: parentVC)
    }

    static func cycleBetweenVC(_ oldVC: UIViewController, newVC: UIViewController, parentVC: UIViewController) {
        parentVC.addChildViewController(newVC)
        
        parentVC.transition(from: oldVC, to: newVC, duration: 0.35, options: UIViewAnimationOptions.transitionFlipFromLeft, animations: nil, completion: { (finished) in
            if finished {
                oldVC.removeFromParentViewController()
                newVC.didMove(toParentViewController: parentVC)
            }
        })
    }

    static func dismissVC(_ currentVC : UIViewController) {
        currentVC.willMove(toParentViewController: nil)
        currentVC.view.removeFromSuperview()
        currentVC.removeFromParentViewController()
    }
    
    static func dismissVC(_ currentVC : UIViewController, _animationStyle : AnimationStyle) {
        switch _animationStyle {
        case .verticalDown:
            let xForm = CGAffineTransform(translationX: 0, y: currentVC.view.frame.height)
            UIView.animate(withDuration: 0.25, animations: { currentVC.view.transform = xForm } , completion: {(value: Bool) in
                currentVC.willMove(toParentViewController: nil)
                currentVC.view.removeFromSuperview()
                currentVC.removeFromParentViewController()
            })
        default: dismissVC(currentVC)
        }
    }
    
    static func moveView(_ newView : UIView, animationStyle : AnimationStyle, parentView : UIView) {
        switch animationStyle {
        case .verticalUp:
            UIView.animate(withDuration: 0.25, animations: {
                newView.frame.origin.y = -parentView.frame.height
            }) 
        case .verticalDown:
            UIView.animate(withDuration: 0.25, animations: {
                newView.frame.origin.y = parentView.frame.origin.y
            }) 
        default: print("unhandled move")
        }
    }
    
    static func createImageFromData(_ data : Data) -> UIImage? {
        if let _image = UIImage(data: data, scale: 1.0) {
            let _orientatedImage = UIImage(cgImage: _image.cgImage!, scale: 1.0, orientation: .up)
            return _orientatedImage
        } else {
            return nil
        }
    }
    
    static func getLabelSize(title : String, width: CGFloat, fontAttributes: [String : Any]) -> CGFloat {
        let tempLabel = UILabel()
        tempLabel.numberOfLines = 0
        tempLabel.attributedText = NSMutableAttributedString(string: title , attributes: fontAttributes )
        let neededSize : CGSize = tempLabel.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        let labelHeight = neededSize.height
        
        return labelHeight
    }
    
    static func getLabelWidth(title : String, fontAttributes: [String : Any]) -> CGFloat {
        let tempLabel = UILabel()
        tempLabel.numberOfLines = 1
        tempLabel.attributedText = NSMutableAttributedString(string: title , attributes: fontAttributes )
        let neededSize : CGSize = tempLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: tempLabel.font.capHeight))
        let labelWidth = neededSize.width
        
        return labelWidth
    }
    
    ///Share content
    static func shareContent(shareType: String, shareText: String, shareLink: String, presenter: UIViewController) -> UIActivityViewController {
        // set up activity view controller
        let textToShare = "Check out this \(shareType) on Pulse - " + shareText + shareLink
        let activityViewController = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = presenter.view // so that iPads won't crash
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop ]
        
        // present the view controller
        presenter.present(activityViewController, animated: true, completion: nil)
        
        return activityViewController
    }
    
    ///Validate email
    static func validateEmail(_ enteredEmail:String?, completion: (_ verified: Bool, _ error: NSError?) -> Void) {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        
        if emailPredicate.evaluate(with: enteredEmail) {
            completion(true, nil)
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "please enter a valid email" ]
            completion(false, NSError.init(domain: "Invalid", code: 200, userInfo: userInfo))
        }
    }
    
    ///Validate password returns true if validated, error otherwise
    static func validatePassword(_ enteredPassword:String?, completion: (_ verified: Bool, _ error: NSError?) -> Void) {
        let passwordFormat = "^(?=.*?[a-z]).{8,}$"
        let passwordPredicate = NSPredicate(format:"SELF MATCHES %@", passwordFormat)
        
        if passwordPredicate.evaluate(with: enteredPassword) {
            completion(true, nil)
            return
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "password must be 8 characters in length" ]
            completion(false, NSError.init(domain: "Invalid", code: 200, userInfo: userInfo))
            return
        }
        //        let passwordFormat = "^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{8,}$"
        //        let passwordPredicate = NSPredicate(format:"SELF MATCHES %@", passwordFormat)
    }
    
    
    ///Validate name
    static func validateName(_ enteredName:String?, completion: (_ verified: Bool, _ error: NSError?) -> Void) {
        let nameFormat = "[A-Za-z\\s]{2,64}"
        let namePredicate = NSPredicate(format:"SELF MATCHES %@", nameFormat)
        
        if namePredicate.evaluate(with: enteredName) {
            completion(true, nil)
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "this doesn't look right" ]
            completion(false, NSError.init(domain: "Invalid", code: 200, userInfo: userInfo))
        }
    }
    
    static func showErrorBlock(_ erTitle: String, erMessage: String) {
        
        let alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (alertAction) -> Void in  }))

        if let topController = UIApplication.shared.keyWindow?.rootViewController {
            topController.present(alertController, animated: true, completion:nil)
        }
    }
    
    //rotate images if they are not correctly aligned
    static func fixOrientation(_ img:UIImage) -> UIImage {
        
        if (img.imageOrientation == UIImageOrientation.up) {
            return img;
        }
        
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale);
        let rect = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
        img.draw(in: rect)
        
        let normalizedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return normalizedImage
    }
    
    static func imageWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor);
        context?.fill(rect);
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image!
    }
    
    static func recolorImage(imageView : UIImageView, color : UIColor) -> UIImageView {
        let recoloredImageView = UIImageView()
        
        recoloredImageView.image = imageView.image!.withRenderingMode(.alwaysTemplate)
        recoloredImageView.tintColor = color
        
        return recoloredImageView
    }
    
    /* NEED TO FIX */
    static func addHeader(_ parent : UIView, appTitle : String?, screenTitle : String?) -> LoginHeaderView {
        let _headerView = UIView()
        parent.addSubview(_headerView)
        
        _headerView.translatesAutoresizingMaskIntoConstraints = false
        parent.addConstraint(NSLayoutConstraint(item: _headerView, attribute: .top, relatedBy: .equal, toItem: parent, attribute: .topMargin , multiplier: 2, constant: 0))
        _headerView.centerXAnchor.constraint(equalTo: parent.centerXAnchor).isActive = true
        _headerView.heightAnchor.constraint(equalTo: parent.heightAnchor, multiplier: 1/13).isActive = true
        _headerView.widthAnchor.constraint(equalTo: parent.widthAnchor, multiplier: 1 - (Spacing.m.rawValue/parent.frame.width)).isActive = true
        _headerView.layoutIfNeeded()
        
        let _LoginHeader = LoginHeaderView(frame: _headerView.frame)
        appTitle != nil ? _LoginHeader.setAppTitleLabel(_message: appTitle!) :
        screenTitle != nil ? _LoginHeader.setScreenTitleLabel(_message: screenTitle!) :
        parent.addSubview(_LoginHeader)

        return _LoginHeader
    }
}
