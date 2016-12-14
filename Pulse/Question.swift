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
    var qAllTags = [String]()
    
    dynamic var qCreated = false
    
    var qFilters = [String]()
    var qAnswers = [String]()
    var qAllAnswers : [Answer]?

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
        
        /* if snapshot.hasChild("choices") {
            for choice in snapshot.childSnapshot(forPath: "choices").children {
                self.qFilters.append((choice as AnyObject).key)
            }
        } */
        
        if snapshot.hasChild("answers") {
            for answer in snapshot.childSnapshot(forPath: "answers").children {
                self.qAnswers.append((answer as AnyObject).key)
            }
        }
        
        if snapshot.hasChild("tags") {
            for tagID in snapshot.childSnapshot(forPath: "tags").children {
                self.qAllTags.append((tagID as AnyObject).key)
            }
        }
        
        self.qCreated = true
    }
    
    func totalAnswers() -> Int {
        return self.qAnswers.count
    }
    
    func hasAnswers() -> Bool {
        return self.qAnswers.count > 0 ? true : false
    }
    
    func hasFilters() -> Bool {
        return self.qFilters.count > 0 ? true : false
    }
    
    func getTag() -> String {
        if qTag != nil {
            return qTag.tagID!
        } else {
            return qAllTags.first!
        }
    }
    
}
