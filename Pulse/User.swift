//
//  User.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

class User {
    var uID : String?
    var name : String?
    var answers : [String]?
    var answeredQuestions : [String]?
    var profilePic : String?
    var shownCameraForQuestion = [ String : String ]()
    var _totalAnswers : Int?
    
    class var currentUser: User? {
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
    
    init(uID: String?) {
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
    
    init(user: FIRUser) {
        self.uID = user.uid
    }
    
    static func isLoggedIn() -> Bool {
        return (User.currentUser?.uID != nil ? true : false)
    }
    
    func hasAnsweredQuestion(qID : String) -> Bool {
        if let _answeredQuestions = answeredQuestions {
            return _answeredQuestions.contains(qID) ? true : false
        } else {
            return false
        }
    }
    
    func totalAnswers() -> Int {
        return _totalAnswers ?? 0
    }
}