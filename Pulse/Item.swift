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
    weak var tag : Item?
    
    lazy var itemCreated = false
    lazy var itemCollection = [Item]()
    lazy var fetchedContent = false
    
    init(itemID: String) {
        self.itemID = itemID
    }
    
    init(itemID: String, type: String) {
        super.init()

        self.itemID = itemID
        setType(_type: type)
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
            itemTitle = snapshot.childSnapshot(forPath: "title").value as? String ?? ""
        }
        
        if snapshot.hasChild("description") {
            itemDescription = snapshot.childSnapshot(forPath: "description").value as? String ?? ""
        }
        
        if let type = snapshot.childSnapshot(forPath: "type").value as? String {
            setType(_type: type)
        }
        
        if snapshot.hasChild("uID") {
            itemUserID = snapshot.childSnapshot(forPath: "uID").value as? String
        }
        
        if let _cID = snapshot.childSnapshot(forPath: "cID").value as? String {
            cID = _cID
        }
        
        if let _cTitle = snapshot.childSnapshot(forPath: "cTitle").value as? String {
            cTitle = _cTitle
        }
        
        if let url = snapshot.childSnapshot(forPath: "url").value as? String {
            contentURL = URL(string: url)
        }
        
        if let assetType = snapshot.childSnapshot(forPath: "contentType").value as? String {
            contentType = CreatedAssetType.getAssetType(assetType)
        }
        
        if let _createdAt = snapshot.childSnapshot(forPath: "createdAt").value as? Double {
            let convertedDate = Date(timeIntervalSince1970: _createdAt / 1000)
            createdAt = convertedDate
        }
        
        if let tagID = snapshot.childSnapshot(forPath: "tagID").value as? String, let tagTitle = snapshot.childSnapshot(forPath: "tagTitle").value as? String {
            tag = Item(itemID: tagID, type: "tag")
            tag?.itemTitle = tagTitle
        }
        
        itemCreated = true
    }
    
    internal func setType(_type : String) {
        switch _type {
        case "question":
            type = .question
        case "questions":
            type = .questions
        case "answer":
            type = .answer
        case "post":
            type = .post
        case "posts":
            type = .posts
        case "feedback":
            type = .feedback
        case "perspectives":
            type = .perspectives
        case "perspective":
            type = .perspective
        case "interviews":
            type = .interviews
        case "interview":
            type = .interview
        case "thread":
            type = .thread
        case "session":
            type = .session
        case "showcases":
            type = .showcases
        case "showcase":
            self.type = .showcase
        case "perspectiveInvite":
            type = .thread
        case "questionInvite":
            type = .question
        case "interviewInvite":
            type = .interview
        case "showcaseInvite":
            type = .showcases
        default:
            type = .unknown
        }
    }
    
    internal func shouldGetImage() -> Bool {
        return type == .post || type == .thread || type == .perspective || type == .session || type == .showcase
    }
    
    internal func childActionType() -> String {
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
    
    internal func childType(plural: Bool = false) -> String {
        switch type {
        case .feedback: return plural ? " feedback" : " feedback"
        case .posts: return plural ? " posts" : " post"
        case .session: return plural ? " session" : " feedback"

        case .perspectives: return plural ? " threads" : " thread"
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
    
    internal func childItemType() -> ItemTypes {
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
    
    internal func inviteType() -> MessageType? {
        switch type {
        case .thread: return .perspectiveInvite
        case .question: return .questionInvite
        case .interviews: return .interviewInvite
        case .showcases: return .showcaseInvite
        case .session: return .feedbackInvite
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
    
    internal func needsCover() -> Bool {
        if self.contentType == .recordedVideo || contentType == .albumVideo {
            switch type {
            case .post: return true
            case .perspective: return false
            case .answer: return false
            case .session: return false
            case .interview: return true
            case .showcase: return true
                
            default: return false
            }
        } else {
            //if it's an image - don't need a cover
            return false
        }
    }
    
    internal func checkVerifiedInput(completion: @escaping (Bool, String?) -> Void) {
        if !PulseUser.isLoggedIn() {
            completion(false, "Please login to continue")
        } else if let inputOpenToUser = acceptsInput() {
            //user is logged in and
            let user = PulseUser.currentUser
            
            guard self.cID != nil else {
                completion(false, "Sorry error getting item")
                return
            }
            
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
    
    internal func getCreatedAt() -> String? {
        return self.createdAt != nil ? GlobalFunctions.getFormattedTime(timeString: self.createdAt!) : nil
    }
    
    internal func createShareLink(invite: Bool = false, completion: @escaping (String?) -> Void) {
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
    
    deinit {
        content = nil
        tag = nil
        user = nil
        itemCollection = []
        contentURL = nil
        contentType = nil
        createdAt = nil
    }
}
