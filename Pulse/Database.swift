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
var initialFeedUpdateComplete = false

class Database {

    static let tagsRef = databaseRef.child(Item.Tags.rawValue)
    static let questionsRef = databaseRef.child(Item.Questions.rawValue)
    static let answersRef = databaseRef.child(Item.Answers.rawValue)
    static let answerCollectionsRef = databaseRef.child(Item.AnswerCollections.rawValue)

    static let currentUserRef = databaseRef.child(Item.Users.rawValue).child(User.currentUser!.uID!)
    static let currentUserFeedRef = databaseRef.child(Item.Users.rawValue).child(User.currentUser!.uID!).child(Item.Feed.rawValue)

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
    
    static func getAnswerCollection(aCollectionID : String, completion: (hasDetail : Bool, answers : [String]?) -> Void) {
        var answers = [String]()
        answerCollectionsRef.child(aCollectionID).observeSingleEventOfType(.Value, withBlock: { snap in
            if snap.childrenCount <= 1 {
                completion(hasDetail : false, answers: nil)
            } else {
                for child in snap.children {
                    answers.append(child.key as String)
                }
                completion(hasDetail : true, answers: answers)
            }
        })
    }
    
    static func getUser(uID : String, completion: (user : User, error : NSError?) -> Void) {
        usersPublicSummaryRef.child(uID).observeSingleEventOfType(.Value, withBlock: { snap in
            let _returnUser = User(uID: uID, snapshot: snap)
            completion(user: _returnUser, error: nil)
        })
    }
    
