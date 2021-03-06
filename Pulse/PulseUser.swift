//
//  User.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.

import Foundation
import FirebaseDatabase
import FirebaseAuth
import UIKit
import CoreLocation

class PulseUser: User {
    var uID : String?
    var name : String?
    var bio : String?
    var shortBio : String?
    var gender : String?
    var birthday : String?
    var location : CLLocation?
    var sLocation : String?
    lazy var items = [Item]()
    
    var profilePic : String?
    var thumbPic : String?
    
    lazy var contributorChannels : [Channel] = [Channel]()
    lazy var editorChannels : [Channel] = [Channel]()

    lazy var shownCameraForQuestion = [ String : String ]()
    lazy var subscriptions : [Channel] = [Channel]()
    lazy var subscriptionIDs = [String]()
    
    lazy var savedItems : [Item] = [Item]()
    lazy var savedVotes = [String : Bool]()
    
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
    
    class var currentUser: PulseUser {
        struct Static {
            static let instance: PulseUser = PulseUser(uID: Auth.auth().currentUser?.uid ?? nil)
        }
        return Static.instance
    }
    
    
    /** override init() {
        self.uID = nil
        self.name = nil
    } **/
    
    init(uID: String?) {
        self.uID = uID
    }
    
    init(uID: String, name:String) {
        self.uID = uID
        self.name = name
    }
    
    init(uID: String, snapshot: DataSnapshot) {
        self.uID = uID
        if snapshot.hasChild("name"), let _name = snapshot.childSnapshot(forPath: "name").value as? String {
            name = _name
        }
        
        if snapshot.hasChild("profilePic"), let _profilePic = snapshot.childSnapshot(forPath: "profilePic").value as? String {
            profilePic = _profilePic
        }
        
        if snapshot.hasChild("thumbPic"), let _thumbPic = snapshot.childSnapshot(forPath: "thumbPic").value as? String {
            thumbPic = _thumbPic
        } else {
            thumbPic = self.profilePic
        }

        if snapshot.hasChild("shortBio"), let _shortBio = snapshot.childSnapshot(forPath: "shortBio").value as? String {
            shortBio = _shortBio
        }
        
        uCreated = true
    }
    
    func updateUser(detailedSnapshot : DataSnapshot) {
        if detailedSnapshot.hasChild("bio"), let _bio = detailedSnapshot.childSnapshot(forPath: "bio").value as? String {
            bio = _bio
        }
        
        if detailedSnapshot.hasChild("items") {
            for child in detailedSnapshot.childSnapshot(forPath: "items").children {
                if let child = child as? DataSnapshot, let type = child.value as? String {
                    let item = Item(itemID: child.key, type: type)
                    items.append(item)
                }
            }
        }
        
        if detailedSnapshot.hasChild("contributorChannels") {
            for child in detailedSnapshot.childSnapshot(forPath: "contributorChannels").children {
                let channel = Channel(cID: (child as AnyObject).key)
                channel.cTitle = (child as! DataSnapshot).value as? String
                contributorChannels.append(channel)
            }
        }
        
        uDetailedCreated = true
    }
    
    static func isLoggedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
    
    func isSubscribedToChannel(cID: String) -> Bool {
        return subscriptionIDs.contains(cID)
    }
    
    func totalItems() -> Int {
        return items.count
    }
    
    func getEmail() -> String? {
        return Auth.auth().currentUser?.email
    }
    
    //Check if user is Contributor
    //Contributors can invite guests, add answers, start new items
    func isContributor(for channel : Channel) -> Bool {
        return contributorChannels.contains(channel) ? true : false
    }
    
    //Check if user is Editor
    //Editors can invite new contributors, invite guests, and all other permissions that contributors have
    func isEditor(for channel : Channel) -> Bool {
        return editorChannels.contains(channel) ? true : false
    }
    
    func getFirstName() -> String? {
        let firstNameArray = name?.components(separatedBy: " ")
        return firstNameArray != nil ? firstNameArray![0] : nil
    }

    
    func getLocation(completion: @escaping (String?) -> Void) {
        if let sLocation = self.sLocation {
            completion(sLocation)
        } else if let location = self.location {
            PulseDatabase.getCityFromLocation(location: location, completion: {[weak self] (city) in
                guard let `self` = self else {
                    return
                }
                
                self.sLocation = city != nil ? city : nil
                city != nil ? completion(city!) : completion(nil)
            })
        }
        else {
            PulseDatabase.getUserLocation(completion: {[weak self] (location, error) in
                if let _location = location, let `self` = self {
                    self.location = _location
                    PulseDatabase.getCityFromLocation(location: _location, completion: {(city) in
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
        case "name": return PulseUser.currentUser.name?.capitalized
        case "shortBio": return PulseUser.currentUser.shortBio
        case "bio": return PulseUser.currentUser.bio
        case "birthday": return PulseUser.currentUser.birthday
        case "gender": return PulseUser.currentUser.gender?.capitalized
        case "email": return getEmail()?.lowercased()
        case "password": return nil
        default: return nil
        }
    }
    
    func createShareLink(completion: @escaping (URL?) -> Void) {
        guard let uID = self.uID else {
            completion(nil)
            return
        }
        
        PulseDatabase.createShareLink(item: self, linkString: "u/"+uID, completion: { link in
            completion(link)
        })
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? PulseUser {
            return uID == object.uID
        } else {
            return false
        }
    }
    
    deinit {
        savedItems.removeAll()
        items.removeAll()
        contributorChannels.removeAll()
        editorChannels.removeAll()
        subscriptions.removeAll()
        savedItems.removeAll()
        
    }
}
