//
//  answer.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation

class Answer : NSObject {
    var aID : String
    var qID : String
    var uID : String?
    var aLocation : String?
    dynamic var aURL : NSURL!
    
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
}