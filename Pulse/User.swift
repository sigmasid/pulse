//
//  User.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import FirebaseDatabase

class User {
    var uID : String?
    var name : String?
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
        self.answers = nil
    }
    
    init(uID: String) {
        self.uID = uID
    }
    
    init(uID: String, name:String) {
        self.uID = uID
        self.name = name
    }
    
    init(uID: String, snapshot: FIRDataSnapshot) {
        self.uID = uID
        if snapshot.hasChild("name") {
            self.name = snapshot.childSnapshotForPath("name").value as? String
        }
        if snapshot.hasChild("profilePic") {
            self.profilePic = snapshot.childSnapshotForPath("profilePic").value as? String
        }
    }
    
    func isLoggedIn() -> Bool {
        return (self.uID != nil ? true : false)
    }
    
    func signOut() {
        self.uID = nil
        self.name = nil
        self.answers = nil
    }
}