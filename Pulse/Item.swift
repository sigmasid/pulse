//
//  Item.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/18/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import Foundation
import FirebaseDatabase

enum ItemTypes {
    case qa
    case post
}

class Item: NSObject {
    var itemID: String!
    var itemTitle : String!
    var itemType : ItemTypes?
    var itemImage : String?
    var itemContent : Any?
    
    init(itemID: String) {
        self.itemID = itemID
    }
    
    init(itemID: String, type: String) {
        self.itemID = itemID
        
        if type == "qa" {
            self.itemType = .qa
        } else if type == "post" {
            self.itemType = .post
        }
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Item {
            return itemID == object.itemID
        } else {
            return false
        }
    }
}
