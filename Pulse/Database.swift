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
import FacebookLogin
import FacebookCore
import GeoFire
import FirebaseDynamicLinks

let storage = Storage.storage()
let storageRef = storage.reference(forURL: "gs://pulse-84022.appspot.com")
let databaseRef = Database.database().reference()
var initialFeedUpdateComplete = false
var currentAuthState : AuthStates = .loggedOut

class PulseDatabase {
    /** Cached Images **/
    static let userImageCache = ImageCache(name: "UserImages")
    static let channelImageCache = ImageCache(name: "ChannelImages")
    static let channelNavImageCache = ImageCache(name: "NavImages")
    static let channelThumbCache = ImageCache(name: "ChannelThumbImages")
    static let seriesImageCache = ImageCache(name: "SeriesImages")
    
    static let channelsRef = databaseRef.child(Element.Channels.rawValue)
    static let channelItemsRef = databaseRef.child(Element.ChannelItems.rawValue)
    static let channelContributorsRef = databaseRef.child(Element.ChannelContributors.rawValue)

    static let itemsRef = databaseRef.child(Element.Items.rawValue)
    static let itemStatsRef = databaseRef.child(Element.ItemStats.rawValue)
    static let itemCollectionRef = databaseRef.child(Element.ItemCollection.rawValue)
    
    static let invitesRef = databaseRef.child(Element.Invites.rawValue)
    static let messagesRef = databaseRef.child(Element.Messages.rawValue)
    static let conversationsRef = databaseRef.child(Element.Conversations.rawValue)

    static var currentUserRef : DatabaseReference!
    static var currentUserFeedRef : DatabaseReference!

    static let usersRef = databaseRef.child(Element.Users.rawValue)
    static let usersPublicDetailedRef = databaseRef.child(Element.UserDetailedSummary.rawValue)
    static let usersPublicSummaryRef = databaseRef.child(Element.UserSummary.rawValue)

    static let filtersRef = databaseRef.child(Element.Filters.rawValue)
    static let settingsRef = databaseRef.child(Element.Settings.rawValue)
    static let settingSectionsRef = databaseRef.child(Element.SettingSections.rawValue)

    static let usersStorageRef = storageRef.child(Element.Users.rawValue)

    static var masterQuestionIndex = [String : String]()
    static var masterTagIndex = [String : String]()

    static let MAX_QUERY_SIZE : UInt = 10
    
    static var activeListeners = [DatabaseReference]()
    static var profileListenersAdded = false
    
    static func updateNotificationToken(tokenID: String?) {
        guard PulseUser.isLoggedIn() else {
            return
        }
        
        databaseRef.child("notificationIDs").child(PulseUser.currentUser.uID!).setValue(tokenID)
    }
    
    static func createShareLink(item: Any, linkString : String, imageURL : URL? = nil, completion: @escaping (URL?) -> Void) {
        
        guard let deepLink = URL(string: "https://checkpulse.co/"+linkString) else { return }
        
        let components = DynamicLinkComponents(link: deepLink, domain: "tc237.app.goo.gl")
        
        let iOSParams = DynamicLinkIOSParameters(bundleID: "co.checkpulse.pulse")
        iOSParams.minimumAppVersion = "0.1"
        iOSParams.appStoreID = "1200702658"
        
        //setting fallback URL makes it not go to appstore and instead open in mobile browser
        /** iOSParams.fallbackURL = URL(string: "https://checkpulse.co/"+linkString) **/
        
        let socialParams = DynamicLinkSocialMetaTagParameters()
        let analyticsParams = DynamicLinkGoogleAnalyticsParameters()
        let componentOptions = DynamicLinkComponentsOptions()
        
        componentOptions.pathLength = .short
        analyticsParams.source = "app"
        
        if linkString.contains("invites") {
            analyticsParams.campaign = "invites"
        } else {
            analyticsParams.campaign = "share"
        }

        if let item = item as? Item {
            analyticsParams.medium = "item"
            analyticsParams.content = item.itemID
            
            socialParams.descriptionText = item.itemDescription != "" ? item.itemDescription : item.tag?.itemTitle ?? item.cTitle
            socialParams.title = item.itemTitle.capitalized
            socialParams.imageURL = imageURL ?? item.contentURL
        } else if let channel = item as? Channel {
            analyticsParams.medium = "channel"
            analyticsParams.content = channel.cID

            socialParams.descriptionText = channel.cDescription
            socialParams.title = channel.cTitle?.capitalized
            socialParams.imageURL = channel.cImageURL != nil ? URL(string: channel.cImageURL!) : URL(string: "")
        } else if let user = item as? PulseUser {
            analyticsParams.medium = "user"
            analyticsParams.content = user.uID

            socialParams.descriptionText = user.shortBio
            socialParams.title = user.name?.capitalized
            socialParams.imageURL = URL(string: user.profilePic ?? user.thumbPic ?? "")
        }
        
        components.iOSParameters = iOSParams
        components.socialMetaTagParameters = socialParams
        components.options = componentOptions
        components.analyticsParameters = analyticsParams

        // Build the dynamic link
        let link = components.url
        
        // Or create a shortened dynamic link
        components.shorten { (shortURL, warnings, error) in
            if error != nil {
                completion(link)
                return
            } else {
                completion(shortURL)
            }
        }
    }
    
