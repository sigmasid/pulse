//
//  Channel.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/18/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import Foundation
import FirebaseDatabase
import UIKit

class Channel : NSObject {
    var cID: String!
    var cTitle : String?
    var cDescription : String?
    
    var tags = [Item]()
    var contributors = [PulseUser]()
    var items = [Item]()
    
    var cNavImage: UIImage?
    var cThumbImage : UIImage?
    var cPreviewImage : UIImage?
    
    var cImageURL : String?
    
    dynamic var cCreated = false
    dynamic var cDetailedCreated = false
    
    init(cID: String) {
        self.cID = cID
    }
    
    init(cID: String, title: String?) {
        self.cID = cID
        self.cTitle = title
    }

    init(cID: String, snapshot: DataSnapshot) {
        self.cID = cID
        super.init()
        
        if let _title = snapshot.childSnapshot(forPath: "title").value as? String {
            self.cTitle = _title
        }
        
        if let _description = snapshot.childSnapshot(forPath: "description").value as? String {
            self.cDescription = _description
        }
        
        if let _imageURL = snapshot.childSnapshot(forPath: "url").value as? String {
            self.cImageURL = _imageURL
        }
        
        for tag in snapshot.childSnapshot(forPath: "tags").children {
            if let tag = tag as? DataSnapshot, let type = tag.childSnapshot(forPath: "type").value as? String {
                let _tag = Item(itemID: (tag as AnyObject).key, type: type)
                _tag.itemTitle = tag.childSnapshot(forPath: "title").value as? String ?? ""
                
                if let _createdAt = tag.childSnapshot(forPath: "lastCreatedAt").value as? Double {
                    let convertedDate = Date(timeIntervalSince1970: _createdAt / 1000)
                    _tag.createdAt = convertedDate
                }
                
                self.tags.append(_tag)
            }
        }
        
        self.cCreated = true
    }
    
    func updateChannel(detailedSnapshot : DataSnapshot) {
        for child in detailedSnapshot.children {
            let currentItem = Item(itemID: (child as AnyObject).key, snapshot: child as! DataSnapshot)
            currentItem.cID = self.cID
            currentItem.cTitle = self.cTitle
            items.append(currentItem)
        }
        items.reverse()
        cDetailedCreated = true
    }

    func createShareLink(completion: @escaping (URL?) -> Void) {
        guard let cID = self.cID else {
            completion(nil)
            return
        }
        
        PulseDatabase.createShareLink(item: self, linkString: "c/"+cID, completion: { link in
            completion(link)
        })
    }
    
    func getNavImage() -> UIImage? {
        guard cNavImage == nil else {
            return cNavImage
        }
        
        guard let image = cPreviewImage else {
            return cThumbImage
        }
        
        let cropRect = CGRect(x: 0, y: 30, width: image.size.width, height: 130)
        let resizedImage = GlobalFunctions.resizeImage(image: image, newWidth: UIScreen.main.fixedCoordinateSpace.bounds.width * 1.2)
        let croppedImage = GlobalFunctions.cropImage(image: resizedImage, toRect: cropRect)
        cNavImage = GlobalFunctions.processImage(croppedImage)
        
        return cNavImage
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Channel {
            return cID == object.cID
        } else {
            return false
        }
    }
}
