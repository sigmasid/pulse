//
//  Message.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/3/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Message {
    var mID : String!
    var from : PulseUser!
    var to : PulseUser!
    var body : String!
    var time : Date!
    var mType : MessageType = .message
    
    init(from : PulseUser, to: PulseUser, body: String) {
        self.from = from
        self.to = to
        self.body = body
    }
    
    init(snapshot : DataSnapshot) {
        self.mID = snapshot.key
        
        if snapshot.hasChild("body") {
            self.body = snapshot.childSnapshot(forPath: "body").value as? String
        }
        
        if snapshot.hasChild("createdAt") {
            let timestamp = snapshot.childSnapshot(forPath: "createdAt").value as! Double
            let convertedDate = Date(timeIntervalSince1970: timestamp / 1000)
            
            self.time = convertedDate
        }
        
        if snapshot.hasChild("fromID") {
            self.from = PulseUser(uID: snapshot.childSnapshot(forPath: "fromID").value as? String)
        }
        
        if snapshot.hasChild("toID") {
            self.to = PulseUser(uID: snapshot.childSnapshot(forPath: "toID").value as? String)
        }
        
        if snapshot.hasChild("type"), let type = snapshot.childSnapshot(forPath: "type").value as? String {
            self.mType = MessageType.getMessageType(type: type)
        } else {
            self.mType = .message
        }
    }
}
