//
//  Message.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/3/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Message : NSObject {
    var mID : String!
    var from : User!
    var to : User!
    var body : String!
    var time : Date!
    
    init(from : User, to: User, body: String) {
        self.from = from
        self.to = to
        self.body = body
    }
    
    init(snapshot : FIRDataSnapshot) {
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
            self.from = User(uID: snapshot.childSnapshot(forPath: "fromID").value as? String)
        }
        
        if snapshot.hasChild("toID") {
            self.to = User(uID: snapshot.childSnapshot(forPath: "toID").value as? String)
        }
    }
}
