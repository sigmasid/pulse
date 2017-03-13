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
var currentAuthState : AuthStates = .loggedOut

class Database {
    static let channelsRef = databaseRef.child(Element.Channels.rawValue)
    static let channelItemsRef = databaseRef.child(Element.ChannelItems.rawValue)
    
    static let itemsRef = databaseRef.child(Element.Items.rawValue)
    static let itemStatsRef = databaseRef.child(Element.ItemStats.rawValue)
    static let itemCollectionRef = databaseRef.child(Element.ItemCollection.rawValue)
    
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

    static let usersStorageRef = storageRef.child(Element.Users.rawValue)

    static var masterQuestionIndex = [String : String]()
    static var masterTagIndex = [String : String]()

    static let querySize : UInt = 5
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
                itemsRef.child(itemID).setValue(nil, withCompletionBlock: { (error, snap) in
                    if error != nil {
                        //print("error removing item \(error)")
                    }
                })
                
                usersPublicDetailedRef.child(userID).child("items").child(snap.key).setValue(nil)
                
                itemCollectionRef.child(itemID).setValue(nil)
                
                if let cID = snap.childSnapshot(forPath: "cID").value as? String {
                    channelItemsRef.child(cID).child(itemID).setValue(nil)
                    
                    let itemStorageRef = storageRef.child("channels").child(cID).child(itemID)
                    
                    // Delete the file
                    itemStorageRef.delete { (error) -> Void in
                        if (error != nil) {
                            //print("error deleting thumbnail \(error)")
                            // Uh-oh, an error occurred!
                        } else {
                            //print("deleted thumbnail")
                        }
                    }
                }

            } else {
                print("nothing to delete")
            }
        })
    }
    
    /** MARK : SEARCH **/
    static func buildQuery(searchTerm : String, type: ItemTypes) -> [String:Any] {
        var query = [String:Any]()
        
        switch type {
        case .post:
            query["index"] = "post"
            query["type"] = "post"
        case .user:
            query["index"] = "firebase"
            query["type"] = "users"
            query["fields"] = ["name","shortBio","thumbPic"]
        case .question:
            query["index"] = "questions"
            query["type"] = "questions"
        case .answer:
            query["index"] = "answer"
            query["type"] = "answer"
        default: break
        }
        
        let qTerm = ["_all":searchTerm]
        let qBody = ["match_phrase":qTerm]
        query["body"] = ["query":qBody]
        
        return query
    }
    
    static func searchItem(searchText : String, completion: @escaping (_ results : [Item]) -> Void) {
        
        let query = buildQuery(searchTerm: searchText, type: .post)
        let searchKey = databaseRef.child("search/request").childByAutoId().key
        
        databaseRef.child("search/request").child(searchKey).updateChildValues(query)
        
        databaseRef.child("search/response").child(searchKey).observe( .value, with: { snap in
            var _results = [Item]()
            
            if snap.exists() {
                if snap.childSnapshot(forPath: "hits").exists() {
                    for result in snap.childSnapshot(forPath: "hits/hits").children {

                        if let result = result as? FIRDataSnapshot, let itemID = result.childSnapshot(forPath: "_id").value as? String {
                            let currentItem = Item(itemID: itemID)
                            currentItem.itemTitle = result.childSnapshot(forPath: "_source/title").value as? String
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
    
    static func searchChannels(searchText : String, completion: @escaping (_ result : [Channel]) -> Void) {
        let query = buildQuery(searchTerm: searchText, type: .question)
        let searchKey = databaseRef.child("search/request").childByAutoId().key
        
        databaseRef.child("search/request").child(searchKey).updateChildValues(query)
        
        databaseRef.child("search/response").child(searchKey).observe( .value, with: { snap in
            var _results = [Channel]()
            
            if snap.exists() {
                if snap.childSnapshot(forPath: "hits").exists() {
                    for result in snap.childSnapshot(forPath: "hits/hits").children {
                        
                        if let result = result as? FIRDataSnapshot, let id = result.childSnapshot(forPath: "_id").value as? String {
                            
                            let channel = Channel(cID: id)
                            channel.cTitle = result.childSnapshot(forPath: "_source/title").value as? String
                            channel.cDescription = result.childSnapshot(forPath: "_source/description").value as? String

                            _results.append(channel)
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
        let query = buildQuery(searchTerm: searchText, type: .user)
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
    
    static func getSettingsSections(completion: @escaping (_ sections : [SettingSection], _ error : Error?) -> Void) {
        var settings = [SettingSection]()
        
        settingSectionsRef.observeSingleEvent(of: .value, with: { snapshot in
            for settingsSection in snapshot.children {
                if let settingsSection = settingsSection as? FIRDataSnapshot {
                    let section = SettingSection(sectionID: settingsSection.key, snapshot: settingsSection)
                    settings.append(section)
                }
            }
            completion(settings, nil)

        }, withCancel: { error in
            completion(settings, error)
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
    static func getChannel(cID : String, completion: @escaping (_ channel : Channel, _ error : NSError?) -> Void) {
        channelsRef.child(cID).queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { snap in
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
    
    static func getChannelItems(channelID : String, lastItem : String, completion: @escaping (_ success : Bool, _ items : [Item]) -> Void) {
        var items = [Item]()
        
        channelItemsRef.child(channelID).queryOrderedByKey().queryEnding(atValue: lastItem).queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                for child in snap.children {
                    if (child as AnyObject).key != lastItem {
                        let item = Item(itemID: (child as AnyObject).key, type:  (child as AnyObject).value)
                        items.append(item)
                    }
                }
                items.reverse()
                completion(false, items)
            } else {
                completion(false, items)
            }
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
    
    static func getItemCollection(_ itemID : String, completion: @escaping (_ success : Bool, _ items : [Item]) -> Void) {
        var items = [Item]()
        
        itemCollectionRef.child(itemID).queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                for child in snap.children {
                    let item = Item(itemID: (child as AnyObject).key, type:  (child as AnyObject).value)
                    items.append(item)
                }
                items.reverse()
                completion(true, items)
            } else {
                completion(false, items)
            }
        })
    }
    
    static func getItemCollection(_ itemID : String, lastItem : String, completion: @escaping (_ success : Bool, _ items : [Item]) -> Void) {
        var items = [Item]()
        
        itemCollectionRef.child(itemID).queryOrderedByKey().queryEnding(atValue: lastItem).queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                for child in snap.children {
                    if (child as AnyObject).key != lastItem {
                        let item = Item(itemID: (child as AnyObject).key, type:  (child as AnyObject).value)
                        items.append(item)
                    }
                }
                items.reverse()
                completion(false, items)
            } else {
                completion(false, items)
            }
        })
    }
    /*** MARK END : GET INDIVIDUAL ITEMS ***/

    /*** MARK START : GET USER ***/
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
    
    //items a user has saved
    static func getUserSavedItems(completion: @escaping (_ items : [Item]) -> Void) {
        guard let user = User.currentUser else { return }
        var allItems = [Item]()
        
        usersRef.child(user.uID!).child("savedItems").observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                for item in snap.children {
                    if let item = item as? FIRDataSnapshot, let type = item.value as? String{
                        let savedItem = Item(itemID: item.key, type: type)
                        
                        if !User.currentUser!.savedItems.contains(savedItem) {
                            User.currentUser!.savedItems.append(savedItem)
                            allItems.append(savedItem)
                        }
                    }
                }
            }
            completion(allItems)
        })
    }
    
    //items a user has created
    static func getUserItems(uID: String, completion: @escaping (_ items : [Item]) -> Void) {
        var allItems = [Item]()
        usersPublicDetailedRef.child(uID).child("items").queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                for child in snap.children {
                    let item = Item(itemID: (child as AnyObject).key, type:  (child as AnyObject).value)
                    allItems.append(item)
                }
                completion(allItems)
            } else {
                completion(allItems)
            }
        })
    }
    
    ///Get all tags that user is a verified expert in
    static func getUserExpertTags(uID: String, completion: @escaping (_ tags : [Channel]) -> Void) {
        var allChannels = [Channel]()
        
        usersPublicDetailedRef.child(uID).child("approvedChannels").queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                for child in snap.children {
                    let channel = Channel(cID: (child as AnyObject).key)
                    allChannels.append(channel)
                }
                completion(allChannels)
            } else {
                completion(allChannels)
            }
        })
    }
    /*** MARK END : GET USER ITEMS ***/
    
    //Create Feed for current user from followed tags
    static func createFeed(_ completion: @escaping (_ item : Item) -> Void) {
        guard let user = User.currentUser else { return }
        
        if user.subscriptions.count == 0 && !initialFeedUpdateComplete {
            
            keepChannelsUpdated(completion: { newItem in
                completion(newItem)
            })
            
            //add listener if user subscribes to new channel
            initialFeedUpdateComplete = true

        } else if user.subscriptions.count > 0 && !initialFeedUpdateComplete {
            
            keepChannelsUpdated(completion: { newItem in
                completion(newItem)
            })
            
            //add in new posts before returning feed
            for channel in user.subscriptions {
                Database.addNewItemsToFeed(channelID: channel.cID, startingAt: Date(), completion: { newItem in
                    
                    completion(newItem)

                    if channel == user.subscriptions.last {
                        //reached last subscribed channel
                        initialFeedUpdateComplete = true
                    }
                })
            }
        }
    }
    
    static func removeItemsFromFeed(_ channelID : String) {
        
        channelItemsRef.child(channelID).removeAllObservers()

    }
    
    static func addNewItemsToFeed(channelID : String, startingAt : Date, completion: @escaping (_ item : Item) -> Void) {
        
        let channelItems : FIRDatabaseQuery = channelItemsRef.child(channelID)
        activeListeners.append(channelItemsRef.child(channelID))
        
        channelItems.queryOrdered(byChild: "createdAt").queryStarting(atValue: NSNumber(value: startingAt.timeIntervalSince1970)).queryLimited(toLast: querySize).observe(.childAdded, with: { snap in
            let item = Item(itemID: snap.key, snapshot: snap, feedUpdate: true)
            item.cID = channelID
            
            completion(item)
        })
    }
    
    static func keepChannelsUpdated(completion: @escaping (_ item : Item) -> Void) {
        if User.isLoggedIn() {
            
            let subscriptions : FIRDatabaseQuery = currentUserRef.child("subscriptions")
            activeListeners.append(currentUserRef.child("subscriptions"))
            
            subscriptions.observe(.childAdded, with: { channelSnap in
                if initialFeedUpdateComplete {
                    addNewItemsToFeed(channelID: channelSnap.key, startingAt: Date(), completion: { item in
                        completion(item)
                    })
                } else {
                    print("ignoring child added)")
                }
            })
            
            subscriptions.observe(.childRemoved, with: { channelSnap in
                if initialFeedUpdateComplete {
                    removeItemsFromFeed(channelSnap.key)
                }
            })
        }
    }
    
    static func cleanupListeners() {
        for listener in activeListeners {
            listener.removeAllObservers()
        }
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
                currentAuthState = .loggedOut
                
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
            if let _user = user, currentAuthState != .loggedIn {
                currentAuthState = .loggedIn
                
                setCurrentUserPaths()
                
                populateCurrentUser(_user, completion: { (success) in
                    if success {
                        completion(true)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "FeedUpdateLogin"), object: self)
                    }
                })
            } else if currentAuthState == .loggedIn {
                //ignore the call - state is logged in and auth fired again
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
        currentUser.savedItems = []

        currentUser.subscriptions = []
        currentUser.subscriptionIDs = []

        currentUser.approvedChannels = []
        
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
                NotificationCenter.default.post(name: Notification.Name(rawValue: "UserUpdated"), object: self)
            }
        }
    }
    
    ///Populate current user
    static func populateCurrentUser(_ user: FIRUser!, completion: @escaping (_ success: Bool) -> Void) {
        print("populate current user fired")
        
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
            
            completion(true)

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
            
            if snap.hasChild("approvedChannels") {
                User.currentUser!.approvedChannels = []
                for channel in snap.childSnapshot(forPath: "approvedChannels").children {
                    if let channelSnap = channel as? FIRDataSnapshot {
                        let channel = Channel(cID: channelSnap.key)
                        channel.cTitle = channelSnap.value as? String
                        User.currentUser!.approvedChannels.append(channel)
                    }
                }
            }
            
            setCurrentUserPaths()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "UserUpdated"), object: self)
            addUserProfileListener(uID: user.uid)
            
        }, withCancel: { error in
            print("error getting user public detailed summary \(error)")
        })

        usersRef.child(user.uid).child("subscriptions").observeSingleEvent(of: .value, with: { snap in
            for channel in snap.children {
                if let channel = channel as? FIRDataSnapshot {
                    let savedChannel = Channel(cID: channel.key)
                    savedChannel.cTitle = channel.value as? String
                    
                    if !User.currentUser!.subscriptionIDs.contains(channel.key) {
                        User.currentUser!.subscriptions.append(savedChannel)
                        User.currentUser!.subscriptionIDs.append(channel.key)
                    }
                }
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SubscriptionsUpdated"), object: self)
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

            usersPublicDetailedRef.child(uID).child("items").observe(.childAdded, with: { snap in
                let currentItem = Item(itemID: snap.key, snapshot: snap)

                if !User.currentUser!.items.contains(currentItem) {
                    User.currentUser!.items.append(currentItem)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "UserUpdated"), object: self)
                }
            })
            activeListeners.append(usersPublicDetailedRef.child(uID).child("items"))
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
    
    ///Save individual item to Pulse database after Auth
    static func addItemToDatabase( _ item : Item, channelID: String, completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
        
        if let _user = FIRAuth.auth()?.currentUser {
            var itemPost : [ String : AnyObject] = ["title": item.itemTitle as AnyObject,
                                                   "uID": _user.uid as AnyObject,
                                                   "createdAt" : FIRServerValue.timestamp() as AnyObject,
                                                   "type" : item.type.rawValue as AnyObject,
                                                   "cID": channelID as AnyObject]
            
            let itemStatsPost : [ String : AnyObject] = ["downVoteCount": 0 as AnyObject,
                                                         "upVoteCount": 0 as AnyObject,
                                                         "views" : 0 as AnyObject]
            
            if let url = item.contentURL?.absoluteString {
                itemPost["url"] = url as AnyObject?
            }
            
            if let contentType = item.contentType {
                itemPost["contentType"] = contentType.rawValue as AnyObject?
            }
            
            let post : [String: Any] = ["items/\(item.itemID)": itemPost,
                                        "itemStats/\(item.itemID)" : itemStatsPost]

            databaseRef.updateChildValues(post , withCompletionBlock: { (blockError, ref) in
                blockError != nil ? completion(false, blockError as Error?) : completion(true, nil)
            })
            
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "please login" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: userInfo))
        }
    }
    
    ///Save collection into question / user
    static func addItemCollectionToDatabase(_ item : Item, parentItemID : String, channelID : String, post : [String : String],
                                            completion: @escaping (_ success : Bool, _ error : NSError?) -> Void) {
        
        let _user = FIRAuth.auth()?.currentUser
        var collectionPost : [AnyHashable: Any]!
        
        var channelPost : [String : AnyObject] = ["type" : item.type.rawValue as AnyObject,
                                                "tagID" : item.tag?.itemID as AnyObject,
                                                "tagTitle" : item.tag?.itemTitle as AnyObject,
                                                "title" : item.itemTitle as AnyObject,
                                                "uID" : item.itemUserID as AnyObject,
                                                "createdAt" : FIRServerValue.timestamp() as AnyObject]
        
        if let contentType = item.contentType {
            channelPost["contentType"] = contentType.rawValue as AnyObject?
        }
        
        if let url = item.contentURL?.absoluteString {
            channelPost["url"] = url as AnyObject?
        }

        switch item.type {
        case .answer:
            collectionPost = ["userDetailedPublicSummary/\(_user!.uid)/items/\(item.itemID)": item.itemID,
                              "itemCollection/\(item.itemID)" : post,
                              "channelItems/\(channelID)/\(item.itemID)":channelPost,
                              "itemCollection/\(parentItemID)/\(item.itemID)" : "answer" as AnyObject]
        case .post:
            collectionPost = ["userDetailedPublicSummary/\(_user!.uid)/items/\(item.itemID)": item.itemID,
                              "itemCollection/\(item.itemID)" : post,
                              "channelItems/\(channelID)/\(item.itemID)":channelPost,
                              "itemCollection/\(parentItemID)/\(item.itemID)" : "post" as AnyObject]
        default:
            collectionPost = ["userDetailedPublicSummary/\(_user!.uid)/items/\(item.itemID)": true,
                              "itemCollection/\(item.itemID)" : post,
                              "channelItems/\(channelID)/\(item.itemID)":channelPost]
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
    static func askQuestion(parentItem : Item, qText: String, completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
        guard let user = FIRAuth.auth()?.currentUser else {
            let errorInfo = [ NSLocalizedDescriptionKey : "you must be logged in to ask a question" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: errorInfo))
            return
        }
        
        guard let channelID = parentItem.cID else {
            let errorInfo = [ NSLocalizedDescriptionKey : "please select a channel first" ]
            completion(false, NSError.init(domain: "WrongChannel", code: 404, userInfo: errorInfo))
            return
        }
        
        let itemKey = itemsRef.childByAutoId().key
        
        let itemPost = ["title": qText,
                        "type":"question",
                        "uID": user.uid,
                        "cID":parentItem.cID]
        
        let channelPost : [String : AnyObject] = ["type" : "question" as AnyObject,
                                                  "tagID" : parentItem.itemID as AnyObject,
                                                  "tagTitle" : parentItem.itemTitle as AnyObject,
                                                  "title" : qText as AnyObject,
                                                  "uID" : user.uid as AnyObject,
                                                  "createdAt" : FIRServerValue.timestamp() as AnyObject]
        
        let post = ["channelItems/\(channelID)/\(itemKey)":channelPost,
                    "items/\(itemKey)":itemPost,
                    "itemCollection/\(parentItem.itemID)/\(itemKey)":"question",
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
    static func recommendJoinChannel(channel: Channel, applyName: String, applyEmail: String, applyText: String,
                                completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
    
        guard let user = FIRAuth.auth()?.currentUser else {
            let errorInfo = [ NSLocalizedDescriptionKey : "you must be logged in to recommend experts" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: errorInfo))
            return
        }
        
        guard let channelID = channel.cID else {
            let errorInfo = [ NSLocalizedDescriptionKey : "please choose a channel first" ]
            completion(false, NSError.init(domain: "Invalidtag", code: 404, userInfo: errorInfo))
            return
        }
        
        let post = ["email":applyEmail,
                    "tagID":channelID,
                    "name":applyName,
                    "reason":applyText,
                    "recommenderID": user.uid]
    
        databaseRef.child("channelRequests").childByAutoId().updateChildValues(post, withCompletionBlock: { (completionError, ref) in
            if completionError != nil {
                let errorInfo = [ NSLocalizedDescriptionKey : "error sending, please try again!" ]
                completion(false, NSError.init(domain: "Error", code: 404, userInfo: errorInfo))
            } else {
                completion(true, nil)
            }
        })
    }
    
    /* BECOME EXPERT */
    static func joinChannel(channel : Channel, applyText: String, completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
        guard let user = FIRAuth.auth()?.currentUser else {
            let errorInfo = [ NSLocalizedDescriptionKey : "you must be logged in to apply" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: errorInfo))
            return
        }
        
        guard let channelID = channel.cID else {
            let errorInfo = [ NSLocalizedDescriptionKey : "please select a channel first" ]
            completion(false, NSError.init(domain: "Invalidtag", code: 404, userInfo: errorInfo))
            return
        }
        
        let verificationPath = databaseRef.child("channelRequests")
        let post = ["uID":user.uid,
                    "reason":applyText,
                    "channelID":channelID]
        
        currentUserRef.child("appliedChannels").child(channelID).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                let errorInfo = [ NSLocalizedDescriptionKey : "you have already applied! we will get back to you soon." ]
                completion(false, NSError.init(domain: "AlreadyApplied", code: 404, userInfo: errorInfo))
            } else {
                verificationPath.childByAutoId().updateChildValues(post, withCompletionBlock: { (completionError, ref) in
                    if completionError != nil {
                        let errorInfo = [ NSLocalizedDescriptionKey : "error applying, please try again!" ]
                        completion(false, NSError.init(domain: "Error", code: 404, userInfo: errorInfo))
                    } else {
                        currentUserRef.child("appliedChannels").child(channelID).setValue(true)
                        completion(true, nil)
                    }
                })
            }
        })
    }

    
    /* STORAGE METHODS */
    static func getItemURL(channelID: String, fileID : String, completion: @escaping (_ URL : URL?, _ error : NSError?) -> Void) {
        let path = storageRef.child("channels/\(channelID)").child(fileID).child("content")
        
        let _ = path.downloadURL { (URL, error) -> Void in
            error != nil ? completion(nil, error! as NSError?) : completion(URL!, nil)
        }
    }
    
    static func getImage(channelID: String, itemID : String, fileType : FileTypes, maxImgSize : Int64, completion: @escaping (_ data : Data?, _ error : NSError?) -> Void) {
        let path = storageRef.child("channels/\(channelID)").child(itemID).child(fileType.rawValue)
        
        path.data(withMaxSize: maxImgSize) { (data, error) -> Void in
            error != nil ? completion(nil, error! as NSError?) : completion(data, nil)
        }
    }
    
    static func getChannelImage(channelID: String, fileType : FileTypes, maxImgSize : Int64, completion: @escaping (_ data : Data?, _ error : NSError?) -> Void) {
        let path = storageRef.child("channels/\(channelID)").child(fileType.rawValue)
        
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
    
    //Save an item for a user
    static func saveItem(item : Item, completion: @escaping (Bool, Error?) -> Void) {
        if User.isLoggedIn() {
            if User.currentUser?.savedItems != nil, User.currentUser!.savedItems.contains(item) { //remove item
                let _path = getDatabasePath(Element.Users, itemID: User.currentUser!.uID!).child("savedItems/\(item.itemID)")
                _path.setValue("true", withCompletionBlock: { (completionError, ref) in
                    completionError != nil ? completion(false, completionError!) : completion(false, nil)
                })
            } else { //pin item
                let _path = getDatabasePath(Element.Users, itemID: User.currentUser!.uID!).child("savedItems")
                _path.updateChildValues([item.itemID: item.type.rawValue], withCompletionBlock: { (completionError, ref) in
                    User.currentUser!.savedItems.append(item)
                    completionError != nil ? completion(false, completionError) : completion(true, nil)
                })
            }
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "please login to save questions" ]
            completion(false, NSError(domain: "NotLoggedIn", code: 200, userInfo: userInfo))
        }
    }
    
    static func subscribeChannel(_ channel : Channel, completion: @escaping (Bool, NSError?) -> Void) {
        if let user = User.currentUser {
            if let savedIndex = user.subscriptionIDs.index(of: channel.cID), let channelID = channel.cID  { //remove subscription case
                let _path = currentUserRef.child("subscriptions/\(channelID)")
                
                _path.setValue(nil, withCompletionBlock: { (completionError, ref) in
                    if completionError != nil {
                        completion(false, completionError as NSError?)
                    } else {
                        
                        user.subscriptions.append(channel)
                        user.subscriptionIDs.remove(at: savedIndex)

                        completion(true, nil)

                        _path.removeAllObservers()
                    }
                })
            } else { //save tag
                let _path = getDatabasePath(Element.Users, itemID: user.uID!).child("subscriptions")
                
                _path.updateChildValues([channel.cID!: channel.cTitle ?? ""], withCompletionBlock: { (completionError, ref) in
                    if completionError != nil {
                        completion(false, completionError as NSError?)
                    }
                    else {
                        if user.subscriptions.isEmpty {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "SubscriptionsUpdated"), object: self)
                        }

                        user.subscriptions.append(channel)
                        
                        if !User.currentUser!.subscriptionIDs.contains(channel.cID) {
                            user.subscriptionIDs.append(channel.cID)
                        }
                        
                        completion(true, nil)
                    }
                })
            }
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "please login to subscribe to channels" ]
            completion(false, NSError(domain: "NotLoggedIn", code: 200, userInfo: userInfo))
        }
    }
    
    /* UPLOAD IMAGE TO STORAGE */
    static func uploadThumbImage(channelID: String, itemID : String, image : UIImage, completion: @escaping (_ success : Bool, _ error : NSError?) -> Void) {
        let path = storageRef.child("channels").child(channelID).child(itemID).child("thumb")
        
        let _metadata = FIRStorageMetadata()
        _metadata.contentType = "image/jpeg"
        
        if let _thumbImageData = resizeImageHeight(image, newHeight: defaultPostHeight) {
            let _metadata = FIRStorageMetadata()
            _metadata.contentType = "image/jpeg"
            
            path.put(_thumbImageData, metadata: _metadata) { (metadata, error) in
                if (error != nil) {
                    completion(false, error as NSError?)
                } else {
                    completion(true, nil)
                }
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
        print("actual image dimensions are \(image.size)")
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return UIImageJPEGRepresentation(newImage!, 1.0)
    }
    
    static func resizeImageHeight(_ image: UIImage, newHeight: CGFloat) -> Data? {
        print("actual image dimensions are \(image.size.height, image.size.width)")
        let scale = newHeight / image.size.height
        let newWidth = image.size.width * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        print("final image dimensions are \(newImage?.size.height, newImage?.size.width)")

        UIGraphicsEndImageContext()
        
        return UIImageJPEGRepresentation(newImage!, 1.0)
    }
}
