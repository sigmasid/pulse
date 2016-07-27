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
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func setDarkBackground() {
        view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.95)
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

enum LoadMoreStatus{
    case Loading
    case Finished
    case haveMore
}

enum AnimationStyle {
    case VerticalUp
    case VerticalDown
    case Horizontal
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
}

enum UserErrors: ErrorType {
    case NotLoggedIn
    case InvalidData
}

/* EXTEND CUSTOM LOADING */