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
    var cUser : PulseUser!
    var cID : String!
    
    var cLastMessageID : String!
    var cLastMessage : String?
    var cLastMessageTime : Date!
    var cLastMessageType : MessageType!
    var cLastMessageSender : PulseUser!

    dynamic var cCreated = false

    init(snapshot : DataSnapshot) {
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
        
        if snapshot.hasChild("lastMessageSender") {
            self.cLastMessageSender = PulseUser(uID: snapshot.childSnapshot(forPath: "lastMessageSender").value as? String)
        }
        
        if snapshot.hasChild("lastMessageType"), let type = snapshot.childSnapshot(forPath: "lastMessageType").value as? String {
            switch type {
            case "interviewInvite":
                self.cLastMessageType = .interviewInvite
            case "channelInvite":
                self.cLastMessageType = .channelInvite
            case "perspectiveInvite":
                self.cLastMessageType = .perspectiveInvite
            case "questionInvite":
                self.cLastMessageType = .questionInvite
            case "showcaseInvite":
                self.cLastMessageType = .showcaseInvite
            case "contributorInvite":
                self.cLastMessageType = .contributorInvite
            default:
                self.cLastMessageType = .message
            }
        } else {
            self.cLastMessageType = .message
        }
        
        if snapshot.hasChild("lastMessageTime") {
            let timestamp = snapshot.childSnapshot(forPath: "lastMessageTime").value as! Double
            let convertedDate = Date(timeIntervalSince1970: timestamp / 1000)

            self.cLastMessageTime = convertedDate
        }

        self.cUser = PulseUser(uID: snapshot.key)
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
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Conversation {
            return self.cID == object.cID
        } else {
            return false
        }
    }
}
