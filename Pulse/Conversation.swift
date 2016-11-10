//
//  Conversation.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/13/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Conversation : NSObject {
    var cUser : User!
    var cID : String!
    var cLastMessageID : String!
    var cLastMessage : String?
    var cLastMessageTime : Date!
    
    dynamic var cCreated = false

    init(snapshot : FIRDataSnapshot) {
        if snapshot.hasChild("conversationID") {
            self.cID = snapshot.childSnapshot(forPath: "conversationID").value as? String
        }
        
        if snapshot.hasChild("lastMessageID") {
            self.cLastMessageID = snapshot.childSnapshot(forPath: "lastMessageID").value as? String
        }
        
        if snapshot.hasChild("lastMessage") {
            self.cLastMessage = snapshot.childSnapshot(forPath: "lastMessage").value as? String
        }
        
        if snapshot.hasChild("lastMessageTime") {
            let timestamp = snapshot.childSnapshot(forPath: "lastMessageTime").value as! Double
            let convertedDate = Date(timeIntervalSince1970: timestamp / 1000)

            self.cLastMessageTime = convertedDate
        }

        self.cUser = User(uID: snapshot.key)
    }
    
    func getLastMessage(completion: @escaping (Message?) -> Void) {
        if cLastMessageID != nil {
            Database.getMessage(mID: cLastMessageID, completion: { message in
                completion(message)
            })
        }
    }
    
    func getConversationUser(uID : String, completion: @escaping (User?) -> Void) {
        Database.getUser(uID, completion: { (user, error) in
            error != nil ? completion(user) : completion(nil)
        })
    }
    
    func getLastMessageTime() -> String? {
        if cLastMessageTime != nil {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            let stringDate : String = formatter.string(from: self.cLastMessageTime)
            return stringDate
        } else {
            return nil
        }
    }
}
