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
    var settings = [String]()
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
            var unsortedSettings = [String : Int]()
            for settingID in snapshot.children {
                if let settingID = settingID as? FIRDataSnapshot, let settingValue = settingID.value as? Int {
                    unsortedSettings[settingID.key] = settingValue
                }
            }
            let sortedDict = unsortedSettings.sorted{ $0.value < $1.value }
            self.settings = sortedDict.map({$0.key})
        }
    }
}

class Setting {
    let settingID : String
    let display : String?
    let type : SettingTypes?
    let editable : Bool
    let section : String?
    let longDescription : String?
    let placeholder : String?
    let options : [String]?
    
    init(_settingID : String, _display: String, _type: SettingTypes, _editable : Bool, _section : String) {
        self.settingID = _settingID
        self.display = _display
        self.type = _type
        self.editable = _editable
        self.section = _section
        self.longDescription = nil
        self.placeholder = nil
        self.options = nil
    }
    
    init(snap : FIRDataSnapshot) {
        self.settingID = snap.key
        
        if snap.hasChild("display") {
            self.display = snap.childSnapshot(forPath: "display").value as? String
        } else {
            self.display = nil
        }
        
        if snap.hasChild("editable") {
            switch snap.childSnapshot(forPath: "editable").value as! Bool {
            case true: self.editable = true
            case false: self.editable = false
            }
        } else {
            self.editable = false
        }
        
        if snap.hasChild("type") {
            self.type = SettingTypes.getSettingType(snap.childSnapshot(forPath: "type").value as! String)
        } else {
            self.type = nil
        }
        
        if snap.hasChild("section") {
            self.section = snap.childSnapshot(forPath: "section").value as? String
        } else {
            self.section = nil
        }
        
        if snap.hasChild("longDescription") {
            self.longDescription = snap.childSnapshot(forPath: "longDescription").value as? String
        } else {
            self.longDescription = nil
        }
        
        if snap.hasChild("placeholder") {
            self.placeholder = snap.childSnapshot(forPath: "placeholder").value as? String
        } else {
            self.placeholder = nil
        }
        
        if snap.hasChild("choices") {
            self.options = [String]()
            for option in snap.childSnapshot(forPath: "choices").children {
                self.options?.append((option as AnyObject).key)
            }
        } else {
            self.options = nil
        }
    }
}
