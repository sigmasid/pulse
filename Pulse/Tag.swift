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
    var tagID: String?
    var questions: [String]?
    var tagImage : String?
    
    dynamic var tagCreated = false
    
    init(tagID: String) {
        self.tagID = tagID
        self.questions = nil
    }
    
    init(tagID: String, questions : [String]?) {
        self.tagID = tagID
        self.questions = questions
    }
    
    init(tagID: String, snapshot: FIRDataSnapshot) {
        self.tagID = tagID
        super.init()
        let tagPath = databaseRef.child("tags").child(tagID)
        tagPath.observeSingleEventOfType(.Value, withBlock: { snapshot in
            self.tagImage = snapshot.childSnapshotForPath("tagImage").value as? String
            
            for choice in snapshot.childSnapshotForPath("questions").children {
                if (self.questions?.append(choice.key) == nil) {
                    self.questions = [choice.key]
                }
            }
            self.tagCreated = true
        })
    }
    
    func totalQuestionsForTag() -> Int? {
        if self.questions?.count > 0 {
            return self.questions!.count
        } else {
            return nil
        }
    }
}