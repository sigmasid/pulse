//
//  Database.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/30/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

let storage = FIRStorage.storage()
let storageRef = storage.referenceForURL("gs://pulse-84022.appspot.com")
let databaseRef = FIRDatabase.database().reference()

class Database {

    static let tagsRef = databaseRef.child("tags")
    static let questionsRef = databaseRef.child("questions")
    static let answersRef = databaseRef.child("answers")
    static let usersRef = databaseRef.child("users")

    static func getAllTags(completion: (tags : [Tag], error : NSError?) -> Void) {
        var allTags = [Tag]()
        
        tagsRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            for item in snapshot.children {
                let child = item as! FIRDataSnapshot
                allTags.append(Tag(tagID: child.key, snapshot: child))
            }
            completion(tags: allTags, error: nil)
        })
    }
    
    static func getQuestionsForTag(tag : Tag, completion: (questions : [Question], error : NSError?) -> Void) {
        var allQuestions = [Question]()
        if tag.totalQuestionsForTag() > 0 {
            for aQuestion in tag.questions! {
                questionsRef.child("\(aQuestion)").observeSingleEventOfType(.Value, withBlock: { snapshot in
                    allQuestions.append(Question(qID: snapshot.key, snapshot: snapshot))
                })
            }
            completion(questions: allQuestions, error: nil)
        } else {
            completion(questions: allQuestions, error: NSError.init(domain: "Empty", code: 1, userInfo: nil))
        }
    }
    
    static func getQuestion(qID : String, completion: (question : Question, error : NSError?) -> Void) {
        questionsRef.child(qID).observeSingleEventOfType(.Value, withBlock: { snap in
            let _currentQuestion = Question(qID: qID, snapshot: snap)
            completion(question: _currentQuestion, error: nil)
        })
    }
    
    static func getAnswer(aID : String, completion: (answer : Answer, error : NSError?) -> Void) {
        answersRef.child(aID).observeSingleEventOfType(.Value, withBlock: { snap in
            let _currentAnswer = Answer(aID: aID, snapshot: snap)
            completion(answer: _currentAnswer, error: nil)
        })
    }
    
    static func getUser(uID : String, completion: (user : User, error : NSError?) -> Void) {
        usersRef.child(uID).observeSingleEventOfType(.Value, withBlock: { snap in
            let _currentUser = User(uID: uID, snapshot: snap)
            completion(user: _currentUser, error: nil)
        })
    }
    
}