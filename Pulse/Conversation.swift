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
    var cType : ConversationType!

    dynamic var cCreated = false

    init(snapshot : FIRDataSnapshot) {
        super.init()
        if snapshot.hasChild("conversationID") {
            self.cID = snapshot.childSnapshot(forPath: "conversationID").value as? String
        }
        
        if snapshot.hasChild("lastMessageID") {
            self.cLastMessageID = snapshot.childSnapshot(forPath: "lastMessageID").value as? String
        }
        
        if snapshot.hasChild("lastMessage") {
            self.cLastMessage = snapshot.childSnapshot(forPath: "lastMessage").value as? String
        }
        
        if snapshot.hasChild("type"), let type = snapshot.childSnapshot(forPath: "type").value as? String {
            switch type {
            case "interviewInvite":
                self.cType = .interviewInvite
            case "channelInvite":
                self.cType = .channelInvite
            default:
                self.cType = .message
            }
        } else {
            self.cType = .message
        }
        
        if snapshot.hasChild("lastMessageTime") {
            let timestamp = snapshot.childSnapshot(forPath: "lastMessageTime").value as! Double
            let convertedDate = Date(timeIntervalSince1970: timestamp / 1000)

            self.cLastMessageTime = convertedDate
        }

        self.cUser = User(uID: snapshot.key)
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
