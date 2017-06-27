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
import UserNotifications

let maxImgSize : Int64 = 1242 * 2208
let searchBarHeight : CGFloat = 44
let statusBarHeight : CGFloat = UIApplication.shared.statusBarFrame.size.height
let defaultCellHeight : CGFloat = 225
let defaultPostHeight : CGFloat = 325

let scopeBarHeight : CGFloat = 40
let bottomLogoLayoutHeight : CGFloat = IconSizes.medium.rawValue + Spacing.xs.rawValue + Spacing.m.rawValue

enum GlobalFunctions {
    static var hasAskedNotificationPermission : Bool = UserDefaults.standard.bool(forKey: "askedNotificationPermission")

    /** START: NETWORK + PERMISSIONS **/
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
    
    static func askNotificationPermssion(viewController: UIViewController) -> MiniPreview? {
        let _frame = CGRect(x: viewController.view.bounds.width * (1/6),
                            y: viewController.view.bounds.height * (1/5),
                            width: viewController.view.bounds.width * (2/3),
                            height: viewController.view.bounds.height * (3/5))
        
        if !hasAskedNotificationPermission {
            let miniPreview =  MiniPreview(frame: _frame, buttonTitle: "Enable")
            miniPreview.backgroundColor = .white
            if let image = UIImage(named: "notifications-popup") {
                miniPreview.setIcon(image: image, tintColor: .white, backgroundColor: .pulseBlue)
                miniPreview.setTitleLabel("Allow Notifications?", textColor: .white, blurText: false)
            } else {
                miniPreview.setTitleLabel("Allow Notifications?", textColor: .black)
            }
            miniPreview.setLongDescriptionLabel("So we can remind you of requests to share your perspectives, ideas & expertise!",
                                                textColor: .darkGray, blurText: false)
            return miniPreview
        } else {
            return nil
        }
    }
    
    static func showNotificationPermissions() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { success, _ in
            
            let defaults = UserDefaults.standard
            defaults.setValue(true, forKey: "askedNotificationPermission")
                
            if !success {
                GlobalFunctions.showAlertBlock("Error Registering",
                                               erMessage: "you can change notifications permissions by going into the settings")
            }
        })
    }
    /** END: NETWORK + PERMISSIONS **/
    
    /** START: UIVIEW / LAYER EFFECTS **/
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
    /** END: UIVIEW / LAYER EFFECTS **/

    
    /** START CHANGE VIEW / VCS **/
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
        default: return
        }
    }
    /** END CHANGE VIEW / VCS **/
    
    /** START: FORMAT TIME **/
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
    /** END: FORMAT TIME **/
    
    /** START: COLLECTION VIEW ITEMS **/
    static func getPulseCollectionLayout() -> UICollectionViewFlowLayout {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionHeadersPinToVisibleBounds = true
        
        return layout
    }
    
    static func getCellHeight(type : ItemTypes) -> CGFloat {
        switch type {
        case .question: return 145
        case .answer: return 145
        case .post: return 420
        case .thread: return 420
        case .perspective: return 420
        case .session: return 420
        case .showcase: return 420

        default: return 145
        }
    }
    /** END: COLLECTION VIEW ITEMS **/
    
    ///Share content
    static func shareContent(shareType: String, shareText: String, shareLink: URL, presenter: UIViewController) -> UIActivityViewController {
        // set up activity view controller
        let textToShare = "Check out this \(shareType) on Pulse - " + shareText
        let activityViewController = UIActivityViewController(activityItems: [textToShare, shareLink], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = presenter.view // so that iPads won't crash
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop ]
        
        // present the view controller
        presenter.present(activityViewController, animated: true, completion: nil)
        
        return activityViewController
    }
    
    /** START: VALIDATE ITEMS **/
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
    /** END: VALIDATE ITEMS **/
    
    
    /** START: ALERTS **/
    static func showAlertBlock(_ erTitle: String, erMessage: String) {
        if let topController = UIApplication.shared.keyWindow?.rootViewController {
            showAlertBlock(viewController: topController, erTitle: erTitle, erMessage: erMessage)
        }
    }
    
    static func showAlertBlock(viewController : UIViewController, erTitle: String, erMessage: String, buttonTitle: String = "cancel") {
        let alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: buttonTitle, style: buttonTitle == "cancel" ? .destructive : .default, handler: { (alertAction) -> Void in  }))
        viewController.present(alertController, animated: true, completion:nil)
    }
    /** END: ALERTS **/
    
    /** START: IMAGE FUNCTIONS **/
    static func createImageFromData(_ data : Data) -> UIImage? {
        if let _image = UIImage(data: data, scale: 1.0) {
            let _orientatedImage = UIImage(cgImage: _image.cgImage!, scale: 1.0, orientation: .up)
            return _orientatedImage
        } else {
            return nil
        }
    }
    
    static func fixOrientation(img:UIImage?) -> UIImage? {
        guard let img = img else {
            return nil
        }
        
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
    
    static func getSquareImage(image: UIImage, newWidth: CGFloat) -> UIImage? {
        var cropRect: CGRect!
        
        if image.size.height > image.size.width, let returnImage = image.resizeImage(newWidth: newWidth) {
            cropRect = CGRect(x: 0, y: (returnImage.size.height / 2) - (newWidth / 2), width: newWidth, height: newWidth)
            return returnImage.cropImage(toRect: cropRect)
        } else if image.size.width > image.size.height {
            let scale = image.size.width / image.size.height
            if let returnImage = image.resizeImage(newWidth: newWidth * scale) {
                cropRect = CGRect(x: returnImage.size.width / 2 - newWidth / 2, y: 0, width: newWidth, height: newWidth)
                return returnImage.cropImage(toRect: cropRect)
            } else {
                return nil
            }
        } else if image.size.height == image.size.width {
            return image.resizeImage(newWidth: newWidth)
        } else {
            return nil
        }
    }
    
    static func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage? {
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    static func cropImage(image: UIImage?, toRect: CGRect) -> UIImage? {
        guard let image = image else { return nil }
        
        if let imageRef = image.cgImage!.cropping(to: toRect) {
            return UIImage(cgImage: imageRef, scale: 0, orientation: image.imageOrientation)
        }
        
        return nil
    }
    /** END: IMAGE FUNCTIONS **/
}
