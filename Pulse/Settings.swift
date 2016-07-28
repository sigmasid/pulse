//
//  Settings.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/28/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import Firebase

class Settings : NSObject {
    var activity : [String]?
    var personalInfo : [String]?
    var sections = [Int : String]()
    var sectionCount : Int?
    
    override init() {
        super.init()
        self.activity = nil
        self.personalInfo = nil
    }
    
    init(activity: [String], personalInfo: [String]) {
        super.init()
        self.activity = activity
        self.personalInfo = personalInfo
    }
    
    init(snapshot: FIRDataSnapshot) {
        super.init()
        self.sectionCount = Int(snapshot.childrenCount)
        
        if snapshot.childrenCount > 0 {
            var index = 0
            for section in snapshot.children {
                self.sections[index] = section.key
                index += 1
            }
        }
    
        if snapshot.hasChild("activity") {
            for activity in snapshot.childSnapshotForPath("activity").children {
                if (self.activity?.append(activity.key) == nil) {
                    self.activity = [activity.key]
                }
            }
        }
        
        if snapshot.hasChild("personalInfo") {
            for info in snapshot.childSnapshotForPath("personalInfo").children {
                if (self.personalInfo?.append(info.key) == nil) {
                    self.personalInfo = [info.key]
                }
            }
        }
    }
}
