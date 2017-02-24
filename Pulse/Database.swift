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
    static let channelsRef = databaseRef.child(Element.Channels.rawValue)
    static let channelItemsRef = databaseRef.child(Element.ChannelItems.rawValue)
    static let itemsRef = databaseRef.child(Element.Items.rawValue)
    static let itemStatsRef = databaseRef.child(Element.ItemStats.rawValue)
    static let itemCollectionRef = databaseRef.child(Element.ItemCollection.rawValue)
    
    static let tagsRef = databaseRef.child(Element.Tags.rawValue)

    static let messagesRef = databaseRef.child(Element.Messages.rawValue)
    static let conversationsRef = databaseRef.child(Element.Conversations.rawValue)

    static var currentUserRef : FIRDatabaseReference!
    static var currentUserFeedRef : FIRDatabaseReference!

    static let usersRef = databaseRef.child(Element.Users.rawValue)
    static let usersPublicDetailedRef = databaseRef.child(Element.UserDetailedSummary.rawValue)
    static let usersPublicSummaryRef = databaseRef.child(Element.UserSummary.rawValue)

    static let filtersRef = databaseRef.child(Element.Filters.rawValue)
    static let settingsRef = databaseRef.child(Element.Settings.rawValue)
    static let settingSectionsRef = databaseRef.child(Element.SettingSections.rawValue)

    static let answersStorageRef = storageRef.child(Element.Answers.rawValue)
    static let tagsStorageRef = storageRef.child(Element.Tags.rawValue)
    static let usersStorageRef = storageRef.child(Element.Users.rawValue)

    static var masterQuestionIndex = [String : String]()
    static var masterTagIndex = [String : String]()

    static let querySize : UInt = 50
    static var activeListeners = [FIRDatabaseReference]()
    static var profileListenersAdded = false
    
    static func createShareLink(linkString : String, completion: @escaping (String?) -> Void) {
        var request = URLRequest(url: URL(string: "https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key=AIzaSyAJa2_jjaxFCWE0mLbRNfZ9lKZWK0mUyNU")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let longLink = "https://tc237.app.goo.gl/?link=http://checkpulse.co/" + linkString +
                        "&ibi=co.checkpulse.pulse&isi=1200702658"
        let json: [String: Any] = ["longDynamicLink": longLink, "suffix":["option":"SHORT"]]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        request.httpBody = jsonData
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion("https://checkpulse.co/"+linkString)
                return
            }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                completion(responseJSON["shortLink"] as! String?)
            }
        }

        task.resume()
    }
    
    static func removeItem(userID : String, itemID : String) {
        databaseRef.child("userDetailedPublicSummary/\(userID)/items/\(itemID)").observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                itemsRef.child(snap.value as! String).child("items").child(snap.key).setValue(nil, withCompletionBlock: { (error, snap) in
                    if error != nil {
                        //print("error removing answer \(error)")
                    }
                })
                usersPublicDetailedRef.child(userID).child("items").child(snap.key).setValue(nil)
                itemCollectionRef.child(snap.key).setValue(nil)
                
                let desertRef = storageRef.child("answers").child(snap.key)
                let thumbRef = storageRef.child("answerThumbnails").child(snap.key)

                // Delete the file
                thumbRef.delete { (error) -> Void in
                    if (error != nil) {
                        //print("error deleting thumbnail \(error)")
                        // Uh-oh, an error occurred!
                    } else {
                        //print("deleted thumbnail")
                    }
                }
                
                desertRef.delete { (error) -> Void in
                    if (error != nil) {
                        //print("error deleting video \(error)")
                        // Uh-oh, an error occurred!
                    } else {
                        //print("deleted video")
                    }
                }


            } else {
                //print("couldn't cast as answerSnap")
            }
        })
    }
    
    /** MARK : SEARCH **/
    static func buildQuery(searchTerm : String, type: FeedItemType) -> [String:Any] {
        var query = [String:Any]()
        
        switch type {
        case .tag:
            query["index"] = "tags"
            query["type"] = "tags"
        case .people:
            query["index"] = "firebase"
            query["type"] = "users"
            query["fields"] = ["name","shortBio","thumbPic"]
        case .question:
            query["index"] = "questions"
            query["type"] = "questions"
        default: break
        }
        
        let qTerm = ["_all":searchTerm]
        let qBody = ["match_phrase":qTerm]
        query["body"] = ["query":qBody]
        
        return query
    }
    
    static func searchTags(searchText : String, completion: @escaping (_ tagResult : [Tag]) -> Void) {
        
        let query = buildQuery(searchTerm: searchText, type: .tag)
        let searchKey = databaseRef.child("search/request").childByAutoId().key
        
        databaseRef.child("search/request").child(searchKey).updateChildValues(query)
        
        databaseRef.child("search/response").child(searchKey).observe( .value, with: { snap in
            var _results = [Tag]()
            
            if snap.exists() {
                if snap.childSnapshot(forPath: "hits").exists() {
                    for result in snap.childSnapshot(forPath: "hits/hits").children {

                        if let result = result as? FIRDataSnapshot, let tagID = result.childSnapshot(forPath: "_id").value as? String {
                            let tagTitle = result.childSnapshot(forPath: "_source/title").value as? String
                            let currentTag = Tag(tagID: tagID, tagTitle: tagTitle)
                            currentTag.tagDescription = result.childSnapshot(forPath: "_source/description").value as? String
                            _results.append(currentTag)
                        }
                    }
                    completion(_results)
                } else {
                    completion(_results)
                }
                snap.ref.removeAllObservers()
                snap.ref.removeValue()
            }
        })
    }
    
    static func searchQuestions(searchText : String, completion: @escaping (_ result : [Item]) -> Void) {
        let query = buildQuery(searchTerm: searchText, type: .question)
        let searchKey = databaseRef.child("search/request").childByAutoId().key
        
        databaseRef.child("search/request").child(searchKey).updateChildValues(query)
        
        databaseRef.child("search/response").child(searchKey).observe( .value, with: { snap in
            var _results = [Item]()
            
            if snap.exists() {
                if snap.childSnapshot(forPath: "hits").exists() {
                    for result in snap.childSnapshot(forPath: "hits/hits").children {
                        
                        if let result = result as? FIRDataSnapshot, let itemID = result.childSnapshot(forPath: "_id").value as? String {
                            let itemTitle = result.childSnapshot(forPath: "_source/title").value as? String
                            let currentItem = Item(itemID: itemID)
                            currentItem.itemTitle = itemTitle
                            _results.append(currentItem)
                        }
                    }
                    completion(_results)
                } else {
                    completion(_results)
                }
                snap.ref.removeAllObservers()
                snap.ref.removeValue()
            }
        })
    }
    
    static func searchUsers(searchText : String, completion: @escaping (_ peopleResult : [User]) -> Void) {
        let query = buildQuery(searchTerm: searchText, type: .people)
        let searchKey = databaseRef.child("search/request").childByAutoId().key
        
        databaseRef.child("search/request").child(searchKey).updateChildValues(query)
        
        databaseRef.child("search/response").child(searchKey).observe( .value, with: { snap in
            var _results = [User]()
            
            if snap.exists() {
                if snap.childSnapshot(forPath: "hits").exists() {
                    for result in snap.childSnapshot(forPath: "hits/hits").children {
                        if let result = result as? FIRDataSnapshot, let uID = result.childSnapshot(forPath: "_id").value as? String {
                            let uName = result.childSnapshot(forPath: "fields/name/0").value as? String
                            let uShortBio = result.childSnapshot(forPath: "fields/shortBio/0").value as? String
                            let uPic = result.childSnapshot(forPath: "fields/thumbPic/0").value as? String

                            let currentUser = User(uID: uID)
                            
                            currentUser.name = uName
                            currentUser.shortBio = uShortBio
                            currentUser.thumbPic = uPic
                            currentUser.uCreated = true
                            
                            _results.append(currentUser)
                        }
                    }
                    completion(_results)
                } else {
                    completion(_results)
                }
                snap.ref.removeAllObservers()
                snap.ref.removeValue()
            }
        })
    }
    
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
        
        activeListeners.append(conversationsRef.child(conversationID))
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
        }, withCancel: { error in
            completion(nil)
        })
    }
    
    //Retrieve all messages in conversation
    static func getConversationMessages(conversationID : String, completion: @escaping ([Message], String?, Error?) -> Void) {
        var messages = [Message]()
        
        conversationsRef.child(conversationID).queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { snapshot in
            for messageID in snapshot.children {
                messagesRef.child((messageID as AnyObject).key).observeSingleEvent(of: .value, with: { snap in
                    let message = Message(snapshot: snap)
                    messages.append(message)
                    
                    if messages.count == Int(snapshot.childrenCount) {
                        let lastMessageID = snap.key
                        completion(messages, lastMessageID, nil)
                    }
                })
            }
        }, withCancel: { error in
            completion(messages, nil, error)
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
    static func keepConversationUpdated(to : String?) {
        
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
        if let user = FIRAuth.auth()?.currentUser {
            currentUserRef = usersRef.child(user.uid)
            currentUserFeedRef = usersRef.child(user.uid).child(Element.Feed.rawValue)
        } else {
            currentUserRef = nil
            currentUserFeedRef = nil
        }
    }
    
    static func getDatabasePath(_ type : Element, itemID : String) -> FIRDatabaseReference {
        return databaseRef.child(type.rawValue).child(itemID)
    }
    
    static func getStoragePath(_ type : Element, itemID : String) -> FIRStorageReference {
        return storageRef.child(type.rawValue).child(itemID)
    }
    /*** MARK END : DATABASE PATHS ***/

    /*** MARK START : EXPLORE FEED ***/
    static func getExploreChannels(_ completion: @escaping (_ channels : [Channel], _ error : Error?) -> Void) {
        var allChannels = [Channel]()
        
        channelsRef.queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { snapshot in
            for channel in snapshot.children {
                let child = channel as! FIRDataSnapshot
                allChannels.append(Channel(cID: child.key, snapshot: child))
            }
            completion(allChannels, nil)
        }, withCancel: { error in
            completion(allChannels, error)
        })
    }
    
    static func getExploreTags(_ completion: @escaping (_ tags : [Tag], _ error : Error?) -> Void) {
        var allTags = [Tag]()
        
        tagsRef.queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { snapshot in
            for item in snapshot.children {
                let child = item as! FIRDataSnapshot
                allTags.append(Tag(tagID: child.key, snapshot: child))
            }
            completion(allTags, nil)
        }, withCancel: { error in
            completion(allTags, error)
        })
    }
    
    static func getExploreQuestions(_ completion: @escaping (_ questions : [Item], _ error : Error?) -> Void) {
        var allItems = [Item]()
        
        itemsRef.queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { snapshot in
            for item in snapshot.children {
                let child = item as! FIRDataSnapshot
                allItems.append(Item(itemID: child.key, snapshot: child))
            }
            completion(allItems, nil)
        }, withCancel: { error in
            completion(allItems, error)
        })
    }
    
    static func getExploreUsers(_ completion: @escaping (_ users : [User], _ error : Error?) -> Void) {
        var allUsers = [User]()
        
        usersPublicSummaryRef.queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { snapshot in
            for item in snapshot.children {
                let child = item as! FIRDataSnapshot
                allUsers.append(User(uID: child.key, snapshot: child))
            }
            completion(allUsers, nil)
        }, withCancel: { error in
            completion(allUsers, error)
        })
    }
    /*** MARK END : EXPLORE FEED ***/

    /*** MARK START : SETTINGS ***/
    static func getSections(_ completion: @escaping (_ sections : [SettingSection], _ error : Error?) -> Void) {
        var _sections = [SettingSection]()
        
        settingSectionsRef.observeSingleEvent(of: .value, with: { snapshot in

            for section in snapshot.children {
                let _section = section as! FIRDataSnapshot
                _sections.append(SettingSection(sectionID: _section.key, snapshot: _section))
            }
            completion(_sections, nil)
        }, withCancel: { error in
            completion(_sections, error)
        })
    }
    
    static func getSectionsSection(sectionName : String, completion: @escaping (_ section : SettingSection?, _ error : Error?) -> Void) {

        settingSectionsRef.child(sectionName).queryOrderedByValue().observeSingleEvent(of: .value, with: { snapshot in
            let section = SettingSection(sectionID: snapshot.key, snapshot: snapshot)
            completion(section, nil)
        }, withCancel: { error in
            completion(nil, error)
        })
    }
    
    static func getSetting(_ settingID : String, completion: @escaping (_ setting : Setting?, _ error : Error?) -> Void) {
        settingsRef.child(settingID).observeSingleEvent(of: .value, with: { snapshot in
            let _setting = Setting(snap: snapshot)
            completion(_setting, nil)
        }, withCancel: { error in
            completion(nil, error)
        })
    }
    /*** MARK END : SETTINGS ***/
 
    /*** MARK START : GET FEED ITEMS ***/
    static func getTag(_ tagID : String, completion: @escaping (_ tag : Tag, _ error : NSError?) -> Void) {
        tagsRef.child(tagID).observeSingleEvent(of: .value, with: { snap in
            let currentTag = Tag(tagID: tagID, snapshot: snap)
            completion(currentTag, nil)
        }, withCancel: { error in
            //print("error gettings tag \(error)")
        })
    }
    
    static func getChannel(cID : String, completion: @escaping (_ channel : Channel, _ error : NSError?) -> Void) {
        channelsRef.child(cID).observeSingleEvent(of: .value, with: { snap in
            let _currentChannel = Channel(cID: cID, snapshot: snap)
            completion(_currentChannel, nil)
        }, withCancel: { error in
            //print("error gettings tag \(error)")
        })
    }
    
    static func getChannelItems(channel : Channel, completion: @escaping (_ channel : Channel?) -> Void) {
        channelItemsRef.child(channel.cID).observeSingleEvent(of: .value, with: { snap in
            channel.updateChannel(detailedSnapshot: snap)
            completion(channel)
        }, withCancel: { error in
            completion(nil)
        })
    }
    
    static func getRelatedTags(_ tagID : String, completion: @escaping (_ tags : [Tag], _ error: Error?) -> Void) {
        var allTags = [Tag]()
        
        tagsRef.child(tagID).child("related").observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                for child in snap.children {
                    let _currentTag = Tag(tagID: (child as AnyObject).key)
                    allTags.append(_currentTag)
                }
                completion(allTags, nil)
            } else {
                completion(allTags, nil)
            }
        }, withCancel: { error in
            completion(allTags, error)
        })
    }
    
    static func getExpertsForTag(tagID : String, completion: @escaping (_ experts : [User], _ error: Error?) -> Void) {
        var allExperts = [User]()
        
        tagsRef.child(tagID).child("experts").observeSingleEvent(of: .value, with: { snap in
            for child in snap.children {
                let _currentUser = User(uID: (child as AnyObject).key)
                allExperts.append(_currentUser)
            }
            completion(allExperts, nil)
        }, withCancel: { error in
            completion(allExperts, error)
        })
    }
    
    static func getItem(_ itemID : String, completion: @escaping (_ item : Item?, _ error : NSError?) -> Void) {
        itemsRef.child(itemID).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                let _currentItem = Item(itemID: itemID, snapshot: snap)
                completion(_currentItem, nil)
            }
            else {
                let userInfo = [ NSLocalizedDescriptionKey : "no item found" ]
                completion(nil, NSError.init(domain: "No Item Found", code: 404, userInfo: userInfo))
            }
        })
    }
    
    static func getItemCollection(_ itemID : String, completion: @escaping (_ hasDetail : Bool, _ items : [String]) -> Void) {
        var items = [String]()
        
        itemCollectionRef.child(itemID).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                for child in snap.children {
                    items.append((child as AnyObject).key as String)
                }
                completion(true, items)
            } else {
                completion(false, items)
            }
        })
    }
    /*** MARK END : GET INDIVIDUAL ITEMS ***/

    /*** MARK START : GET USER ITEMS ***/
    
    ///Returns the shortest public profile
    static func getUser(_ uID : String, completion: @escaping (_ user : User?, _ error : NSError?) -> Void) {
        usersPublicSummaryRef.child(uID).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                let _returnUser = User(uID: uID, snapshot: snap)
                completion(_returnUser, nil)
            } else {
                let userInfo = [ NSLocalizedDescriptionKey : "no user found" ]
                completion(nil, NSError.init(domain: "NoUserFound", code: 404, userInfo: userInfo))
            }
        })
    }
    
    static func getUserPublicProperty(_ uID : String, property: String, completion: @escaping (_ property : String?) -> Void) {
        usersPublicDetailedRef.child("\(uID)/\(property)").observeSingleEvent(of: .value, with: { snap in
            if let _property = snap.value as? String {
                completion(_property)
            } else {
                completion(nil)
            }
        })
    }
    
    static func getUserPrivateProperty(_ uID : String, property: String, completion: @escaping (_ property : String?) -> Void) {
        usersRef.child("\(uID)/\(property)").observeSingleEvent(of: .value, with: { snap in
            if let _property = snap.value as? String {
                completion(_property)
            } else {
                completion(nil)
            }
        })
    }
    
    static func getDetailedUserProfile(user: User, completion: @escaping (_ user: User) -> Void) {
        usersPublicDetailedRef.child(user.uID!).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                user.updateUser(detailedSnapshot: snap)
                completion(user) 
            }
        })
    }
    static func getUserAnswerIDs(uID: String, completion: @escaping (_ answers : [Answer]) -> Void) {
        var allAnswers = [Answer]()
        usersPublicDetailedRef.child(uID).child("answers").queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { snap in
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
    
    ///Get all tags that user is a verified expert in
    static func getUserExpertTags(uID: String, completion: @escaping (_ tags : [Tag]) -> Void) {
        var allTags = [Tag]()
        
        usersPublicDetailedRef.child(uID).child("expertiseTags").queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                for child in snap.children {
                    let currentTag = Tag(tagID: (child as AnyObject).key)
                    allTags.append(currentTag)
                }
                completion(allTags)
            } else {
                completion(allTags)
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
        case .answer: break
        case .people: break
        }
    }
    
    //Create Feed for current user from followed tags
    static func createFeed(_ completedFeed: @escaping (_ feed : Tag) -> Void) {
        
        if User.currentUser!.savedTags.count == 0 && !initialFeedUpdateComplete {
            
            let homeFeed = Tag(tagID: "feed")         //create new blank 'tag' that will be used for all the questions
            keepUserTagsUpdated()
            completedFeed(homeFeed)
            initialFeedUpdateComplete = true

        } else if User.currentUser!.savedTags.count > 0 && !initialFeedUpdateComplete {
            //check for questions added to tags
            keepUserTagsUpdated()
        
            //monitor updates to existing questions
            updateAnswersForExistingFeedQuestions()
        
            //add in new posts before returning feed
            for (offset : index, (key : tag, value : _)) in User.currentUser!.savedTags.enumerated() {
                Database.addNewQuestionsFromTagToFeed(tag.tagID!, tagTitle: tag.tagTitle, completion: {(success) in
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
    }
    
    static func getFeed(_ completion: @escaping (_ feed : Tag) -> Void) {
        /**
        let homeFeed = Tag(tagID: "feed")         //create new blank 'tag' that will be used for all the questions
        let feedPath = currentUserFeedRef.queryOrdered(byChild: "lastAnswerID").queryLimited(toLast: querySize)
        homeFeed.questions = [Question]()
        
        feedPath.observeSingleEvent(of: .value, with: {(snap) in
            for question in snap.children {
                let currentTag = Tag(tagID: (question as AnyObject).childSnapshot(forPath: "tagID").value as! String,
                                     tagTitle: (question as AnyObject).childSnapshot(forPath: "tagTitle").value as? String)
                let _question = Question(qID: (question as AnyObject).key, qTag: currentTag)
                homeFeed.items.insert(_question, at: 0)
            }
            completion(homeFeed)
        })
         **/
    }
    
    static func updateAnswersForExistingFeedQuestions() {
        /**
        currentUserFeedRef.observeSingleEvent(of: .value, with: {(questionSnap) in
            for question in questionSnap.children {
                if let _answerID = questionSnap.childSnapshot(forPath: "\((question as AnyObject).key as String)/lastAnswerID").value as? String {
                    User.currentUser!.savedQuestions[(question as AnyObject).key] = _answerID
                    //  Database.keepQuestionsAnswersUpdated(question.key, lastAnswerID: _answerID)
                } else {
                    User.currentUser!.savedQuestions[(question as AnyObject).key] = "true"
                }
            }
            //updateFeedQuestions(nil, questions: User.currentUser!.savedQuestions, completion: { _ in })
        })
         **/
    }
    
    static func removeQuestionsFromTagInFeed(_ tagID : String, completion: @escaping (_ success: Bool) -> Void) {
        let tagQuestions : FIRDatabaseQuery = tagsRef.child(tagID).child("questions")
        
        tagQuestions.observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                for question in snap.children {
                    currentUserRef.child("savedQuestions").child((question as! FIRDataSnapshot).key).setValue(nil)
                }
                completion(true)
            }
        })
    }
    
    static func addNewQuestionsFromTagToFeed(_ tagID : String, tagTitle: String?, completion: @escaping (_ success: Bool) -> Void) {
        var tagQuestions : FIRDatabaseQuery = tagsRef.child(tagID).child("questions")
        
        currentUserRef.child("savedTags").child(tagID).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() && (snap.childSnapshot(forPath: "lastQuestionID").value! as AnyObject).isKind(of: NSString.self) {
                //first get the last sync'd question for a tag
                let lastQuestionID = snap.childSnapshot(forPath: "lastQuestionID").value as! String
                    
                if lastQuestionID != "true" {
                    tagQuestions = tagQuestions.queryOrderedByKey().queryStarting(atValue: lastQuestionID)
                }
                
                var newQuestions = [String : String?]()
                
                tagQuestions.observeSingleEvent(of: .value, with: { questionSnap in
                    for (questionIndex, questionID) in questionSnap.children.enumerated() {
                        
                        let lastQuestionKey = (questionID as! FIRDataSnapshot).key
                        
                        if lastQuestionKey != lastQuestionID {
                            newQuestions[(questionID as AnyObject).key] = "true"
                        }
                        
                        if questionIndex + 1 == Int(questionSnap.childrenCount) && lastQuestionKey != lastQuestionID { //at the last question in tag query
                            currentUserRef.child("savedTags/\(tagID)").updateChildValues(["lastQuestionID" : (questionID as! FIRDataSnapshot).key]) // update last sync'd question ID
                            keepTagQuestionsUpdated(tagID, tagTitle: tagTitle, lastQuestionID: (questionID as AnyObject).key) // add listener for new questions added to tag
                        } else if questionIndex + 1 == Int(questionSnap.childrenCount) && lastQuestionKey == lastQuestionID {
                            keepTagQuestionsUpdated(tagID, tagTitle: tagTitle, lastQuestionID: (questionID as AnyObject).key) // add listener for new questions added to tag
                        }
                    }
                    
                    // adds the questions to the feed once we have iterated through all the questions
                    updateFeedQuestions(tagID, tagTitle: tagTitle, questions: newQuestions, completion: { added in
                        completion(true)
                    })
                })
            }
        })
    }
    
    static func updateFeedQuestions(_ tagID : String?, tagTitle: String?, questions : [String : String?], completion: @escaping (_ added: Bool) -> Void) {
        //add new questions to feed
        let _updatePath = currentUserRef.child(Element.Feed.rawValue)
        var post = [String : AnyObject]()
        
        if let _tagID = tagID {
            post["tagID"] = _tagID as AnyObject?
        }
        
        if let _tagTitle = tagTitle {
            post["tagTitle"] = _tagTitle as AnyObject?
        }

        if questions.count == 0 {
            completion(true)
        } else {
            for (offset : index, (key : questionID, value : lastAnswerID)) in questions.enumerated() {
                var newAnswersForQuestion : FIRDatabaseQuery = itemsRef.child(questionID).child("answers")

                if lastAnswerID != "true" {
                    newAnswersForQuestion = newAnswersForQuestion.queryOrderedByKey().queryStarting(atValue: lastAnswerID)
                }
                
                //snap is a specific question's answers
                newAnswersForQuestion.observeSingleEvent(of: .value, with: { snap in
                    let totalNewAnswers = snap.childrenCount
                    for (answerIndex, answerID) in snap.children.enumerated() {
                        if answerIndex + 1 == Int(totalNewAnswers) && (answerID as AnyObject).key != lastAnswerID {
                            
                            //if last answer then update value for last sync'd answer in database and add listener
                            post["lastAnswerID"] = (answerID as AnyObject).key
                            post["newAnswerCount"] = totalNewAnswers as AnyObject?
                            
                            _updatePath.updateChildValues([questionID : post], withCompletionBlock: { (error, ref) in
                                
                                if index + 1 == questions.count {
                                    completion(true)
                                }
                            })
    //                        keepQuestionsAnswersUpdated(questionID, lastAnswerID: answerID.key)
                        } else if answerIndex + 1 == Int(totalNewAnswers) && (answerID as AnyObject).key == lastAnswerID {
                            if index + 1 == questions.count {
                                completion(true)
                            }
                        }
                        else if totalNewAnswers == 0 {
                            post["lastAnswerID"] = (answerID as AnyObject).key
                            post["newAnswerCount"] = totalNewAnswers as AnyObject?

                            _updatePath.updateChildValues([questionID : post], withCompletionBlock: { (error, ref) in
                                if index + 1 == questions.count {
                                    completion(true)
                                }
                            })
                        }
                    }
                    
                })
            }
        }
    }
    
    static func keepUserTagsUpdated() {
        if User.isLoggedIn() {
            
            let userTagsPath : FIRDatabaseQuery = getDatabasePath(Element.Users, itemID: User.currentUser!.uID!).child("savedTags")
            activeListeners.append(getDatabasePath(Element.Users, itemID: User.currentUser!.uID!).child("savedTags"))
            
            userTagsPath.observe(.childAdded, with: { tagSnap in
                if initialFeedUpdateComplete {
                    addNewQuestionsFromTagToFeed(tagSnap.key, tagTitle: tagSnap.childSnapshot(forPath: "title").value as? String, completion: { success in
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "FeedUpdated"), object: self)
                    })
                } else {
                    //print("ignoring child added)")
                }
            })
            
            userTagsPath.observe(.childRemoved, with: { tagSnap in
                if initialFeedUpdateComplete {
                    removeQuestionsFromTagInFeed(tagSnap.key, completion: { success in
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "FeedUpdated"), object: self)
                    })
                } else {
                    //print("ignoring child removed)")
                }
            })
        }
    }
    
    static func keepTagQuestionsUpdated(_ tagID : String, tagTitle: String?, lastQuestionID : String) {
        let tagsRef = getDatabasePath(Element.Tags, itemID: tagID).child("questions").queryOrderedByKey().queryStarting(atValue: lastQuestionID)
        activeListeners.append(getDatabasePath(Element.Tags, itemID: tagID).child("questions"))
        
        tagsRef.observe(.childAdded, with: { (snap) in
            if snap.key != lastQuestionID {
                currentUserRef.child("savedTags/\(tagID)").updateChildValues(["lastQuestionID" : snap.key]) //update last sync'd question for user
                updateFeedQuestions(tagID, tagTitle: tagTitle, questions: [snap.key : "true"], completion: { _ in })
                    //add question to feed
            }
        })
    }
    
    static func cleanupListeners() {
        for listener in activeListeners {
            listener.removeAllObservers()
        }
    }
    
    /** REMOVED THIS LISTENER TO MINIMIZE NUMBER OF CONNECTIONS - ONLY REFRESHING ANSWERS ON RELOAD **/
    static func keepQuestionsAnswersUpdated(_ questionID : String, lastAnswerID : String) {
        let _updatePath = currentUserRef.child("savedQuestions").child(questionID).child("lastAnswerID")
        let _observePath = getDatabasePath(Element.Questions, itemID: questionID).child("answers").queryOrderedByKey().queryStarting(atValue: lastAnswerID)
        
        activeListeners.append(getDatabasePath(Element.Questions, itemID: questionID).child("answers"))
        _observePath.observe(.childAdded, with: { snap in
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
                cleanupListeners()
                removeCurrentUser()
                initialFeedUpdateComplete = false
                NotificationCenter.default.post(name: Notification.Name(rawValue: "LogoutSuccess"), object: self)
                completion(true)
            } catch {
                completion(false)
            }
        }
    }
    
    static func checkSocialTokens(_ completion: @escaping (_ result: Bool) -> Void) {
        if FBSDKAccessToken.current() != nil {
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
            let credential = FIRTwitterAuthProvider.credential(withToken: session.authToken, secret: session.authTokenSecret)
            FIRAuth.auth()?.signIn(with: credential) { (aUser, error) in
                if error != nil {
                    completion(false)
                } else {
                    completion(true)
                }
            }
        } else {
            completion(false)
        }
    }
    
    ///Check if user is logged in
    static func checkCurrentUser(_ completion: @escaping (Bool) -> Void) {
        Database.checkSocialTokens({(result) in
            //result ? completion(true) : completion(false) //user not populated yet - so shouldn't fire completion block - wait till auth listener fires
        })

        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if let _user = user {
                setCurrentUserPaths()
                
                populateCurrentUser(_user, completion: { (success) in
                    if success {
                        completion(true)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "FeedUpdateLogin"), object: self)
                    }
                })
            } else {
                removeCurrentUser()
                completion(false)
            }
        }
    }
    
    ///Remove current user
    static func removeCurrentUser() {
        guard let currentUser = User.currentUser else { return }
        
        currentUser.uID = nil
        currentUser.name = nil
        currentUser.items = []
        currentUser.savedItems = [ : ]

        currentUser.answeredQuestions = []
        currentUser.expertiseTags = []
        currentUser.savedTags = [ : ]
        currentUser.savedTagIDs = []
        currentUser.profilePic = nil
        currentUser.thumbPic = nil
        currentUser._totalItems = nil
        currentUser.birthday = nil
        currentUser.bio = nil
        currentUser.shortBio = nil
        currentUser.gender = nil
        currentUser.socialSources = [ : ]
        
        setCurrentUserPaths()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "UserUpdated"), object: self)
    }
    
    ///Get user image
    static func getUserProfilePic() {
        let userPicPath = User.currentUser!.profilePic != nil ? User.currentUser!.profilePic : User.currentUser!.thumbPic
        
        if let userPicPath = userPicPath {
            if let userPicURL = URL(string: userPicPath), let _userImageData = try? Data(contentsOf: userPicURL) {
                User.currentUser?.thumbPicImage = UIImage(data: _userImageData)
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
        }, withCancel: { error in
            //print("error getting user public summary \(error)")
        })
        
        usersPublicDetailedRef.child(user.uid).observeSingleEvent(of: .value, with: { snap in
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
                User.currentUser!.answeredQuestions.removeAll()
                for _answeredQuestion in snap.childSnapshot(forPath: "answeredQuestions").children {
                    User.currentUser!.answeredQuestions.append((_answeredQuestion as AnyObject).key)
                }
            }
            if snap.hasChild("items") {
                User.currentUser!.items = []
                User.currentUser?._totalItems = Int(snap.childSnapshot(forPath: "items").childrenCount)
                for item in snap.childSnapshot(forPath: "items").children {
                    if let item = item as? FIRDataSnapshot {
                        let currentItem = Item(itemID: item.key, snapshot: item)
                        User.currentUser!.items.append(currentItem)
                    }
                }
            }
            
            if snap.hasChild("expertiseTags") {
                User.currentUser!.expertiseTags = []
                for expertise in snap.childSnapshot(forPath: "expertiseTags").children {
                    let expertiseTag = Tag(tagID: (expertise as AnyObject).key, tagTitle: (expertise as AnyObject).value)
                    User.currentUser!.expertiseTags.append(expertiseTag)
                }
            }
            
            setCurrentUserPaths()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "UserUpdated"), object: self)
            addUserProfileListener(uID: user.uid)
            
        }, withCancel: { error in
            print("error getting user public detailed summary \(error)")
        })

        usersRef.child(user.uid).observeSingleEvent(of: .value, with: { snap in
            if snap.hasChild("savedTags") {
                for _tag in snap.childSnapshot(forPath: "savedTags").children {
                    let tagTitle = (_tag as! FIRDataSnapshot).childSnapshot(forPath: "title").value as? String
                    let lastAnswer = (_tag as! FIRDataSnapshot).childSnapshot(forPath: "lastAnswerID").value as? String

                    let savedTag = Tag(tagID: (_tag as AnyObject).key,
                                        tagTitle: tagTitle)
                    User.currentUser!.savedTags[savedTag] = lastAnswer
                    User.currentUser!.savedTagIDs.append((_tag as AnyObject).key as String)
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
            
            completion(true)
            
        }, withCancel: { error in
            print("error getting user public summary \(error)")
        })
    }
    
    static func addUserProfileListener(uID : String) {
        if !profileListenersAdded {
            usersPublicDetailedRef.child(uID).child("gender").observe(.value, with: { snap in
                User.currentUser!.gender = snap.value as? String
            })
            activeListeners.append(usersPublicDetailedRef.child(uID).child("gender"))
            
            usersPublicDetailedRef.child(uID).child("birthday").observe(.value, with: { snap in
                User.currentUser!.birthday = snap.value as? String
            })
            activeListeners.append(usersPublicDetailedRef.child(uID).child("birthday"))

            usersPublicDetailedRef.child(uID).child("bio").observe(.value, with: { snap in
                User.currentUser!.bio = snap.value as? String
            })
            activeListeners.append(usersPublicDetailedRef.child(uID).child("bio"))

            usersPublicDetailedRef.child(uID).child("answeredQuestions").observe(.childAdded, with: { snap in
                if !User.currentUser!.answeredQuestions.contains(snap.key) {
                    User.currentUser!.answeredQuestions.append(snap.key)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "UserUpdated"), object: self)
                }
            })
            activeListeners.append(usersPublicDetailedRef.child(uID).child("answeredQuestions"))

            usersPublicDetailedRef.child(uID).child("items").observe(.childAdded, with: { snap in
                let currentItem = Item(itemID: snap.key, snapshot: snap)

                if !User.currentUser!.items.contains(currentItem) {
                    User.currentUser!.items.append(currentItem)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "UserUpdated"), object: self)
                }
            })
            activeListeners.append(usersPublicDetailedRef.child(uID).child("answers"))
            profileListenersAdded = true
        }
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
            case .birthday, .gender, .location, .bio:
                userPost[setting.settingID] = newValue
                usersPublicDetailedRef.child(_user!.uid).updateChildValues(userPost, withCompletionBlock: { (completionError, ref) in
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
    static func addItemToDatabase( _ item : Item, channelID: String, completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
        
        if let _user = FIRAuth.auth()?.currentUser {
            var itemPost : [ String : AnyObject] = ["title": item.itemTitle as AnyObject,
                                                   "uID": _user.uid as AnyObject,
                                                   "createdAt" : FIRServerValue.timestamp() as AnyObject,
                                                   "type" : item.type.rawValue as AnyObject]
            
            if let url = item.contentURL?.absoluteString {
                itemPost["contentURL"] = url as AnyObject?
            }
            
            if let contentType = item.contentType {
                itemPost["contentType"] = contentType.rawValue as AnyObject?
            }
            
            if let parentID = item.parentItemID {
                itemPost["parentID"] = parentID as AnyObject?
            }
            
            let post : [String: Any] = ["items/\(item.itemID)": itemPost]

            databaseRef.updateChildValues(post , withCompletionBlock: { (blockError, ref) in
                print("updated child values and error is \(blockError?.localizedDescription)")
                blockError != nil ? completion(false, blockError as Error?) : completion(true, nil)
            })
            
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "please login" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: userInfo))
        }
    }
    
    ///Save collection into question / user
    static func addItemCollectionToDatabase(_ item : Item, channelID : String, post : [String : Bool], completion: @escaping (_ success : Bool, _ error : NSError?) -> Void) {
        guard item.type != nil else { return }
        
        let _user = FIRAuth.auth()?.currentUser
        var collectionPost : [AnyHashable: Any]!
        
        var channelPost : [String : AnyObject] = ["type" : item.type.rawValue as AnyObject]
        channelPost["tagID"] = item.tag?.tagID as AnyObject
        channelPost["tagTitle"] = item.tag?.tagTitle as AnyObject
        
        switch item.type! {
        case .answer:
            collectionPost = ["userDetailedPublicSummary/\(_user!.uid)/items/\(item.itemID)": item.parentItemID!,
                              "itemCollection/\(item.itemID)" : post,
                              "channelItems/\(channelID)/\(item.itemID)":channelPost]
        case .post:
            collectionPost = ["userDetailedPublicSummary/\(_user!.uid)/items/\(item.itemID)": item.parentItemID!,
                              "itemCollection/\(item.itemID)" : post,
                              "channelItems/\(channelID)":channelPost]
        default:
            collectionPost = ["userDetailedPublicSummary/\(_user!.uid)/items/\(item.itemID)": true,
                              "itemCollection/\(item.itemID)" : post,
                              "channelItems/\(channelID)":channelPost]
        }

        if _user != nil {
            databaseRef.updateChildValues(collectionPost , withCompletionBlock: { (blockError, ref) in
                blockError != nil ? completion(false, blockError as? NSError) : completion(true, nil)
            })
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "please login" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: userInfo))
        }
    }
    
    static func updateItemViewCount(itemID : String) {
        itemStatsRef.child(itemID).child("views").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let currentViews = currentData.value as? Float {
                currentData.value = currentViews + 1
                return FIRTransactionResult.success(withValue: currentData)
            }
            return FIRTransactionResult.success(withValue: currentData)
        })
    }
    
    static func addVote(_ _vote : VoteType, itemID : String, completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
        var upVoteCount = 0
        var downVoteCount = 0
        
        if User.currentUser?.savedVotes[itemID] != true {
            itemStatsRef.child(itemID).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if var item = currentData.value as? [String : AnyObject] {
                    upVoteCount = item["upVoteCount"] as? Int ?? 0
                    downVoteCount = item["downVoteCount"] as? Int ?? 0

                    if _vote == .downvote {
                        downVoteCount -= 1
                    } else {
                        upVoteCount += 1
                    }
                    item["upVoteCount"] = upVoteCount as AnyObject?
                    item["downVoteCount"] = downVoteCount as AnyObject?
                    
                    currentData.value = item
                    return FIRTransactionResult.success(withValue: currentData)
                }
                return FIRTransactionResult.success(withValue: currentData)
            }) { (error, committed, snapshot) in
                if let error = error {
                    completion(false, error as Error?)
                } else if committed == true {
                    let post = [itemID:true]
                    currentUserRef.child("votes").updateChildValues(post , withCompletionBlock: { (error, ref) in
                        User.currentUser?.savedVotes[itemID] = true
                    })
                    completion(true, nil)
                }
            }
        }
    }
    
    /** ASK QUESTIONS **/
    static func askTagQuestion(tag : Tag, qText: String, completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
        guard let user = FIRAuth.auth()?.currentUser else {
            let errorInfo = [ NSLocalizedDescriptionKey : "you must be logged in to ask a question" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: errorInfo))
            return
        }
        
        guard let tagID = tag.tagID else {
            let errorInfo = [ NSLocalizedDescriptionKey : "you can only post a question in an active tag" ]
            completion(false, NSError.init(domain: "Invalidtag", code: 404, userInfo: errorInfo))
            return
        }
        
        let itemKey = itemsRef.childByAutoId().key
        
        let itemPost = ["title": qText,
                        "type":"question",
                        "uID": user.uid]
        
        let post = ["items/\(itemKey)":itemPost,
                    "tags/\(tagID)/items/\(itemKey)":true,
                    "users/\(user.uid)/askedQuestions/\(itemKey)":true] as [String: Any]
        
        databaseRef.updateChildValues(post, withCompletionBlock: { (completionError, ref) in
            if completionError != nil {
                let errorInfo = [ NSLocalizedDescriptionKey : "error posting question, please try again!" ]
                completion(false, NSError.init(domain: "Error", code: 404, userInfo: errorInfo))
            } else {
                completion(true, nil)
            }
        })
    }
    
    static func askUserQuestion(askUserID : String, qText: String, completion: @escaping (_ success : Bool, _ error : NSError?) -> Void) {
        guard let user = FIRAuth.auth()?.currentUser else {
            let errorInfo = [ NSLocalizedDescriptionKey : "you must be logged in to ask a question" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: errorInfo))
            return
        }

        let itemKey = itemsRef.childByAutoId().key
        
        let itemPost = ["title": qText,
                    "type":"question",
                    "uID": user.uid]

        let post = ["items/\(itemKey)": itemPost,
                    "users/\(user.uid)/askedQuestions/\(itemKey)":true,
                    "users/\(askUserID)/unansweredQuestions/\(itemKey)":true] as [String: Any]
        
        databaseRef.updateChildValues(post, withCompletionBlock: { (completionError, ref) in
            if completionError != nil {
                let errorInfo = [ NSLocalizedDescriptionKey : "error posting question, please try again!" ]
                completion(false, NSError.init(domain: "Error", code: 404, userInfo: errorInfo))
            } else {
                completion(true, nil)
            }
        })
    }
    
    /* RECOMMEND EXPERT */
    static func recommendExpert(tag: Tag, applyName: String, applyEmail: String, applyText: String,
                                completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
    
        guard let user = FIRAuth.auth()?.currentUser else {
            let errorInfo = [ NSLocalizedDescriptionKey : "you must be logged in to recommend experts" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: errorInfo))
            return
        }
        
        guard let tagID = tag.tagID else {
            let errorInfo = [ NSLocalizedDescriptionKey : "please choose a channel first" ]
            completion(false, NSError.init(domain: "Invalidtag", code: 404, userInfo: errorInfo))
            return
        }
        
        let post = ["email":applyEmail,
                    "tagID":tagID,
                    "name":applyName,
                    "reason":applyText,
                    "recommenderID": user.uid]
    
        databaseRef.child("expertRequests").childByAutoId().updateChildValues(post, withCompletionBlock: { (completionError, ref) in
            if completionError != nil {
                let errorInfo = [ NSLocalizedDescriptionKey : "error sending, please try again!" ]
                completion(false, NSError.init(domain: "Error", code: 404, userInfo: errorInfo))
            } else {
                completion(true, nil)
            }
        })
    }
    
    /* BECOME EXPERT */
    static func becomeExpert(tag : Tag, applyText: String, completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
        guard let user = FIRAuth.auth()?.currentUser else {
            let errorInfo = [ NSLocalizedDescriptionKey : "you must be logged in to apply" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: errorInfo))
            return
        }
        
        guard let tagID = tag.tagID else {
            let errorInfo = [ NSLocalizedDescriptionKey : "please select a channel first" ]
            completion(false, NSError.init(domain: "Invalidtag", code: 404, userInfo: errorInfo))
            return
        }
        
        let verificationPath = databaseRef.child("expertRequests")
        let post = ["uID":user.uid,
                    "reason":applyText,
                    "tagID":tagID]
        
        currentUserRef.child("appliedTags").child(tagID).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                let errorInfo = [ NSLocalizedDescriptionKey : "you have already applied! we will get back to you soon." ]
                completion(false, NSError.init(domain: "AlreadyApplied", code: 404, userInfo: errorInfo))
            } else {
                verificationPath.childByAutoId().updateChildValues(post, withCompletionBlock: { (completionError, ref) in
                    if completionError != nil {
                        let errorInfo = [ NSLocalizedDescriptionKey : "error applying, please try again!" ]
                        completion(false, NSError.init(domain: "Error", code: 404, userInfo: errorInfo))
                    } else {
                        currentUserRef.child("appliedTags").child(tagID).setValue(true)
                        completion(true, nil)
                    }
                })
            }
        })
    }

    
    /* STORAGE METHODS */
    static func getAnswerURL(qID: String, fileID : String, completion: @escaping (_ URL : URL?, _ error : NSError?) -> Void) {
        let path = answersStorageRef.child(qID).child(fileID)
        
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
    
    static func getTagImage(_ tagID : String, maxImgSize : Int64, completion: @escaping (_ data : Data?, _ error : NSError?) -> Void) {
        let _ = tagsStorageRef.child("tags/\(tagID)").child(tagID).data(withMaxSize: maxImgSize) { (data, error) -> Void in
            error != nil ? completion(nil, error! as NSError?) : completion(data, nil)
        }
    }
    
    static func getImage(_ type : Element, fileID : String, maxImgSize : Int64, completion: @escaping (_ data : Data?, _ error : NSError?) -> Void) {
        let path = getStoragePath(type, itemID: fileID)
        path.data(withMaxSize: maxImgSize) { (data, error) -> Void in
            error != nil ? completion(nil, error! as NSError?) : completion(data, nil)
        }
    }
    
    static func getProfilePicForUser(user: User, completion: @escaping (_ image : UIImage?) -> Void) {
        let userPicPath = user.profilePic != nil ? user.thumbPic : user.profilePic
        
        if let userPicPath = userPicPath {
            if let userPicURL = URL(string: userPicPath), let _userImageData = try? Data(contentsOf: userPicURL) {
                completion(UIImage(data: _userImageData))
            } else {
                completion(nil)
            }
        }
    }
    
    static func getAnswerImage(qID : String, fileID : String, maxImgSize : Int64, completion: @escaping (_ data : Data?, _ error : NSError?) -> Void) {
        let path = storageRef.child("answers").child(qID).child(fileID)
        
        path.data(withMaxSize: maxImgSize) { (data, error) -> Void in
            error != nil ? completion(nil, error! as NSError?) : completion(data, nil)
        }
    }
    
    //Save a question for a user
    static func saveItem(_ itemID : String, completion: @escaping (Bool, Error?) -> Void) {
        if User.isLoggedIn() {
            if User.currentUser?.savedItems != nil && User.currentUser!.savedItems[itemID] != nil { //remove item
                let _path = getDatabasePath(Element.Users, itemID: User.currentUser!.uID!).child("savedItems/\(itemID)")
                _path.setValue("true", withCompletionBlock: { (completionError, ref) in
                    completionError != nil ? completion(false, completionError!) : completion(true, nil)
                })
            } else { //pin item
                let _path = getDatabasePath(Element.Users, itemID: User.currentUser!.uID!).child("savedItems")
                _path.updateChildValues([itemID: "true"], withCompletionBlock: { (completionError, ref) in
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
            if User.currentUser?.savedTags != nil && User.currentUser!.savedTagIDs.contains(tag.tagID!) { //remove tag
                let _path = getDatabasePath(Element.Users, itemID: User.currentUser!.uID!).child("savedTags/\(tag.tagID!)")
                _path.setValue(nil, withCompletionBlock: { (completionError, ref) in
                    if completionError != nil {
                        completion(false, completionError as NSError?)
                    } else {
                        completion(true, nil)
                        User.currentUser?.savedTags[tag] = nil
                        _path.removeAllObservers()
                    }
                })
            }
            else { //save tag
                let _path = getDatabasePath(Element.Users, itemID: User.currentUser!.uID!).child("savedTags")
                
                let post = ["lastQuestionID" : "true", "title" : tag.tagTitle ?? ""] as [String: Any]
                
                _path.updateChildValues([tag.tagID!: post], withCompletionBlock: { (completionError, ref) in
                    if completionError != nil {
                        completion(false, completionError as NSError?)
                    }
                    else {
                        User.currentUser?.savedTags[tag] = "true"
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
    static func uploadImage(_ type : Element, fileID : String, image : UIImage, completion: @escaping (_ success : Bool, _ error : NSError?) -> Void) {
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
