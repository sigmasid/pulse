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
    case question
    case post
    case answer
    case tag
    case user
    case unknown
}

enum FileTypes: String {
    case content
    case thumb
    case cover
}

class Item: NSObject {
    var itemID = String()
    var itemUserID : String!
    var itemTitle : String!
    var type : ItemTypes = .unknown
    var cID : String!
    
    var contentURL : URL?
    var content : Any?
    var contentType : CreatedAssetType?
    var createdAt : Date!
    
    var user : User?
    var tag : Item?
    
    dynamic var itemCreated = false
    
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
    
    init(itemID: String, snapshot: FIRDataSnapshot, feedUpdate:Bool) {
        self.itemID = itemID
        super.init()
        if let tagID = snapshot.childSnapshot(forPath: "tagID").value as? String, let tagTitle = snapshot.childSnapshot(forPath: "tagTitle").value as? String {
            self.tag = Item(itemID: tagID, type: "tag")
            self.tag?.itemTitle = tagTitle
        }
        
        if let type = snapshot.childSnapshot(forPath: "type").value as? String {
            setType(type: type)
        }
    }
    
    init(itemID: String, snapshot: FIRDataSnapshot) {
        self.itemID = itemID
        super.init()
        if snapshot.hasChild("title") {
            self.itemTitle = snapshot.childSnapshot(forPath: "title").value as? String
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
        
        itemCreated = true
    }
    
    internal func setType(type : String) {
        if type == "question" {
            self.type = .question
        } else if type == "post" {
            self.type = .post
        }  else if type == "answer" {
            self.type = .answer
        }
    }
    
    func getCreatedAt() -> String {
        return self.createdAt != nil ? GlobalFunctions.getFormattedTime(timeString: self.createdAt) : ""
    }
    
    func createShareLink(completion: @escaping (String?) -> Void) {
        Database.createShareLink(linkString: "q/"+itemID, completion: { link in
            completion(link)
        })
    }
}
