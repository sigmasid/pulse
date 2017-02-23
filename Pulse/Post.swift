//
//  Post.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/19/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import Foundation
import Firebase

class Post : NSObject {
    var pID : String
    var uID : String?
    var tagID : String?
    var cID : String?

    var pDescription : String?
    var pLocation : String?
    var pCoverImage : UIImage?
    var pType : CreatedAssetType?
    var pContent = [String : String]()
    
    dynamic var pURL : URL! //used to indicate local file location or when upload is completed - do not remove dynamic keyword to allow notification observers
    dynamic var pCreated = false
    
    init(pID: String, tagID:String, cID: String, uID : String, pType : CreatedAssetType, pLocation : String?, pCoverImage : UIImage?, pURL : URL?) {
        self.pID = pID
        self.tagID = tagID
        self.cID = cID
        self.uID = uID
        self.pType = pType
        self.pLocation = pLocation
        self.pCoverImage = pCoverImage
    }
    
    init(aID: String, tagID:String, uID : String, cID : String) {
        self.pID = aID
        self.tagID = tagID
        self.uID = uID
        self.cID = cID
    }
    
    init(pID: String, snapshot: FIRDataSnapshot) {
        self.pID = pID
        
        if snapshot.hasChild("tagID") {
            self.tagID = snapshot.childSnapshot(forPath: "tagID").value as? String
        }
        
        if snapshot.hasChild("cID") {
            self.cID = snapshot.childSnapshot(forPath: "qID").value as? String
        }
        
        if snapshot.hasChild("uID") {
            self.uID = snapshot.childSnapshot(forPath: "uID").value as? String
        }
        
        if snapshot.hasChild("type") {
            self.pType = CreatedAssetType.getAssetType(snapshot.childSnapshot(forPath: "type").value as? String)
        }
        
        if snapshot.hasChild("cover") {
            self.pURL = URL(string:snapshot.childSnapshot(forPath: "cover").value as! String)
        }
        
        if snapshot.hasChild("location") {
            self.pLocation = snapshot.childSnapshot(forPath: "location").value as? String
        }
        
        pCreated = true
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Post {
            return pID == object.pID
        } else {
            return false
        }
    }
}
