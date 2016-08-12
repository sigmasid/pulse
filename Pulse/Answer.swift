//
//  answer.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import Firebase

class Answer : NSObject {
    var aID : String
    var qID : String
    var uID : String?
    var aLocation : String?
    dynamic var aURL : NSURL! //used to indicate when upload is completed - do not remove dynamic keyword to allow notification observers
    
    init(aID: String, qID:String, uID : String, aURL : NSURL) {
        self.aID = aID
        self.qID = qID
        self.uID = uID
        self.aURL = aURL
    }
    
    init(aID: String, qID:String, aURL : NSURL) {
        self.aID = aID
        self.qID = qID
        self.aURL = aURL
    }
    
    init(aID: String, qID:String, uID : String) {
        self.aID = aID
        self.qID = qID
        self.uID = uID
    }
    
    init(aID: String, qID:String) {
        self.aID = aID
        self.qID = qID
    }
    
    init(aID: String, snapshot: FIRDataSnapshot) {
        self.aID = aID
        self.qID = snapshot.childSnapshotForPath("qID").value as! String
        if snapshot.hasChild("uID") {
            self.uID = snapshot.childSnapshotForPath("uID").value as? String
        }
        
        if snapshot.hasChild("location") {
            self.aLocation = snapshot.childSnapshotForPath("location").value as? String
        }

    }
}