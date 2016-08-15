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

    static let tagsRef = databaseRef.child(Item.Tags.rawValue)
    static let questionsRef = databaseRef.child(Item.Questions.rawValue)
    static let answersRef = databaseRef.child(Item.Answers.rawValue)

    static let usersRef = databaseRef.child(Item.Users.rawValue)
    static let usersPublicSummaryRef = databaseRef.child(Item.UserSummary.rawValue)

    static let filtersRef = databaseRef.child(Item.Filters.rawValue)
    static let settingsRef = databaseRef.child(Item.Settings.rawValue)
    static let settingSectionsRef = databaseRef.child(Item.SettingSections.rawValue)

    static let answersStorageRef = storageRef.child(Item.Answers.rawValue)
    static let tagsStorageRef = storageRef.child(Item.Tags.rawValue)
    static let usersStorageRef = storageRef.child(Item.Users.rawValue)

//    static func getPath(from : Source, type : Item, itemID : String) -> FIRDatabaseReference? {
//        if from == .Storage {
//            return storageRef.child(type.rawValue).child(itemID)
//        }
//    }
    
    static func getDatabasePath(type : Item, itemID : String) -> FIRDatabaseReference {
        return databaseRef.child(type.rawValue).child(itemID)
    }
    
    static func getStoragePath(type : Item, itemID : String) -> FIRStorageReference {
        return storageRef.child(type.rawValue).child(itemID)
    }
    
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
    
    static func getSections(completion: (sections : [SettingSection], error : NSError?) -> Void) {
        var _sections = [SettingSection]()
        
        settingSectionsRef.observeSingleEventOfType(.Value, withBlock: { snapshot in

            for section in snapshot.children {
                let _section = section as! FIRDataSnapshot
                _sections.append(SettingSection(sectionID: _section.key, snapshot: _section))
            }
            completion(sections: _sections, error: nil)
        })
    }
    
    static func getSetting(settingID : String, completion: (setting : Setting, error : NSError?) -> Void) {
        settingsRef.child(settingID).observeSingleEventOfType(.Value, withBlock: { snapshot in
            let _setting = Setting(snap: snapshot)
            completion(setting: _setting, error: nil)
        })
    }
    
