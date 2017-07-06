//
//  globalExtensions.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    static var iconBackgroundColor: UIColor  { return UIColor( red: 237/255, green: 19/255, blue:90/255, alpha: 1.0 ) }
    static var pulseBlue: UIColor  { return UIColor(red: 67/255, green: 217/255, blue: 253/255, alpha: 1.0) }
    static var pulseRed: UIColor  { return UIColor(red: 238/255, green: 49/255, blue: 93/255, alpha: 1.0) }
    static var pulseGrey: UIColor  { return UIColor(red: 233/255, green: 233/255, blue: 233/255, alpha: 1.0) }
    static var pulseDarkGrey: UIColor  { return UIColor(red: 35/255, green: 31/255, blue: 32/255, alpha: 1.0) }
    static var placeholderGrey: UIColor  { return UIColor(red: 199/255, green: 199/255, blue: 205/255, alpha: 1.0) }
}

extension UIFont {
    static func pulseFont(ofWeight: CGFloat, size : CGFloat) -> UIFont {
        switch ofWeight {
        case UIFontWeightBold:
            return UIFont(name: "Avenir-Black", size: size) ?? UIFont.systemFont(ofSize: size, weight: ofWeight)
        case UIFontWeightBlack:
            return UIFont(name: "AvenirNext-Black", size: size) ?? UIFont.systemFont(ofSize: size, weight: ofWeight)
        case UIFontWeightHeavy:
            return UIFont(name: "Avenir-Heavy", size: size) ?? UIFont.systemFont(ofSize: size, weight: ofWeight)
        case UIFontWeightRegular:
            return UIFont(name: "Avenir-Roman", size: size) ?? UIFont.systemFont(ofSize: size, weight: ofWeight)
        case UIFontWeightThin:
            return UIFont(name: "Avenir-Light", size: size) ?? UIFont.systemFont(ofSize: size, weight: ofWeight)
        case UIFontWeightMedium:
            return UIFont(name: "Avenir-Medium", size: size) ?? UIFont.systemFont(ofSize: size, weight: ofWeight)
        default:
            return UIFont(name: "Avenir-Book", size: size) ?? UIFont.systemFont(ofSize: size, weight: ofWeight)
        }
    }
}

class PaddingLabel: UILabel {
    
    @IBInspectable var topInset: CGFloat = 2.5
    @IBInspectable var bottomInset: CGFloat = 2.5
    @IBInspectable var leftInset: CGFloat = 5.0
    @IBInspectable var rightInset: CGFloat = 5.0
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: UIEdgeInsetsInsetRect(rect, UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)))
    }
    
    // Override -intrinsicContentSize: for Auto layout code
    override var intrinsicContentSize : CGSize {
        let superContentSize = super.intrinsicContentSize
        let width = superContentSize.width + leftInset + rightInset
        let heigth = superContentSize.height + topInset + bottomInset
        return CGSize(width: width, height: heigth)
    }
    
    // Override -sizeThatFits: for Springs & Struts code
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let superSizeThatFits = super.sizeThatFits(size)
        let width = superSizeThatFits.width + leftInset + rightInset
        let heigth = superSizeThatFits.height  + topInset + bottomInset
        return CGSize(width: width, height: heigth)
    }
}

extension UIImageView {
    override func makeRound() {
        super.makeRound()
        layer.masksToBounds = true
        clipsToBounds = true
    }
}

extension UICollectionViewCell {
    override func addShadow(cornerRadius: CGFloat = 0) {
        super.addShadow()
        
        contentView.layer.borderWidth = 1.0
        contentView.layer.borderColor = UIColor.clear.cgColor
        contentView.layer.masksToBounds = true
        
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: contentView.layer.cornerRadius).cgPath
    }
}

extension UIView {
    func addShadow(cornerRadius: CGFloat = 0) {
        if cornerRadius > 0 {
            layer.shadowColor = UIColor.lightGray.cgColor
            layer.shadowOpacity = 1

            let loweredShadowOffset  = CGSize(width: 0.5, height: 0.5)
            let downRect = CGRect(x: bounds.origin.x - loweredShadowOffset.width,
                              y: bounds.origin.y + loweredShadowOffset.height,
                              width: bounds.size.width + loweredShadowOffset.width,
                              height: bounds.size.height + loweredShadowOffset.height)
            
            layer.shadowRadius = 0.5
            layer.shadowPath = UIBezierPath.init(roundedRect: downRect , cornerRadius: cornerRadius).cgPath
            layer.shadowOffset = loweredShadowOffset
            
        } else {
            layer.addBorder(edge: .bottom, color: .pulseGrey, thickness: 1.0)
            
            layer.shadowColor = UIColor.lightGray.cgColor
            layer.shadowOffset = CGSize(width: 1, height: 2)
            layer.shadowRadius = 2.0
            layer.shadowOpacity = 0.5
        }
        
        layer.masksToBounds = false
    }
    