    static func getUserProperty(uID : String, property: String, completion: (property : String?) -> Void) {
        usersRef.child("\(uID)/\(property)").observeSingleEventOfType(.Value, withBlock: { snap in
            if let _property = snap.value as? String {
                completion(property : _property)
            } else {
                completion(property :  nil)
            }
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
    
    /* CREATE / UPDATE FEED */
    static func addNewQuestionsFromTagToFeed(tagID : String, completion: (success: Bool) -> Void) {
        var tagQuestions : FIRDatabaseQuery = tagsRef.child(tagID).child("questions")
        
        currentUserRef.child("savedTags").child(tagID).observeSingleEventOfType(.Value, withBlock: { snap in
        if snap.exists() && snap.value!.isKindOfClass(NSString) {
            //first get the last sync'd question for a tag
            let lastQuestionID = snap.value as! String
            
            if lastQuestionID != "true" {
                tagQuestions = tagQuestions.queryOrderedByKey().queryStartingAtValue(lastQuestionID)
            }
            
            print("last question ID \(lastQuestionID)")
            
            var newQuestions = [String : String?]()
            
            tagQuestions.observeSingleEventOfType(.Value, withBlock: { questionSnap in
                for (questionIndex, questionID) in questionSnap.children.enumerate() {
                    print("current index is \(questionIndex) and questionID is \(questionID)")
                    
                    if questionID.key != lastQuestionID {
                        newQuestions[questionID.key] = "true"
                    }
                        
                    if questionIndex + 1 == Int(questionSnap.childrenCount) && questionID.key != lastQuestionID { //at the last question in tag query
                        currentUserRef.child("savedTags").updateChildValues([tagID : questionID.key]) // update last sync'd question ID
                        keepTagQuestionsUpdated(tagID, lastQuestionID: questionID.key) // add listener for new questions added to tag
                    }
                }
                
                // adds the questions to the feed once we have iterated through all the questions
                updateFeedQuestions(newQuestions)
                completion(success: true)
            })
        }
        })
    }
    
    static func updateFeedQuestions(questions : [String : String?]) {
        //add new questions to feed
        let _updatePath = currentUserRef.child(Item.Feed.rawValue)
        
        for (questionID, lastAnswerID) in questions {
            var newAnswersForQuestion : FIRDatabaseQuery = questionsRef.child(questionID).child("answers")

            if lastAnswerID != "true" {
                newAnswersForQuestion = newAnswersForQuestion.queryOrderedByKey().queryStartingAtValue(lastAnswerID)
            }
            
            newAnswersForQuestion.observeSingleEventOfType(.Value, withBlock: { snap in
                let totalNewAnswers = snap.childrenCount

                for (answerIndex, answerID) in snap.children.enumerate() {
                    
                    if answerIndex + 1 == Int(totalNewAnswers) && answerID.key != lastAnswerID {
                        //if last answer then update value for last sync'd answer in database and add listener
                        _updatePath.updateChildValues([questionID : answerID.key])
                        keepQuestionsAnswersUpdated(questionID, lastAnswerID: answerID.key)
                    }
                }
            })
        }
    }
    
    static func keepUserTagsUpdated() {
        let userTagsPath : FIRDatabaseQuery = getDatabasePath(Item.Users, itemID: User.currentUser!.uID!).child("savedTags")
        
        userTagsPath.observeEventType(.ChildAdded, withBlock: { tagSnap in
            if initialFeedUpdateComplete {
                print("observer for child added fired")
                addNewQuestionsFromTagToFeed(tagSnap.key, completion: { success in })
            } else {
                print("ignoring child added)")
            }
        })
    }
    
    static func keepTagQuestionsUpdated(tagID : String, lastQuestionID : String) {
        let tagsRef = getDatabasePath(Item.Tags, itemID: tagID).child("questions").queryOrderedByKey().queryStartingAtValue(lastQuestionID)
        tagsRef.observeEventType(.ChildAdded, withBlock: { (snap) in
            if snap.key != lastQuestionID {
                print("observer fired for new question added to tag, tagID : questionID \(tagID, lastQuestionID)")
                currentUserRef.child("savedTags").updateChildValues([tagID : snap.key]) //update last sync'd question for user
                updateFeedQuestions([snap.key : "true"]) //add question to feed
            }
        })
    }
    
    static func keepQuestionsAnswersUpdated(questionID : String, lastAnswerID : String) {
        let _updatePath = currentUserRef.child("savedQuestions")
        let _observePath = getDatabasePath(Item.Questions, itemID: questionID).child("answers").queryOrderedByKey().queryStartingAtValue(lastAnswerID)
        
        _observePath.observeEventType(.ChildAdded, withBlock: { snap in
            print("this should fire once for each question with questionID : lastAnswerID \(questionID, lastAnswerID)")
            _updatePath.updateChildValues([questionID : snap.key])
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
        User.currentUser!.savedTags = [ : ]
        User.currentUser!.profilePic = nil
        User.currentUser!._totalAnswers = nil
        User.currentUser!.birthday = nil
        User.currentUser!.bio = nil
        User.currentUser!.gender = nil
        User.currentUser!.savedQuestions = [ : ]
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
                for _tag in snap.childSnapshotForPath("savedTags").children {
                    User.currentUser!.savedTags[_tag.key] = _tag.value
                }
            }
            
            if snap.hasChild("savedQuestions") {
                User.currentUser!.savedQuestions = [ : ]
                for _tag in snap.childSnapshotForPath("savedQuestions").children {
                    User.currentUser!.savedQuestions[_tag.key] = _tag.value
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
            case .shortBio, .name, .profilePic, .thumbPic:
                userPost[setting.settingID] = newValue
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
    
    ///Save individual answer to Pulse database after Auth
    static func addUserAnswersToDatabase( answer : Answer, completion: (success : Bool, error : NSError?) -> Void) {
        let _user = FIRAuth.auth()?.currentUser
        
        var answersPost : [ String : AnyObject ] = ["qID": answer.qID, "uID": _user!.uid, "createdAt" : FIRServerValue.timestamp()]
        
        if answer.aLocation != nil {
            answersPost["location"] = answer.aLocation!
        }
        
        if answer.aType != nil {
            answersPost["type"] = String(answer.aType!)
        }
        
        let post : [NSObject : AnyObject] = ["answers/\(answer.aID)" : answersPost]

        if _user != nil {
            databaseRef.updateChildValues(post , withCompletionBlock: { (error:NSError?, ref:FIRDatabaseReference!) in
                error != nil ? completion(success: false, error: error) : completion(success: true, error: nil)
            })
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "please login" ]
            completion(success: false, error: NSError.init(domain: "NotLoggedIn", code: 404, userInfo: userInfo))
        }
    }
    
    ///Save collection into question / user
    static func addAnswerCollectionToDatabase(firstAnswer : Answer, post : [String : Bool], completion: (success : Bool, error : NSError?) -> Void) {
        let _user = FIRAuth.auth()?.currentUser
        
        let collectionPost : [NSObject : AnyObject] = ["users/\(_user!.uid)/answers/\(firstAnswer.aID)": "true", "users/\(_user!.uid)/answeredQuestions/\(firstAnswer.qID)" : "true","questions/\(firstAnswer.qID)/answers/\(firstAnswer.aID)" : true, "answerCollections/\(firstAnswer.aID)" : post]
        
        if _user != nil {
            databaseRef.updateChildValues(collectionPost , withCompletionBlock: { (error:NSError?, ref:FIRDatabaseReference!) in
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
        let path = answersStorageRef.child(fileID)
        
        let _ = path.downloadURLWithCompletion { (URL, error) -> Void in
            error != nil ? completion(URL: nil, error: error!) : completion(URL: URL!, error: nil)
        }
    }
    
    
    static func getAnswerMeta(fileID : String, completion: (contentType : MediaAssetType?, error : NSError?) -> Void) {
        let path = answersStorageRef.child(fileID)
        
        path.metadataWithCompletion { (metadata, error) -> Void in
            if let _metadata = metadata?.contentType {
                error != nil ? completion(contentType : nil, error: error!) : completion(contentType: MediaAssetType.getAssetType(_metadata), error: nil)
            }
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
    
    static func saveQuestion(questionID : String, completion: (success : Bool, error : NSError?) -> Void) {
        if User.isLoggedIn() {
            if User.currentUser?.savedQuestions != nil && User.currentUser!.savedQuestions[questionID] != nil { //remove question
                let _path = getDatabasePath(Item.Users, itemID: User.currentUser!.uID!).child("savedQuestions/\(questionID)")
                _path.setValue("true", withCompletionBlock: { (error:NSError?, ref:FIRDatabaseReference!) in
                    error != nil ? completion(success: false, error: error!) : completion(success: true, error: nil)
                })
            } else { //pin question
                let _path = getDatabasePath(Item.Users, itemID: User.currentUser!.uID!).child("savedQuestions")
                _path.updateChildValues([questionID: "true"], withCompletionBlock: { (error:NSError?, ref:FIRDatabaseReference!) in
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
            if User.currentUser?.savedTags != nil && User.currentUser!.savedTags[tag.tagID!] != nil { //remove tag
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
        let imgData = image.mediumQualityJPEGNSData
        
        path.putData(imgData, metadata: _metadata) { (metadata, error) in
            if (error != nil) {
                completion(success: false, error: error)
            } else {
                completion(success: true, error: nil)
            }
        }
    }
    
    ///upload image to firebase and update current user with photoURL upon success
    static func uploadProfileImage(imgData : NSData, completion: (URL : NSURL?, error : NSError?) -> Void) {
        var _downloadURL : NSURL?
        let _metadata = FIRStorageMetadata()
        _metadata.contentType = "image/jpeg"
        
        if let _currentUserID = User.currentUser?.uID, _imageToResize = UIImage(data: imgData), _img = resizeImage(_imageToResize, newWidth: 600){
            usersStorageRef.child(_currentUserID).child("profilePic").putData(_img, metadata: nil) { (metadata, error) in
                if let metadata = metadata {
                    _downloadURL = metadata.downloadURL()
                    updateUserData(.photoURL, value: String(_downloadURL!)) { success, error in
                        success ? completion(URL: _downloadURL, error: nil) : completion(URL: nil, error: error)
                    }
                } else {
                    completion(URL: nil, error: error)
                }
            }
            
            if let _thumbImageData = resizeImage(UIImage(data: imgData)!, newWidth: 100) {
                usersStorageRef.child(_currentUserID).child("thumbPic").putData(_thumbImageData, metadata: nil) { (metadata, error) in
                    if let url = metadata?.downloadURL() {
                        let userPost = ["thumbPic" : String(url)]
                        usersPublicSummaryRef.child(_currentUserID).updateChildValues(userPost)
                    }
                }

            }
        }
    }
    
    static func resizeImage(image: UIImage, newWidth: CGFloat) -> NSData? {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        image.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return UIImageJPEGRepresentation(newImage, 0.7)
    }
}