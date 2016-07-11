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
    static let answersStorageRef = storageRef.child("answers")

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
    
    static func getAnswerURL(fileID : String, completion: (URL : NSURL?, error : NSError?) -> Void) {
        let _ = answersStorageRef.child(fileID).downloadURLWithCompletion { (URL, error) -> Void in
            if (error != nil) {
                completion(URL: nil, error: error)
            } else {
                completion(URL: URL, error: nil)
            }
        }
    }
    
    static func createEmailUser(email : String, password: String, completion: (user : User?, error : NSError?) -> Void) {
        FIRAuth.auth()?.createUserWithEmail(email, password: password) { (_user, _error) in
            if _error != nil {
                completion(user: nil, error: _error)
            } else {
                saveUserToDatabase(_user!, completion: { (success , error) in
                    if error != nil {
                        completion(user: nil, error: error)
                    } else {
                        completion(user: User(user: _user!), error: nil)
                    }
                })
            }
        }
    }
    
    static func updateUserDisplayName(name: String, completion: (success : Bool, error : NSError?) -> Void) {
        let user = FIRAuth.auth()?.currentUser
        if let user = user {
            let changeRequest = user.profileChangeRequest()
            
            changeRequest.displayName = name
            changeRequest.commitChangesWithCompletion { error in
                if let error = error {
                    completion(success: false, error: error)
                } else {
                    saveUserToDatabase(user, completion: { (success , error) in
                        if error != nil {
                            completion(success: false, error: error)
                        } else {
                            completion(success: true, error: nil)
                        }
                    })
                }
            }
        }
    }
    
    static func saveUserToDatabase(user: FIRUser, completion: (success : Bool, error : NSError?) -> Void) {
        var userPost = [String : String]()
        if let _uName = user.displayName {
            userPost["name"] = _uName
        }
        if let _uPic = user.photoURL {
            userPost["profilePic"] = String(_uPic)
        }
        usersRef.child(user.uid).updateChildValues(userPost, withCompletionBlock: { (error:NSError?, ref:FIRDatabaseReference!) in
            if error != nil {
                completion(success: false, error: error)
            } else {
                completion(success: true, error: nil)
            }
        })
    }
    
    static func addUserAnswersToDatabase(user: FIRUser, aID: String, completion: (success : Bool, error : NSError?) -> Void) {
        let post = ["\(aID)": "true"]

        usersRef.child(user.uid).child("answers").updateChildValues(post, withCompletionBlock: { (error:NSError?, ref:FIRDatabaseReference!) in
        if error != nil {
            completion(success: false, error: error)
        } else {
            completion(success: true, error: nil)
        }
        })
    }
}