    func addBottomBorder(color: UIColor = .darkGray, thickness: CGFloat = 1.0) {
        layer.addBorder(edge: .bottom, color: color, thickness: thickness)
    }
    
    func addBorder(color : UIColor = .darkGray, thickness: CGFloat = 1.0) {
        layer.addBorder(color: color, thickness: thickness)
    }
    
    func makeRound() {
        layer.cornerRadius = frame.width > frame.height ?  5 : frame.width / 2
    }
    
    func shrinkDismiss(duration: Double = 0.3) {
        let endFrame = CGRect(x: frame.width / 2 - 2, y: frame.height / 2 - 2,
                              width: 4, height: 4)
        
        let maskPath : UIBezierPath = UIBezierPath(arcCenter: CGPoint(x: frame.midX, y: frame.midY), radius: frame.width / 2, startAngle: 0, endAngle: 180, clockwise: true)
        let maskLayer = CAShapeLayer()
        maskLayer.frame = frame
        maskLayer.path = maskPath.cgPath
        
        let smallCirclePath = UIBezierPath(ovalIn: endFrame)
        maskLayer.path = smallCirclePath.cgPath
        layer.mask = maskLayer
        
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = maskPath.cgPath
        pathAnimation.toValue   = smallCirclePath
        pathAnimation.duration  = duration
        
        let opacityAnimation = CABasicAnimation(keyPath:"opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.3
        opacityAnimation.duration = duration
        
        CATransaction.begin()
        
        CATransaction.setCompletionBlock {
            self.isHidden = true
            self.layer.mask = nil
        }
        
        maskLayer.add(pathAnimation, forKey:"pathAnimation")
        maskLayer.add(opacityAnimation, forKey:"opacityAnimation")
        
        CATransaction.commit()
    }
}

// To dismiss keyboard when needed
extension UIViewController {
    func getRectToLeft() -> CGRect {
        var rectToLeft = view.frame
        rectToLeft.origin.x = view.frame.minX - view.frame.size.width
        return rectToLeft
    }
    
    func getRectToRight() -> CGRect {
        var rectToRight = view.frame
        rectToRight.origin.x = view.frame.maxX
        return rectToRight
    }
    
    func goBack() {
        if let nav = navigationController {
            let _ = nav.popViewController(animated: true)
        }
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func setDarkBackground() {
        self.view.backgroundColor = UIColor(red: 35/255, green: 31/255, blue: 32/255, alpha: 1.0)
    }
    
    func setGradientBackground() {
        let gradientLayer = CAGradientLayer()
        self.view.backgroundColor = UIColor(red: 21/255, green: 27/255, blue: 31/255, alpha: 1.0)
        gradientLayer.frame = self.view.bounds

        // 3
        let color1 = UIColor(red: 21/255, green: 27/255, blue: 31/255, alpha: 1.0).cgColor as CGColor
        let color2 = UIColor(red: 9/255, green: 21/255, blue: 77/255, alpha: 1.0).cgColor as CGColor
        let color3 = UIColor(red: 50/255, green: 5/255, blue: 66/255, alpha: 1.0).cgColor as CGColor
        let color4 = UIColor(red: 3/255, green: 1/255, blue: 1/255, alpha: 1.0).cgColor as CGColor
        gradientLayer.colors = [color1, color2, color3, color4]

        // 4
        gradientLayer.locations = [0.0, 0.25, 0.75, 1.0]
        
        // 5
        self.view.layer.addSublayer(gradientLayer)
    }
    
    func addIcon(text : String) -> IconContainer {
        let iconContainer = IconContainer(frame: CGRect(x: 0,y: 0,width: IconSizes.medium.rawValue, height: IconSizes.medium.rawValue + Spacing.m.rawValue))
        iconContainer.setViewTitle(text)
        view.addSubview(iconContainer)
        
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Spacing.s.rawValue).isActive = true
        iconContainer.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue + Spacing.m.rawValue).isActive = true
        iconContainer.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        iconContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        iconContainer.layoutIfNeeded()
        
