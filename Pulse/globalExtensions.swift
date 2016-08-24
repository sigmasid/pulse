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
    
    let padding = UIEdgeInsets(top: 2.5, left: 5, bottom: 2.5, right: 5)
    
    override func drawTextInRect(rect: CGRect) {
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, padding))
    }
    
    // Override -intrinsicContentSize: for Auto layout code
    override func intrinsicContentSize() -> CGSize {
        let superContentSize = super.intrinsicContentSize()
        let width = superContentSize.width + padding.left + padding.right
        let heigth = superContentSize.height + padding.top + padding.bottom
        return CGSize(width: width, height: heigth)
    }
    
    // Override -sizeThatFits: for Springs & Struts code
    override func sizeThatFits(size: CGSize) -> CGSize {
        let superSizeThatFits = super.sizeThatFits(size)
        let width = superSizeThatFits.width + padding.left + padding.right
        let heigth = superSizeThatFits.height + padding.top + padding.bottom
        return CGSize(width: width, height: heigth)
    }
}

// To dismiss keyboard when needed
extension UIViewController {
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
}

extension UILabel {
    func setPreferredFont(color : UIColor, alignment : NSTextAlignment) {
        self.textAlignment = alignment
        self.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
        self.textColor = color
        self.numberOfLines = 0
        self.lineBreakMode = .ByWordWrapping
    }
    
    func addTextSpacing(spacing: CGFloat){
        if let _text = self.text {
            let attributedString = NSMutableAttributedString(string: _text)
            attributedString.addAttribute(NSKernAttributeName, value: spacing, range: NSRange(location: 0, length: self.text!.characters.count))
            self.attributedText = attributedString
        }
    }
}

extension UIButton {
    func setEnabled() {
        self.enabled = true
        self.alpha = 1.0
        self.backgroundColor = UIColor(red: 245/255, green: 44/255, blue: 90/255, alpha: 1.0 )
    }
    
    func setDisabled() {
        self.enabled = false
        self.alpha = 0.5
        self.backgroundColor = UIColor(red: 57/255, green: 63/255, blue: 75/255, alpha: 1.0 )
    }
    
    func addLoadingIndicator() -> UIView {
        let _loadingIndicatorFrame = CGRectMake(5, 0, self.frame.height, self.frame.height)
        let _loadingIndicator = LoadingIndicatorView(frame: _loadingIndicatorFrame, color: UIColor.whiteColor())
        self.addSubview(_loadingIndicator)
        return _loadingIndicator
    }
    
    func removeLoadingIndicator(indicator : UIView) {
        indicator.removeFromSuperview()
    }
    
    func makeRound() {
        self.layer.cornerRadius = self.frame.width / 2
    }
}

extension UIImage
{
    var highestQualityJPEGNSData: NSData { return UIImageJPEGRepresentation(self, 1.0)! }
    var highQualityJPEGNSData: NSData    { return UIImageJPEGRepresentation(self, 0.75)!}
    var mediumQualityJPEGNSData: NSData  { return UIImageJPEGRepresentation(self, 0.5)! }
    var lowQualityJPEGNSData: NSData     { return UIImageJPEGRepresentation(self, 0.25)!}
    var lowestQualityJPEGNSData: NSData  { return UIImageJPEGRepresentation(self, 0.0)! }
}

extension Double {
    var degreesToRadians : CGFloat {
        return CGFloat(self) * CGFloat(M_PI) / 180.0
    }
}

extension NSTimeInterval {
    var time:String {
        return String(format:"%02d:%02d", Int(self/60.0),  Int(ceil(self%60)) )
    }
}

enum AnimationStyle {
    case VerticalUp
    case VerticalDown
    case Horizontal
    case HorizontalFlip
}

enum IconSizes: CGFloat {
    case XXSmall = 10
    case XSmall = 20
    case Small = 25
    case Medium = 50
    case Large = 75
}

enum IconThickness: CGFloat {
    case Thin = 1.0
    case Medium = 2.0
    case Thick = 3.0
}

enum UserProfileUpdateType {
    case displayName
    case photoURL
}

enum AnswerVoteType {
    case Upvote
    case Downvote
}

enum SaveType {
    case Save
    case Unsave
}

enum Spacing: CGFloat {
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
    
    static func radius(type : buttonCornerRadius, width: Int) -> CGFloat {
        switch type {
        case .regular: return buttonCornerRadius.regular.rawValue
        case .small: return buttonCornerRadius.small.rawValue
        case .round: return CGFloat(width / 2)
        }
    }
    
    static func radius(type : buttonCornerRadius) -> CGFloat {
        switch type {
        case .regular: return buttonCornerRadius.regular.rawValue
        case .small: return buttonCornerRadius.small.rawValue
        case .round: return buttonCornerRadius.small.rawValue
        }
    }
}


enum FontSizes: CGFloat {
    case Caption2 = 8
    case Caption = 10
    case Body = 14
    case Title = 16
    case Headline = 20
}

enum UserErrors: ErrorType {
    case NotLoggedIn
    case InvalidData
}

/* CORE DATABASE */
enum SectionTypes : String {
    case activity = "activity"
    case personalInfo = "personalInfo"
    case account = "account"
    
    static func getSectionDisplayName(index : String) -> String? {
        switch index {
        case "activity": return "Activity"
        case "personalInfo": return "Personal Info"
        case "account": return "Account"
        default: return index
        }
    }
    
    static func getSectionType(index : String) -> SectionTypes? {
        switch index {
        case "account": return .account
        case "activity": return .activity
        case "personalInfo": return .personalInfo
        default: return nil
        }
    }
}

enum Item : String {
    case Tags = "tags"
    case Questions = "questions"
    case Answers = "answers"
    case Users = "users"
    case Filters = "filters"
    case Settings = "settings"
    case SettingSections = "settingsSections"
    case AnswerThumbs = "answerThumbnails"
    case AnswerCollections = "answerCollections"
    case UserSummary = "userPublicSummary"
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
    case array = "array"
    
    static func getSettingType(index : String) -> SettingTypes? {
        switch index {
        case "bio": return .bio
        case "shortBio": return .shortBio
        case "email": return .email
        case "name": return .name
        case "birthday": return .birthday
        case "password": return .password
        case "array": return .array
        case "gender": return .array
        case "profilePic": return .profilePic

        default: return nil
        }
    }
}

enum CreatedAssetType {
    case recordedImage
    case albumImage
    case recordedVideo
    case albumVideo
    
    static func getAssetType(value : String?) -> CreatedAssetType? {
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
    
    static func getAssetType(metadata : String) -> MediaAssetType? {
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

/* EXTEND CUSTOM LOADING */