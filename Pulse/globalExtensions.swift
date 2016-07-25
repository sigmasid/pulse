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

enum Source {
    case Storage    
    case Database
}

/* EXTEND CUSTOM LOADING */