        return iconContainer
    }
}

extension UITextView {
    func setFont(_ size : CGFloat, weight : CGFloat, color : UIColor, alignment : NSTextAlignment) {
        self.textAlignment = alignment
        self.font = UIFont.pulseFont(ofWeight: weight, size: size)
        self.textColor = color
    }
}

class VerticallyCenteredTextView: UITextView {
    override var contentSize: CGSize {
        didSet {
            var topCorrection = (bounds.size.height - contentSize.height * zoomScale) / 2.0
            topCorrection = max(0, topCorrection)
            contentInset = UIEdgeInsets(top: topCorrection, left: 0, bottom: 0, right: 0)
        }
    }
}

extension UILabel {
    func setFont(_ size : CGFloat, weight : CGFloat, color : UIColor, alignment : NSTextAlignment) {
        self.textAlignment = alignment
        self.font = UIFont.pulseFont(ofWeight: weight, size: size)
        self.textColor = color
        self.numberOfLines = 0
        self.lineBreakMode = .byWordWrapping
    }
    
    func setPreferredFont(_ color : UIColor, alignment : NSTextAlignment) {
        self.textAlignment = alignment
        self.font = UIFont.pulseFont(ofWeight: UIFontWeightRegular, size: FontSizes.caption2.rawValue)
        self.textColor = color
        self.numberOfLines = 0
        self.lineBreakMode = .byWordWrapping
    }
    
    func addTextSpacing(_ spacing: CGFloat){
        if let _text = self.text {
            let attributedString = NSMutableAttributedString(string: _text)
            attributedString.addAttribute(NSKernAttributeName, value: spacing, range: NSRange(location: 0, length: self.text!.characters.count))
            self.attributedText = attributedString
        }
    }
    
    func setBlurredBackground() {
        textColor = .white
        shadowColor = .black
        
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 1
        layer.shadowRadius = 3
    }
    
    func removeShadow() {
        shadowColor = .clear
        
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 0
        layer.shadowRadius = 0
    }
}

fileprivate let minimumHitArea = CGSize(width: 50, height: 50)

extension UIButton {
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // if the button is hidden/disabled/transparent it can't be hit
        if self.isHidden || !self.isUserInteractionEnabled || self.alpha < 0.01 { return nil }
        
        // increase the hit frame to be at least as big as `minimumHitArea`
        let buttonSize = self.bounds.size
        let widthToAdd = max(minimumHitArea.width - buttonSize.width, 0) * 1.25
        let heightToAdd = max(minimumHitArea.height - buttonSize.height, 0) * 1.25
        let largerFrame = self.bounds.insetBy(dx: -widthToAdd / 2, dy: -heightToAdd / 2)
        
        // perform hit test on larger frame
        return (largerFrame.contains(point)) ? self : nil
    }
    
    func setEnabled() {
        self.isEnabled = true
        self.alpha = 1.0
        self.backgroundColor = .pulseRed
    }
    
    func setDisabled() {
        self.isEnabled = false
        self.alpha = 0.5
        self.backgroundColor = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 1.0 )
    }
    
    func addLoadingIndicator(color: UIColor = UIColor.white) -> UIView {
        let _loadingIndicatorFrame = CGRect(x: 5, y: 0, width: self.frame.height, height: self.frame.height)
        let _loadingIndicator = LoadingIndicatorView(frame: _loadingIndicatorFrame, color: color)
        self.addSubview(_loadingIndicator)
        return _loadingIndicator
    }
    
    func removeLoadingIndicator(_ indicator : UIView) {
        indicator.removeFromSuperview()
    }
    
    func setButtonFont(_ size : CGFloat, weight : CGFloat, color : UIColor, alignment : NSTextAlignment) {
        self.titleLabel?.textAlignment = alignment
        self.titleLabel?.font = UIFont.pulseFont(ofWeight: weight, size: size)
        self.setTitleColor(color, for: UIControlState())
    }
    
    func changeTint(color : UIColor, state : UIControlState) {
        let image = self.imageView?.image?.withRenderingMode(.alwaysTemplate)

        if let image = image {
            self.setImage(image, for: state)
            self.tintColor = color
        }
    }
}

