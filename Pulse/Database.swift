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
import GeoFire

let storage = FIRStorage.storage()
let storageRef = storage.reference(forURL: "gs://pulse-84022.appspot.com")
let databaseRef = FIRDatabase.database().reference()
var initialFeedUpdateComplete = false

class Database {

    static let tagsRef = databaseRef.child(Item.Tags.rawValue)
    static let questionsRef = databaseRef.child(Item.Questions.rawValue)
    static let answersRef = databaseRef.child(Item.Answers.rawValue)
    static let answerCollectionsRef = databaseRef.child(Item.AnswerCollections.rawValue)

    static let messagesRef = databaseRef.child(Item.Messages.rawValue)
    static let conversationsRef = databaseRef.child(Item.Conversations.rawValue)

    static var currentUserRef : FIRDatabaseReference!
    static var currentUserFeedRef : FIRDatabaseReference!

    static let usersRef = databaseRef.child(Item.Users.rawValue)
    static let usersPublicSummaryRef = databaseRef.child(Item.UserSummary.rawValue)

    static let filtersRef = databaseRef.child(Item.Filters.rawValue)
    static let settingsRef = databaseRef.child(Item.Settings.rawValue)
    static let settingSectionsRef = databaseRef.child(Item.SettingSections.rawValue)

    static let answersStorageRef = storageRef.child(Item.Answers.rawValue)
    static let tagsStorageRef = storageRef.child(Item.Tags.rawValue)
    static let usersStorageRef = storageRef.child(Item.Users.rawValue)

    static var masterQuestionIndex = [String : String]()
    static var masterTagIndex = [String : String]()

    static let querySize : UInt = 20
    
    
    /** MARK : SEARCH **/
    static func searchTags(searchText : String, completion: @escaping (_ tagResult : [Tag]) -> Void) {
        var _results = [Tag]()
    
        search(type: .tag, searchText: searchText, completion: { results in
            for (key, value) in results {
                let _currentTag = Tag(tagID: key)
                _currentTag.tagDescription = value
                _results.append(_currentTag)
            }
            
            completion(_results)
        })
    }
    
    static func searchQuestions(searchText : String, completion: @escaping (_ questionsResult : [Question]) -> Void) {
        var _results = [Question]()
        
        search(type: .question, searchText: searchText, completion: { results in
            for (key, value) in results {
                let _currentQuestion = Question(qID: key)
                _currentQuestion.qTitle = value
                _results.append(_currentQuestion)
            }
            
            completion(_results)
        })
    }
    
    static func searchUsers(searchText : String, completion: @escaping (_ peopleResult : [User]) -> Void) {
        var allUsers = [User]()
        let endingString = searchText.appending("\u{f8ff}")
        
        usersPublicSummaryRef.queryOrdered(byChild: "name").queryStarting(atValue: searchText).queryEnding(atValue: endingString).observeSingleEvent(of: .value, with: { snapshot in
            for item in snapshot.children {
                let snap = item as! FIRDataSnapshot
                allUsers.append(User(uID: snap.key, snapshot: snap))
            }
            completion(allUsers)
        })
    }
    
    static func search(type : FeedItemType, searchText : String, completion: @escaping (_ results : [(key: String, value: String)]) -> Void) {
        switch type {
        case .question:
            if masterQuestionIndex.count == 0 {
                createQuestionIndex{
                    performSearch(searchText: searchText, type: type, completion: {(_results) in
                        completion(_results)
                    })                }
            } else {
                performSearch(searchText: searchText, type: type, completion: {(_results) in
                    completion(_results)
                })
            }
        case .tag:
            if masterTagIndex.count == 0 {
                createTagIndex{
                    performSearch(searchText: searchText, type: type, completion: {(_results) in
                        completion(_results)
                    })
                }
            } else {
                performSearch(searchText: searchText, type: type, completion: {(_results) in
                    completion(_results)
                })
            }
        case .people: break
        case .answer: break
        }
    }
    
    internal static func createTagIndex(completion: @escaping () -> Void) {
        databaseRef.child("tagSearchIndex").observeSingleEvent(of: .value, with: { snapshot in
            for aTag in snapshot.children {
                masterTagIndex[(aTag as AnyObject).key] = (aTag as AnyObject).value.lowercased()
                
                if masterTagIndex.count == Int(snapshot.childrenCount) {
                    completion()
                }
            }
        })
    }
    
    internal static func createQuestionIndex(completion: @escaping () -> Void) {
        databaseRef.child("questionSearchIndex").observeSingleEvent(of: .value, with: { snapshot in
            for aQuestion in snapshot.children {
                masterQuestionIndex[(aQuestion as AnyObject).key] = (aQuestion as AnyObject).value.lowercased()
                
                if masterQuestionIndex.count == Int(snapshot.childrenCount) {
                    completion()
                }

            }
        })
    }
    
    internal static func performSearch(searchText : String, type : FeedItemType, completion: @escaping (_ results : [(key: String, value: String)]) -> Void) {
        switch type {
        case .question:
            let _results = masterQuestionIndex.filter({
                $0.value.contains(searchText)
            })
            completion(_results)
        case .tag:
            let _results = masterTagIndex.filter({
                $0.key.contains(searchText)
            })
            completion(_results)
        case .people: break
        case .answer: break
        }
    }
    
    //OLD WAY OF DIRECTLY SEARCHING ON DB - NEW WAY DOWNLOADS THE FULL STACK
//    static func getSearchTags(searchText : String, completion: @escaping (_ tags : [String], _ error : NSError?) -> Void) {
//        var allTags = [String]()
//        let endingString = searchText.appending("\u{f8ff}")
//        
//        tagsRef.queryOrderedByKey().queryStarting(atValue: searchText).queryEnding(atValue: endingString).observeSingleEvent(of: .value, with: { snapshot in
//            for item in snapshot.children {
//                let child = item as! FIRDataSnapshot
//                allTags.append(child.key)
//            }
//            completion(allTags, nil)
//        })
//    }
    
