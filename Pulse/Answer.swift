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
    var aImage : UIImage?
    var thumbImage : UIImage?
    var aType : CreatedAssetType?
    dynamic var aURL : URL! //used to indicate local file location or when upload is completed - do not remove dynamic keyword to allow notification observers
    dynamic var aCreated = false
    
    init(aID: String, qID:String, uID : String, aType : CreatedAssetType, aLocation : String?, aImage : UIImage?, aURL : URL?) {
        self.aID = aID
        self.qID = qID
        self.uID = uID
        self.aType = aType
        self.aLocation = aLocation
        
        if aImage != nil {
            self.aImage = aImage
        }
        
        if aURL != nil {
            self.aURL = aURL!
        }
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
        if snapshot.hasChild("qID") {
            self.qID = snapshot.childSnapshot(forPath: "qID").value as! String
        } else {
            self.qID = ""
        }
        
        if snapshot.hasChild("uID") {
            self.uID = snapshot.childSnapshot(forPath: "uID").value as? String
        }
        
        if snapshot.hasChild("type") {
            self.aType = CreatedAssetType.getAssetType(snapshot.childSnapshot(forPath: "type").value as? String)
        }
        
        if snapshot.hasChild("location") {
            self.aLocation = snapshot.childSnapshot(forPath: "location").value as? String
        }
        
        aCreated = true
    }
}