extension UITextField {
    override func addBorder(color: UIColor, thickness: CGFloat) {
        super.addBottomBorder(color: color, thickness: thickness)
        layer.sublayerTransform = CATransform3DMakeTranslation(7.5, 0, 0)
    }
    
    func setFont(_ size : CGFloat, weight : CGFloat, color : UIColor, alignment : NSTextAlignment) {
        self.textAlignment = alignment
        self.font = UIFont.pulseFont(ofWeight: weight, size: size)
        self.textColor = color
    }
}

class PaddingTextField: UITextField {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        font = UIFont.pulseFont(ofWeight: UIFontWeightThin, size: FontSizes.body.rawValue)
        backgroundColor = UIColor.pulseGrey.withAlphaComponent(0.3)
        layer.cornerRadius = 5
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        font = UIFont.pulseFont(ofWeight: UIFontWeightThin, size: FontSizes.body.rawValue)
        backgroundColor = UIColor.pulseGrey.withAlphaComponent(0.3)
        layer.cornerRadius = 5
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.origin.x + 10, y: bounds.origin.y, width: bounds.width - 10, height: bounds.height)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.origin.x + 10, y: bounds.origin.y, width: bounds.width - 10, height: bounds.height)
    }
    
}

class PaddingTextView: UITextView {
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        font = UIFont.pulseFont(ofWeight: UIFontWeightThin, size: FontSizes.body.rawValue)
        backgroundColor = UIColor.pulseGrey.withAlphaComponent(0.3)
        layer.cornerRadius = 5
        textContainerInset = UIEdgeInsetsMake(7.5, 7.5, 7.5, 7.5)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        font = UIFont.pulseFont(ofWeight: UIFontWeightThin, size: FontSizes.body.rawValue)
        backgroundColor = UIColor.pulseGrey.withAlphaComponent(0.3)
        layer.cornerRadius = 5
    }
    
}

extension CALayer {
    
    func addBorder(edge: UIRectEdge, color: UIColor, thickness: CGFloat) {
        
        let border = CALayer()
        
        switch edge {
        case UIRectEdge.top:
            border.frame = CGRect.init(x: 0, y: 0, width: frame.width, height: thickness)
            break
        case UIRectEdge.bottom:
            border.frame = CGRect.init(x: 0, y: frame.height - thickness, width: frame.width, height: thickness)
            break
        case UIRectEdge.left:
            border.frame = CGRect.init(x: 0, y: 0, width: thickness, height: frame.height)
            break
        case UIRectEdge.right:
            border.frame = CGRect.init(x: frame.width - thickness, y: 0, width: thickness, height: frame.height)
            break
        default:
            break
        }
        
        border.backgroundColor = color.cgColor;
        self.addSublayer(border)
    }
    
    func addBorder(color: UIColor, thickness: CGFloat) {
        borderColor = color.cgColor
        borderWidth = thickness
    }
}

extension UIImage
{
    var highestQualityJPEGNSData: Data { return UIImageJPEGRepresentation(self, 1.0)! }
    var highQualityJPEGNSData: Data    { return UIImageJPEGRepresentation(self, 0.75)!}
    var mediumQualityJPEGNSData: Data  { return UIImageJPEGRepresentation(self, 0.5)! }
    var lowQualityJPEGNSData: Data     { return UIImageJPEGRepresentation(self, 0.25)!}
    var lowestQualityJPEGNSData: Data  { return UIImageJPEGRepresentation(self, 0.0)! }
    
