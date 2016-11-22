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
    var questions = [Question?]()
    var experts: [User?]?
    var tagImage : String?
    var tagDescription : String?
    var previewImage : String?
    
    dynamic var tagCreated = false
    
    init(tagID: String) {
        self.tagID = tagID
    }
    
    init(tagID: String, questions : [Question]?) {
        self.tagID = tagID
        self.questions = questions!
    }
    
    init(tagID: String, snapshot: FIRDataSnapshot) {
        self.tagID = tagID
        super.init()
        
        self.tagDescription  = snapshot.childSnapshot(forPath: "description").value as? String
        self.previewImage = snapshot.childSnapshot(forPath: "previewImage").value as? String

        for question in snapshot.childSnapshot(forPath: "questions").children {
            let _question = Question(qID: (question as AnyObject).key)
            self.questions.append(_question)
        }
        
        for user in snapshot.childSnapshot(forPath: "experts").children {
            let _user = User(uID: (user as AnyObject).key)
            if (self.experts?.append(_user) == nil) {
                self.experts = [_user]
            }
        }
        self.tagCreated = true
    }
    
    func totalQuestionsForTag() -> Int {
        return self.questions.count
    }
}
