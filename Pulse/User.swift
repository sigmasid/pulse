//
//  User.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.

import Foundation
import FirebaseDatabase
import FirebaseAuth
import UIKit
import CoreLocation

class User {
    var uID : String?
    var name : String?
    var bio : String?
    var shortBio : String?
    var gender : String?
    var birthday : String?
    var location : CLLocation?
    var sLocation : String?
    var answers = [String]()
    var answeredQuestions = [String]()
    var profilePic : String?
    var thumbPic : String?
    var thumbPicImage : UIImage?

    var shownCameraForQuestion = [ String : String ]()
    var _totalAnswers : Int?
    var savedTags = [String : String?]()
    var savedQuestions = [String : String?]()
    var socialSources = [ Social : Bool ]()
    
    dynamic var uCreated = false

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
        
        uCreated = true
    }
    
    init(user: FIRUser) {
        self.uID = user.uid
    }
    
    static func isLoggedIn() -> Bool {
        return (User.currentUser?.uID != nil ? true : false)
    }
    
    func hasAnsweredQuestion(_ qID : String) -> Bool {
        print(answeredQuestions)
        return answeredQuestions.contains(qID) ? true : false
    }
    
    func hasSavedTags() -> Bool {
        return self.savedTags.isEmpty ? false : true
    }
    
    func totalAnswers() -> Int {
        return answers.count
    }
    
    func getEmail() -> String? {
        return FIRAuth.auth()?.currentUser?.email
    }
    
    func getLocation(completion: @escaping (String?) -> Void) {
        if let sLocation = self.sLocation {
            completion(sLocation)
        } else if let location = self.location {
            Database.getCityFromLocation(location: location, completion: {(city) in
                self.sLocation = city != nil ? city : nil
                city != nil ? completion(city!) : completion(nil)
            })
        }
        else {
            Database.getUserLocation(completion: {(location, error) in
                if let _location = location {
                    self.location = _location
                    Database.getCityFromLocation(location: _location, completion: {(city) in
                        self.sLocation = city != nil ? city : nil
                        city != nil ? completion(city!) : completion(nil)
                    })
                } else {
                    completion(nil)
                }
            })
        }
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