    var circle: UIImage? {
        let square = CGSize(width: min(size.width, size.height), height: min(size.width, size.height))
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: square))
        imageView.backgroundColor = UIColor.black
        imageView.contentMode = .scaleAspectFill
        imageView.image = self
        imageView.layer.cornerRadius = square.width/2
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
    func imageWithColor(color: UIColor) -> UIImage? {
        var image = withRenderingMode(.alwaysTemplate)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        color.set()
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    func getSquareImage(newWidth: CGFloat) -> UIImage? {
        var cropRect: CGRect!
        
        if size.height > size.width, let returnImage = resizeImage(newWidth: newWidth) {
            cropRect = CGRect(x: 0, y: (returnImage.size.height / 2) - (newWidth / 2), width: newWidth, height: newWidth)
            return returnImage.cropImage(toRect: cropRect)
        } else if size.width > size.height {
            let scale = size.width / size.height
            if let returnImage = resizeImage(newWidth: newWidth * scale) {
                cropRect = CGRect(x: returnImage.size.width / 2 - newWidth / 2, y: 0, width: newWidth, height: newWidth)
                return returnImage.cropImage(toRect: cropRect)
            } else {
                return nil
            }
        } else if size.height == size.width {
            return resizeImage(newWidth: newWidth)
        } else {
            return nil
        }
    }
    
    func resizeImage(newWidth: CGFloat) -> UIImage? {
        let scale = newWidth / size.width
        let newHeight = size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func cropImage(toRect: CGRect) -> UIImage? {
        if let imageRef = cgImage!.cropping(to: toRect) {
            return UIImage(cgImage: imageRef, scale: 0, orientation: imageOrientation)
        }
        
        return nil
    }
    
    /// Extension to fix orientation of an UIImage without EXIF
    func fixOrientation() -> CGImage? {
        
        guard let cgImage = cgImage else { return nil }
        
        if imageOrientation == .up { return cgImage }
        
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
            
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
            
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2))
            
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat(-Double.pi / 2))
            
        case .up, .upMirrored:
            break
        }
        
        switch imageOrientation {
            
        case .upMirrored, .downMirrored:
            transform.translatedBy(x: size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
            
        case .leftMirrored, .rightMirrored:
            transform.translatedBy(x: size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
            
        case .up, .down, .left, .right:
            break
        }
        
        if let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: cgImage.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
            
            ctx.concatenate(transform)
            
            switch imageOrientation {
                
            case .left, .leftMirrored, .right, .rightMirrored:
                ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
                
            default:
                ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            }
            
            if let finalImage = ctx.makeImage() {
                return finalImage
            }
        }
        
        // something failed -- return original
        return cgImage
    }
}

extension Double {
    var degreesToRadians : CGFloat {
        return CGFloat(self) * CGFloat(Double.pi) / 180.0
    }
}

extension TimeInterval {
    var time:String {
        return String(format:"%02d:%02d", Int(self/60.0),  Int(ceil(self.truncatingRemainder(dividingBy: 60))) )
    }
}

/** START ENUMS **/

enum AuthStates {
    case loggedIn
    case loggedOut
}

enum AnimationStyle {
    case verticalUp
    case verticalDown
    case horizontal
    case horizontalFlip
}

enum FollowToggle {
    case follow
    case unfollow
}

enum IconSizes: CGFloat {
    case xxSmall = 20
    case xSmall = 30
    case small = 35
    case medium = 50
    case large = 75
    case xLarge = 100
}

enum IconThickness: CGFloat {
    case thin = 1.0
    case medium = 2.0
    case thick = 3.0
    case extraThick = 4.0
}

enum UserProfileUpdateType {
    case displayName
    case photoURL
}

enum VoteType {
    case favorite
    case upvote
    case downvote
}

enum IntroType {
    case login
    case other
}

enum TabType {
    case login
    case explore
    case conversations
    case home
}

enum AssetSize {
    case fullScreen
    case square
}

enum Spacing: CGFloat {
    case xxs = 5
    case xs = 10
    case s = 20
    case m = 30
    case l = 40
    case xl = 50
    case xxl = 60
    case max = 100
}

enum buttonCornerRadius : CGFloat {
    case regular = 20
    case small = 5
    case round = 0
    
    static func radius(_ type : buttonCornerRadius, width: Int) -> CGFloat {
        switch type {
        case .regular: return buttonCornerRadius.regular.rawValue
        case .small: return buttonCornerRadius.small.rawValue
        case .round: return CGFloat(width / 2)
        }
    }
    
    static func radius(_ type : buttonCornerRadius) -> CGFloat {
        switch type {
        case .regular: return buttonCornerRadius.regular.rawValue
        case .small: return buttonCornerRadius.small.rawValue
        case .round: return buttonCornerRadius.small.rawValue
        }
    }
}

enum FontSizes: CGFloat {
    case caption2 = 8
    case caption = 10
    case body2 = 12
    case body = 14
    case title = 16
    case headline = 20
    case headline2 = 30
    case mammoth = 40
}

enum ZoomDirection {
    case LEFT_DOWN
    case LEFT_UP
    case RIGHT_DOWN
    case RIGHT_UP
}

enum ZoomType {
    case IN
    case OUT
}

enum UserErrors: Error {
    case notLoggedIn
    case invalidData
}

/* CORE DATABASE */
enum SectionTypes : String {
    case activity = "activity"
    case personalInfo = "personalInfo"
    case account = "account"
    
