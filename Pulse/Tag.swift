//
//  Tag.swift
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


class Tag : NSObject {
    var tagID: String?
    var questions: [Question?]?
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
        
        self.tagDescription  = snapshot.childSnapshot(forPath: "description").value as? String
        self.previewImage = snapshot.childSnapshot(forPath: "previewImage").value as? String

        for question in snapshot.childSnapshot(forPath: "questions").children {
            let _question = Question(qID: (question as AnyObject).key)
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