    /** MARK : MESSAGING **/
    ///Check if user has an existing conversation with receiver, if yes then return the conversation ID
    static func checkExistingConversation(to : User, completion: @escaping (Bool, String?) -> Void) {
        if let _user = FIRAuth.auth()?.currentUser {
            usersRef.child(_user.uid).child("conversations").child(to.uID!).observeSingleEvent(of: .value, with: { snapshot in
                snapshot.exists() ? completion(true, snapshot.childSnapshot(forPath: "conversationID").value as? String) : completion(false, nil)
            })
        }
    }
    
    //Keep conversation updated
    static func keepConversationUpdated(conversationID : String, lastMessage : String?, completion: @escaping (Message) -> Void) {
        let startingValue = lastMessage ?? ""
        
        conversationsRef.child(conversationID).queryOrderedByKey().queryStarting(atValue: startingValue).observe(.childAdded, with: { snapshot in
            if lastMessage != (snapshot as AnyObject).key {
                messagesRef.child((snapshot as AnyObject).key).observeSingleEvent(of: .value, with: { snap in

                    let message = Message(snapshot: snap)
                    completion(message)
                })
            }
        })
    }
    
    //Remove listener
    static func removeConversationObserver(conversationID : String) {
        conversationsRef.child(conversationID).removeAllObservers()
    }
    
    //Get message
    static func getMessage(mID : String, completion: @escaping (Message?) -> Void) {
        messagesRef.child(mID).observeSingleEvent(of: .value, with: { snapshot in
            snapshot.exists() ? completion(Message(snapshot: snapshot)) : completion(nil)
        })
    }
    
