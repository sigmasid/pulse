//
//  globalRefs.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage

let storage = FIRStorage.storage()
let storageRef = storage.referenceForURL("gs://beacon-camera.appspot.com")
let databaseRef = FIRDatabase.database().reference()