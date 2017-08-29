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
    
    //Collections
    case collections
    case collection
    
    //Forum
    case forum
    
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
    var cTitle : String?
    
    //Content items
    var contentURL : URL?
    var linkedURL : URL?

    var content : UIImage?
    var contentType : CreatedAssetType?
    var createdAt : Date?
    
    var user : PulseUser?
    var tag : Item?
    
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
    
    init(itemID: String, itemUserID: String, itemTitle: String, type: ItemTypes, tag: Item?, cID: String) {
        super.init()
        self.itemID = itemID

        self.itemUserID = itemUserID
        self.itemTitle = itemTitle
        self.type = type
        self.tag = tag
        self.cID = cID
    }
    
    init(itemID: String, snapshot: DataSnapshot) {
        self.itemID = itemID
        super.init()
        if snapshot.hasChild("title"), let _itemTitle = snapshot.childSnapshot(forPath: "title").value as? String {
            itemTitle = _itemTitle
        } else {
            itemTitle = ""
        }
        
        if snapshot.hasChild("description"), let _itemDescription = snapshot.childSnapshot(forPath: "description").value as? String {
            itemDescription = _itemDescription
        } else {
            itemDescription = ""
        }
        
        if let type = snapshot.childSnapshot(forPath: "type").value as? String {
            setType(_type: type)
        }
        
        if snapshot.hasChild("uID"), let userID = snapshot.childSnapshot(forPath: "uID").value as? String  {
            itemUserID = userID
        }
        
        if let _cID = snapshot.childSnapshot(forPath: "cID").value as? String {
            cID = _cID
        }
        
        if let _cTitle = snapshot.childSnapshot(forPath: "cTitle").value as? String {
            cTitle = _cTitle
        }
        
        if let url = snapshot.childSnapshot(forPath: "url").value as? String, let _contentURL = URL(string: url) {
            contentURL = _contentURL
        }
        
        if let assetType = snapshot.childSnapshot(forPath: "contentType").value as? String {
            contentType = CreatedAssetType.getAssetType(assetType)
        }
        
        if let url = snapshot.childSnapshot(forPath: "linkedurl").value as? String, let _linkedURL = URL(string: url) {
            linkedURL = _linkedURL
        }
        
        if let _createdAt = snapshot.childSnapshot(forPath: "createdAt").value as? Double {
            let convertedDate = Date(timeIntervalSince1970: _createdAt / 1000)
            createdAt = convertedDate
        }
        
        if let tagID = snapshot.childSnapshot(forPath: "tagID").value as? String, let tagTitle = snapshot.childSnapshot(forPath: "tagTitle").value as? String {
            tag = Item(itemID: tagID)
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
        case "collections":
            type = .collections
        case "collection":
            type = .collection
        case "perspectives":
            type = .perspectives
        case "perspective":
            type = .perspective
        case "interviews":
            type = .interviews
        case "interview":
            type = .interview
        case "forum":
            type = .forum
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
        case "feedbackInvite":
            type = .session
        default:
            type = .unknown
        }
    }
    
    internal func shouldGetImage() -> Bool {
        return type == .post || type == .thread || type == .perspective || type == .session || type == .showcase || type == .interview
    }
    
    internal func shouldGetBrowseImage() -> Bool {
        return type == .interview || type == .posts || type == .showcases
    }
    
    internal func childActionType() -> String {
        switch type {
        case .feedback: return "get"
        case .session: return "give"
            
        case .posts: return "new"
            
        case .thread: return "add a"
        case .question: return "add an"
        case .questions: return "ask"
            
        case .collections: return "start a"
        case .collection: return "create a"

        case .showcases: return "add a"
        case .interviews: return "start an"
            
        default: return "new"
        }
    }
    
    internal func defaultImage() -> UIImage? {
        switch type {
        case .feedback: return UIImage(named: "feedback")
        case .session: return UIImage(named: "feedback")
            
        case .posts: return UIImage(named: "post")
        case .post: return UIImage(named: "post")
            
        case .thread: return UIImage(named: "perspectives")
        case .perspectives: return UIImage(named: "perspectives")
        case .perspective: return UIImage(named: "perspectives")

        case .question: return UIImage(named: "questions")
        case .questions: return UIImage(named: "questions")
            
        case .showcases: return UIImage(named: "showcase")
        case .showcase: return UIImage(named: "showcase")
            
        case .interview: return UIImage(named: "interview")
        case .interviews: return UIImage(named: "interview")

        case .collections: return UIImage(named: "collections")
        case .collection: return UIImage(named: "collections")

        case .forum: return UIImage(named: "forum")
            
        default: return nil
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
            
        case .collections: return plural ? " collections" : " collection"
        case .collection: return plural ? " collections" : " collection"

        case .forum: return plural ? " threads" : " thread"

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
        case .collections: return .collection
        case .collection: return .collection

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
    
    internal func shareText() -> String {
        switch type {
        case .interview: return user?.name ?? itemTitle
        default: return itemTitle
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
            
        case .collections: return .contributor
        case .collection: return .contributor

        case .forum: return .subscriber
            
        default: return nil
        }
    }
    
    internal func allowGuestSubmissions() -> Bool {
        switch type {
        case .posts: return true
        case .thread: return true
        case .question: return true
        case .showcases: return true
            
        default: return false
        }
    }
    
    internal func needsCover() -> Bool {
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
    
    internal func cameraButtonText() -> String {
        switch type {
        case .post: return "Next"
        case .interview: return "Next"
        case .answer: return "Done"
        case .showcase: return "Next"
            
        default: return "Post"
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
                user.isContributor(for: Channel(cID: self.cID)) ?
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
    
    internal func getCreatedAt(style: DateFormatter.Style = .medium) -> String? {
        return self.createdAt != nil ? GlobalFunctions.getFormattedTime(timeString: self.createdAt!, style: style) : nil
    }
    
    internal func createShareLink(invite: Bool = false, inviteItemID: String? = nil, completion: @escaping (URL?) -> Void) {
        guard cID != nil else {
            completion(nil)
            return
        }
        
        PulseDatabase.getItemStorageURL(channelID: cID, type: "thumb", fileID : inviteItemID != nil ? inviteItemID! : itemID, completion: { url, error in
            if !invite {
                PulseDatabase.createShareLink(item: self, linkString: "i/"+self.itemID, imageURL: url, completion: { link in
                    completion(link)
                })
            } else {
                PulseDatabase.createShareLink(item: self, linkString: "invites/"+self.itemID, imageURL: url, completion: { link in
                    completion(link)
                })
            }
        })
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
    
    //used to make sure we are sharing the full thread vs. one individual item
    static func shareItemType(parentType: ItemTypes, childType: ItemTypes) -> ItemTypes {
        switch childType {
        case .answer: return parentType
        case .session: return parentType
        case .perspective: return parentType
            
        default: return childType
        }
    }
}
