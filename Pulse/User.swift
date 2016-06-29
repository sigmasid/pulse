//
//  User.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation

class User {
    var uID : String?
    var name : String?
    var screenName : String?
    var answers : [String]?
    var askedToAnswerCurrentQuestion = false
    var profilePic : String?
    
    class var currentUser: User {
        struct Static {
            static let instance: User = User()
        }
        return Static.instance
    }
    
    init() {
        self.uID = nil
        self.name = nil
        self.screenName = nil
        self.answers = nil
    }
    
    init(uID: String) {
        self.uID = uID
    }
    
    init(uID: String, screenName: String) {
        self.uID = uID
        self.screenName = screenName
    }
    
    init(uID: String, name:String) {
        self.uID = uID
        self.name = name
    }
    
    func isLoggedIn() -> Bool {
        return (self.uID != nil ? true : false)
    }
    
    func signOut() {
        self.uID = nil
        self.name = nil
        self.screenName = nil
        self.answers = nil
    }
}