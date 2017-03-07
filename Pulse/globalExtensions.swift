//
//  globalExtensions.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import UIKit

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
    func makeRound() {
        GlobalFunctions.makeRound(self)
        layer.masksToBounds = true
        clipsToBounds = true
    }
}

extension UICollectionViewCell {
    override func addShadow() {
        super.addShadow()
        
        contentView.layer.borderWidth = 1.0
        contentView.layer.borderColor = UIColor.clear.cgColor
        contentView.layer.masksToBounds = true
        
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: contentView.layer.cornerRadius).cgPath
    }
}

extension UIView {
    func addShadow() {
        layer.shadowColor = UIColor.lightGray.cgColor
        layer.shadowOffset = CGSize(width: 1, height: 2)
        layer.shadowRadius = 2.0
        layer.shadowOpacity = 0.5
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

//        let gradientLayer = CAGradientLayer()
//        self.view.backgroundColor = UIColor(red: 21/255, green: 27/255, blue: 31/255, alpha: 1.0)
//        gradientLayer.frame = self.view.bounds
//        
//        // 3
//        let color1 = UIColor(red: 21/255, green: 27/255, blue: 31/255, alpha: 1.0).CGColor as CGColorRef
//        let color2 = UIColor(red: 9/255, green: 21/255, blue: 77/255, alpha: 1.0).CGColor as CGColorRef
//        let color3 = UIColor(red: 50/255, green: 5/255, blue: 66/255, alpha: 1.0).CGColor as CGColorRef
//        let color4 = UIColor(red: 3/255, green: 1/255, blue: 1/255, alpha: 1.0).CGColor as CGColorRef
//        gradientLayer.colors = [color1, color2, color3, color4]
//        
//        // 4
//        gradientLayer.locations = [0.0, 0.25, 0.75, 1.0]
//        
//        // 5
//        self.view.layer.addSublayer(gradientLayer)
    }
    
//    func addHeader(text : String) -> LoginHeaderView {
//        let _headerView = UIView()
//        
//        view.addSubview(_headerView)
//        
//        _headerView.translatesAutoresizingMaskIntoConstraints = false
//        
//        if self.prefersStatusBarHidden {
//            _headerView.topAnchor.constraint(equalTo: topLayoutGuide.topAnchor, constant: Spacing.s.rawValue).isActive = true
//        } else {
//            _headerView.topAnchor.constraint(equalTo: topLayoutGuide.topAnchor, constant: Spacing.l.rawValue).isActive = true
//        }
//        _headerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        _headerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/12).isActive = true
//        _headerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
//        _headerView.layoutIfNeeded()
//        
//        let _loginHeader = LoginHeaderView(frame: _headerView.bounds)
//        _loginHeader.setAppTitleLabel(_message: "PULSE")
//        _loginHeader.setScreenTitleLabel(_message: text)
//        _headerView.addSubview(_loginHeader)
//        
//        return _loginHeader
//    }
    
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

extension UILabel {
    func setFont(_ size : CGFloat, weight : CGFloat, color : UIColor, alignment : NSTextAlignment) {
        self.textAlignment = alignment
        self.font = UIFont.systemFont(ofSize: size, weight: weight)
        self.textColor = color
        self.numberOfLines = 0
        self.lineBreakMode = .byWordWrapping
    }
    
    func setPreferredFont(_ color : UIColor, alignment : NSTextAlignment) {
        self.textAlignment = alignment
        self.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption2)
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
        self.backgroundColor = pulseRed
    }
    
    func setDisabled() {
        self.isEnabled = false
        self.alpha = 0.5
        self.backgroundColor = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 1.0 )
    }
    
    func addLoadingIndicator() -> UIView {
        let _loadingIndicatorFrame = CGRect(x: 5, y: 0, width: self.frame.height, height: self.frame.height)
        let _loadingIndicator = LoadingIndicatorView(frame: _loadingIndicatorFrame, color: UIColor.white)
        self.addSubview(_loadingIndicator)
        return _loadingIndicator
    }
    
    func removeLoadingIndicator(_ indicator : UIView) {
        indicator.removeFromSuperview()
    }
    
    func makeRound() {
        GlobalFunctions.makeRound(self)
    }
    
    func setButtonFont(_ size : CGFloat, weight : CGFloat, color : UIColor, alignment : NSTextAlignment) {
        self.titleLabel?.textAlignment = alignment
        self.titleLabel?.font = UIFont.systemFont(ofSize: size, weight: weight)
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
}

extension Double {
    var degreesToRadians : CGFloat {
        return CGFloat(self) * CGFloat(M_PI) / 180.0
    }
}

extension TimeInterval {
    var time:String {
        return String(format:"%02d:%02d", Int(self/60.0),  Int(ceil(self.truncatingRemainder(dividingBy: 60))) )
    }
}

enum AnimationStyle {
    case verticalUp
    case verticalDown
    case horizontal
    case horizontalFlip
}

enum ContentManagerDismissalType {
    case seeAll
    case reachedEnd
}

enum FollowToggle {
    case follow
    case unfollow
}

enum IconSizes: CGFloat {
    case xxSmall = 10
    case xSmall = 20
    case small = 35
    case medium = 50
    case large = 75
    case xLarge = 100
}

enum IconThickness: CGFloat {
    case thin = 1.0
    case medium = 2.0
    case thick = 3.0
    case extraThick = 5.0
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

enum Spacing: CGFloat {
    case xxs = 5
    case xs = 10
    case s = 20
    case m = 30
    case l = 40
    case xl = 50
}

enum buttonCornerRadius : CGFloat {
    case regular = 20
    case small = 10
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

enum PageType {
    case home
    case detail
    case explore
}

enum Element : String {
    case Channels = "channels"
    case ChannelItems = "channelItems"
    
    case Items = "items"
    case ItemThumbs = "itemThumbnails"
    case ItemCollection = "itemCollection"
    case ItemStats = "itemStats"
    
    case Users = "users"
    case UserDetailedSummary = "userDetailedPublicSummary"
    case UserSummary = "userPublicSummary"

    case Filters = "filters"
    case Settings = "settings"
    case Feed = "savedChannels"
    case SettingSections = "settingsSections"
    
    case Messages = "messages"
    case Conversations = "conversations"
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

struct ItemMetaData {
    var itemCollection = [Item]() //this is the collection within the answer - i.e. all the posts
    
    var gettingImageForPreview : Bool = false
    var gettingInfoForPreview : Bool = false
}

/* EXTEND CUSTOM LOADING */
