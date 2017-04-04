//
//  globalFunctions.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/9/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration

let maxImgSize : Int64 = 1242 * 2208
let searchBarHeight : CGFloat = 44
let statusBarHeight : CGFloat = UIApplication.shared.statusBarFrame.size.height
let defaultCellHeight : CGFloat = 225
let defaultPostHeight : CGFloat = 325

let scopeBarHeight : CGFloat = 40
let bottomLogoLayoutHeight : CGFloat = IconSizes.medium.rawValue + Spacing.xs.rawValue + Spacing.m.rawValue

class GlobalFunctions {
    
    static func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0,
                                      sin_port: 0, sin_addr: in_addr(s_addr: 0),
                                      sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        let isReachable = flags == .reachable
        let needsConnection = flags == .connectionRequired
        
        return isReachable && !needsConnection
    }
    
    static func getPulseCollectionLayout() -> UICollectionViewFlowLayout {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionHeadersPinToVisibleBounds = true
        
        return layout
    }
    
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
    
    static func makeRound(_ view: UIView) {
        view.layer.cornerRadius = view.frame.width > view.frame.height ?  view.frame.height / 2 : view.frame.width / 2
    }
    
    static func addShadow(_ view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 2, height: 4)
        view.layer.shadowRadius = 4.0
        view.layer.shadowOpacity = 0.7
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
    
    static func getFormattedTime(timeString : Date) -> String {
        
        return getFormattedTime(timeString: timeString, style : .medium)
    }
    
    static func getFormattedTime(timeString : Date, style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        let stringDate: String = formatter.string(from: timeString)
        
        return stringDate
    }
    
    static func getCellHeight(type : ItemTypes) -> CGFloat {
        switch type {
        case .question: return 145
        case .answer: return 145
        case .post: return 420
        case .thread: return 420
        case .perspective: return 420
        default: return 145
        }
    }
    
    ///Share content
    static func shareContent(shareType: String, shareText: String, shareLink: String, presenter: UIViewController) -> UIActivityViewController {
        // set up activity view controller
        let textToShare = "Check out this \(shareType) on Pulse - " + shareText + " " + shareLink
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
        
        if let topController = UIApplication.shared.keyWindow?.rootViewController {
            showErrorBlock(viewController: topController, erTitle: erTitle, erMessage: erMessage)
        }
    }
    
    static func showErrorBlock(viewController : UIViewController, erTitle: String, erMessage: String) {
        
        let alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (alertAction) -> Void in  }))

        viewController.present(alertController, animated: true, completion:nil)
    }
    
    /** IMAGE FUNCTIONS **/
    static func fixOrientation(_ img:UIImage) -> UIImage {
        print("image orientation is \(img.imageOrientation)")
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
    
    static func processImage(_ image : UIImage?) -> UIImage? {
        guard let cgimg = image?.cgImage else {
            return nil
        }
        
        let openGLContext = EAGLContext(api: .openGLES2)
        let context = CIContext(eaglContext: openGLContext!)
        
        let coreImage = CIImage(cgImage: cgimg)
        
        let filter = CIFilter(name: "CIPhotoEffectNoir")
        filter?.setValue(coreImage, forKey: kCIInputImageKey)
        
        if let output = filter?.value(forKey: kCIOutputImageKey) as? CIImage {
            let cgimgresult = context.createCGImage(output, from: output.extent)
            let result = UIImage(cgImage: cgimgresult!)
            return result
        } else {
            return image
        }
    }
}
