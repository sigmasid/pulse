//
//  question.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import Firebase
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

class Question : NSObject {
    var qID : String
    var qTag : Tag!
    var qTitle : String?
    var uID : String?
    
    dynamic var qCreated = false
    
    var qFilters = [String]()
    var qItems = [Item]()

    init(qID: String) {
        self.qID = qID
    }
    
    init(qID: String, qTag : Tag) {
        self.qID = qID
        self.qTag = qTag
    }
    
    init(qID: String, snapshot: FIRDataSnapshot) {
        self.qID = qID
        self.qTitle = snapshot.childSnapshot(forPath: "title").value as? String
        
        if snapshot.hasChild("items") {
            for item in snapshot.childSnapshot(forPath: "items").children {
                let item = Item(itemID: (item as AnyObject).key)
                item.type = .answer
                self.qItems.append(item)
            }
        }
        
        if snapshot.hasChild("tagID") {
            if let tagID = snapshot.childSnapshot(forPath: "tagID").value as? String {
                self.qTag = Tag(tagID: tagID)
            }
        }
        
        self.qCreated = true
    }
    
    func totalAnswers() -> Int {
        return self.qItems.count
    }
    
    func hasAnswers() -> Bool {
        return self.qItems.count > 0 ? true : false
    }
    
    func hasFilters() -> Bool {
        return self.qFilters.count > 0 ? true : false
    }
    
    func getTag() -> String {
        if qTag != nil {
            return qTag.tagID!
        } else {
            // Need to update to remove 
            return ""
        }
    }
    
    func createShareLink(completion: @escaping (String?) -> Void) {
        Database.createShareLink(linkString: "q/"+qID, completion: { link in
            completion(link)
        })
    }
}
