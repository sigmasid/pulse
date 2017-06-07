//
//  Item.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/18/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import Foundation
import FirebaseDatabase
import UIKit

enum ItemTypes: String {
    //Questions > has Question > has Answer
    case questions
    case question
    case answer
    
    //Posts > has Post
    case post
    case posts
    
    //Feedback > session
    case feedback
    case session
    
    //Perspectives > has Threads > Thread has Perspective
    case perspectives
    case thread
    case perspective
    
    //Interviews
    case interviews
    case interview
    
    //Showcases > showcase
    case showcases
    case showcase
    
    //The rest to come
    case unknown
}

enum FileTypes: String {
    case content
    case thumb
}

class Item: NSObject {
    //Item Meta
    var itemID = String()
    var itemUserID : String!
    var itemTitle : String = ""
    var itemDescription : String = ""
    var type : ItemTypes = .unknown
    
    //Channel items
    var cID : String!
    var cTitle : String!
    
    //Content items
    var contentURL : URL?
    var content : Any?
    var contentType : CreatedAssetType?
    var createdAt : Date?
    
    var user : PulseUser?
    var tag : Item?
    
    dynamic var itemCreated = false
    var fetchedContent = false
    
    init(itemID: String) {
        self.itemID = itemID
    }
    
    init(itemID: String, type: String) {
        super.init()

        self.itemID = itemID
        setType(type: type)
    }
    
    init(itemID: String, itemUserID: String, itemTitle: String, type: ItemTypes, contentURL: URL?, content: Any?, contentType : CreatedAssetType?, tag: Item?, cID: String) {
        super.init()
        self.itemID = itemID

        self.itemUserID = itemUserID
        self.itemTitle = itemTitle
        self.type = type
        self.contentURL = contentURL
        self.content = content
        self.contentType = contentType
        self.tag = tag
        self.cID = cID
    }
    
    init(itemID: String, snapshot: DataSnapshot) {
        self.itemID = itemID
        super.init()
        if snapshot.hasChild("title") {
            self.itemTitle = snapshot.childSnapshot(forPath: "title").value as? String ?? ""
        }
        
        if snapshot.hasChild("description") {
            self.itemDescription = snapshot.childSnapshot(forPath: "description").value as? String ?? ""
        }
        
        if let type = snapshot.childSnapshot(forPath: "type").value as? String {
            setType(type: type)
        }
        
        if snapshot.hasChild("uID") {
            self.itemUserID = snapshot.childSnapshot(forPath: "uID").value as? String
        }
        
        if let cID = snapshot.childSnapshot(forPath: "cID").value as? String {
            self.cID = cID
        }
        
        if let cTitle = snapshot.childSnapshot(forPath: "cTitle").value as? String {
            self.cTitle = cTitle
        }
        
        if let url = snapshot.childSnapshot(forPath: "url").value as? String {
            self.contentURL = URL(string: url)
        }
        
        if let assetType = snapshot.childSnapshot(forPath: "contentType").value as? String {
            self.contentType = CreatedAssetType.getAssetType(assetType)
        }
        
        if let createdAt = snapshot.childSnapshot(forPath: "createdAt").value as? Double {
            let convertedDate = Date(timeIntervalSince1970: createdAt / 1000)
            self.createdAt = convertedDate
        }
        
        if let tagID = snapshot.childSnapshot(forPath: "tagID").value as? String, let tagTitle = snapshot.childSnapshot(forPath: "tagTitle").value as? String {
            self.tag = Item(itemID: tagID, type: "tag")
            self.tag?.itemTitle = tagTitle
        }
        
        itemCreated = true
    }
    
    internal func setType(type : String) {
        switch type {
        case "question":
            self.type = .question
        case "questions":
            self.type = .questions
        case "answer":
            self.type = .answer
        case "post":
            self.type = .post
        case "posts":
            self.type = .posts
        case "feedback":
            self.type = .feedback
        case "perspectives":
            self.type = .perspectives
        case "perspective":
            self.type = .perspective
        case "interviews":
            self.type = .interviews
        case "interview":
            self.type = .interview
        case "thread":
            self.type = .thread
        case "session":
            self.type = .session
        case "showcases":
            self.type = .showcases
        case "showcase":
            self.type = .showcase
        case "perspectiveInvite":
            self.type = .thread
        case "questionInvite":
            self.type = .question
        case "interviewInvite":
            self.type = .interview
        case "showcaseInvite":
            self.type = .showcase
        default:
            self.type = .unknown
        }
    }
    