//    static func getSettings(sectionID: String, completion: (settings : [Setting], error : NSError?) -> Void) {
//        let _settings = (ref.child("user-posts").child(getUid())).queryOrderedByChild("starCount")
//
//    }
 
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
        usersPublicSummaryRef.child(uID).observeSingleEventOfType(.Value, withBlock: { snap in
            let _returnUser = User(uID: uID, snapshot: snap)
            completion(user: _returnUser, error: nil)
        })
    }
    
    static func getUserSummaryForAnswer(aID : String, completion: (user : User?, error : NSError?) -> Void) {
        answersRef.child(aID).observeSingleEventOfType(.Value, withBlock: { snap in
            if snap.hasChild("uID") {
                let _uID = snap.childSnapshotForPath("uID").value as! String
                getUser(_uID, completion: {(_user, error) in
                    error != nil ? completion(user: nil, error: error) : completion(user: _user, error: nil)
                })
            } else {
                let userInfo = [ NSLocalizedDescriptionKey : "no user found" ]
                completion(user: nil, error: NSError.init(domain: "NoUserFound", code: 404, userInfo: userInfo))
            }
        })
    }
    
    /* AUTH METHODS */
    static func createEmailUser(email : String, password: String, completion: (user : User?, error : NSError?) -> Void) {
        FIRAuth.auth()?.createUserWithEmail(email, password: password) { (_user, _error) in
            if _error != nil {
                completion(user: nil, error: _error)
            } else {
                saveUserToDatabase(_user!, completion: { (success , error) in
                    error != nil ? completion(user: nil, error: error) : completion(user: User(user: _user!), error: nil)
                })
            }
        }
    }
    
    // Update FIR auth profile - name, profilepic
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
                        error != nil ? completion(success: false, error: error) : completion(success: true, error: nil)
                    })
                }
            }
        }
    }
    
    static func signOut( completion: (success: Bool) -> Void ) {
        if let user = FIRAuth.auth() {
            do {
                try user.signOut()
                //might not want to remove the tokens - but need to check its working first
                if let session = Twitter.sharedInstance().sessionStore.session() {
                    Twitter.sharedInstance().sessionStore.logOutUserID(session.userID)
                }
                if FBSDKAccessToken.currentAccessToken() != nil {
                    FBSDKLoginManager().logOut()
                }
                NSNotificationCenter.defaultCenter().postNotificationName("LogoutSuccess", object: self)
                completion(success: true)
            } catch {
                print(error)
                completion(success: false)
            }
        }
    }
    
    static func checkSocialTokens(completion: (result: Bool) -> Void) {
        print("checking social tokens")
        if FBSDKAccessToken.currentAccessToken() != nil {
            print("found fb token")

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
            print("found twtr token")

            let credential = FIRTwitterAuthProvider.credentialWithToken(session.authToken, secret: session.authTokenSecret)
            FIRAuth.auth()?.signInWithCredential(credential) { (aUser, error) in
                if error != nil {
                    completion(result : false)
                } else {
                    print("logged in with twtr")
                    completion(result : true)
                }
            }
        } else {
            print("no token found")
            completion(result: false)
        }
    }
    
    ///Check if user is logged in
    static func checkCurrentUser() {
        Database.checkSocialTokens({(result) in print(result)})

        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if let _user = user {
                Database.populateCurrentUser(_user)
            } else {
                print("auth state changed")
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
        User.currentUser!.savedTags = nil
        User.currentUser!.profilePic = nil
        User.currentUser!._totalAnswers = nil
        User.currentUser!.birthday = nil
        User.currentUser!.bio = nil
        User.currentUser!.gender = nil
        User.currentUser!.savedQuestions = nil
        User.currentUser!.socialSources = [ : ]
        
        NSNotificationCenter.defaultCenter().postNotificationName("UserUpdated", object: self)

    }
    
    ///Populate current user
    static func populateCurrentUser(user: FIRUser!) {
        User.currentUser!.uID = user.uid
        
        usersPublicSummaryRef.child(user.uid).observeEventType(.Value, withBlock: { snap in
            if snap.hasChild(SettingTypes.name.rawValue) {
                User.currentUser!.name = snap.childSnapshotForPath(SettingTypes.name.rawValue).value as? String
            }
            if snap.hasChild(SettingTypes.profilePic.rawValue) {
                User.currentUser!.profilePic = snap.childSnapshotForPath(SettingTypes.profilePic.rawValue).value as? String
            }
            if snap.hasChild(SettingTypes.shortBio.rawValue) {
                User.currentUser!.shortBio = snap.childSnapshotForPath(SettingTypes.shortBio.rawValue).value as? String
            }
        })

        usersRef.child(user.uid).observeEventType(.Value, withBlock: { snap in

            if snap.hasChild(SettingTypes.birthday.rawValue) {
                User.currentUser!.birthday = snap.childSnapshotForPath(SettingTypes.birthday.rawValue).value as? String
            }
            if snap.hasChild(SettingTypes.bio.rawValue) {
                User.currentUser!.bio = snap.childSnapshotForPath(SettingTypes.bio.rawValue).value as? String
            }
            if snap.hasChild(SettingTypes.gender.rawValue) {
                User.currentUser!.gender = snap.childSnapshotForPath(SettingTypes.gender.rawValue).value as? String
            }
            if snap.hasChild("answeredQuestions") {
                User.currentUser!.answeredQuestions = nil
                for _answeredQuestion in snap.childSnapshotForPath("answeredQuestions").children {
                    if (User.currentUser!.answeredQuestions?.append(_answeredQuestion.key) == nil) {
                        User.currentUser!.answeredQuestions = [_answeredQuestion.key]
                    }
                }
            }
            if snap.hasChild("answers") {
                User.currentUser!.answers = nil
                User.currentUser?._totalAnswers = Int(snap.childSnapshotForPath("answers").childrenCount)
                for _answer in snap.childSnapshotForPath("answers").children {
                    if (User.currentUser!.answers?.append(_answer.key) == nil) {
                        User.currentUser!.answers = [_answer.key]
                    }
                }
            }
            
            if snap.hasChild("savedTags") {
                User.currentUser!.savedTags = nil
                for _tag in snap.childSnapshotForPath("savedTags").children {
                    if (User.currentUser!.savedTags?.append(_tag.key) == nil) {
                        User.currentUser!.savedTags = [_tag.key]
                    }
                }
            }
            
            if snap.hasChild("savedQuestions") {
                User.currentUser!.savedQuestions = nil
                for _tag in snap.childSnapshotForPath("savedQuestions").children {
                    if (User.currentUser!.savedQuestions?.append(_tag.key) == nil) {
                        User.currentUser!.savedQuestions = [_tag.key]
                    }
                }
            }
            
            for profile in user.providerData {
                let providerID = profile.providerID
                if providerID == "facebook.com" {
                    User.currentUser!.socialSources[.facebook] = true
                } else if providerID == "twitter.com" {
                    User.currentUser!.socialSources[.twitter] = true
                }
            }
            NSNotificationCenter.defaultCenter().postNotificationName("UserUpdated", object: self)

        })
    }
    
    ///Update user profile to Pulse database from settings
    static func updateUserProfile(setting : Setting, newValue : String, completion: (success : Bool, error : NSError?) -> Void) {
        let _user = FIRAuth.auth()?.currentUser
        
        var userPost = [String : String]()
        if User.isLoggedIn() {
            switch setting.type! {
            case .email:
                _user?.updateEmail(newValue) { error in
                    error != nil ? completion(success: false, error: error) : completion(success: true, error: nil)
                }
            case .password:
                _user?.updatePassword(newValue) { error in
                    error != nil ? completion(success: false, error: error) : completion(success: true, error: nil)
                }
            case .shortBio, .name, .profilePic:
                usersPublicSummaryRef.child(_user!.uid).updateChildValues(userPost, withCompletionBlock: { (error:NSError?, ref:FIRDatabaseReference!) in
                    error != nil ? completion(success: false, error: error) : completion(success: true, error: nil)
                })
            default:
                userPost[setting.settingID] = newValue
                usersRef.child(_user!.uid).updateChildValues(userPost, withCompletionBlock: { (error:NSError?, ref:FIRDatabaseReference!) in
                    error != nil ? completion(success: false, error: error) : completion(success: true, error: nil)
                })
            }
        }
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
        usersPublicSummaryRef.child(user.uid).updateChildValues(userPost, withCompletionBlock: { (error:NSError?, ref:FIRDatabaseReference!) in
            error != nil ? completion(success: false, error: error) : completion(success: true, error: nil)
        })
    }
    
    ///Save user answers to Pulse database after Auth
    static func addUserAnswersToDatabase( aID: String, qID: String, completion: (success : Bool, error : NSError?) -> Void) {
        let _user = FIRAuth.auth()?.currentUser
        let post = ["users/\(_user!.uid)/answers/\(aID)": "true", "users/\(_user!.uid)/answeredQuestions/\(qID)" : "true","questions/\(qID)/answers/\(aID)" : true]
        if _user != nil {
            databaseRef.updateChildValues(post, withCompletionBlock: { (error:NSError?, ref:FIRDatabaseReference!) in
                error != nil ? completion(success: false, error: error) : completion(success: true, error: nil)
            })
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "please login" ]
            completion(success: false, error: NSError.init(domain: "NotLoggedIn", code: 404, userInfo: userInfo))
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
                completion(success: false, error: error)
            } else if committed == true {
                completion(success: true, error: nil)
            }
        }
    }
    
    /* STORAGE METHODS */
    static func getAnswerURL(fileID : String, completion: (URL : NSURL?, error : NSError?) -> Void) {
        let _ = answersStorageRef.child(fileID).downloadURLWithCompletion { (URL, error) -> Void in
            error != nil ? completion(URL: nil, error: error!) : completion(URL: URL, error: nil)
        }
    }
    
    static func getTagImage(fileID : String, maxImgSize : Int64, completion: (data : NSData?, error : NSError?) -> Void) {
        let _ = tagsStorageRef.child(fileID).dataWithMaxSize(maxImgSize) { (data, error) -> Void in
            error != nil ? completion(data: nil, error: error!) : completion(data: data, error: nil)
        }
    }
    
    static func getImage(type : Item, fileID : String, maxImgSize : Int64, completion: (data : NSData?, error : NSError?) -> Void) {
        let path = getStoragePath(type, itemID: fileID)
        path.dataWithMaxSize(maxImgSize) { (data, error) -> Void in
            error != nil ? completion(data: nil, error: error!) : completion(data: data, error: nil)
        }
    }
    
    static func pinQuestionForUser(question : Question, completion: (success : Bool, error : NSError?) -> Void) {
        if User.isLoggedIn() {
            if User.currentUser?.savedQuestions != nil && User.currentUser!.savedQuestions!.contains(question.qID) { //remove question
                let _path = getDatabasePath(Item.Users, itemID: User.currentUser!.uID!).child("savedQuestions/\(question.qID)")
                _path.setValue(nil, withCompletionBlock: { (error:NSError?, ref:FIRDatabaseReference!) in
                    error != nil ? completion(success: false, error: error!) : completion(success: true, error: nil)
                })
            } else { //pin question
                let _path = getDatabasePath(Item.Users, itemID: User.currentUser!.uID!).child("savedQuestions")
                _path.updateChildValues([question.qID: "true"], withCompletionBlock: { (error:NSError?, ref:FIRDatabaseReference!) in
                    error != nil ? completion(success: false, error: error) : completion(success: true, error: nil)
                })
            }
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "please login to save questions" ]
            completion(success: false, error: NSError(domain: "NotLoggedIn", code: 200, userInfo: userInfo))
        }
    }
    
    static func pinTagForUser(tag : Tag, completion: (success : Bool, error : NSError?) -> Void) {
        if User.isLoggedIn() {
            if User.currentUser?.savedTags != nil && User.currentUser!.savedTags!.contains(tag.tagID!) { //remove tag
                let _path = getDatabasePath(Item.Users, itemID: User.currentUser!.uID!).child("savedTags/\(tag.tagID!)")
                _path.setValue(nil, withCompletionBlock: { (error:NSError?, ref:FIRDatabaseReference!) in
                    error != nil ? completion(success: false, error: error) : completion(success: true, error: nil)
                })
            }
            else { //save tag
                let _path = getDatabasePath(Item.Users, itemID: User.currentUser!.uID!).child("savedTags")
                _path.updateChildValues([tag.tagID!: "true"], withCompletionBlock: { (error:NSError?, ref:FIRDatabaseReference!) in
                    error != nil ? completion(success: false, error: error) : completion(success: true, error: nil)
                })
            }
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "please login to save tags" ]
            completion(success: false, error: NSError(domain: "NotLoggedIn", code: 200, userInfo: userInfo))
        }
    }
    
    /* UPLOAD IMAGE TO STORAGE */
    
    static func uploadImage(type : Item, fileID : String, image : UIImage, completion: (success : Bool, error : NSError?) -> Void) {
        let path = getStoragePath(type, itemID: fileID)
        let _metadata = FIRStorageMetadata()
        _metadata.contentType = "image/jpeg"
        let imgData = UIImageJPEGRepresentation(image, 0.4)
        
        if let imgData = imgData {
            path.putData(imgData, metadata: _metadata) { (metadata, error) in
                if (error != nil) {
                    completion(success: false, error: error)
                } else {
                    
                }
            }
        }
    }
    
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