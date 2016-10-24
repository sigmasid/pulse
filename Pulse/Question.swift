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

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class Question : NSObject {
    var qID : String
    var qTagID : String?
    var qTitle : String?
    
    dynamic var qCreated = false
    
    var qFilters : [String]?
    var qAnswers : [String]?
    var qAllAnswers : [Answer]?

    init(qID: String) {
        self.qID = qID
    }
    
    init(qID: String, qTagID : String?) {
        self.qID = qID
        self.qTagID = qTagID
    }
    
    init(qID: String, snapshot: FIRDataSnapshot) {
        self.qID = qID
        self.qTitle = snapshot.childSnapshot(forPath: "title").value as? String
//        for choice in snapshot.childSnapshotForPath("choices").children {
//            if (self.qFilters?.append(choice.key) == nil) {
//                self.qFilters = [choice.key]
//            }
//        }
        for answer in snapshot.childSnapshot(forPath: "answers").children {
            if (self.qAnswers?.append((answer as AnyObject).key) == nil) {
                self.qAnswers = [(answer as AnyObject).key]
            }
        }
        self.qCreated = true
    }
    
    func totalAnswers() -> Int {
        return self.qAnswers?.count ?? 0
    }
    
    func hasAnswers() -> Bool {
        return self.qAnswers?.count > 0 ? true : false
    }
    
    func hasFilters() -> Bool {
        return self.qFilters?.count > 0 ? true : false
    }
}
