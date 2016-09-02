//
//  question.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import Firebase

class Question : NSObject {
    var qID : String
    var qTagID : String?
    var qTitle : String?
    
    dynamic var qCreated = false
    
    var qFilters : [String]?
    var qAnswers : [String]?
    
    init(qID: String) {
        self.qID = qID
    }
    
    init(qID: String, qTagID : String?) {
        self.qID = qID
        self.qTagID = qTagID
    }
    
    init(qID: String, snapshot: FIRDataSnapshot) {
        self.qID = qID
        self.qTitle = snapshot.childSnapshotForPath("title").value as? String
        for choice in snapshot.childSnapshotForPath("choices").children {
            if (self.qFilters?.append(choice.key) == nil) {
                self.qFilters = [choice.key]
            }
        }
        for answer in snapshot.childSnapshotForPath("answers").children {
            if (self.qAnswers?.append(answer.key) == nil) {
                self.qAnswers = [answer.key]
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