    //Retrieve all messages in conversation
    static func getConversationMessages(conversationID : String, completion: @escaping ([Message], String?) -> Void) {
        var messages = [Message]()
        
        conversationsRef.child(conversationID).queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { snapshot in
            for messageID in snapshot.children {
                messagesRef.child((messageID as AnyObject).key).observeSingleEvent(of: .value, with: { snap in
                    let message = Message(snapshot: snap)
                    messages.append(message)
                    
                    if messages.count == Int(snapshot.childrenCount) {
                        let lastMessageID = snap.key
                        completion(messages, lastMessageID)
                    }
                })
            }
        })
    }
    
    //Get all conversations for given user - can only do for auth user
    static func getConversations(completion: @escaping ([Conversation]) -> Void) {
        var conversations = [Conversation]()
        if let _user = FIRAuth.auth()?.currentUser {
            usersRef.child(_user.uid).child("conversations").queryLimited(toLast: querySize).queryOrdered(byChild: "lastMessageID").observeSingleEvent(of: .value, with: { snapshot in
                for conversation in snapshot.children {
                    let _conversation = Conversation(snapshot: conversation as! FIRDataSnapshot)
                    conversations.append(_conversation)
                }
                completion(conversations)
            })
        }
    }
    
    //Keep conversation updated
    static func keepConversationUpdate(to : String?) {
        
    }
    
    ///Send message
    static func sendMessage(existing : Bool, message: Message, completion: @escaping (_ success : Bool, _ conversationID : String?) -> Void) {
        let _user = FIRAuth.auth()?.currentUser
        let messagePost : [ String : AnyObject ] = ["fromID": _user!.uid as AnyObject,
                                                    "toID": message.to.uID! as AnyObject,
                                                    "body": message.body as AnyObject,
                                                    "createdAt" : FIRServerValue.timestamp() as AnyObject]
        
        let messageKey = messagesRef.childByAutoId().key
        
        messagesRef.child(messageKey).setValue(messagePost)
        
        //check if user has this user in existing conversations [toID : conversationID]
        if existing {
            //append to existing conversation if it already exists - message.mID has conversationID saved
            let conversationPost : [AnyHashable: Any] =
                ["conversations/\(message.mID!)/\(messageKey)": FIRServerValue.timestamp() as AnyObject,
                 "users/\(_user!.uid)/conversations/\(message.to.uID!)/lastMessageID" : messageKey,
                 "users/\(message.to.uID!)/conversations/\(_user!.uid)/lastMessageID" : messageKey,
                 "users/\(_user!.uid)/conversations/\(message.to.uID!)/lastMessage" : message.body,
                 "users/\(message.to.uID!)/conversations/\(_user!.uid)/lastMessage" : message.body,
                 "users/\(_user!.uid)/conversations/\(message.to.uID!)/lastMessageTime" : FIRServerValue.timestamp() as AnyObject,
                 "users/\(message.to.uID!)/conversations/\(_user!.uid)/lastMessageTime" : FIRServerValue.timestamp() as AnyObject,
                 "users/\(message.to.uID!)/unreadMessages/\(messageKey)" : FIRServerValue.timestamp() as AnyObject]
            
            databaseRef.updateChildValues(conversationPost, withCompletionBlock: { (completionError, ref) in
                print("completion error \(completionError)")
                completionError != nil ? completion(false, nil) : completion(true, message.mID)
            })
        } else {
            //start new conversation
            let conversationPost : [AnyHashable: Any] =
                ["conversations/\(messageKey)/\(messageKey)": FIRServerValue.timestamp() as AnyObject,
                 "users/\(_user!.uid)/conversations/\(message.to.uID!)/conversationID" : messageKey,
                 "users/\(_user!.uid)/conversations/\(message.to.uID!)/lastMessageID" : messageKey,
                 "users/\(_user!.uid)/conversations/\(message.to.uID!)/lastMessage" : message.body,
                 "users/\(_user!.uid)/conversations/\(message.to.uID!)/lastMessageTime" : FIRServerValue.timestamp() as AnyObject,
                 "users/\(message.to.uID!)/conversations/\(_user!.uid)/conversationID" : messageKey,
                 "users/\(message.to.uID!)/conversations/\(_user!.uid)/lastMessageID" : messageKey,
                 "users/\(message.to.uID!)/conversations/\(_user!.uid)/lastMessage" : message.body,
                 "users/\(message.to.uID!)/conversations/\(_user!.uid)/lastMessageTime" : FIRServerValue.timestamp() as AnyObject,
                 "users/\(message.to.uID!)/unreadMessages/\(messageKey)" : FIRServerValue.timestamp() as AnyObject]
            
            databaseRef.updateChildValues(conversationPost, withCompletionBlock: { (completionError, ref) in
                completionError != nil ? completion(false, nil) : completion(true, messageKey)
            })
        }
    }
    /*** MARK END : MESSAGING ***/

    /*** MARK START : DATABASE PATHS ***/
    static func setCurrentUserPaths() {
        if let _user = FIRAuth.auth()?.currentUser {
            currentUserRef = databaseRef.child(Item.Users.rawValue).child(_user.uid)
            currentUserFeedRef = databaseRef.child(Item.Users.rawValue).child(_user.uid).child(Item.Feed.rawValue)
        } else {
            currentUserRef = nil
            currentUserFeedRef = nil
        }
    }
    
    static func getDatabasePath(_ type : Item, itemID : String) -> FIRDatabaseReference {
        return databaseRef.child(type.rawValue).child(itemID)
    }
    
    static func getStoragePath(_ type : Item, itemID : String) -> FIRStorageReference {
        return storageRef.child(type.rawValue).child(itemID)
    }
    /*** MARK END : DATABASE PATHS ***/

    /*** MARK START : EXPLORE FEED ***/
    static func getExploreTags(_ completion: @escaping (_ tags : [Tag], _ error : NSError?) -> Void) {
        var allTags = [Tag]()
        
        tagsRef.queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { snapshot in
            for item in snapshot.children {
                let child = item as! FIRDataSnapshot
                allTags.append(Tag(tagID: child.key, snapshot: child))
            }
            completion(allTags, nil)
        })
    }
    
    static func getExploreQuestions(_ completion: @escaping (_ questions : [Question?], _ error : NSError?) -> Void) {
        var allQuestions = [Question?]()
        
        questionsRef.queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { snapshot in
            for item in snapshot.children {
                let child = item as! FIRDataSnapshot
                allQuestions.append(Question(qID: child.key, snapshot: child))
            }
            completion(allQuestions, nil)
        })
    }
    
    static func getExploreAnswers(_ completion: @escaping (_ answers : [Answer], _ error : NSError?) -> Void) {
        var allAnswers = [Answer]()
        
        answersRef.queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { snapshot in
            for item in snapshot.children {
                let child = item as! FIRDataSnapshot
                allAnswers.append(Answer(aID: child.key, snapshot: child))
            }
            completion(allAnswers, nil)
        })
    }
    
    static func getExploreUsers(_ completion: @escaping (_ users : [User], _ error : NSError?) -> Void) {
        var allUsers = [User]()
        
        usersPublicSummaryRef.queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { snapshot in
            for item in snapshot.children {
                let child = item as! FIRDataSnapshot
                allUsers.append(User(uID: child.key, snapshot: child))
            }
            completion(allUsers, nil)
        })
    }
    /*** MARK END : EXPLORE FEED ***/

    /*** MARK START : SETTINGS ***/
    static func getSections(_ completion: @escaping (_ sections : [SettingSection], _ error : NSError?) -> Void) {
        var _sections = [SettingSection]()
        
        settingSectionsRef.observeSingleEvent(of: .value, with: { snapshot in

            for section in snapshot.children {
                let _section = section as! FIRDataSnapshot
                _sections.append(SettingSection(sectionID: _section.key, snapshot: _section))
            }
            completion(_sections, nil)
        })
    }
    
    static func getSectionsSection(sectionName : String, completion: @escaping (_ section : SettingSection, _ error : NSError?) -> Void) {
        
        settingSectionsRef.child(sectionName).queryOrderedByValue().observeSingleEvent(of: .value, with: { snapshot in
            let section = SettingSection(sectionID: snapshot.key, snapshot: snapshot)
            completion(section, nil)
        })
    }
    
    static func getSetting(_ settingID : String, completion: @escaping (_ setting : Setting, _ error : NSError?) -> Void) {
        settingsRef.child(settingID).observeSingleEvent(of: .value, with: { snapshot in
            let _setting = Setting(snap: snapshot)
            completion(_setting, nil)
        })
    }
    /*** MARK END : SETTINGS ***/
 
    /*** MARK START : GET FEED ITEMS ***/
    static func getTag(_ tagID : String, completion: @escaping (_ tag : Tag, _ error : NSError?) -> Void) {
        tagsRef.child(tagID).observeSingleEvent(of: .value, with: { snap in
            let _currentTag = Tag(tagID: tagID, snapshot: snap)
            completion(_currentTag, nil)
        })
    }
    
    static func getRelatedTags(_ tagID : String, completion: @escaping (_ tags : [Tag]) -> Void) {
        var allTags = [Tag]()
        
        tagsRef.child(tagID).child("related").observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                for child in snap.children {
                    let _currentTag = Tag(tagID: (child as AnyObject).key)
                    allTags.append(_currentTag)
                }
                completion(allTags)
            } else {
                completion(allTags)
            }
        })
    }
    
    static func getExpertsForTag(tagID : String, completion: @escaping (_ experts : [User]) -> Void) {
        var allExperts = [User]()
        
        tagsRef.child(tagID).child("experts").observeSingleEvent(of: .value, with: { snap in
            for child in snap.children {
                let _currentUser = User(uID: (child as AnyObject).key)
                allExperts.append(_currentUser)
            }
            completion(allExperts)
        })
    }
    
    static func getExpertsForQuestion(qID : String, completion: @escaping (_ experts : [User]) -> Void) {
        var allExperts = [User]()
        
        questionsRef.child(qID).child("experts").observeSingleEvent(of: .value, with: { snap in
            for child in snap.children {
                let _currentUser = User(uID: (child as AnyObject).key)
                allExperts.append(_currentUser)
            }
            completion(allExperts)
        })
    }

    static func getRelatedQuestions(_ qID : String, completion: @escaping (_ questions : [Question]) -> Void) {
        var allQuestions = [Question]()
        
        questionsRef.child(qID).child("related").observeSingleEvent(of: .value, with: { snap in
            for child in snap.children {
                let _currentQuestion = Question(qID: (child as AnyObject).key)
                allQuestions.append(_currentQuestion)
            }
            completion(allQuestions)
        })
    }
    
    static func getQuestion(_ qID : String, completion: @escaping (_ question : Question?, _ error : NSError?) -> Void) {
        questionsRef.child(qID).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                let _currentQuestion = Question(qID: qID, snapshot: snap)
                completion(_currentQuestion, nil)
            }
            else {
                let userInfo = [ NSLocalizedDescriptionKey : "no question found" ]
                completion(nil, NSError.init(domain: "No Question Found", code: 404, userInfo: userInfo))
            }
        })
    }
    
    static func getAnswer(_ aID : String, completion: @escaping (_ answer : Answer, _ error : NSError?) -> Void) {
        answersRef.child(aID).observeSingleEvent(of: .value, with: { snap in
            let _currentAnswer = Answer(aID: aID, snapshot: snap)
            completion(_currentAnswer, nil)
        })
    }
    
    static func getAnswerCollection(_ aCollectionID : String, completion: @escaping (_ hasDetail : Bool, _ answers : [String]?) -> Void) {
        var answers = [String]()
        answerCollectionsRef.child(aCollectionID).observeSingleEvent(of: .value, with: { snap in
            if snap.childrenCount <= 1 {
                completion(false, nil)
            } else {
                for child in snap.children {
                    answers.append((child as AnyObject).key as String)
                }
                completion(true, answers)
            }
        })
    }
    /*** MARK END : GET INDIVIDUAL ITEMS ***/

    /*** MARK START : GET USER ITEMS ***/
    static func getUser(_ uID : String, completion: @escaping (_ user : User, _ error : NSError?) -> Void) {
        usersPublicSummaryRef.child(uID).observeSingleEvent(of: .value, with: { snap in
            let _returnUser = User(uID: uID, snapshot: snap)
            completion(_returnUser, nil)
        })
    }
    
    static func getUserProperty(_ uID : String, property: String, completion: @escaping (_ property : String?) -> Void) {
        usersRef.child("\(uID)/\(property)").observeSingleEvent(of: .value, with: { snap in
            if let _property = snap.value as? String {
                completion(_property)
            } else {
                completion(nil)
            }
        })
    }
    
    static func getUserSummaryForAnswer(_ aID : String, completion: @escaping (_ user : User?, _ error : NSError?) -> Void) {
        answersRef.child(aID).observeSingleEvent(of: .value, with: { snap in
            if snap.hasChild("uID") {
                let _uID = snap.childSnapshot(forPath: "uID").value as! String
                getUser(_uID, completion: {(_user, error) in
                    error != nil ? completion(nil, error) : completion(_user, nil)
                })
            } else {
                let userInfo = [ NSLocalizedDescriptionKey : "no user found" ]
                completion(nil, NSError.init(domain: "NoUserFound", code: 404, userInfo: userInfo))
            }
        })
    }
    
    static func getUserAnswerIDs(uID: String, completion: @escaping (_ answers : [Answer]) -> Void) {
        var allAnswers = [Answer]()
        usersRef.child(uID).child("answers").queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                for child in snap.children {
                    let currentAnswer = Answer(aID: (child as AnyObject).key, qID: (child as AnyObject).value)
                    allAnswers.append(currentAnswer)
                }
                completion(allAnswers)
            } else {
                completion(allAnswers)
            }
        })
    }
    /*** MARK END : GET USER ITEMS ***/
    
    /* CREATE / UPDATE FEED */
    static func createExploreFeed(_ feedItemType: FeedItemType, completedFeed: @escaping (_ feed : [AnyObject?]) -> Void) {
        switch feedItemType {
        case .tag:
            getExploreTags({ tags, error in
                if error == nil {
                    let _feed = tags.map({$0 as AnyObject?})
                    completedFeed(_feed)
                }
            })
        case .question:
            getExploreQuestions({ questions, error in
                if error == nil {
                    let _feed = questions.map({$0 as AnyObject?})
                    completedFeed(_feed)
                }
            })
        case .answer:
            getExploreAnswers({ answers, error in
                if error == nil {
                    completedFeed(answers)
                }
            })
        case .people: break
        }
    }
    
    //Create Feed for current user from followed tags
    static func createFeed(_ completedFeed: @escaping (_ feed : Tag) -> Void) {
        Database.keepUserTagsUpdated()
        
        //monitor updates to existing questions
        updateAnswersForExistingFeedQuestions()
        
        //add in new posts before returning feed
        for (offset : index, (key : tagID, value : _)) in User.currentUser!.savedTags.enumerated() {
            Database.addNewQuestionsFromTagToFeed(tagID, completion: {(success) in
                if index + 1 == User.currentUser?.savedTags.count && success {
                    initialFeedUpdateComplete = true
                    
                    //once feed is updated get the feed to return
                    getFeed({ homeFeed in
                        completedFeed(homeFeed)
                    })
                }
            })
        }
    }
    
    static func getFeed(_ completion: @escaping (_ feed : Tag) -> Void) {
        let homeFeed = Tag(tagID: "feed")         //create new blank 'tag' that will be used for all the questions
        let feedPath = currentUserFeedRef.queryOrdered(byChild: "lastAnswerID").queryLimited(toLast: querySize)
        homeFeed.questions = [Question]()
        
        feedPath.observeSingleEvent(of: .value, with: {(snap) in
            for question in snap.children {
                let _question = Question(qID: (question as AnyObject).key, qTagID: (question as AnyObject).childSnapshot(forPath: "tagID").value as? String)
                homeFeed.questions!.insert(_question, at: 0)
            }
            completion(homeFeed)
        })
    }
    
    static func updateAnswersForExistingFeedQuestions() {
        currentUserFeedRef.observeSingleEvent(of: .value, with: {(questionSnap) in
            for question in questionSnap.children {
                if let _answerID = questionSnap.childSnapshot(forPath: "\((question as AnyObject).key as String)/lastAnswerID").value as? String {
                    User.currentUser!.savedQuestions[(question as AnyObject).key] = _answerID
                    //  Database.keepQuestionsAnswersUpdated(question.key, lastAnswerID: _answerID)
                } else {
                    User.currentUser!.savedQuestions[(question as AnyObject).key] = "true"
                }
            }
            updateFeedQuestions(nil, questions: User.currentUser!.savedQuestions)
        })
    }
    
    static func addNewQuestionsFromTagToFeed(_ tagID : String, completion: @escaping (_ success: Bool) -> Void) {
        var tagQuestions : FIRDatabaseQuery = tagsRef.child(tagID).child("questions")
        
        currentUserRef.child("savedTags").child(tagID).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() && (snap.value! as AnyObject).isKind(of: NSString.self) {
            //first get the last sync'd question for a tag
            let lastQuestionID = snap.value as! String
            
            if lastQuestionID != "true" {
                tagQuestions = tagQuestions.queryOrderedByKey().queryStarting(atValue: lastQuestionID)
            }
            
            var newQuestions = [String : String?]()
            
            tagQuestions.observeSingleEvent(of: .value, with: { questionSnap in
                for (questionIndex, questionID) in questionSnap.children.enumerated() {
                    print("current index is \(questionIndex) and questionID is \(questionID)")
                    
                    let lastQuestionKey = (questionID as! FIRDataSnapshot).key
                    
                    if lastQuestionKey != lastQuestionID {
                        newQuestions[(questionID as AnyObject).key] = "true"
                    }
                    
                    if questionIndex + 1 == Int(questionSnap.childrenCount) && lastQuestionKey != lastQuestionID { //at the last question in tag query
                        currentUserRef.child("savedTags").updateChildValues([tagID : (questionID as! FIRDataSnapshot).key]) // update last sync'd question ID
                        keepTagQuestionsUpdated(tagID, lastQuestionID: (questionID as AnyObject).key) // add listener for new questions added to tag
                    }
                }
                
                // adds the questions to the feed once we have iterated through all the questions
                updateFeedQuestions(tagID, questions: newQuestions)
                completion(true)
            })
        }
        })
    }
    
    static func updateFeedQuestions(_ tagID : String?, questions : [String : String?]) {
        //add new questions to feed
        let _updatePath = currentUserRef.child(Item.Feed.rawValue)
        var post = [String : AnyObject]()
        
        for (questionID, lastAnswerID) in questions {
            var newAnswersForQuestion : FIRDatabaseQuery = questionsRef.child(questionID).child("answers")

            if lastAnswerID != "true" {
                newAnswersForQuestion = newAnswersForQuestion.queryOrderedByKey().queryStarting(atValue: lastAnswerID)
            }
            
            newAnswersForQuestion.observeSingleEvent(of: .value, with: { snap in
                let totalNewAnswers = snap.childrenCount

                for (answerIndex, answerID) in snap.children.enumerated() {
                    
                    if answerIndex + 1 == Int(totalNewAnswers) && (answerID as AnyObject).key != lastAnswerID {
                        
                        //if last answer then update value for last sync'd answer in database and add listener
                        post["lastAnswerID"] = (answerID as AnyObject).key
                        post["newAnswerCount"] = totalNewAnswers as AnyObject?
                        
                        if let _tagID = tagID {
                            post["tagID"] = _tagID as AnyObject?
                        }
                        
                        _updatePath.updateChildValues([questionID : post])
//                        keepQuestionsAnswersUpdated(questionID, lastAnswerID: answerID.key)
                    }
                }
            })
        }
    }
    
    static func keepUserTagsUpdated() {
        if User.isLoggedIn() {
            
            let userTagsPath : FIRDatabaseQuery = getDatabasePath(Item.Users, itemID: User.currentUser!.uID!).child("savedTags")
            
            userTagsPath.observe(.childAdded, with: { tagSnap in
                if initialFeedUpdateComplete {
                    print("observer for child added to tag fired with tag : \(tagSnap.key)")
                    addNewQuestionsFromTagToFeed(tagSnap.key, completion: { success in })
                } else {
                    print("ignoring child added)")
                }
            })
        }
    }
    
    static func keepTagQuestionsUpdated(_ tagID : String, lastQuestionID : String) {
        let tagsRef = getDatabasePath(Item.Tags, itemID: tagID).child("questions").queryOrderedByKey().queryStarting(atValue: lastQuestionID)
        tagsRef.observe(.childAdded, with: { (snap) in
            if snap.key != lastQuestionID {
                print("observer fired for new question added to tag, tagID : questionID \(tagID, lastQuestionID)")
                currentUserRef.child("savedTags").updateChildValues([tagID : snap.key]) //update last sync'd question for user
                updateFeedQuestions(tagID, questions: [snap.key : "true"]) //add question to feed
            }
        })
    }
    
    /** REMOVED THIS LISTENER TO MINIMIZE NUMBER OF CONNECTIONS - ONLY REFRESHING ANSWERS ON RELOAD **/
    static func keepQuestionsAnswersUpdated(_ questionID : String, lastAnswerID : String) {
        let _updatePath = currentUserRef.child("savedQuestions").child(questionID).child("lastAnswerID")
        let _observePath = getDatabasePath(Item.Questions, itemID: questionID).child("answers").queryOrderedByKey().queryStarting(atValue: lastAnswerID)
        
        _observePath.observe(.childAdded, with: { snap in
            print("this should fire once for each last answer with questionID : lastAnswerID \(questionID, lastAnswerID)")
            _updatePath.setValue(snap.key)
        })
    }
    
    /* AUTH METHODS */
    static func createEmailUser(_ email : String, password: String, completion: @escaping (_ user : User?, _ error : NSError?) -> Void) {
        FIRAuth.auth()?.createUser(withEmail: email, password: password) { (_user, _error) in
            if _error != nil {
                completion(nil, _error as NSError?)
            } else {
                saveUserToDatabase(_user!, completion: { (success , error) in
                    error != nil ? completion(nil, error) : completion(User(user: _user!), nil)
                })
            }
        }
    }
    
    // Update FIR auth profile - name, profilepic
    static func updateUserData(_ updateType: UserProfileUpdateType, value: String, completion: @escaping (_ success : Bool, _ error : NSError?) -> Void) {
        let user = FIRAuth.auth()?.currentUser
        if let user = user {
            let changeRequest = user.profileChangeRequest()
            
            switch updateType {
            case .displayName: changeRequest.displayName = value
            case .photoURL: changeRequest.photoURL = URL(string: value)
            }
            
            changeRequest.commitChanges { error in
                if let error = error {
                    completion(false, error as NSError?)
                } else {
                    saveUserToDatabase(user, completion: { (success , error) in
                        error != nil ? completion(false, error) : completion(true, nil)
                    })
                }
            }
        }
    }
    
    static func signOut( _ completion: (_ success: Bool) -> Void ) {
        if let user = FIRAuth.auth() {
            do {
                try user.signOut()
                //might not want to remove the tokens - but need to check its working first
                if let session = Twitter.sharedInstance().sessionStore.session() {
                    Twitter.sharedInstance().sessionStore.logOutUserID(session.userID)
                }
                if FBSDKAccessToken.current() != nil {
                    FBSDKLoginManager().logOut()
                }
                NotificationCenter.default.post(name: Notification.Name(rawValue: "LogoutSuccess"), object: self)
                completion(true)
            } catch {
                print(error)
                completion(false)
            }
        }
    }
    
    static func checkSocialTokens(_ completion: @escaping (_ result: Bool) -> Void) {
        if FBSDKAccessToken.current() != nil {
            print("found fb token")

            let token = FBSDKAccessToken.current().tokenString
            let credential = FIRFacebookAuthProvider.credential(withAccessToken: token!)
            FIRAuth.auth()?.signIn(with: credential) { (aUser, error) in
                if error != nil {
                    GlobalFunctions.showErrorBlock("Error logging in", erMessage: error!.localizedDescription)
                } else {
                    completion(true)
                }
            }
        } else if let session = Twitter.sharedInstance().sessionStore.session() {
            print("found twtr token")

            let credential = FIRTwitterAuthProvider.credential(withToken: session.authToken, secret: session.authTokenSecret)
            FIRAuth.auth()?.signIn(with: credential) { (aUser, error) in
                if error != nil {
                    completion(false)
                } else {
                    print("logged in with twtr")
                    completion(true)
                }
            }
        } else {
            print("no token found")
            completion(false)
        }
    }
    
    ///Check if user is logged in
    static func checkCurrentUser(_ completion: @escaping (Bool) -> Void) {
        Database.checkSocialTokens({(result) in print(result)})

        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if let _user = user {
                populateCurrentUser(_user, completion: { (success) in
                    setCurrentUserPaths()
                    completion(true)
                })
            } else {
                Database.removeCurrentUser()
                completion(false)
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
        User.currentUser!.thumbPic = nil
        User.currentUser!._totalAnswers = nil
        User.currentUser!.birthday = nil
        User.currentUser!.bio = nil
        User.currentUser!.gender = nil
        User.currentUser!.savedQuestions = [ : ]
        User.currentUser!.socialSources = [ : ]
        
        print("notification for no current user fired")
        
        setCurrentUserPaths()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "UserUpdated"), object: self)
    }
    
    ///Get user image
    static func getUserProfilePic() {
        let userPicPath = User.currentUser!.profilePic != nil ? User.currentUser!.profilePic : User.currentUser!.thumbPic
        
        if let userPicPath = userPicPath {
            if let userPicURL = URL(string: userPicPath) {
                let _userImageData = try? Data(contentsOf: userPicURL)
                User.currentUser?.thumbPicImage = UIImage(data: _userImageData!)
            }
        }
    }
    
    ///Populate current user
    static func populateCurrentUser(_ user: FIRUser!, completion: @escaping (_ success: Bool) -> Void) {
        User.currentUser!.uID = user.uid
        
        usersPublicSummaryRef.child(user.uid).observe(.value, with: { snap in
            if snap.hasChild(SettingTypes.name.rawValue) {
                User.currentUser!.name = snap.childSnapshot(forPath: SettingTypes.name.rawValue).value as? String
            }
            if snap.hasChild(SettingTypes.profilePic.rawValue) {
                User.currentUser!.profilePic = snap.childSnapshot(forPath: SettingTypes.profilePic.rawValue).value as? String
                getUserProfilePic()
            }
            if snap.hasChild(SettingTypes.shortBio.rawValue) {
                User.currentUser!.shortBio = snap.childSnapshot(forPath: SettingTypes.shortBio.rawValue).value as? String
            }
        })

        usersRef.child(user.uid).observe(.value, with: { snap in

            if snap.hasChild(SettingTypes.birthday.rawValue) {
                User.currentUser!.birthday = snap.childSnapshot(forPath: SettingTypes.birthday.rawValue).value as? String
            }
            if snap.hasChild(SettingTypes.bio.rawValue) {
                User.currentUser!.bio = snap.childSnapshot(forPath: SettingTypes.bio.rawValue).value as? String
            }
            if snap.hasChild(SettingTypes.gender.rawValue) {
                User.currentUser!.gender = snap.childSnapshot(forPath: SettingTypes.gender.rawValue).value as? String
            }
            if snap.hasChild("answeredQuestions") {
                User.currentUser!.answeredQuestions = nil
                for _answeredQuestion in snap.childSnapshot(forPath: "answeredQuestions").children {
                    if (User.currentUser!.answeredQuestions?.append((_answeredQuestion as AnyObject).key) == nil) {
                        User.currentUser!.answeredQuestions = [(_answeredQuestion as AnyObject).key]
                    }
                }
            }
            if snap.hasChild("answers") {
                User.currentUser!.answers = nil
                User.currentUser?._totalAnswers = Int(snap.childSnapshot(forPath: "answers").childrenCount)
                for _answer in snap.childSnapshot(forPath: "answers").children {
                    if (User.currentUser!.answers?.append((_answer as AnyObject).key) == nil) {
                        User.currentUser!.answers = [(_answer as AnyObject).key]
                    }
                }
            }
            
            if snap.hasChild("savedTags") {
                for _tag in snap.childSnapshot(forPath: "savedTags").children {
                    User.currentUser!.savedTags[(_tag as AnyObject).key] = (_tag as AnyObject).value
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
            
            setCurrentUserPaths()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "UserUpdated"), object: self)
            completion(true)
        })
    }
    
    ///Update user profile to Pulse database from settings
    static func updateUserProfile(_ setting : Setting, newValue : String, completion: @escaping (Bool, Error?) -> Void) {
        let _user = FIRAuth.auth()?.currentUser
        
        var userPost = [String : String]()
        if User.isLoggedIn() {
            switch setting.type! {
            case .email:
                _user?.updateEmail(newValue) { completionError in
                    completionError != nil ? completion(false, completionError) : completion(true, nil)
                }
            case .password:
                _user?.updatePassword(newValue) { completionError in
                    completionError != nil ? completion(false, completionError) : completion(true, nil)
                }
            case .shortBio, .name, .profilePic, .thumbPic:
                userPost[setting.settingID] = newValue
                usersPublicSummaryRef.child(_user!.uid).updateChildValues(userPost, withCompletionBlock: { (completionError, ref) in
                    completionError != nil ? completion(false, completionError) : completion(true, nil)
                })
            default:
                userPost[setting.settingID] = newValue
                usersRef.child(_user!.uid).updateChildValues(userPost, withCompletionBlock: { (completionError, ref) in
                    completionError != nil ? completion(false, completionError) : completion(true, nil)
                })
            }
        }
    }
    
    static func updateUserLocation(newValue : CLLocation, completion: @escaping (Bool, Error?) -> Void) {
        let _user = FIRAuth.auth()?.currentUser
        let geoFire = GeoFire(firebaseRef: databaseRef.child("userLocations"))
        
        if let _user = _user {
            geoFire?.setLocation(newValue, forKey: _user.uid) { (error) in
                if (error != nil) {
                    completion(false, error)
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    
    static func getUserLocation(completion: @escaping (CLLocation?, Error?) -> Void) {
        let _user = FIRAuth.auth()?.currentUser
        let geoFire = GeoFire(firebaseRef: databaseRef.child("userLocations"))

        if let _user = _user {
            geoFire?.getLocationForKey(_user.uid, withCallback: { (location, error) in
                if (error != nil) {
                    let userInfo = [ NSLocalizedDescriptionKey : "error getting location" ]
                    completion(nil, NSError.init(domain: "NoLocation", code: 404, userInfo: userInfo))
                } else if (location != nil) {
                    let location = CLLocation(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
                    User.currentUser?.location = location
                    completion(location, nil)
                } else {
                    let userInfo = [ NSLocalizedDescriptionKey : "no location found" ]
                    completion(nil, NSError.init(domain: "NoLocation", code: 404, userInfo: userInfo))
                }
            })
        }
    }
    
    static func getCityFromLocation(location: CLLocation, completion: @escaping (String?) -> Void) {
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error)-> Void in
            if (error != nil) {
                return
            }
            
            if let allPlacemarks = placemarks {
                if allPlacemarks.count != 0 {
                    let pm = allPlacemarks[0] as CLPlacemark
                    pm.locality != nil ? completion(pm.locality) : completion(nil)
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        })
    }
    
    
    ///Save user to Pulse database after Auth
    static func saveUserToDatabase(_ user: FIRUser, completion: @escaping (Bool, NSError?) -> Void) {
        var userPost = [String : String]()
        if let _uName = user.displayName {
            userPost["name"] = _uName
        }
        if let _uPic = user.photoURL {
            userPost["profilePic"] = String(describing: _uPic)
        }
        usersPublicSummaryRef.child(user.uid).updateChildValues(userPost, withCompletionBlock: { (blockError, ref) in
            blockError != nil ? completion(false, blockError as NSError?) : completion(true, nil)
        })
    }
    
    ///Save individual answer to Pulse database after Auth
    static func addUserAnswersToDatabase( _ answer : Answer, completion: @escaping (_ success : Bool, _ error : NSError?) -> Void) {
        let _user = FIRAuth.auth()?.currentUser
        
        var answersPost : [ String : AnyObject ] = ["qID": answer.qID as AnyObject, "uID": _user!.uid as AnyObject, "createdAt" : FIRServerValue.timestamp() as AnyObject]
        
        if answer.aLocation != nil {
            answersPost["location"] = answer.aLocation! as AnyObject
        }
        
        if answer.aType != nil {
            answersPost["type"] = answer.aType!.rawValue as AnyObject?
        }
        
        let post : [String: Any] = ["answers/\(answer.aID)" : answersPost] //NEED TO CHECK THIS

        if _user != nil {
            databaseRef.updateChildValues(post , withCompletionBlock: { (blockError, ref) in
                blockError != nil ? completion(false, blockError as NSError?) : completion(true, nil)
            })
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "please login" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: userInfo))
        }
    }
    
    ///Save collection into question / user
    static func addAnswerCollectionToDatabase(_ firstAnswer : Answer, post : [String : Bool], completion: @escaping (_ success : Bool, _ error : NSError?) -> Void) {
        let _user = FIRAuth.auth()?.currentUser
        
        let collectionPost : [AnyHashable: Any] = ["users/\(_user!.uid)/answers/\(firstAnswer.aID)": firstAnswer.qID, "users/\(_user!.uid)/answeredQuestions/\(firstAnswer.qID)" : "true","questions/\(firstAnswer.qID)/answers/\(firstAnswer.aID)" : true, "answerCollections/\(firstAnswer.aID)" : post]
        
        if _user != nil {
            databaseRef.updateChildValues(collectionPost , withCompletionBlock: { (blockError, ref) in
                blockError != nil ? completion(false, blockError as? NSError) : completion(true, nil)
            })
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "please login" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: userInfo))
        }
    }
    
    static func addAnswerVote(_ _vote : AnswerVoteType, aID : String, completion: @escaping (_ success : Bool, _ error : NSError?) -> Void) {
        answersRef.child(aID).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if var answer = currentData.value as? [String : AnyObject], let uid = FIRAuth.auth()?.currentUser?.uid {
                var votes : Dictionary<String, Bool>
                votes = answer["votes"] as? [String : Bool] ?? [:]
                var voteCount = answer["voteCount"] as? Int ?? 0
                if let _ = votes[uid] {
                    //already voted for answer
                }
                else {
                    if _vote == AnswerVoteType.downvote {
                        voteCount -= 1
                        votes[uid] = true
                    } else {
                        voteCount += 1
                        votes[uid] = true
                    }
                }
                answer["voteCount"] = voteCount as AnyObject?
                answer["votes"] = votes as AnyObject?
                
                currentData.value = answer
                return FIRTransactionResult.success(withValue: currentData)
            }
            return FIRTransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                completion(false, error as NSError?)
            } else if committed == true {
                completion(true, nil)
            }
        }
    }
    
    /* STORAGE METHODS */
    static func getAnswerURL(_ fileID : String, completion: @escaping (_ URL : URL?, _ error : NSError?) -> Void) {
        let path = answersStorageRef.child(fileID)
        
        let _ = path.downloadURL { (URL, error) -> Void in
            error != nil ? completion(nil, error! as NSError?) : completion(URL!, nil)
        }
    }
    
    static func getAnswerMeta(_ fileID : String, completion: @escaping (_ contentType : MediaAssetType?, _ error : NSError?) -> Void) {
        let path = answersStorageRef.child(fileID)
        
        path.metadata { (metadata, error) -> Void in
            if let _metadata = metadata?.contentType {
                error != nil ? completion(nil, error! as NSError?) : completion(MediaAssetType.getAssetType(_metadata), nil)
            }
        }
    }
    
    static func getTagImage(_ fileID : String, maxImgSize : Int64, completion: @escaping (_ data : Data?, _ error : NSError?) -> Void) {
        let _ = tagsStorageRef.child(fileID).data(withMaxSize: maxImgSize) { (data, error) -> Void in
            error != nil ? completion(nil, error! as NSError?) : completion(data, nil)
        }
    }
    
    static func getImage(_ type : Item, fileID : String, maxImgSize : Int64, completion: @escaping (_ data : Data?, _ error : NSError?) -> Void) {
        let path = getStoragePath(type, itemID: fileID)
        path.data(withMaxSize: maxImgSize) { (data, error) -> Void in
            error != nil ? completion(nil, error! as NSError?) : completion(data, nil)
        }
    }
    
    //Save a question for a user
    static func saveQuestion(_ questionID : String, completion: @escaping (Bool, Error?) -> Void) {
        if User.isLoggedIn() {
            if User.currentUser?.savedQuestions != nil && User.currentUser!.savedQuestions[questionID] != nil { //remove question
                let _path = getDatabasePath(Item.Users, itemID: User.currentUser!.uID!).child("savedQuestions/\(questionID)")
                _path.setValue("true", withCompletionBlock: { (completionError, ref) in
                    completionError != nil ? completion(false, completionError!) : completion(true, nil)
                })
            } else { //pin question
                let _path = getDatabasePath(Item.Users, itemID: User.currentUser!.uID!).child("savedQuestions")
                _path.updateChildValues([questionID: "true"], withCompletionBlock: { (completionError, ref) in
                    completionError != nil ? completion(false, completionError) : completion(true, nil)
                })
            }
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "please login to save questions" ]
            completion(false, NSError(domain: "NotLoggedIn", code: 200, userInfo: userInfo))
        }
    }
    
    static func pinTagForUser(_ tag : Tag, completion: @escaping (Bool, NSError?) -> Void) {
        if User.isLoggedIn() {
            if User.currentUser?.savedTags != nil && User.currentUser!.savedTags[tag.tagID!] != nil { //remove tag
                let _path = getDatabasePath(Item.Users, itemID: User.currentUser!.uID!).child("savedTags/\(tag.tagID!)")
                _path.setValue(nil, withCompletionBlock: { (completionError, ref) in
                    if completionError != nil {
                        completion(false, completionError as NSError?)
                    } else {
                        completion(true, nil)
                        User.currentUser?.savedTags[tag.tagID!] = nil
                    }
                })
            }
            else { //save tag
                let _path = getDatabasePath(Item.Users, itemID: User.currentUser!.uID!).child("savedTags")
                _path.updateChildValues([tag.tagID!: "true"], withCompletionBlock: { (completionError, ref) in
                    if completionError != nil {
                        completion(false, completionError as NSError?)
                    }
                    else {
                        User.currentUser?.savedTags[tag.tagID!] = "true"
                        completion(true, nil)
                    }
                })
            }
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "please login to save tags" ]
            completion(false, NSError(domain: "NotLoggedIn", code: 200, userInfo: userInfo))
        }
    }
    
    /* UPLOAD IMAGE TO STORAGE */
    static func uploadImage(_ type : Item, fileID : String, image : UIImage, completion: @escaping (_ success : Bool, _ error : NSError?) -> Void) {
        let path = getStoragePath(type, itemID: fileID)
        let _metadata = FIRStorageMetadata()
        _metadata.contentType = "image/jpeg"
        let imgData = image.mediumQualityJPEGNSData
        
        path.put(imgData as Data, metadata: _metadata) { (metadata, error) in
            if (error != nil) {
                completion(false, error as NSError?)
            } else {
                completion(true, nil)
            }
        }
    }
    
    ///upload image to firebase and update current user with photoURL upon success
    static func uploadProfileImage(_ imgData : Data, completion: @escaping (_ URL : URL?, _ error : NSError?) -> Void) {
        var _downloadURL : URL?
        let _metadata = FIRStorageMetadata()
        _metadata.contentType = "image/jpeg"
        
        if let _currentUserID = User.currentUser?.uID, let _imageToResize = UIImage(data: imgData), let _img = resizeImage(_imageToResize, newWidth: 600){
            usersStorageRef.child(_currentUserID).child("profilePic").put(_img, metadata: nil) { (metadata, error) in
                if let metadata = metadata {
                    _downloadURL = metadata.downloadURL()
                    updateUserData(.photoURL, value: String(describing: _downloadURL!)) { success, error in
                        success ? completion(_downloadURL, nil) : completion(nil, error)
                    }
                } else {
                    completion(nil, error as NSError?)
                }
            }
            
            if let _thumbImageData = resizeImage(UIImage(data: imgData)!, newWidth: 100) {
                usersStorageRef.child(_currentUserID).child("thumbPic").put(_thumbImageData, metadata: nil) { (metadata, error) in
                    if let url = metadata?.downloadURL() {
                        let userPost = ["thumbPic" : String(describing: url)]
                        usersPublicSummaryRef.child(_currentUserID).updateChildValues(userPost)
                    }
                }

            }
        }
    }
    
    static func resizeImage(_ image: UIImage, newWidth: CGFloat) -> Data? {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return UIImageJPEGRepresentation(newImage!, 0.7)
    }
}
