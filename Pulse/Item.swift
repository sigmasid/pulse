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
    case unknown
}

class Item: NSObject {
    var itemID = String()
    var itemUserID : String!
    var itemTitle : String!
    var type : ItemTypes!
    var parentItemID : String?
    
    var contentURL : URL?
    var content : Any?
    var contentType : CreatedAssetType?
    
    var user : User?
    var tag : Tag?
    
    dynamic var itemCreated = false
    
    init(itemID: String) {
        self.itemID = itemID
    }
    
    init(itemID: String, type: String) {
        super.init()

        self.itemID = itemID
        setType(type: type)
    }
    
    init(itemID: String, itemUserID: String, itemTitle: String, type: ItemTypes, contentURL: URL?, content: Any?, contentType : CreatedAssetType?, tag: Tag?, parentItemID: String?) {
        super.init()
        self.itemID = itemID

        self.itemUserID = itemUserID
        self.itemTitle = itemTitle
        self.type = type
        self.contentURL = contentURL
        self.content = content
        self.contentType = contentType
        self.tag = tag
        self.parentItemID = parentItemID
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
        
        if let type = snapshot.childSnapshot(forPath: "type").value as? String {
            setType(type: type)
        }
        
        if snapshot.hasChild("uID") {
            self.itemUserID = snapshot.childSnapshot(forPath: "uID").value as? String
        }
        
        if let url = snapshot.childSnapshot(forPath: "url").value as? String {
            self.contentURL = URL(string: url)
        }
        
        if let assetType = snapshot.childSnapshot(forPath: "contentType").value as? String {
            self.contentType = CreatedAssetType.getAssetType(assetType)
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
}