    static func getSectionDisplayName(_ index : String) -> String? {
        switch index {
        case "activity": return "Activity"
        case "personalInfo": return "Personal Info"
        case "account": return "Account"
        default: return index
        }
    }
    
    static func getSectionType(_ index : String) -> SectionTypes? {
        switch index {
        case "account": return .account
        case "activity": return .activity
        case "personalInfo": return .personalInfo
        default: return nil
        }
    }
}

enum Element : String {
    case Channels = "channels"
    case ChannelItems = "channelItems"
    case ChannelContributors = "channelContributors"

    case Items = "items"
    case ItemThumbs = "itemThumbnails"
    case ItemCollection = "itemCollection"
    case ItemStats = "itemStats"
    
    case Users = "users"
    case UserDetailedSummary = "userDetailedPublicSummary"
    case UserSummary = "userPublicSummary"
    
    case Subscriptions = "subscriptions"
    case SavedItems = "savedItems"

    case Filters = "filters"
    case Settings = "settings"
    case Feed = "savedChannels"
    case SettingSections = "settingsSections"
    
    case Messages = "messages"
    case Conversations = "conversations"
    case Invites = "invites"
}

enum SettingTypes : String{
    case bio = "bio"
    case shortBio = "shortBio"
    case email = "email"
    case name = "name"
    case birthday = "birthday"
    case password = "password"
    case gender = "gender"
    case profilePic = "profilePic"
    case thumbPic = "thumbPic"
    case location = "location"
    case array = "array" //for saved tags / questions
    
    static func getSettingType(_ index : String) -> SettingTypes? {
        switch index {
        case "bio": return .bio
        case "shortBio": return .shortBio
        case "email": return .email
        case "name": return .name
        case "birthday": return .birthday
        case "password": return .password
        case "array": return .array
        case "gender": return .gender
        case "profilePic": return .profilePic
        case "thumbPic": return .thumbPic
        case "location": return .location

        default: return nil
        }
    }
}

enum CreatedAssetType: String {
    case recordedImage
    case albumImage
    case recordedVideo
    case albumVideo
    
    static func getAssetType(_ value : String?) -> CreatedAssetType? {
        if let _value = value {
            switch _value {
            case "recordedImage": return .recordedImage
            case "albumImage": return .albumImage
            case "recordedVideo": return .recordedVideo
            case "albumVideo": return .albumVideo
                
            default: return nil
            }
        } else {
            return nil
        }
    }
}

enum MediaAssetType {
    case video
    case image
    case unknown
    
    static func getAssetType(_ metadata : String) -> MediaAssetType? {
        switch metadata {
        case "video/mp4": return .video
        case "video/mpeg": return .video
        case "video/mpeg-4": return .video
        case "video/avi": return .video

        case "image/jpeg": return .image
        case "image/png": return .image
        case "image/gif": return .image
        case "image/pict": return .image
        case "image/tiff": return .image
        case "image/jpg": return .image
            
        default: return .unknown
        }
    }
}

enum MessageType: String {
    case message
    case contributorInvite

    case interviewInvite
    case channelInvite
    case showcaseInvite
    case perspectiveInvite
    case questionInvite
    case feedbackInvite
    
    static func getMessageType(type : String) -> MessageType {
        switch type {
        case "interviewInvite":
            return .interviewInvite
        case "channelInvite":
            return .channelInvite
        case "perspectiveInvite":
            return .perspectiveInvite
        case "questionInvite":
            return .perspectiveInvite
        case "contributorInvite":
            return .contributorInvite
        case "showcaseInvite":
            return .showcaseInvite
        case "feedbackInvite":
            return .feedbackInvite
        default:
            return .message
        }
    }
}

enum UserTypes: String {
    case user
    case guest
    case subscriber
    case contributor
    case editor
}

enum InputMode {
    case album
    case camera
}

struct ItemMetaData {
    var itemCollection = [Item]() //this is the collection within the answer - i.e. all the posts
    
    var gettingImageForPreview : Bool = false
    var gettingInfoForPreview : Bool = false
}

/* EXTEND CUSTOM LOADING */

/** PULSE ERROR **/
/**
public enum PulseError: Error {
    case invalidLogin
    case customError
}

extension PulseError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidLogin:
            return NSLocalizedString("Please login to continue", comment: "")
        case let .customError(msg):
            return \(msg)
        }
    }
} **/
