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
    var bio : String?
    var shortBio : String?
    var gender : String?
    var birthday : String?
    var answers : [String]?
    var answeredQuestions : [String]?
    var profilePic : String?
    var thumbPic : String?
    var shownCameraForQuestion = [ String : String ]()
    var _totalAnswers : Int?
    var savedTags = [String : String?]()
    var savedQuestions = [String : String?]()
    var socialSources = [ Social : Bool ]()

    enum Gender {
        case male
        case female
    }
    
    enum Social {
        case facebook
        case twitter
        case linkedin
    }
    
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
            self.name = snapshot.childSnapshot(forPath: "name").value as? String
        }
        
        if snapshot.hasChild("profilePic") {
            self.profilePic = snapshot.childSnapshot(forPath: "profilePic").value as? String
        }
        
        if snapshot.hasChild("thumbPic") {
            self.thumbPic = snapshot.childSnapshot(forPath: "thumbPic").value as? String
        } else {
            self.thumbPic = self.profilePic
        }

        if snapshot.hasChild("shortBio") {
            self.shortBio = snapshot.childSnapshot(forPath: "shortBio").value as? String
        }
    }
    
    init(user: FIRUser) {
        self.uID = user.uid
    }
    
    static func isLoggedIn() -> Bool {
        return (User.currentUser?.uID != nil ? true : false)
    }
    
    func hasAnsweredQuestion(_ qID : String) -> Bool {
        if let _answeredQuestions = answeredQuestions {
            return _answeredQuestions.contains(qID) ? true : false
        } else {
            return false
        }
    }
    
    func hasSavedTags() -> Bool {
        return self.savedTags.isEmpty ? false : true
    }
    
    func totalAnswers() -> Int {
        return _totalAnswers ?? 0
    }
    
    func getEmail() -> String? {
        return FIRAuth.auth()?.currentUser?.email
    }
    
    func getValueForStringProperty(_ property : String) -> String? {
        switch property {
        case "name": return User.currentUser!.name
        case "shortBio": return User.currentUser!.shortBio
        case "bio": return User.currentUser!.bio
        case "birthday": return User.currentUser!.birthday
        case "gender": return User.currentUser!.gender
        case "email": return getEmail()
        case "password": return nil
        default: return nil
        }
    }
}
