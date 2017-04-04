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
    //Feedback > ??
    case feedback
    //Perspectives > has Threads > Thread has Perspective
    case perspectives
    case thread
    case perspective
    //Interviews
    case interviews
    case interview
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
    var itemTitle : String!
    var itemDescription : String!
    var type : ItemTypes = .unknown
    
    //Channel items
    var cID : String!
    var cTitle : String!
    
    //Content items
    var contentURL : URL?
    var content : Any?
    var contentType : CreatedAssetType?
    var createdAt : Date?
    
    var user : User?
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

    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Item {
            return itemID == object.itemID
        } else {
            return false
        }
    }
    
    init(itemID: String, snapshot: FIRDataSnapshot) {
        self.itemID = itemID
        super.init()
        if snapshot.hasChild("title") {
            self.itemTitle = snapshot.childSnapshot(forPath: "title").value as? String
        }
        
        if snapshot.hasChild("description") {
            self.itemDescription = snapshot.childSnapshot(forPath: "description").value as? String
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
        default:
            self.type = .unknown
        }
    }
    
    func childType(plural: Bool = false) -> String {
        switch type {
        case .feedback: return plural ? " questions" : " question"
        case .posts: return plural ? " posts" : " post"
        case .thread: return plural ? " perspectives" : " perspective"
        case .question: return plural ? " answers" : " answer"
        case .questions: return plural ? " questions" : " question"

        case .interviews: return plural ? " interviews" : " interview"
        case .interview: return plural ? " interview" : " interview"

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
        default: return .unknown
        }
    }
    
    func acceptsInput() -> Bool {
        switch type {
        case .posts: return true
        case .post: return false
        
        case .perspectives: return false
        case .thread: return true
        case .perspective: return false

        case .questions: return true
        case .question: return true
        case .answer: return false

        case .interviews: return true
        case .interview: return false
        
        default: return false
        }
    }
    
    func checkVerifiedInput() -> Bool {
        if let user = User.currentUser, user.uID != nil, user.isVerified(for: Channel(cID: self.cID)) {
            return true
        }
        return false
    }
    
    func getCreatedAt() -> String? {
        return self.createdAt != nil ? GlobalFunctions.getFormattedTime(timeString: self.createdAt!) : nil
    }
    
    func createShareLink(completion: @escaping (String?) -> Void) {
        switch type {
        case .posts:
            Database.createShareLink(linkString: "tag/"+itemID, completion: { link in
                completion(link)
            })
        case .post:
            Database.createShareLink(linkString: "p/"+itemID, completion: { link in
                completion(link)
            })
        case .feedback:
            Database.createShareLink(linkString: "tag/"+itemID, completion: { link in
                completion(link)
            })
        case .question:
            Database.createShareLink(linkString: "q/"+itemID, completion: { link in
                completion(link)
            })
        case .answer:
            Database.createShareLink(linkString: "a/"+itemID, completion: { link in
                completion(link)
            })
        case .interview:
            Database.createShareLink(linkString: "interviewRequest/"+itemID, completion: { link in
                completion(link)
            })
        default: completion(nil)
        }
    }
}
