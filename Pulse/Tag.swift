//
//  Tag.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import Firebase

class Tag : NSObject {
    var tagID: String!
    var tagTitle : String?
    
    var items = [Item]()
    var tagImage : String?
    var tagDescription : String?
    
    var type : ItemTypes!
    
    dynamic var tagCreated = false
    
    init(tagID: String) {
        self.tagID = tagID
    }
    
    init(tagID: String, tagTitle : String?) {
        self.tagID = tagID
        self.tagTitle = tagTitle
    }
    
    init(tagID: String, items : [Item]) {
        self.tagID = tagID
        self.items = items
    }
    
    init(tagID: String, snapshot: FIRDataSnapshot) {
        self.tagID = tagID
        super.init()
        
        self.tagDescription  = snapshot.childSnapshot(forPath: "description").value as? String
        self.tagImage = snapshot.childSnapshot(forPath: "tagImage").value as? String

        self.tagTitle = snapshot.childSnapshot(forPath: "title").value as? String
        
        if let type = snapshot.childSnapshot(forPath: "type").value as? String {
            setType(type: type)
        }

        for item in snapshot.childSnapshot(forPath: "items").children {
            let item = Item(itemID: (item as AnyObject).key)
            self.items.append(item)
        }
        
        self.tagCreated = true
    }
    
    func totalItemsForTag() -> Int {
        return self.items.count
    }
    
    func createShareLink(completion: @escaping (String?) -> Void) {
        guard let cID = self.tagID else {
            completion(nil)
            return
        }
        
        Database.createShareLink(linkString: "c/"+cID, completion: { link in
            completion(link)
        })
    }
    
    func getTagImage(completion: @escaping (UIImage?) -> Void) {
        Database.getTagImage(tagID!, maxImgSize: maxImgSize, completion: {(imgData, error) in
            if let imgData = imgData {
                completion(UIImage(data: imgData))
            } else {
                completion(nil)
            }
        })
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Tag {
            return tagID == object.tagID
        } else {
            return false
        }
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
