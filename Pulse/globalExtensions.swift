//
//  globalExtensions.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import UIKit

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
        view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.95)
    }
}

extension UILabel {
    func setPreferredFont(color : UIColor) {
        self.textAlignment = .Center
        self.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
        self.textColor = color
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

enum Spacing: CGFloat {
    case xs = 10
    case s = 20
    case m = 30
    case l = 40
    case xl = 50
}

enum Item : String {
    case Tags = "tags"
    case Questions = "questions"
    case Answers = "answers"
    case Users = "users"
    case Filters = "filters"
    case Settings = "settings"
    case SettingSections = "settingsSections"
}

enum UserErrors: ErrorType {
    case NotLoggedIn
    case InvalidData
}

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

enum SettingTypes : String{
    case bio = "bio"
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

/* EXTEND CUSTOM LOADING */