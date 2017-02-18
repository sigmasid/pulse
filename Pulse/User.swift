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
    var answers = [Answer]()
    var answeredQuestions = [String]()
    var profilePic : String?
    var thumbPic : String?
    var thumbPicImage : UIImage?
    var expertiseTags = [Tag]()
    
    var shownCameraForQuestion = [ String : String ]()
    var _totalAnswers : Int?
    var savedTags = [Tag : String?]()
    var savedTagIDs = [String]()
    var savedQuestions = [String : String?]()
    var savedVotes = [String : Bool]()
    var socialSources = [ Social : Bool ]()
    
    dynamic var uCreated = false
    dynamic var uDetailedCreated = false
    
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
    
    func updateUser(detailedSnapshot : FIRDataSnapshot) {
        if detailedSnapshot.hasChild("bio") {
            self.bio = detailedSnapshot.childSnapshot(forPath: "bio").value as? String
        }
        
        if detailedSnapshot.hasChild("answers") {
            for child in detailedSnapshot.childSnapshot(forPath: "answers").children {
                let currentAnswer = Answer(aID: (child as AnyObject).key, qID: (child as AnyObject).value)
                self.answers.append(currentAnswer)
            }
        }
        
        if detailedSnapshot.hasChild("expertiseTags") {
            for child in detailedSnapshot.childSnapshot(forPath: "expertiseTags").children {
                let tagTitle = (child as! FIRDataSnapshot).value as? String
                let currentTag = Tag(tagID: (child as AnyObject).key, tagTitle: tagTitle ?? "")
                self.expertiseTags.append(currentTag)
            }
        }
        
        uDetailedCreated = true
    }
    
    init(user: FIRUser) {
        self.uID = user.uid
    }
    
    static func isLoggedIn() -> Bool {
        return (FIRAuth.auth()?.currentUser != nil ? true : false)
    }
    
    /// Returns if user can answer question in given tag
    func canAnswer(qID: String, tag : Tag, completion: (Bool, String?, String?) -> Void) {
        // if user has not answered the question and is an expert in the tag then allowed to answer question
        if !hasAnsweredQuestion(qID), expertiseTags.contains(tag) {
            completion(true, nil, nil)
        } else if hasAnsweredQuestion(qID) {
            completion(false, "Already Answered!", "Sorry you can only answer a question once")
        } else if !expertiseTags.contains(tag) {
            completion(false, "Experts Only", "Are you an expert? Apply to answer!")
        }
    }
    
    func hasAnsweredQuestion(_ qID : String) -> Bool {
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
    
    func hasExpertise() -> Bool {
        return self.expertiseTags.isEmpty ? false : true
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
    
    func createShareLink(completion: @escaping (String?) -> Void) {
        guard let uID = self.uID else {
            completion(nil)
            return
        }
        
        Database.createShareLink(linkString: "u/"+uID, completion: { link in
            completion(link)
        })
    }
}
