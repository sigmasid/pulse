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
    var items = [Item]()
    
    var profilePic : String?
    var thumbPic : String?
    var thumbPicImage : UIImage?
    
    var approvedChannels = [Channel]()
    
    var shownCameraForQuestion = [ String : String ]()
    var _totalItems : Int?
    var subscriptions = [Channel : String?]()
    var subscriptionIDs = [String]()
    
    var savedItems = [String : String?]()
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
        
        if detailedSnapshot.hasChild("items") {
            for child in detailedSnapshot.childSnapshot(forPath: "items").children {
                if let child = child as? FIRDataSnapshot, let type = child.value as? String {
                    let item = Item(itemID: child.key, type: type)
                    self.items.append(item)
                }
            }
        }
        
        if detailedSnapshot.hasChild("approvedChannels") {
            for child in detailedSnapshot.childSnapshot(forPath: "approvedChannels").children {
                let channel = Channel(cID: (child as AnyObject).key)
                channel.cTitle = (child as! FIRDataSnapshot).value as? String
                self.approvedChannels.append(channel)
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
    func canAnswer(itemID: String, tag : Item, completion: (Bool, String?, String?) -> Void) {
        completion(true, nil, nil)
        
        /** if user has not answered the question and is an expert in the tag then allowed to answer question
        if !hasAnsweredQuestion(itemID), expertiseTags.contains(tag) {
            completion(true, nil, nil)
        } else if hasAnsweredQuestion(itemID) {
            completion(false, "Already Answered!", "Sorry you can only answer a question once")
        } else if !expertiseTags.contains(tag) {
            completion(false, "Experts Only!", "Are you an expert? Apply to get approved!")
        } **/
    }
    
    func isSubscribedToChannel(cID: String) -> Bool {
        return self.subscriptionIDs.contains(cID)
    }
    
    func totalItems() -> Int {
        return items.count
    }
    
    func getEmail() -> String? {
        return FIRAuth.auth()?.currentUser?.email
    }
    
    func hasExpertise() -> Bool {
        return self.approvedChannels.isEmpty ? false : true
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
