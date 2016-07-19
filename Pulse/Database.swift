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
import TwitterKit
import FBSDKLoginKit

let storage = FIRStorage.storage()
let storageRef = storage.referenceForURL("gs://pulse-84022.appspot.com")
let databaseRef = FIRDatabase.database().reference()

class Database {

    static let tagsRef = databaseRef.child("tags")
    static let questionsRef = databaseRef.child("questions")
    static let answersRef = databaseRef.child("answers")
    static let usersRef = databaseRef.child("users")
    static let answersStorageRef = storageRef.child("answers")
    static let tagsStorageRef = storageRef.child("tags")
    static let usersStorageRef = storageRef.child("users")

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
    
    static func getTag(tagID : String, completion: (tag : Tag, error : NSError?) -> Void) {
        tagsRef.child(tagID).observeSingleEventOfType(.Value, withBlock: { snap in
            let _currentTag = Tag(tagID: tagID, snapshot: snap)
            completion(tag: _currentTag, error: nil)
        })
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
            let _returnUser = User(uID: uID, snapshot: snap)
            completion(user: _returnUser, error: nil)
        })
    }
    
    /* AUTH METHODS */
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
    
    static func updateUserData(updateType: UserProfileUpdateType, value: String, completion: (success : Bool, error : NSError?) -> Void) {
        let user = FIRAuth.auth()?.currentUser
        if let user = user {
            let changeRequest = user.profileChangeRequest()
            
            switch updateType {
            case .displayName: changeRequest.displayName = value
            case .photoURL: changeRequest.photoURL = NSURL(string: value)
            }
            
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
    
    static func signOut( completion: (success: Bool) -> Void ) {
        if let user = FIRAuth.auth() {
            do {
                try user.signOut()
                if let session = Twitter.sharedInstance().sessionStore.session() {
                    Twitter.sharedInstance().sessionStore.logOutUserID(session.userID)
                }
                if FBSDKAccessToken.currentAccessToken() != nil {
                    FBSDKLoginManager().logOut()
                }
                completion(success: true)
            } catch {
                print(error)
                completion(success: false)
            }
        }
    }
    
    static func checkSocialTokens(completion: (result: Bool) -> Void) {
        if FBSDKAccessToken.currentAccessToken() != nil {
            let token = FBSDKAccessToken.currentAccessToken().tokenString
            let credential = FIRFacebookAuthProvider.credentialWithAccessToken(token)
            FIRAuth.auth()?.signInWithCredential(credential) { (aUser, error) in
                if error != nil {
                    print(error?.localizedDescription)
                } else {
                    completion(result : true)
                }
            }
        } else if let session = Twitter.sharedInstance().sessionStore.session() {
            try! FIRAuth.auth()!.signOut()
            Twitter.sharedInstance().sessionStore.logOutUserID(session.userID)
            let credential = FIRTwitterAuthProvider.credentialWithToken(session.authToken, secret: session.authTokenSecret)
            FIRAuth.auth()?.signInWithCredential(credential) { (aUser, error) in
                if error != nil {
                    completion(result : false)
                } else {
                    completion(result : true)
                }
            }
        } else {
            completion(result: false)
        }
    }
    
    ///Check if user is logged in
    static func checkCurrentUser() {
        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if let _user = user {
                Database.populateCurrentUser(_user)
            } else {
                Database.removeCurrentUser()
                return
            }
        }
    }
    
    ///Remove current user
    static func removeCurrentUser() {
        User.currentUser!.uID = nil
        User.currentUser!.name = nil
        User.currentUser!.answers = nil
        User.currentUser!.answeredQuestions = nil
        User.currentUser!.profilePic = nil
        User.currentUser!._totalAnswers = nil
        NSNotificationCenter.defaultCenter().postNotificationName("UserUpdated", object: self)

    }
    
    ///Populate current user
    static func populateCurrentUser(user: FIRUser!) {
        User.currentUser!.uID = user.uid
        usersRef.child(user.uid).observeEventType(.Value, withBlock: { snap in
            if snap.hasChild("name") {
                User.currentUser!.name = snap.childSnapshotForPath("name").value as? String
            }
            if snap.hasChild("profilePic") {
                User.currentUser!.profilePic = snap.childSnapshotForPath("profilePic").value as? String
            }
            if snap.hasChild("answeredQuestions") {
                for _answeredQuestion in snap.childSnapshotForPath("answeredQuestions").children {
                    if (User.currentUser!.answeredQuestions?.append(_answeredQuestion.key) == nil) {
                        User.currentUser!.answeredQuestions = [_answeredQuestion.key]
                    }
                }
            }
            if snap.hasChild("answers") {
                User.currentUser?._totalAnswers = Int(snap.childSnapshotForPath("answers").childrenCount)
                for _answer in snap.childSnapshotForPath("answers").children {
                    if (User.currentUser!.answers?.append(_answer.key) == nil) {
                        User.currentUser!.answers = [_answer.key]
                    }
                }
            }
            
            NSNotificationCenter.defaultCenter().postNotificationName("UserUpdated", object: self)

        })
    }
    
    ///Save user to Pulse database after Auth
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
    
    ///Save user answers to Pulse database after Auth
    static func addUserAnswersToDatabase( aID: String, qID: String, completion: (success : Bool, error : NSError?) -> Void) {
        let _user = FIRAuth.auth()?.currentUser
        let post = ["users/\(_user!.uid)/answers/\(aID)": "true", "users/\(_user!.uid)/answeredQuestions/\(qID)" : "true","questions/\(qID)/answers/\(aID)" : true]
        if _user != nil {
            databaseRef.updateChildValues(post, withCompletionBlock: { (error:NSError?, ref:FIRDatabaseReference!) in
            if error != nil {
                completion(success: false, error: error)
            } else {
                completion(success: true, error: nil)
            }
            })
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "please enter a valid email" ]
            completion(success: false, error: NSError.init(domain: "NotLoggedIn", code: 200, userInfo: userInfo))
        }
    }
    
    static func addAnswerVote(_vote : AnswerVoteType, aID : String, completion: (success : Bool, error : NSError?) -> Void) {
        answersRef.child(aID).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if var answer = currentData.value as? [String : AnyObject], let uid = FIRAuth.auth()?.currentUser?.uid {
                var votes : Dictionary<String, Bool>
                votes = answer["votes"] as? [String : Bool] ?? [:]
                var voteCount = answer["voteCount"] as? Int ?? 0
                if let _ = votes[uid] {
                    //already voted for answer
                }
                else {
                    if _vote == AnswerVoteType.Downvote {
                        voteCount -= 1
                        votes[uid] = true
                    } else {
                        voteCount += 1
                        votes[uid] = true
                    }
                }
                answer["voteCount"] = voteCount
                answer["votes"] = votes
                
                currentData.value = answer
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
                completion(success: false, error: error)
            } else if committed == true {
                completion(success: true, error: nil)
            }
        }
    }
    
    /* STORAGE METHODS */
    static func getAnswerURL(fileID : String, completion: (URL : NSURL?, error : NSError?) -> Void) {
        let _ = answersStorageRef.child(fileID).downloadURLWithCompletion { (URL, error) -> Void in
            if (error != nil) {
                completion(URL: nil, error: error)
            } else {
                completion(URL: URL, error: nil)
            }
        }
    }
    
    static func getTagImage(fileID : String, maxImgSize : Int64, completion: (data : NSData?, error : NSError?) -> Void) {
        let _ = tagsStorageRef.child(fileID).dataWithMaxSize(maxImgSize) { (data, error) -> Void in
            if (error != nil) {
                completion(data: nil, error: error)
            } else {
                completion(data: data, error: nil)
            }
        }
    }
    
    /* UPLOAD IMAGE TO STORAGE */
    ///upload image to firebase and update current user with photoURL upon success
    static func uploadProfileImage(imgData : NSData, completion: (URL : NSURL?, error : NSError?) -> Void) {
        var _downloadURL : NSURL?
        let _metadata = FIRStorageMetadata()
        _metadata.contentType = "image/"
        
        if let _currentUserID = User.currentUser?.uID {
            usersStorageRef.child(_currentUserID).child("profilePic").putData(imgData, metadata: nil) { (metadata, error) in
                if (error != nil) {
                    completion(URL: nil, error: error)
                } else {
                    _downloadURL = metadata!.downloadURL()
                    updateUserData(.photoURL, value: String(_downloadURL!)) { success, error in
                        if success {
                            completion(URL: _downloadURL, error: nil)
                        }
                        else {
                            completion(URL: nil, error: error)
                        }
                    }
                }
            }
        }
    }
}