    static func removeItem(userID : String, itemID : String, completion: @escaping (Bool) -> Void) {
        databaseRef.child("userDetailedPublicSummary/\(userID)/items/\(itemID)").observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                itemsRef.child(itemID).setValue(nil, withCompletionBlock: { (error, snap) in
                    if error != nil {
                        //still need to implement
                    }
                })
                
                usersPublicDetailedRef.child(userID).child("items").child(snap.key).setValue(nil)
                
                itemCollectionRef.child(itemID).setValue(nil)
                
                if let cID = snap.childSnapshot(forPath: "cID").value as? String {
                    channelItemsRef.child(cID).child(itemID).setValue(nil)
                    
                    let itemStorageRef = storageRef.child("channels").child(cID).child(itemID)
                    
                    // Delete the file
                    itemStorageRef.delete { error -> Void in
                        error != nil ? completion(false) : completion(true)
                    }
                }

            } else {
                completion(false)
            }
        })
    }
    
    /** MARK : SEARCH **/
    static func buildQuery(searchTerm : String, type: SearchTypes) -> [String:Any] {
        var query = [String:Any]()
        
        switch type {
        case .items:
            query["index"] = "series"
            query["type"] = "series"
            query["fields"] = ["title","description","type","cID"]
        case .users:
            query["index"] = "users"
            query["type"] = "users"
            query["fields"] = ["name","shortBio","thumbPic"]
        case .channels:
            query["index"] = "channels"
            query["type"] = "channels"
            query["fields"] = ["title","description"]
        }
        
        let qTerm = ["_all":searchTerm]
        let qBody = ["match_phrase":qTerm]
        query["body"] = ["query":qBody]
        
        return query
    }
    
    static func searchItem(searchText : String, completion: @escaping (_ results : [Item]) -> Void) {
        
        let query = buildQuery(searchTerm: searchText, type: .items)
        let searchKey = databaseRef.child("search/request").childByAutoId().key
        
        databaseRef.child("search/request").child(searchKey).updateChildValues(query)
        
        databaseRef.child("search/response").child(searchKey).observe( .value, with: { snap in
            var _results = [Item]()
            
            if snap.exists() {
                if snap.childSnapshot(forPath: "hits").exists() {
                    for result in snap.childSnapshot(forPath: "hits/hits").children {

                        if let result = result as? DataSnapshot, let itemID = result.childSnapshot(forPath: "_id").value as? String {
                            let itemType = result.childSnapshot(forPath: "fields/type/0").value as? String
                            let currentItem = Item(itemID: itemID, type: itemType ?? "")
                            currentItem.itemTitle = result.childSnapshot(forPath: "fields/title/0").value as? String ?? ""
                            currentItem.itemDescription = result.childSnapshot(forPath: "fields/description/0").value as? String ?? ""
                            currentItem.cID = result.childSnapshot(forPath: "fields/cID/0").value as? String

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
        let query = buildQuery(searchTerm: searchText, type: .channels)
        let searchKey = databaseRef.child("search/request").childByAutoId().key
        
        databaseRef.child("search/request").child(searchKey).updateChildValues(query)
        
        databaseRef.child("search/response").child(searchKey).observe( .value, with: { snap in
            var _results = [Channel]()
            
            if snap.exists() {
                if snap.childSnapshot(forPath: "hits").exists() {
                    for result in snap.childSnapshot(forPath: "hits/hits").children {
                        
                        if let result = result as? DataSnapshot, let id = result.childSnapshot(forPath: "_id").value as? String {
                            let cDescription = result.childSnapshot(forPath: "fields/description/0").value as? String
                            let cTitle = result.childSnapshot(forPath: "fields/title/0").value as? String

                            let channel = Channel(cID: id, title: cTitle ?? "")
                            channel.cDescription = cDescription
                            channel.cImageURL = result.childSnapshot(forPath: "fields/url/0").value as? String
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
    
    static func searchUsers(searchText : String, completion: @escaping (_ peopleResult : [PulseUser]) -> Void) {
        let query = buildQuery(searchTerm: searchText, type: .users)
        let searchKey = databaseRef.child("search/request").childByAutoId().key
        
        databaseRef.child("search/request").child(searchKey).updateChildValues(query)
        
        databaseRef.child("search/response").child(searchKey).observe( .value, with: { snap in
            var _results = [PulseUser]()
            
            if snap.exists() {
                if snap.childSnapshot(forPath: "hits").exists() {
                    for result in snap.childSnapshot(forPath: "hits/hits").children {
                        if let result = result as? DataSnapshot, let uID = result.childSnapshot(forPath: "_id").value as? String {
                            let uName = result.childSnapshot(forPath: "fields/name/0").value as? String
                            let uShortBio = result.childSnapshot(forPath: "fields/shortBio/0").value as? String
                            let uPic = result.childSnapshot(forPath: "fields/thumbPic/0").value as? String

                            let currentUser = PulseUser(uID: uID)
                            
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
    static func checkExistingConversation(to : PulseUser, completion: @escaping (Bool, String?) -> Void) {
        if PulseUser.isLoggedIn() {
            usersRef.child(PulseUser.currentUser.uID!).child("conversations").child(to.uID!).observeSingleEvent(of: .value, with: { snapshot in
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
    static func getConversationMessages(user: PulseUser, conversationID : String, completion: @escaping ([Message], String?, Error?) -> Void) {
        var messages = [Message]()
        
        conversationsRef.child(conversationID).queryLimited(toLast: MAX_QUERY_SIZE).observeSingleEvent(of: .value, with: { snapshot in
            for messageID in snapshot.children {
                messagesRef.child((messageID as AnyObject).key).observeSingleEvent(of: .value, with: { snap in
                    if snap.exists() {
                        let message = Message(snapshot: snap)
                        messages.append(message)
                    }
                    
                    if messages.count == Int(snapshot.childrenCount) {
                        let lastMessageID = snap.key
                        completion(messages, lastMessageID, nil)
                    }
                }, withCancel: { error in
                    
                    let message = Message(from: user, to: PulseUser.currentUser, body: "Error getting this message")
                    messages.append(message)
                    
                    if messages.count == Int(snapshot.childrenCount) {
                        completion(messages, (messageID as AnyObject).key, nil)
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
        if PulseUser.isLoggedIn() {
            usersRef.child(PulseUser.currentUser.uID!).child("conversations").queryLimited(toLast: MAX_QUERY_SIZE).queryOrdered(byChild: "lastMessageID").observeSingleEvent(of: .value, with: { snapshot in
                for conversation in snapshot.children {
                    let _conversation = Conversation(snapshot: conversation as! DataSnapshot)
                    conversations.append(_conversation)
                }
                conversations.reverse()
                completion(conversations)
            })
        }
    }
    
    //Keep conversation updated
    static func keepConversationsUpdated(completion: @escaping (Conversation) -> Void) {
        if PulseUser.isLoggedIn()  {
            
            activeListeners.append(usersRef.child(PulseUser.currentUser.uID!).child("conversations"))

            usersRef.child(PulseUser.currentUser.uID!).child("conversations").observe(.childChanged, with: { snap in
                let _conversation = Conversation(snapshot: snap)
                completion(_conversation)
            })
        }
    }
    
    ///Send message
    static func sendMessage(existing : Bool, message: Message, completion: @escaping (_ success : Bool, _ conversationID : String?) -> Void) {
        guard PulseUser.isLoggedIn() else { return }
        let user = PulseUser.currentUser
        
        let messagePost : [ String : AnyObject ] = ["fromID": user.uID! as AnyObject,
                                                    "toID": message.to.uID! as AnyObject,
                                                    "body": message.body as AnyObject,
                                                    "createdAt" : ServerValue.timestamp() as AnyObject]
        
        let messageKey = messagesRef.childByAutoId().key
        
        messagesRef.child(messageKey).setValue(messagePost)
        
        //check if user has this user in existing conversations [toID : conversationID]
        if existing {
            //append to existing conversation if it already exists - message.mID has conversationID saved
            let conversationPost : [AnyHashable: Any] =
                ["conversations/\(message.mID!)/\(messageKey)": ServerValue.timestamp() as AnyObject,
                 "users/\(user.uID!)/conversations/\(message.to.uID!)/lastMessageType" : message.mType.rawValue,
                 "users/\(message.to.uID!)/conversations/\(user.uID!)/lastMessageType" : message.mType.rawValue,
                 "users/\(user.uID!)/conversations/\(message.to.uID!)/lastMessageSender" : user.uID!,
                 "users/\(message.to.uID!)/conversations/\(user.uID!)/lastMessageSender" : user.uID!,
                 "users/\(user.uID!)/conversations/\(message.to.uID!)/lastMessageID" : messageKey,
                 "users/\(message.to.uID!)/conversations/\(user.uID!)/lastMessageID" : messageKey,
                 "users/\(user.uID!)/conversations/\(message.to.uID!)/lastMessage" : message.body,
                 "users/\(message.to.uID!)/conversations/\(user.uID!)/lastMessage" : message.body,
                 "users/\(user.uID!)/conversations/\(message.to.uID!)/lastMessageTime" : ServerValue.timestamp() as AnyObject,
                 "users/\(message.to.uID!)/conversations/\(user.uID!)/lastMessageTime" : ServerValue.timestamp() as AnyObject,
                 "users/\(message.to.uID!)/unreadMessages/\(messageKey)" : ServerValue.timestamp() as AnyObject]
            
            databaseRef.updateChildValues(conversationPost, withCompletionBlock: { (completionError, ref) in
                completionError != nil ? completion(false, nil) : completion(true, message.mID)
            })
        } else {
            //start new conversation
            let conversationPost : [AnyHashable: Any] =
                ["conversations/\(messageKey)/\(messageKey)": ServerValue.timestamp() as AnyObject,
                 "users/\(user.uID!)/conversations/\(message.to.uID!)/conversationID" : messageKey,
                 "users/\(user.uID!)/conversations/\(message.to.uID!)/lastMessageID" : messageKey,
                "users/\(user.uID!)/conversations/\(message.to.uID!)/lastMessageSender" : user.uID!,
                 "users/\(user.uID!)/conversations/\(message.to.uID!)/lastMessage" : message.body,
                 "users/\(user.uID!)/conversations/\(message.to.uID!)/lastMessageType" : message.mType.rawValue,
                 "users/\(user.uID!)/conversations/\(message.to.uID!)/lastMessageTime" : ServerValue.timestamp() as AnyObject,
                 "users/\(message.to.uID!)/conversations/\(user.uID!)/conversationID" : messageKey,
                 "users/\(message.to.uID!)/conversations/\(user.uID!)/lastMessageID" : messageKey,
                 "users/\(message.to.uID!)/conversations/\(user.uID!)/lastMessageSender" : user.uID!,
                 "users/\(message.to.uID!)/conversations/\(user.uID!)/lastMessage" : message.body,
                 "users/\(message.to.uID!)/conversations/\(user.uID!)/lastMessageType" : message.mType.rawValue,
                 "users/\(message.to.uID!)/conversations/\(user.uID!)/lastMessageTime" : ServerValue.timestamp() as AnyObject,
                 "users/\(message.to.uID!)/unreadMessages/\(messageKey)" : ServerValue.timestamp() as AnyObject]
            
            databaseRef.updateChildValues(conversationPost, withCompletionBlock: { (completionError, ref) in
                completionError != nil ? completion(false, nil) : completion(true, messageKey)
            })
        }
    }
    /*** MARK END : MESSAGING ***/

    /*** MARK START : DATABASE PATHS ***/
    static func setCurrentUserPaths() {
        if PulseUser.isLoggedIn() {
            if PulseUser.currentUser.uID != nil {
                currentUserRef = usersRef.child(PulseUser.currentUser.uID!)
                currentUserFeedRef = usersRef.child(PulseUser.currentUser.uID!).child(Element.Feed.rawValue)
            }
        } else {
            currentUserRef = nil
            currentUserFeedRef = nil
        }
    }
    
    static func getDatabasePath(_ type : Element, itemID : String) -> DatabaseReference {
        return databaseRef.child(type.rawValue).child(itemID)
    }
    
    static func getStoragePath(_ type : Element, itemID : String) -> StorageReference {
        return storageRef.child(type.rawValue).child(itemID)
    }
    /*** MARK END : DATABASE PATHS ***/

    /*** MARK START : EXPLORE FEED ***/
    static func getExploreChannels(_ completion: @escaping (_ channels : [Channel], _ error : Error?) -> Void) {
        var allChannels = [Channel]()
        
        channelsRef.queryLimited(toLast: MAX_QUERY_SIZE).observeSingleEvent(of: .value, with: { snapshot in
            for channel in snapshot.children {
                let child = channel as! DataSnapshot
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
                let _section = section as! DataSnapshot
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
                if let settingsSection = settingsSection as? DataSnapshot {
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
 
    /*** MARK START : GET ITEMS ***/
    static func getChannel(cID : String, completion: @escaping (_ channel : Channel?, _ error : Error?) -> Void) {
        channelsRef.child(cID).observeSingleEvent(of: .value, with: { snap in
            let _currentChannel = Channel(cID: cID, snapshot: snap)
            completion(_currentChannel, nil)
        }, withCancel: { error in
            completion(nil, error)
        })
    }
    
    static func getChannelItems(channel : Channel, startingAt : Date, endingAt: Date, completion: @escaping (_ channel : Channel?) -> Void) {
        channelItemsRef.child(channel.cID!).queryOrdered(byChild: "createdAt").queryStarting(atValue: NSNumber(value: endingAt.timeIntervalSince1970 * 1000)).queryEnding(atValue: startingAt.timeIntervalSince1970 * 1000).observeSingleEvent(of: .value, with: { snap in
            channel.updateChannel(detailedSnapshot: snap)
            completion(channel)
        }, withCancel: { error in
            completion(nil)
        })
    }
    
    static func getChannelItems(channel : Channel, completion: @escaping (_ channel : Channel?) -> Void) {
        channelItemsRef.child(channel.cID!).queryLimited(toLast: MAX_QUERY_SIZE).observeSingleEvent(of: .value, with: { snap in
            channel.updateChannel(detailedSnapshot: snap)
            completion(channel)
        }, withCancel: { error in
            completion(nil)
        })
    }
    
    static func getChannelItems(channelID : String, startingAt : Date, endingAt: Date, completion: @escaping (_ success : Bool, _ items : [Item]) -> Void) {
        var items = [Item]()
        
        channelItemsRef.child(channelID).queryOrdered(byChild: "createdAt").queryStarting(atValue: NSNumber(value: endingAt.timeIntervalSince1970 * 1000)).queryEnding(atValue: startingAt.timeIntervalSince1970 * 1000).observeSingleEvent(of: .value, with: { snap in

            if snap.exists() {
                for child in snap.children {
                    let currentItem = Item(itemID: (child as AnyObject).key, snapshot: child as! DataSnapshot)
                    currentItem.cID = channelID
                    items.append(currentItem)
                }
                items.reverse()
                completion(true, items)
            } else {
                completion(false, items)
            }
        })
    }
    
    static func getChannelContributors(channelID : String, completion: @escaping (_ success : Bool, _ users : [PulseUser]) -> Void) {
        var users = [PulseUser]()
        
        channelContributorsRef.child(channelID).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                for child in snap.children {
                    let user = PulseUser(uID: (child as AnyObject).key)
                    users.append(user)
                }
                completion(false, users)
            } else {
                completion(false, users)
            }
        })
    }
    
    static func getItem(_ itemID : String, completion: @escaping (_ item : Item?, _ error : Error?) -> Void) {
        itemsRef.child(itemID).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                let _currentItem = Item(itemID: itemID, snapshot: snap)
                completion(_currentItem, nil)
            }
            else {
                let userInfo = [ NSLocalizedDescriptionKey : "no item found" ]
                completion(nil, NSError.init(domain: "notFound", code: 404, userInfo: userInfo))
            }
        })
    }
    
    static func getInviteItem(_ itemID : String,
                              completion: @escaping (_ item : Item?, _ type: MessageType?, _ questions: [Item], _ toUser : PulseUser?, _ conversationID: String?, _ error : Error?) -> Void) {
        var allItems = [Item]()
        var toUser : PulseUser? = nil
        var type : MessageType?
        
        databaseRef.child("invites").child(itemID).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                var currentItem : Item!
                
                let conversationID = snap.childSnapshot(forPath: "conversationID").value as? String

                //if interview or anything with child items - the itemID is the in
                if let parentItemID = snap.childSnapshot(forPath: "parentItemID").value as? String {
                    currentItem = Item(itemID: parentItemID, snapshot: snap)
                } else {
                    currentItem = Item(itemID: itemID, snapshot: snap)
                }

                if let userID = snap.childSnapshot(forPath: "fromUserID").value as? String {
                    currentItem.user = PulseUser(uID: userID)
                }
                
                if let userName = snap.childSnapshot(forPath: "fromUserName").value as? String {
                    currentItem.user?.name = userName
                }
                
                if let typeString = snap.childSnapshot(forPath: "type").value as? String {
                    type = MessageType.getMessageType(type: typeString)
                }
                
                if snap.childSnapshot(forPath: "items").exists() {
                    for aItem in snap.childSnapshot(forPath: "items").children {
                        if let aSnap = aItem as? DataSnapshot, let itemTitle = aSnap.value as? String {
                            let newItem = Item(itemID: aSnap.key)
                            newItem.itemTitle = itemTitle
                            allItems.append(newItem)
                        }
                    }
                }
                
                if let toUserID = snap.childSnapshot(forPath: "toUserID").value as? String, PulseUser.isLoggedIn(), toUserID == PulseUser.currentUser.uID! {
                    toUser = PulseUser.currentUser
                } else if let toUserID = snap.childSnapshot(forPath: "toUserID").value as? String {
                    toUser = PulseUser(uID: toUserID)
                    toUser?.name = snap.childSnapshot(forPath: "toUserName").value as? String
                }
                
                completion(currentItem, type, allItems, toUser, conversationID, nil)
            }
            else {
                let userInfo = [ NSLocalizedDescriptionKey : "no item found" ]
                completion(nil, nil, [], nil, nil, NSError.init(domain: "No Item Found", code: 404, userInfo: userInfo))
            }
        })
    }
    
    static func getSeriesTypes(completion: @escaping (_ allItems : [Item]) -> Void) {
        var allItems = [Item]()
        
        databaseRef.child("seriesTypes").queryOrdered(byChild: "rank").observeSingleEvent(of: .value, with: { snap in
            for child in snap.children {
                let currentItem = Item(itemID: (child as AnyObject).key, snapshot: child as! DataSnapshot)
                allItems.append(currentItem)
            }
            completion(allItems)
        })
    }
    
    static func getItemCollection(_ itemID : String, completion: @escaping (_ success : Bool, _ items : [Item]) -> Void) {
        var items = [Item]()
        
        itemCollectionRef.child(itemID).queryLimited(toLast: MAX_QUERY_SIZE).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                for child in snap.children {
                    let item = Item(itemID: (child as AnyObject).key, type:  (child as AnyObject).value)
                    items.append(item)
                }
                items.reverse()
                completion(true, items)
                //items.removeAll()
            } else {
                completion(false, items)
            }
        })
    }
    
    static func getItemCollection(_ itemID : String, lastItem : String, completion: @escaping (_ success : Bool, _ items : [Item]) -> Void) {
        var items = [Item]()
        
        itemCollectionRef.child(itemID).queryOrderedByKey().queryEnding(atValue: lastItem).queryLimited(toLast: MAX_QUERY_SIZE).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                for child in snap.children {
                    if (child as AnyObject).key != lastItem {
                        let item = Item(itemID: (child as AnyObject).key, type:  (child as AnyObject).value)
                        items.append(item)
                    }
                }
                items.reverse()
                completion(false, items)
                items.removeAll()
            } else {
                completion(false, items)
            }
        })
    }
    /*** MARK END : GET INDIVIDUAL ITEMS ***/

    /*** MARK START : GET USER ***/
    ///Returns the shortest public profile
    static func getUser(_ uID : String, completion: @escaping (_ user : PulseUser?, _ error : NSError?) -> Void) {
        usersPublicSummaryRef.child(uID).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                let _returnUser = PulseUser(uID: uID, snapshot: snap)
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
    
    static func getDetailedUserProfile(user: PulseUser, completion: @escaping (_ user: PulseUser) -> Void) {
        usersPublicDetailedRef.child(user.uID!).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                user.updateUser(detailedSnapshot: snap)
                completion(user) 
            }
        })
    }
    
    //items a user has saved
    static func getUserSavedItems(completion: @escaping (_ items : [Item]) -> Void) {
        guard PulseUser.isLoggedIn() else { return }
        var allItems = [Item]()
        
        usersRef.child(PulseUser.currentUser.uID!).child("savedItems").observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                for item in snap.children {
                    if let item = item as? DataSnapshot, let type = item.value as? String{
                        let savedItem = Item(itemID: item.key, type: type)
                        
                        if !PulseUser.currentUser.savedItems.contains(savedItem) {
                            PulseUser.currentUser.savedItems.append(savedItem)
                            allItems.append(savedItem)
                        }
                    }
                }
            }
            completion(allItems)
            allItems.removeAll()
        })
    }
    
    //items a user has created
    static func getUserItems(uID: String, completion: @escaping (_ items : [Item]) -> Void) {
        var allItems = [Item]()
        usersPublicDetailedRef.child(uID).child("items").queryLimited(toLast: MAX_QUERY_SIZE).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                for child in snap.children {
                    let item = Item(itemID: (child as AnyObject).key, type:  (child as AnyObject).value)
                    allItems.append(item)
                }
                completion(allItems.reversed())
            } else {
                completion(allItems)
            }
            allItems.removeAll()
        })
    }
    
    /*** MARK END : GET USER ITEMS ***/
    
    //Create Feed for current user from followed tags
    static func createFeed(startingAt : Date, endingAt: Date, completion: @escaping (_ items : [Item]) -> Void) {
        guard PulseUser.isLoggedIn() else { return }
        var allNewItems = [Item]()
        var itemStack = [Bool](repeating: false, count: PulseUser.currentUser.subscriptions.count)
        
        if PulseUser.currentUser.subscriptions.count == 0 && !initialFeedUpdateComplete {
            completion(allNewItems)
            
            keepChannelsUpdated(completion: { newItems in
                completion(newItems)
            })
            
            //add listener if user subscribes to new channel
            initialFeedUpdateComplete = true

        } else if PulseUser.currentUser.subscriptions.count > 0 && !initialFeedUpdateComplete {
            
            keepChannelsUpdated(completion: { newItems in
                completion(newItems)
            })
            
            //add in new posts before returning feed
            for (index, channel) in PulseUser.currentUser.subscriptions.enumerated() {
                PulseDatabase.addNewItemsToFeed(channel: channel, startingAt: startingAt, endingAt: endingAt, completion: { newItems in
                    
                    allNewItems.append(contentsOf: newItems)
                    itemStack[index] = true
                    
                    if isUpdateComplete(stack: itemStack) {
                        initialFeedUpdateComplete = true
                        completion(sortNewItems(items: allNewItems))
                    }
                })
            }
        }
    }
    
    static func fetchMoreItems(startingAt : Date, endingAt: Date, completion: @escaping (_ items : [Item]) -> Void) {
        guard PulseUser.isLoggedIn() else { return }
        var allNewItems = [Item]()
        var itemStack = [Bool](repeating: false, count: PulseUser.currentUser.subscriptions.count)
        
        //add in new posts before returning feed
        for (index, channel) in PulseUser.currentUser.subscriptions.enumerated() {
            
            PulseDatabase.addNewItemsToFeed(channel: channel, startingAt: startingAt, endingAt: endingAt, completion: { newItems in
                allNewItems.append(contentsOf: newItems)
                itemStack[index] = true
                
                if isUpdateComplete(stack: itemStack) {
                    completion(sortNewItems(items: allNewItems))
                    allNewItems.removeAll()
                    itemStack.removeAll()
                }
            })
        }
    }
    
    static func sortNewItems(items : [Item]) -> [Item] {
        return items.sorted(by: { $0.createdAt! > $1.createdAt! })
    }
    
    static func isUpdateComplete(stack : [Bool]) -> Bool {
        return !stack.contains(false)
    }
    
    static func removeItemsFromFeed(_ channelID : String) {
        
        channelItemsRef.child(channelID).removeAllObservers()

    }
    
    static func addNewItemsToFeed(channel : Channel, startingAt : Date, endingAt: Date, completion: @escaping (_ items : [Item]) -> Void) {
        var channelNewItems = [Item]()
        
        let channelItems : DatabaseQuery = channelItemsRef.child(channel.cID)
        
        if !activeListeners.contains(channelItemsRef.child(channel.cID)) {
            activeListeners.append(channelItemsRef.child(channel.cID))
        }
        
        channelItems.queryOrdered(byChild: "createdAt").queryStarting(atValue: NSNumber(value: endingAt.timeIntervalSince1970 * 1000)).queryEnding(atValue: startingAt.timeIntervalSince1970 * 1000).observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                for item in snap.children {
                    if let itemSnap = item as? DataSnapshot {
                        let item = Item(itemID: itemSnap.key, snapshot: itemSnap)
                        item.cID = channel.cID
                        item.cTitle = channel.cTitle
                        
                        channelNewItems.append(item)
                    }
                }
            }
            channelNewItems.reverse()
            completion(channelNewItems)
            channelNewItems.removeAll()
        })
    }
    
    static func keepChannelsUpdated(completion: @escaping (_ items : [Item]) -> Void) {
        if PulseUser.isLoggedIn() {
            
            let subscriptions : DatabaseQuery = currentUserRef.child("subscriptions")
            activeListeners.append(currentUserRef.child("subscriptions"))
            let endUpdateAt : Date = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

            subscriptions.observe(.childAdded, with: { channelSnap in
                if initialFeedUpdateComplete {
                    let channel = Channel(cID: channelSnap.key, title: channelSnap.value as? String ?? "")
                    addNewItemsToFeed(channel: channel, startingAt: Date(), endingAt: endUpdateAt, completion: { items in
                        completion(items)
                    })
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
            profileListenersAdded = false
        }
    }
    
    /* AUTH METHODS */
    static func createEmailUser(_ email : String, password: String, completion: @escaping (_ user : PulseUser?, _ error : NSError?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { (_user, _error) in
            if _error != nil {
                completion(nil, _error as NSError?)
            } else {
                saveUserToDatabase(_user!, completion: { (success , error) in
                    error != nil ? completion(nil, error) : completion(PulseUser(uID: _user?.uid), nil)
                })
            }
        }
    }
    
    // Update FIR auth profile - name, profilepic
    static func updateUserData(_ updateType: UserProfileUpdateType, value: Any, completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
        if let user = Auth.auth().currentUser {
            let changeRequest = user.createProfileChangeRequest()
            
            switch updateType {
            case .displayName: changeRequest.displayName = value as? String
            case .photoURL: changeRequest.photoURL = value as? URL
            }
            
            changeRequest.commitChanges { error in
                if let error = error {
                    completion(false, error)
                } else {
                    
                    saveUserToDatabase(user, completion: { (success , error) in
                        error != nil ? completion(false, error) : completion(true, nil)
                    })
                }
            }
        } else {
            completion(false, nil)
        }
    }
    
    static func signOut( _ completion: (_ success: Bool) -> Void ) {
        do {
            try Auth.auth().signOut()
            //might not want to remove the tokens - but need to check its working first
            if let session = Twitter.sharedInstance().sessionStore.session() {
                Twitter.sharedInstance().sessionStore.logOutUserID(session.userID)
            }
            if AccessToken.current != nil {
                let loginManager = LoginManager()
                loginManager.logOut()
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
    
    static func loginEmail(email: String, password: String, completion: @escaping (_ user: User?, _ error: Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) {(user, blockError) in
            completion(user, blockError)
        }
    }
    
    static func checkSocialTokens(_ completion: @escaping (_ result: Bool) -> Void) {
        if let token = AccessToken.current {
            let credential = FacebookAuthProvider.credential(withAccessToken: token.authenticationToken)
            Auth.auth().signIn(with: credential) { (aUser, error) in
                error != nil ? completion(false) : completion(true)
            }
        } else if let session = Twitter.sharedInstance().sessionStore.session() {
            let credential = TwitterAuthProvider.credential(withToken: session.authToken, secret: session.authTokenSecret)
            Auth.auth().signIn(with: credential) { (aUser, error) in
                error != nil ? completion(false) : completion(true)
            }
        } else {
            completion(false)
        }
    }
    
    ///Check if user is logged in
    static func checkCurrentUser(_ completion: @escaping (Bool) -> Void) {
        PulseDatabase.checkSocialTokens({(result) in
            //result ? completion(true) : completion(false) //user not populated yet - so shouldn't fire completion block - wait till auth listener fires
        })

        Auth.auth().addStateDidChangeListener { auth, user in
            if let _user = user, currentAuthState != .loggedIn {
                currentAuthState = .loggedIn
                
                setCurrentUserPaths()
                
                populateCurrentUser(_user, completion: { (success) in
                    if success {
                        completion(true)
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
        guard PulseUser.isLoggedIn() else { return }
        
        let currentUser = PulseUser.currentUser
        currentUser.uID = nil
        currentUser.name = nil
        currentUser.items = []
        currentUser.savedItems = []
        currentUser.savedVotes = [:]
        
        currentUser.subscriptions = []
        currentUser.subscriptionIDs = []

        currentUser.contributorChannels = []
        currentUser.editorChannels = []

        currentUser.profilePic = nil
        currentUser.thumbPic = nil
        currentUser.birthday = nil
        currentUser.bio = nil
        currentUser.shortBio = nil
        currentUser.gender = nil
        
        setCurrentUserPaths()
    }
    
    ///Populate current user - takes the Firebase User and uses it to populate the current user
    static func populateCurrentUser(_ user: User!, completion: @escaping (_ success: Bool) -> Void) {
        removeCurrentUser()
        PulseUser.currentUser.uID = user.uid
        
        usersPublicSummaryRef.child(user.uid).observe(.value, with: { snap in
            if snap.hasChild(SettingTypes.name.rawValue) {
                PulseUser.currentUser.name = snap.childSnapshot(forPath: SettingTypes.name.rawValue).value as? String
            } else if let name = Auth.auth().currentUser?.displayName {
                PulseUser.currentUser.name = name
                saveUserToDatabase(user, completion: {_ in })
            } else {
                PulseUser.currentUser.name = nil
            }
            
            if snap.hasChild(SettingTypes.profilePic.rawValue) || snap.hasChild(SettingTypes.thumbPic.rawValue) {
                PulseUser.currentUser.profilePic = snap.childSnapshot(forPath: SettingTypes.profilePic.rawValue).value as? String ?? snap.childSnapshot(forPath: SettingTypes.thumbPic.rawValue).value as? String
            } else if let url = Auth.auth().currentUser?.photoURL {
                PulseUser.currentUser.profilePic = String(describing: url)
                saveUserToDatabase(user, completion: {_ in })
            }
            
            PulseUser.currentUser.shortBio = snap.childSnapshot(forPath: SettingTypes.shortBio.rawValue).value as? String
            NotificationCenter.default.post(name: Notification.Name(rawValue: "UserSummaryUpdated"), object: self)
            completion(true)

        }, withCancel: { error in
            completion(false)
        })
        
        usersPublicDetailedRef.child(user.uid).observeSingleEvent(of: .value, with: { snap in
            PulseUser.currentUser.birthday = snap.childSnapshot(forPath: SettingTypes.birthday.rawValue).value as? String
            PulseUser.currentUser.bio = snap.childSnapshot(forPath: SettingTypes.bio.rawValue).value as? String
            PulseUser.currentUser.gender = snap.childSnapshot(forPath: SettingTypes.gender.rawValue).value as? String
            
            if snap.hasChild("items") {
                PulseUser.currentUser.items = []
                for item in snap.childSnapshot(forPath: "items").children {
                    if let item = item as? DataSnapshot {
                        let currentItem = Item(itemID: item.key, snapshot: item)
                        PulseUser.currentUser.items.append(currentItem)
                    }
                }
            } else {
                PulseUser.currentUser.items = []
            }
            
            if snap.hasChild("contributorChannels") {
                PulseUser.currentUser.contributorChannels = []
                for channel in snap.childSnapshot(forPath: "contributorChannels").children {
                    if let channelSnap = channel as? DataSnapshot {
                        let channel = Channel(cID: channelSnap.key, title: channelSnap.value as? String ?? "")
                        PulseUser.currentUser.contributorChannels.append(channel)
                    }
                }
            } else {
                PulseUser.currentUser.contributorChannels = []
            }
            
            if snap.hasChild("editorChannels") {
                PulseUser.currentUser.editorChannels = []
                for channel in snap.childSnapshot(forPath: "editorChannels").children {
                    if let channelSnap = channel as? DataSnapshot {
                        let channel = Channel(cID: channelSnap.key, title: channelSnap.value as? String ?? "")
                        PulseUser.currentUser.editorChannels.append(channel)
                    }
                }
            } else {
                PulseUser.currentUser.editorChannels = []
            }
            
            setCurrentUserPaths()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "UserDetailsUpdated"), object: self)
            addUserProfileListener(uID: user.uid)
            
        }, withCancel: { error in
            completion(false)
        })

        usersRef.child(user.uid).child("subscriptions").observeSingleEvent(of: .value, with: { snap in
            for channel in snap.children {
                if let channel = channel as? DataSnapshot {
                    let savedChannel = Channel(cID: channel.key, title: channel.value as? String)
                    
                    if !PulseUser.currentUser.subscriptionIDs.contains(channel.key) {
                        PulseUser.currentUser.subscriptions.append(savedChannel)
                        PulseUser.currentUser.subscriptionIDs.append(channel.key)
                    }
                }
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SubscriptionsUpdated"), object: self)
        }, withCancel: { error in
            
        })
    }
    
    static func addUserProfileListener(uID : String) {
        
        if !profileListenersAdded {
            usersPublicDetailedRef.child(uID).child("gender").observe(.value, with: { snap in
                PulseUser.currentUser.gender = snap.value as? String
            })
            activeListeners.append(usersPublicDetailedRef.child(uID).child("gender"))
            
            usersPublicDetailedRef.child(uID).child("birthday").observe(.value, with: { snap in
                PulseUser.currentUser.birthday = snap.value as? String
            })
            activeListeners.append(usersPublicDetailedRef.child(uID).child("birthday"))

            usersPublicDetailedRef.child(uID).child("bio").observe(.value, with: { snap in
                PulseUser.currentUser.bio = snap.value as? String
            })
            activeListeners.append(usersPublicDetailedRef.child(uID).child("bio"))

            usersPublicDetailedRef.child(uID).child("items").observe(.childAdded, with: { snap in
                let currentItem = Item(itemID: snap.key, snapshot: snap)

                if !PulseUser.currentUser.items.contains(currentItem) {
                    PulseUser.currentUser.items.append(currentItem)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "UserItemsUpdated"), object: self)
                }
            })
            activeListeners.append(usersPublicDetailedRef.child(uID).child("items"))
            profileListenersAdded = true
        }
    }
    
    static func reauthUser(completion: @escaping (Bool, Error?) -> Void) {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            checkSocialTokens{ success in
                if success {
                    completion(success, nil)
                } else {
                    let userInfo = [ NSLocalizedDescriptionKey : "unable to verify your account. please try again" ]
                    completion(false, NSError.init(domain: "InvalidLogin", code: 404, userInfo: userInfo))
                }
            }
            return
        }
        
        let alertController = UIAlertController(title: "Change Password", message: "Please enter your current password ", preferredStyle: .alert)
        alertController.addTextField(configurationHandler: {(_ textField: UITextField) -> Void in
            textField.placeholder = "Current password"
            textField.isSecureTextEntry = true
        })
        
        let confirmAction = UIAlertAction(title: "ok", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            if let password = alertController.textFields?[0].text {
                let credential = EmailAuthProvider.credential(withEmail: email, password: password)
                user.reauthenticate(with: credential) { error in
                    error != nil ? completion(false, error) : completion(true, nil)
                }
            } else {
                let userInfo = [ NSLocalizedDescriptionKey : "please enter your current password" ]
                completion(false, NSError.init(domain: "InvalidPassword", code: 404, userInfo: userInfo))
            }
        })
        alertController.addAction(confirmAction)
        
        let cancelAction = UIAlertAction(title: "cancel", style: .cancel, handler: {(_ action: UIAlertAction) -> Void in
            let userInfo = [ NSLocalizedDescriptionKey : "unable to verify current password" ]
            completion(false, NSError.init(domain: "InvalidPassword", code: 404, userInfo: userInfo))
        })
        alertController.addAction(cancelAction)
        
        if let topController = UIApplication.shared.keyWindow?.rootViewController {
            topController.present(alertController, animated: true, completion:nil)
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "unable to verify current password" ]
            completion(false, NSError.init(domain: "InvalidPassword", code: 404, userInfo: userInfo))
        }
    }
    
    ///Update user profile to Pulse database from settings
    static func updateUserProfile(_ setting : Setting, newValue : String, completion: @escaping (Bool, Error?) -> Void) {
        let _user = PulseUser.currentUser
        
        var userPost = [String : String]()
        if PulseUser.isLoggedIn() {
            switch setting.type! {
            case .email:
                Auth.auth().currentUser?.updateEmail(to: newValue) { completionError in
                    if completionError == nil {
                        completion(true, nil)
                    } else if let completionError = completionError as NSError?, completionError.code == AuthErrorCode.requiresRecentLogin.rawValue {
                        reauthUser(completion: { success, error in
                            if success {
                                updateUserProfile(setting, newValue: newValue, completion: {success, error in
                                    completion(success, error)
                                })
                            } else {
                                completion(false, error)
                            }
                        })
                    } else {
                        completion(false, completionError)
                    }
                }
            case .password:
                Auth.auth().currentUser?.updatePassword(to: newValue, completion: { completionError in
                    if completionError == nil {
                        completion(true, nil)
                    } else if let completionError = completionError as NSError?, completionError.code == AuthErrorCode.requiresRecentLogin.rawValue {
                        reauthUser(completion: { success, error in
                            if success {
                                updateUserProfile(setting, newValue: newValue, completion: {success, error in
                                    completion(success, error)
                                })
                            } else {
                                completion(false, error)
                            }
                        })
                    } else {
                        completion(false, completionError)
                    }
                })
            case .shortBio, .name, .profilePic, .thumbPic:
                userPost[setting.settingID] = newValue
                usersPublicSummaryRef.child(_user.uID!).updateChildValues(userPost, withCompletionBlock: { (completionError, ref) in
                    completionError != nil ? completion(false, completionError) : completion(true, nil)
                })
            case .birthday, .gender, .location, .bio:
                userPost[setting.settingID] = newValue
                usersPublicDetailedRef.child(_user.uID!).updateChildValues(userPost, withCompletionBlock: { (completionError, ref) in
                    completionError != nil ? completion(false, completionError) : completion(true, nil)
                })
            default:
                userPost[setting.settingID] = newValue
                usersRef.child(_user.uID!).updateChildValues(userPost, withCompletionBlock: { (completionError, ref) in
                    completionError != nil ? completion(false, completionError) : completion(true, nil)
                })
            }
        }
    }
    
    static func updateUserLocation(newValue : CLLocation, completion: @escaping (Bool, Error?) -> Void) {
        guard PulseUser.isLoggedIn() else {
            return
        }
        
        let geoFire = GeoFire(firebaseRef: databaseRef.child("userLocations"))
        
        geoFire?.setLocation(newValue, forKey: PulseUser.currentUser.uID!) { (error) in
            if (error != nil) {
                completion(false, error)
            } else {
                completion(true, nil)
            }
        }
    }
    
    static func getUserLocation(completion: @escaping (CLLocation?, Error?) -> Void) {
        let geoFire = GeoFire(firebaseRef: databaseRef.child("userLocations"))

        if PulseUser.isLoggedIn() {
            geoFire?.getLocationForKey(PulseUser.currentUser.uID!, withCallback: { (location, error) in
                if (error != nil) {
                    let userInfo = [ NSLocalizedDescriptionKey : "error getting location" ]
                    completion(nil, NSError.init(domain: "NoLocation", code: 404, userInfo: userInfo))
                } else if (location != nil) {
                    let location = CLLocation(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
                    PulseUser.currentUser.location = location
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
    static func saveUserToDatabase(_ user: User, completion: @escaping (Bool, NSError?) -> Void) {
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
        
        if PulseUser.isLoggedIn() {
            var itemPost : [ String : AnyObject] = ["title": item.itemTitle as AnyObject,
                                                   "uID": PulseUser.currentUser.uID! as AnyObject,
                                                   "createdAt" : ServerValue.timestamp() as AnyObject,
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
    static func addItemCollectionToDatabase(_ item : Item, parentItem : Item, channelID : String, post : [String : String],
                                            completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
        
        guard PulseUser.isLoggedIn() else {
            let userInfo = [ NSLocalizedDescriptionKey : "please login" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: userInfo))
            return
        }
        
        let _user = PulseUser.currentUser
        
        var collectionPost : [AnyHashable: Any]! = [:]
        
        var channelPost : [String : AnyObject] = ["type" : item.type.rawValue as AnyObject,
                                                "tagID" : item.tag?.itemID as AnyObject,
                                                "tagTitle" : item.tag?.itemTitle as AnyObject,
                                                "title" : item.itemTitle as AnyObject,
                                                "uID" : item.itemUserID as AnyObject,
                                                "createdAt" : ServerValue.timestamp() as AnyObject]
        
        if let contentType = item.contentType {
            channelPost["contentType"] = contentType.rawValue as AnyObject?
        }
        
        if let url = item.contentURL?.absoluteString {
            channelPost["url"] = url as AnyObject?
        }
        
        if post.count > 1 {
            collectionPost["itemCollection/\(item.itemID)"] = post
        }
        
        //if it's an item in response to a feedback request, thread or question - add the new item and update the created at for channelItems -
        //keeps only one post for each feedback request
        if (parentItem.type == .session && item.type == .session) || (parentItem.type == .question && item.type == .answer) || (parentItem.type == .thread && item.type == .perspective) {
            collectionPost["itemCollection/\(parentItem.itemID)/\(item.itemID)"] = item.type.rawValue as AnyObject
            collectionPost["channelItems/\(channelID)/\(parentItem.itemID)/createdAt"] = ServerValue.timestamp() as AnyObject
            collectionPost["userDetailedPublicSummary/\(_user.uID!)/items/\(item.itemID)"] = item.type.rawValue as AnyObject
        }
            
        //if it's new feedback session then add it to channel items & series but with the new key
        else if parentItem.type == .feedback, item.type == .session {
            let feedbackItemKey = databaseRef.child("items").childByAutoId().key

            //duplicate the thumbnail for the item
            if let _image = item.content  {
                PulseDatabase.uploadImage(channelID: item.cID, itemID: feedbackItemKey, image: _image,  fileType: .thumb, completion: { _ in })
            }
            
            collectionPost["channelItems/\(channelID)/\(feedbackItemKey)"] = channelPost
            collectionPost["itemCollection/\(feedbackItemKey)/\(item.itemID)"] = item.type.rawValue as AnyObject
            collectionPost["itemCollection/\(parentItem.itemID)/\(feedbackItemKey)"] = item.type.rawValue as AnyObject
            collectionPost["items/\(feedbackItemKey)"] = channelPost
            collectionPost["userDetailedPublicSummary/\(_user.uID!)/items/\(item.itemID)"] = item.type.rawValue as AnyObject
        }
            
        //if any other except interview - add the actual item to the series collection, add the item to channel & update user
        else if parentItem.type != .interview {
            collectionPost["itemCollection/\(parentItem.itemID)/\(item.itemID)"] = item.type.rawValue as AnyObject
            collectionPost["channelItems/\(channelID)/\(item.itemID)"] = channelPost
            collectionPost["userDetailedPublicSummary/\(_user.uID!)/items/\(item.itemID)"] = item.type.rawValue as AnyObject
        } else if parentItem.type == .interview {
            //interviews are added to collection but only one entry is added to channelItems & user records
            collectionPost["itemCollection/\(parentItem.itemID)/\(item.itemID)"] = item.type.rawValue as AnyObject
        }
        
        if let tagID = item.tag?.itemID {
            collectionPost["channels/\(channelID)/tags/\(tagID)/lastCreatedAt"] = ServerValue.timestamp() as AnyObject
        }

        
        databaseRef.updateChildValues(collectionPost, withCompletionBlock: { (blockError, ref) in
            blockError != nil ? completion(false, blockError) : completion(true, nil)
        })
    }
    
    static func updateItemViewCount(itemID : String) {
        itemStatsRef.child(itemID).child("views").runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if let currentViews = currentData.value as? Float {
                currentData.value = currentViews + 1
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        })
    }
    
    static func addVote(_ _vote : VoteType, itemID : String, completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
        guard PulseUser.isLoggedIn() else {
            let errorInfo = [ NSLocalizedDescriptionKey : "you must be logged in to vote" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: errorInfo))
            return
        }
        
        var upVoteCount = 0
        var downVoteCount = 0
        
        if PulseUser.currentUser.savedVotes[itemID] != true {
            itemStatsRef.child(itemID).runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
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
                    return TransactionResult.success(withValue: currentData)
                }
                return TransactionResult.success(withValue: currentData)
            }) { (error, committed, snapshot) in
                if let error = error {
                    completion(false, error as Error?)
                } else if committed == true {
                    let post = [itemID:true]
                    currentUserRef.child("votes").updateChildValues(post , withCompletionBlock: { (error, ref) in
                        PulseUser.currentUser.savedVotes[itemID] = true
                    })
                    completion(true, nil)
                }
            }
        }
    }
    
    /** ASK QUESTIONS **/
    static func askQuestion(parentItem : Item, qText: String, completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
        guard PulseUser.isLoggedIn() else {
            let errorInfo = [ NSLocalizedDescriptionKey : "you must be logged in to ask a question" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: errorInfo))
            return
        }
        
        guard let channelID = parentItem.cID else {
            let errorInfo = [ NSLocalizedDescriptionKey : "please select a channel first" ]
            completion(false, NSError.init(domain: "WrongChannel", code: 404, userInfo: errorInfo))
            return
        }
        
        guard PulseUser.currentUser.subscriptionIDs.contains(parentItem.cID) else {
            let errorInfo = [ NSLocalizedDescriptionKey : "you need to be subscribed to the channel to ask a question" ]
            completion(false, NSError.init(domain: "NotSubscribed", code: 404, userInfo: errorInfo))
            return
        }
        
        let user = PulseUser.currentUser
        
        let itemKey = itemsRef.childByAutoId().key
        
        let itemPost : [String : Any] = ["title": qText,
                                         "type":"question",
                                         "uID": user.uID!,
                                         "cID":parentItem.cID,
                                         "createdAt" : ServerValue.timestamp() as AnyObject]
        
        let channelPost : [String : AnyObject] = ["type" : "question" as AnyObject,
                                                  "tagID" : parentItem.itemID as AnyObject,
                                                  "tagTitle" : parentItem.itemTitle as AnyObject,
                                                  "title" : qText as AnyObject,
                                                  "uID" : user.uID! as AnyObject,
                                                  "createdAt" : ServerValue.timestamp() as AnyObject]
        
        let post = ["channelItems/\(channelID)/\(itemKey)":channelPost,
                    "items/\(itemKey)":itemPost,
                    "itemCollection/\(parentItem.itemID)/\(itemKey)":"question",
                    "userDetailedPublicSummary/\(user.uID!)/items/\(itemKey)":"question"] as [String: Any]
        
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
        guard PulseUser.isLoggedIn() else {
            let errorInfo = [ NSLocalizedDescriptionKey : "you must be logged in to ask a question" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: errorInfo))
            return
        }
        
        let user = PulseUser.currentUser

        let itemKey = itemsRef.childByAutoId().key
        
        let itemPost : [String : Any] = ["title": qText,
                                         "type":"question",
                                         "uID": user.uID!,
                                         "createdAt" : ServerValue.timestamp() as AnyObject]

        let post = ["items/\(itemKey)": itemPost,
                    "userDetailedPublicSummary/\(user.uID!)/items/\(itemKey)":"question",
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
    
    /* RECOMMEND CONTRIBUTOR */
    static func recommendContributorRequest(channel: Channel, applyName: String, applyEmail: String, applyText: String,
                                completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
    
        guard PulseUser.isLoggedIn() else {
            let errorInfo = [ NSLocalizedDescriptionKey : "you must be logged in to recommend contributors" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: errorInfo))
            return
        }
        
        guard let channelID = channel.cID else {
            let errorInfo = [ NSLocalizedDescriptionKey : "please choose a channel first" ]
            completion(false, NSError.init(domain: "Invalidtag", code: 404, userInfo: errorInfo))
            return
        }
        
        let user = PulseUser.currentUser
        
        let post = ["email":applyEmail,
                    "tagID":channelID,
                    "name":applyName,
                    "reason":applyText,
                    "recommenderID": user.uID!]
    
        databaseRef.child("contributorRequests").childByAutoId().updateChildValues(post, withCompletionBlock: { (completionError, ref) in
            if completionError != nil {
                let errorInfo = [ NSLocalizedDescriptionKey : "error sending, please try again!" ]
                completion(false, NSError.init(domain: "Error", code: 404, userInfo: errorInfo))
            } else {
                completion(true, nil)
            }
        })
    }
    
    /* BECOME CONTRIBUTOR */
    static func contributorRequest(channel : Channel, applyText: String, completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
        guard PulseUser.isLoggedIn() else {
            let errorInfo = [ NSLocalizedDescriptionKey : "you must be logged in to apply" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: errorInfo))
            return
        }
        
        guard let channelID = channel.cID else {
            let errorInfo = [ NSLocalizedDescriptionKey : "please select a channel first" ]
            completion(false, NSError.init(domain: "InvalidChannel", code: 404, userInfo: errorInfo))
            return
        }
        
        let user = PulseUser.currentUser
        let verificationPath = databaseRef.child("contributorRequests")
        let post = ["uID":user.uID!,
                    "reason":applyText,
                    "channelID":channelID]
        
        currentUserRef.child("contributorRequests").child(channelID).observeSingleEvent(of: .value, with: { snap in
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
    
    /** MARK INVITE COMPLETED **/
    static func markInviteCompleted(inviteID: String) {
        let invitePost = ["completed" : true]
        messagesRef.child(inviteID).child("type").setValue(nil)
        invitesRef.child(inviteID).updateChildValues(invitePost)
    }
    
    /** INTERVIEW ITEMS **/
    static func declineInterview(interviewItemID: String, interviewParentItem :Item, conversationID: String?, completion: @escaping (_ success : Bool, _ error : NSError?) -> Void) {
        guard let _ = Auth.auth().currentUser else {
            let userInfo = [ NSLocalizedDescriptionKey : "please login" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: userInfo))
            return
        }
        
        guard let fromUser = interviewParentItem.user else {
            let userInfo = [ NSLocalizedDescriptionKey : "couldn't find sender" ]
            completion(false, NSError.init(domain: "IncorrectSender", code: 404, userInfo: userInfo))
            return
        }
        
        let message = Message(from: PulseUser.currentUser, to: fromUser, body: "Sorry! Interview request declined")
        message.mID = conversationID != nil ? conversationID! : interviewParentItem.itemID
        
        PulseDatabase.sendMessage(existing: true, message: message, completion: {(success, conversationID) in
            if success {
                //remove interview type from conversations
                markInviteCompleted(inviteID: interviewItemID)
                messagesRef.child(conversationID!).child("type").setValue(nil)
                
                completion(true, nil)
            } else {
                let errorInfo = [ NSLocalizedDescriptionKey : "error declining interview" ]
                completion(false, NSError.init(domain: "Unknown", code: 404, userInfo: errorInfo))
            }
        })
    }
    
    static func addInterviewToDatabase(interviewItemID: String, interviewParentItem : Item, completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
        guard PulseUser.isLoggedIn() else {
            let userInfo = [ NSLocalizedDescriptionKey : "please login" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: userInfo))
            return
        }
        
        guard interviewParentItem.cID != nil else {
            let errorInfo = [ NSLocalizedDescriptionKey : "error saving to channel" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: errorInfo))
            return
        }
        
        let _user = PulseUser.currentUser
        
        let channelPost : [String : AnyObject] = ["type" : interviewParentItem.type.rawValue as AnyObject,
                                                  "cID" : interviewParentItem.cID as AnyObject,
                                                  "url" : String(describing: interviewParentItem.contentURL) as AnyObject,
                                                  "tagID" : interviewParentItem.tag?.itemID as AnyObject,
                                                  "tagTitle" : interviewParentItem.tag?.itemTitle as AnyObject,
                                                  "title" : interviewParentItem.itemTitle as AnyObject,
                                                  "uID" : _user.uID! as AnyObject,
                                                  "createdAt" : ServerValue.timestamp() as AnyObject]
        
        var collectionPost = ["userDetailedPublicSummary/\(_user.uID!)/items/\(interviewParentItem.itemID)": interviewParentItem.type.rawValue as AnyObject,
                              "items/\(interviewParentItem.itemID)" : channelPost,
                              "channelItems/\(interviewParentItem.cID!)/\(interviewParentItem.itemID)" : channelPost,
                              "invites/\(interviewItemID)/completed": true,
                              "messages/\(interviewItemID)/type" : "message"] as [String : Any]
        
        if let tagID = interviewParentItem.tag?.itemID {
            collectionPost["itemCollection/\(tagID)/\(interviewParentItem.itemID)"] = interviewParentItem.type.rawValue as AnyObject
            collectionPost["channels/\(interviewParentItem.cID!)/tags/\(tagID)/lastCreatedAt"] = ServerValue.timestamp() as AnyObject
        }
        
        databaseRef.updateChildValues(collectionPost , withCompletionBlock: { (blockError, ref) in
            blockError != nil ? completion(false, blockError) : completion(true, nil)
        })
    }
    
    static func createContributorInvite(channel: Channel, type: MessageType, description: String = "", toUser: PulseUser?, toName: String?, toEmail: String? = nil,                                          								completion: @escaping (_ inviteID : String?, _ error : Error?) -> Void) {
        
        guard PulseUser.isLoggedIn()  else {
            let errorInfo = [ NSLocalizedDescriptionKey : "you must be logged in to send invites" ]
            completion(nil, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: errorInfo))
            return
        }
        
        let user = PulseUser.currentUser

        let inviteKey = databaseRef.child("invites").childByAutoId().key

        var channelPost : [String : Any] = ["title" : channel.cTitle ?? "Contributor Invite",
                                            "type" : type.rawValue,
                                            "fromUserID" : user.uID!,
                                            "fromUserName" : user.name ?? "",
                                            "createdAt" : ServerValue.timestamp(),
                                            "cID": channel.cID,
                                            "cTitle": channel.cDescription ?? ""]
        
        var userPost : [String : Any] = ["title" : channel.cTitle ?? "Contributor Invite",
                                         "type" : type.rawValue,
                                         "createdAt" : ServerValue.timestamp()]
        
        //add in toUser
        if let toUser = toUser {
            channelPost["toUserID"] = toUser.uID
            channelPost["toUserName"] = toUser.name ?? ""
            
            userPost["toUserID"] = toUser.uID
            userPost["toUserName"] = toUser.name ?? ""
            
        } else {
            channelPost["toUserName"] = toName ?? toUser?.name
            channelPost["toUserName"] = toName ?? toUser?.name
        }
        
        if let toEmail = toEmail {
            channelPost["toUserEmail"] = toEmail
            userPost["toUserEmail"] = toEmail
        }
        
        if description != "" {
            channelPost["description"] = description
        }

        var collectionPost : [String : Any] = ["invites/\(inviteKey)": channelPost]
        
        if let toUser = toUser, toUser.uID != user.uID! {
            //user is inviting / recommending someone
            collectionPost["users/\(user.uID!)/sentInvites/\(inviteKey)"] = userPost
        } else if let _ = toEmail {
            //user is inviting someone via email
            collectionPost["users/\(user.uID!)/sentInvites/\(inviteKey)"] = userPost

        } else if let toUser = toUser, toUser.uID == user.uID! {
            //user is applying for himself
            let request : [String : Any] = ["inviteID" : inviteKey,
                                            "type" : "contributorInvite"]
            collectionPost["users/\(user.uID!)/pendingInvites/\(channel.cID!)"] = request
        }
        
        databaseRef.updateChildValues(collectionPost, withCompletionBlock: { (completionError, ref) in
            
            completionError == nil ? completion(inviteKey, nil) : completion(nil, completionError)
        })
        
    }
    
    static func updateContributorInvite(status: Bool, inviteID: String, completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
        guard PulseUser.isLoggedIn() else {
            let errorInfo = [ NSLocalizedDescriptionKey : "you must be logged in to send invites" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: errorInfo))
            return
        }
        
        let post : [ String : Any ] = ["accepted" : status]
        
        databaseRef.child("invites/\(inviteID)").updateChildValues(post, withCompletionBlock: {(error, ref) in
            error == nil ? completion(true, nil) : completion(false, error)
        })
    }
    
    static func createInviteRequest(item: Item, type: MessageType, toUser: PulseUser?, toName: String?, toEmail: String? = nil, childItems: [String],
                                    parentItemID: String?, completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
        guard PulseUser.isLoggedIn() else {
            let errorInfo = [ NSLocalizedDescriptionKey : "you must be logged in to apply" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: errorInfo))
            return
        }
        
        let user = PulseUser.currentUser
        
        var itemPost : [String : Any] = ["title" : item.itemTitle,
                                         "type" : type.rawValue,
                                         "fromUserID" : user.uID!,
                                         "fromUserName" : PulseUser.currentUser.name ?? "",
                                         "createdAt" : ServerValue.timestamp(),
                                         "cID": item.cID,
                                         "cTitle": item.cTitle,
                                         "tagID": item.tag?.itemID ?? "",
                                         "tagTitle": item.tag?.itemTitle ?? ""]
        
        var userPost : [String : Any] = ["title" : item.itemTitle,
                                         "type" : type.rawValue,
                                         "createdAt" : ServerValue.timestamp()]
        
        if let parentItemID = parentItemID {
            itemPost["parentItemID"] = parentItemID
        }
        
        //add in the questions
        if !childItems.isEmpty {
            var childItemDetail : [ String : String ] = [:]
            for child in childItems {
                let itemID = databaseRef.child("invites").child(item.itemID).child("items").childByAutoId().key
                childItemDetail[itemID] = child
            }
            
            itemPost["items"] = childItemDetail
        }
        
        //add in toUser
        if let toUser = toUser {
            itemPost["toUserID"] = toUser.uID
            itemPost["toUserName"] = toUser.name ?? ""
            
            userPost["toUserID"] = toUser.uID
            userPost["toUserName"] = toUser.name ?? ""
            
        } else {
            itemPost["toUserName"] = toName ?? toUser?.name
            userPost["toUserName"] = toName ?? toUser?.name
        }
        
        if let toEmail = toEmail {
            itemPost["toUserEmail"] = toEmail
        }
        
        let collectionPost = ["invites/\(item.itemID)": itemPost,
                              "users/\(user.uID!)/sentInvites/\(item.itemID)" : userPost]
        
        databaseRef.updateChildValues(collectionPost, withCompletionBlock: { (completionError, ref) in
            completionError == nil ? completion(true, nil) : completion(false, completionError)
        })
    }
    
    static func addInterviewEmail(interviewID: String, email: String,
                                  completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
        databaseRef.child("invites").child(interviewID).updateChildValues(["toUserEmail":email], withCompletionBlock: { (completionError, ref) in
            if completionError == nil {
                completion(true, nil)
            } else {
                completion(false, completionError)
            }
        })
    }
    /** END INTERVIEW ITEMS **/

    
    /** ADD NEW CHANNEL **/
    static func addNewChannel(cTitle: String, cDescription : String, completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
        guard PulseUser.isLoggedIn() else {
            let errorInfo = [ NSLocalizedDescriptionKey : "you must be logged in to apply" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: errorInfo))
            return
        }
        
        let user = PulseUser.currentUser
        
        let post = ["title": cTitle,
                    "description":cDescription,
                    "fromUserName":user.name ?? "",
                    "fromUserID":user.uID!]
        
        let newChannelRequestID = databaseRef.child("newChannelRequests").childByAutoId().key
        
        let userPost = ["cTitle": cTitle,
                        "cDescription":cDescription,
                        "type" : "newChannel",
                        "requestID" : newChannelRequestID]
        
        let combinedPost : [AnyHashable: Any] =
            ["newChannelRequests/\(newChannelRequestID)": post as AnyObject,
             "users/\(user.uID!)/sentRequests/\(newChannelRequestID)" : userPost]

        
        databaseRef.updateChildValues(combinedPost, withCompletionBlock: { (error, ref) in
            error != nil ? completion(false, error) : completion(true, nil)
        })
    }
    
    /** ADD NEW SERIES TO CHANNEL **/
    static func addNewSeries(channelID: String, item : Item, completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
        
        let itemPost : [String : Any] = ["title" : item.itemTitle,
                                        "description" : item.itemDescription,
                                        "type" : item.type.rawValue,
                                        "uID" : item.itemUserID,
                                        "createdAt" : ServerValue.timestamp(),
                                        "cID":channelID]
        
        let channelPost : [String : Any] = ["title" : item.itemTitle,
                                            "type" : item.type.rawValue,
                                            "lastCreatedAt" : ServerValue.timestamp()]
        
        
        let collectionPost = ["channels/\(channelID)/tags/\(item.itemID)": channelPost,
                              "items/\(item.itemID)" : itemPost]
        
        databaseRef.updateChildValues(collectionPost , withCompletionBlock: { (error, ref) in
            error != nil ? completion(false, error) : completion(true, nil)
        })
    }
    
    /** ADD NEW THREAD TO SERIES **/
    static func addThread(channelID: String, parentItem: Item, item : Item, completion: @escaping (_ success : Bool, _ error : Error?) -> Void) {
        guard PulseUser.isLoggedIn() else {
            let errorInfo = [ NSLocalizedDescriptionKey : "you must be logged in to start a thread" ]
            completion(false, NSError.init(domain: "NotLoggedIn", code: 404, userInfo: errorInfo))
            return
        }
        
        let user = PulseUser.currentUser

        guard item.type != .unknown else {
            let errorInfo = [ NSLocalizedDescriptionKey : "sorry this thread is not valid" ]
            completion(false, NSError.init(domain: "Invalidtag", code: 404, userInfo: errorInfo))
            return
        }
        
        guard user.isVerified(for: Channel(cID: channelID)) else {
            let errorInfo = [ NSLocalizedDescriptionKey : "only verified contributors can start a thread" ]
            completion(false, NSError.init(domain: "NotContributor", code: 404, userInfo: errorInfo))
            return
        }
        
        let itemPost : [String : Any] = ["title" : item.itemTitle,
                                         "description" : item.itemDescription,
                                         "type" : item.type.rawValue,
                                         "uID" : user.uID!,
                                         "createdAt" : ServerValue.timestamp(),
                                         "cID":channelID]
        
        let channelItemsPost : [String : Any] = ["title" : item.itemTitle,
                                                 "tagID" : parentItem.itemID,
                                                 "tagTitle" : parentItem.itemTitle,
                                                 "uID" : user.uID!,
                                                 "createdAt" : ServerValue.timestamp(),
                                                 "type" : item.type.rawValue]
        
        let collectionPost = ["channelItems/\(channelID)/\(item.itemID)": channelItemsPost,
                              "items/\(item.itemID)" : itemPost,
                              "itemCollection/\(parentItem.itemID)/\(item.itemID)": item.type.rawValue] as [String : Any]
        
        databaseRef.updateChildValues(collectionPost , withCompletionBlock: { (error, ref) in
            error != nil ? completion(false, error) : completion(true, nil)
        })
    }
    
    /* STORAGE METHODS */
    static func getItemStorageURL(channelID: String, type: String = "content", fileID : String, completion: @escaping (_ URL : URL?, _ error : NSError?) -> Void) {
        let path = storageRef.child("channels/\(channelID)").child(fileID).child(type)
        
        let _ = path.downloadURL { (URL, error) -> Void in
            error != nil ? completion(nil, error! as NSError?) : completion(URL!, nil)
        }
    }
    
    static func getImage(channelID: String, itemID : String, fileType : FileTypes, maxImgSize : Int64, completion: @escaping (_ data : Data?, _ error : NSError?) -> Void) {
        let path = storageRef.child("channels/\(channelID)").child(itemID).child(fileType.rawValue)
        
        path.getData(maxSize: maxImgSize) { (data, error) -> Void in
            error != nil ? completion(nil, error! as NSError?) : completion(data, nil)
        }
    }
    
    static func getCachedSeriesImage(channelID: String, itemID : String, fileType : FileTypes, completion: @escaping (_ image : UIImage?) -> Void) {
        seriesImageCache.retrieveImage(forKey: itemID, completion: { image, _ in
            if let image = image {
                //return image that was retreived
                completion(image)
            } else {
                getImage(channelID: channelID, itemID : itemID, fileType: fileType, maxImgSize: MAX_IMAGE_FILESIZE, completion: { data, error in
                    if let data = data {
                        //store in DB - return UIImage
                        seriesImageCache.store(data, forKey: itemID)
                        completion(UIImage(data: data))
                    } else {
                        completion(UIImage(named: "pulse-logo"))
                    }
                })
            }
        })
    }
    
    static func getSeriesImage(seriesName: String, fileType : FileTypes, maxImgSize : Int64, completion: @escaping (_ data : Data?, _ error : NSError?) -> Void) {
        let path = storageRef.child("seriesTypes/\(seriesName)").child(fileType.rawValue)
        path.getData(maxSize: maxImgSize) { (data, error) -> Void in
            error != nil ? completion(nil, error! as NSError?) : completion(data, nil)
        }
    }
    
    static func getChannelImage(channelID: String, fileType : FileTypes, maxImgSize : Int64, completion: @escaping (_ data : Data?, _ error : NSError?) -> Void) {
        let path = storageRef.child("channelCovers/\(channelID)").child(fileType.rawValue)
        path.getData(maxSize: maxImgSize) { (data, error) -> Void in
            error != nil ? completion(nil, error! as NSError?) : completion(data, nil)
        }
    }
    
    static func getCachedChannelImage(channelID: String, fileType : FileTypes, completion: @escaping (_ image : UIImage?) -> Void) {
        let channelCache : ImageCache! = fileType == .content ? channelImageCache : channelThumbCache
        
        channelCache.retrieveImage(forKey: channelID, completion: { image, _ in
            if let image = image {
                //return image that was retreived
                completion(image)
            } else {
                getChannelImage(channelID: channelID, fileType: fileType, maxImgSize: MAX_IMAGE_FILESIZE, completion: { data, error in
                    if let data = data {
                        channelCache.store(data, forKey: channelID)
                        completion(UIImage(data: data))
                        //store in DB - return UIImage
                    } else {
                        completion(nil)
                    }
                })
            }
        })
    }
    
    static func clearCaches() {
        channelNavImageCache.clearMemoryCache()
        channelImageCache.clearMemoryCache()
        channelThumbCache.clearMemoryCache()
        userImageCache.clearMemoryCache()
        seriesImageCache.clearMemoryCache()
        
        channelNavImageCache.clearDiskCache()
        channelImageCache.clearDiskCache()
        channelThumbCache.clearDiskCache()
        userImageCache.clearDiskCache()
        seriesImageCache.clearDiskCache()
    }
    
    static func getCachedChannelNavImage(channelID: String, completion: @escaping (_ image : UIImage?) -> Void) {
        
        channelNavImageCache.retrieveImage(forKey: channelID, completion: { image, _ in
            
            if let image = image {
                //return image that was retreived
                completion(image)
            } else {
                getCachedChannelImage(channelID: channelID, fileType: .content, completion: { image in
                    
                    guard let image = image, let filteredImage = image.applyNavImageFilter() else {
                        completion(nil)
                        return
                    }
                    
                    completion(filteredImage)
                    
                    channelNavImageCache.store(filteredImage.highestQualityJPEGNSData, forKey: channelID, toDisk: false)
                })
            }
        })
    }
    
    static func getCachedUserPic(uid: String, completion: @escaping (_ image : UIImage?) -> Void) {
        userImageCache.retrieveImage(forKey: uid, completion: { image, _ in
            if let image = image {
                //return image that was retreived
                completion(image)
            } else {
                let path = storageRef.child("users/\(uid)/thumbPic")
                path.getData(maxSize: MAX_IMAGE_FILESIZE) { (data, error) -> Void in
                    if let data = data {
                        userImageCache.store(data, forKey: uid)
                        completion(UIImage(data: data))
                        //store in DB - return UIImage
                    } else {
                        completion(UIImage(named: "default-profile"))
                    }
                }
            }
        })
    }
    
    static func getProfilePicForUser(user: PulseUser, completion: @escaping (_ image : UIImage?) -> Void) {
        let userPicPath = user.profilePic != nil ? user.profilePic : user.thumbPic
        
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
        if PulseUser.isLoggedIn() {
            if PulseUser.currentUser.savedItems.contains(item) { //remove item
                let _path = getDatabasePath(Element.Users, itemID: PulseUser.currentUser.uID!).child("savedItems/\(item.itemID)")
                _path.setValue("true", withCompletionBlock: { (completionError, ref) in
                    completionError != nil ? completion(false, completionError!) : completion(false, nil)
                })
            } else { //pin item
                let _path = getDatabasePath(Element.Users, itemID: PulseUser.currentUser.uID!).child("savedItems")
                _path.updateChildValues([item.itemID: item.type.rawValue], withCompletionBlock: { (completionError, ref) in
                    PulseUser.currentUser.savedItems.append(item)
                    completionError != nil ? completion(false, completionError) : completion(true, nil)
                })
            }
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "please login to save questions" ]
            completion(false, NSError(domain: "NotLoggedIn", code: 200, userInfo: userInfo))
        }
    }
    
    static func subscribeChannel(_ channel : Channel, completion: @escaping (Bool, NSError?) -> Void) {
        if PulseUser.isLoggedIn() {
            if let savedIndex = PulseUser.currentUser.subscriptionIDs.index(of: channel.cID), let channelID = channel.cID  { //unsubscribe
                let _path = currentUserRef.child("subscriptions/\(channelID)")
                
                _path.setValue(nil, withCompletionBlock: { (completionError, ref) in
                    if completionError != nil {
                        completion(false, completionError as NSError?)
                    } else {
                        if let savedChannelIndex = PulseUser.currentUser.subscriptions.index(of: channel) {
                            PulseUser.currentUser.subscriptions.remove(at: savedChannelIndex)
                        }
                        
                        PulseUser.currentUser.subscriptionIDs.remove(at: savedIndex)

                        completion(true, nil)

                        _path.removeAllObservers()
                    }
                })
                NotificationCenter.default.post(name: Notification.Name(rawValue: "SubscriptionsChanged"), object: self)
                databaseRef.child("channelSubscribers").child(channel.cID).child(PulseUser.currentUser.uID!).setValue(nil)
                
            } else { //subscribe
                let subscriberPost = ["users/\(PulseUser.currentUser.uID!)/subscriptions/\(channel.cID!)":channel.cTitle ?? "",
                            "channelSubscribers/\(channel.cID!)/\(PulseUser.currentUser.uID!)":true] as [String: Any]
                
                databaseRef.updateChildValues(subscriberPost, withCompletionBlock: { (completionError, ref) in
                    if completionError != nil {
                        completion(false, completionError as NSError?)
                    }
                    else {
                        if !PulseUser.currentUser.subscriptionIDs.contains(channel.cID) {
                            PulseUser.currentUser.subscriptionIDs.append(channel.cID)
                            PulseUser.currentUser.subscriptions.append(channel)
                        }
                        
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "SubscriptionsChanged"), object: self)
                        
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
    static func uploadImageData(channelID: String, itemID : String, imageData : Data?, fileType : FileTypes,
                                completion: @escaping (_ metadata: StorageMetadata?, _ error : Error?) -> Void) {
        let path = storageRef.child("channels").child(channelID).child(itemID).child(fileType.rawValue)
        
        if let data = imageData {
            let _metadata = StorageMetadata()
            _metadata.contentType = "image/jpeg"
            
            path.putData(data, metadata: _metadata) { (metadata, error) in
                error != nil ? completion(metadata, error) : completion(metadata, nil)
            }
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "invalid image format" ]
            completion(nil, NSError(domain: "InvalidImage", code: 200, userInfo: userInfo))            
        }
    }
    
    static func uploadImage(channelID: String, itemID : String, image : UIImage, fileType : FileTypes,
                                 completion: @escaping (_ metadata : StorageMetadata?, _ error : Error?) -> Void) {
        
        let path = storageRef.child("channels").child(channelID).child(itemID).child(fileType.rawValue)
        let data = image.mediumQualityJPEGNSData
        let _metadata = StorageMetadata()
        _metadata.contentType = "image/jpeg"
            
        path.putData(data, metadata: _metadata) { (metadata, error) in
            completion(metadata, error)
        }
    }
    
    ///upload image to firebase and update current user with photoURL upon success
    static func uploadProfileImage(_ image : UIImage, completion: @escaping (_ URL : URL?, _ error : Error?) -> Void) {
        var _downloadURL : URL?
        let _metadata = StorageMetadata()
        _metadata.contentType = "image/jpeg"
        
        let imgData = image.mediumQualityJPEGNSData
        
        if PulseUser.isLoggedIn() {
            usersStorageRef.child(PulseUser.currentUser.uID!).child("profilePic").putData(imgData, metadata: _metadata) { (metadata, error) in
                if let metadata = metadata {
                    _downloadURL = metadata.downloadURL()
                    updateUserData(.photoURL, value: String(describing: _downloadURL!)) { success, error in
                        success ? completion(_downloadURL, nil) : completion(nil, error)
                    }
                } else {
                    completion(nil, error)
                }
            }
            
            if let _thumbImageData = image.resizeImage(newWidth: PROFILE_THUMB_WIDTH)?.highQualityJPEGNSData {
                usersStorageRef.child(PulseUser.currentUser.uID!).child("thumbPic").putData(_thumbImageData, metadata: _metadata) { (metadata, error) in
                    if let url = metadata?.downloadURL() {
                        let userPost = ["thumbPic" : String(describing: url)]
                        usersPublicSummaryRef.child(PulseUser.currentUser.uID!).updateChildValues(userPost)
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
        
        return UIImageJPEGRepresentation(newImage!, 0.75)
    }
    
    static func resizeImageHeight(_ image: UIImage, newHeight: CGFloat) -> Data? {
        let scale = newHeight / image.size.height
        let newWidth = image.size.width * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()
        
        return UIImageJPEGRepresentation(newImage!, 0.75)
    }
}
