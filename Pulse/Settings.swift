//
//  Settings.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/28/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import Firebase

class SettingSection {
    var sectionID : String
    var settings : [String]?
    var sectionSettingsCount : Int
    
    struct _setting {
        let id : String
        let orderWeight : Int
    }
    
    init(_sectionID : String, _settings: [String]) {
        self.sectionID = _sectionID
        self.settings = _settings
        self.sectionSettingsCount = _settings.count
    }
    
    init(sectionID : String, snapshot: FIRDataSnapshot) {
        self.sectionID = sectionID
        self.sectionSettingsCount = Int(snapshot.childrenCount)
        
        if snapshot.childrenCount > 0 {
            for settingID in snapshot.children {
                if (self.settings?.append(settingID.key) == nil) {
                    self.settings = [settingID.key]
                }
            }
        }
    }
}

class Setting {
    let settingID : String
    let display : String?
    let type : SettingTypes?
    let editable : Bool?
    let section : SectionTypes?
    
    init(_settingID : String, _display: String, _type: SettingTypes, _editable : Bool, _section : SectionTypes) {
        self.settingID = _settingID
        self.display = _display
        self.type = _type
        self.editable = _editable
        self.section = _section
    }
    
    init(snap : FIRDataSnapshot) {
        self.settingID = snap.key
        
        if snap.hasChild("display") {
            self.display = snap.childSnapshotForPath("display").value as? String
        } else {
            self.display = nil
        }
        
        if snap.hasChild("editable") {
            switch snap.childSnapshotForPath("editable").value as! Bool {
            case true: self.editable = true
            case false: self.editable = false
            }
        } else {
            self.editable = nil
        }
        
        if snap.hasChild("type") {
            self.type = SettingTypes.getSettingType(snap.childSnapshotForPath("type").value as! String)
        } else {
            self.type = nil
        }
        
        if snap.hasChild("section") {
            self.section = SectionTypes.getSectionType(snap.childSnapshotForPath("section").value as! String)
        } else {
            self.section = nil
        }
    }
}
