//
//  Channel.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/18/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import Foundation
import FirebaseDatabase
import UIKit

class Channel : NSObject {
    var cID: String!
    var cTitle : String?
    var cDescription : String?
    
    var tags = [Item]()
    var experts = [User]()
    var items = [Item]()
    
    var cPreviewImage : UIImage?
    var cImageURL : String?
    
    dynamic var cCreated = false
    dynamic var cDetailedCreated = false
    
    init(cID: String) {
        self.cID = cID
    }

    init(cID: String, snapshot: FIRDataSnapshot) {
        self.cID = cID
        super.init()
        
        self.cTitle  = snapshot.childSnapshot(forPath: "title").value as? String
        self.cDescription  = snapshot.childSnapshot(forPath: "description").value as? String
        self.cImageURL = snapshot.childSnapshot(forPath: "image").value as? String
        
        for tag in snapshot.childSnapshot(forPath: "tags").children {
            if let tag = tag as? FIRDataSnapshot {
                let _tag = Item(itemID: (tag as AnyObject).key, type: "tag")
                _tag.itemTitle = tag.value as? String
                self.tags.append(_tag)
            }
        }
        
        for user in snapshot.childSnapshot(forPath: "experts").children {
            let _user = User(uID: (user as AnyObject).key)
            self.experts.append(_user)
        }
        
        self.cCreated = true
    }
    
    func updateChannel(detailedSnapshot : FIRDataSnapshot) {
        for child in detailedSnapshot.children {
            let currentItem = Item(itemID: (child as AnyObject).key)
            
            if let childSnap = child as? FIRDataSnapshot {
                
                if let tagID = childSnap.childSnapshot(forPath: "tagID").value as? String, let tagTitle = childSnap.childSnapshot(forPath: "tagTitle").value as? String{
                    currentItem.tag = Item(itemID: tagID)
                    currentItem.tag?.itemTitle = tagTitle
                }
            
                if let type = childSnap.childSnapshot(forPath: "type").value as? String {
                    currentItem.setType(type: type)
                }
            }
            
            items.append(currentItem)
        }
        
        cDetailedCreated = true
    }

    func createShareLink(completion: @escaping (String?) -> Void) {
        guard let cID = self.cID else {
            completion(nil)
            return
        }
        
        Database.createShareLink(linkString: "c/"+cID, completion: { link in
            completion(link)
        })
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Channel {
            return cID == object.cID
        } else {
            return false
        }
    }
}
