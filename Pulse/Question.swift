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
    var channelTags : [String]?
    var qTitle : String?
    
    dynamic var qCreated = false
    
    var qChoices : [String]?
    var qAnswers : [String]?
    
    init(qID: String) {
        self.qID = qID
    }
    
    init(qID: String, snapshot: FIRDataSnapshot) {
        self.qID = qID
        super.init()
        let questionPath = databaseRef.child("questions").child(qID)
        questionPath.observeSingleEventOfType(.Value, withBlock: { snapshot in
            self.qTitle = snapshot.childSnapshotForPath("title").value as? String
            for choice in snapshot.childSnapshotForPath("choices").children {
                if (self.qChoices?.append(choice.key) == nil) {
                    self.qChoices = [choice.key]
                }
            }
            for answer in snapshot.childSnapshotForPath("answers").children {
                if (self.qAnswers?.append(answer.key) == nil) {
                    self.qAnswers = [answer.key]
                }
            }
            self.qCreated = true
        })
    }
    
    func totalAnswers() -> Int? {
        if self.qAnswers?.count > 0 {
            return self.qAnswers!.count
        } else {
            return nil
        }
    }
    
    func hasAnswers() -> Bool {
        return self.qAnswers?.count > 0 ? true : false
    }
}
