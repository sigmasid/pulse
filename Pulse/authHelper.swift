//
//  authHelper.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import TwitterKit
import FBSDKLoginKit
import FirebaseAuth

class AuthHelper {
    static func checkSocialTokens(completion: (result: Bool) -> Void) {
        if FBSDKAccessToken.currentAccessToken() != nil {
            print("have fb token")
            let token = FBSDKAccessToken.currentAccessToken().tokenString
            let credential = FIRFacebookAuthProvider.credentialWithAccessToken(token)
            FIRAuth.auth()?.signInWithCredential(credential) { (aUser, error) in
                if error != nil {
                    print(error?.localizedDescription)
                } else {
                    if let _aUser = aUser {
                        self.createUser(_aUser.uid, name: _aUser.displayName!, pic: _aUser.photoURL)
                        completion(result : true)
                    } else {
                        completion(result : false)
                    }
                }
            }
        } else if let session = Twitter.sharedInstance().sessionStore.session() {
//            try! FIRAuth.auth()!.signOut()
//            Twitter.sharedInstance().sessionStore.logOutUserID(session.userID)
            print("have twitter token")
            let credential = FIRTwitterAuthProvider.credentialWithToken(session.authToken, secret: session.authTokenSecret)
            FIRAuth.auth()?.signInWithCredential(credential) { (aUser, error) in
                if error != nil {
                    print(error?.code)
                } else {
                    if let _aUser = aUser {
                        self.createUser(_aUser.uid, name: _aUser.displayName!, pic: _aUser.photoURL)
                        completion(result : true)
                    } else {
                        completion(result : false)
                    }
                }
            }
        } else {
            completion(result: false)
        }
    }
    
    static func createUser(uID: String) {
        User.currentUser.uID = uID
    }
    
    static func createUser(uID: String, name: String) {
        User.currentUser.uID = uID
        User.currentUser.name = name
    }
    
    static func createUser(uID: String, name: String, pic: NSURL?) {
        User.currentUser.uID = uID
        User.currentUser.name = name
        if let _pic = pic {
            User.currentUser.profilePic = String(_pic)
        }
    }
}