    func childActionType() -> String {
        switch type {
        case .feedback: return "get"
        case .session: return "give"
            
        case .posts: return "new"
            
        case .thread: return "add a"
        case .question: return "add an"
        case .questions: return "ask"
            
        case .showcases: return "add a"
        case .interviews: return "start an"
            
        default: return "new"
        }
    }
    
    func childType(plural: Bool = false) -> String {
        switch type {
        case .feedback: return plural ? " feedback" : " feedback"
        case .posts: return plural ? " posts" : " post"
        case .session: return plural ? " session" : " feedback"

        case .thread: return plural ? " perspectives" : " perspective"
        case .question: return plural ? " answers" : " answer"
        case .questions: return plural ? " questions" : " question"

        case .interviews: return plural ? " interviews" : " interview"
        case .interview: return plural ? " interview" : " interview"
            
        case .showcases: return plural ? " showcases" : " showcase"
        case .showcase: return plural ? " showcase" : " showcase"

        default: return " entry"
        }
    }
    
    func childItemType() -> ItemTypes {
        switch type {
        case .posts: return .post
        case .thread: return .perspective
        case .question: return .answer
        case .interviews: return .interview
        case .interview: return .answer
        case .feedback: return .session
        case .session: return .session
        case .showcases: return .showcase

        default: return .unknown
        }
    }
    
    func inviteType() -> MessageType? {
        switch type {
        case .thread: return .perspectiveInvite
        case .question: return .questionInvite
        case .interviews: return .interviewInvite
        case .showcases: return .showcaseInvite
        default: return nil
        }
    }
    
    fileprivate func acceptsInput() -> UserTypes? {
        switch type {
        case .posts: return .contributor //only contributors can add a post
        case .post: return nil
            
        case .perspectives: return .contributor //only contributors can start a thread
        case .thread: return .contributor //only contributors can add a perspetive
        case .perspective: return nil
            
        case .questions: return .subscriber //any subscriber can ask a question
        case .question: return .contributor //answers can only be provided by a contributor
        case .answer: return nil
            
        case .feedback: return .subscriber //any subscriber can request feedback
        case .session: return .contributor //feedback can only be provided by a contributor
            
        case .interviews: return .contributor
        case .interview: return nil
            
        case .showcases: return .contributor
        case .showcase: return nil

        default: return nil
        }
    }
    
    fileprivate func needsCover() -> Bool {
        switch type {
        case .post: return true
        case .perspective: return false
        case .answer: return false
        case .session: return false
        case .interview: return true
        case .showcase: return true
            
        default: return false
        }
    }
    
    func checkVerifiedInput(completion: @escaping (Bool, String?) -> Void) {
        if !PulseUser.isLoggedIn() {
            completion(false, "Please login to continue")
        } else if let inputOpenToUser = acceptsInput() {
            //user is logged in and
            let user = PulseUser.currentUser
            switch inputOpenToUser {
            case .contributor:
                //check if user is verified
                user.isVerified(for: Channel(cID: self.cID)) ?
                    completion(true, nil) :
                    completion(false, "Sorry you have to be a verified contributor. You can apply on the prior screen")

            case .subscriber:
                //check if user is subscribed
                user.isSubscribedToChannel(cID: self.cID) ?
                    completion(true, nil) :
                    completion(false, "Please subscribe to channel first")
                
            case .user:
                completion(true, nil)
                
            case .editor:
                //check if user is an editor
                user.isEditor(for: Channel(cID: self.cID)) ?
                    completion(true, nil) :
                    completion(false, "Sorry you have to be an editor to continue")
                
            case .guest:
                completion(false, "Invited guests only")
            }
        } else {
            //user is logged in but item doesn't accept input - should never actually end up here
            completion(false, "Sorry this item doesn't accept input")
        }
    }
    
    func getCreatedAt() -> String? {
        return self.createdAt != nil ? GlobalFunctions.getFormattedTime(timeString: self.createdAt!) : nil
    }
    
    func createShareLink(invite: Bool = false, completion: @escaping (String?) -> Void) {
        if !invite {
            PulseDatabase.createShareLink(linkString: "i/"+itemID, completion: { link in
                completion(link)
            })
        } else {
            PulseDatabase.createShareLink(linkString: "invites/"+itemID, completion: { link in
                completion(link)
            })
        }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Item {
            return itemID == object.itemID
        } else {
            return false
        }
    }
}
