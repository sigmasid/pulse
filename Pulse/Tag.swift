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
    var questions: [Question]?
    var tagImage : String?
    var tagDescription : String?
    var previewImage : String?
    
    dynamic var tagCreated = false
    
    init(tagID: String) {
        self.tagID = tagID
    }
    
    init(tagID: String, questions : [Question]?) {
        self.tagID = tagID
        self.questions = questions
    }
    
    init(tagID: String, snapshot: FIRDataSnapshot) {
        self.tagID = tagID
        super.init()
        
        self.tagDescription  = snapshot.childSnapshotForPath("description").value as? String
        self.previewImage = snapshot.childSnapshotForPath("previewImage").value as? String

        for question in snapshot.childSnapshotForPath("questions").children {
            let _question = Question(qID: question.key)
            if (self.questions?.append(_question) == nil) {
                self.questions = [_question]
            }
        }
        self.tagCreated = true
    }
    
    func totalQuestionsForTag() -> Int {
        return self.questions?.count > 0 ? self.questions!.count : 0
    }
}