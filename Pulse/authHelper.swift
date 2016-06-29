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
            let token = FBSDKAccessToken.currentAccessToken().tokenString
            let credential = FIRFacebookAuthProvider.credentialWithAccessToken(token)
            FIRAuth.auth()?.signInWithCredential(credential) { (aUser, error) in
                if error != nil {
                    print(error?.localizedDescription)
                } else {
                    if let _aUser = aUser {
                        self.createUser(_aUser.uid, realName: _aUser.displayName!)
                        completion(result : true)
                    }
                }
            }
        } else if let session = Twitter.sharedInstance().sessionStore.session() {
            let credential = FIRTwitterAuthProvider.credentialWithToken(session.authToken, secret: session.authTokenSecret)
            FIRAuth.auth()?.signInWithCredential(credential) { (aUser, error) in
                if let _aUser = aUser {
                    self.createUser(_aUser.uid, uScreenName: _aUser.displayName!)
                    completion(result : true)
                }
            }
        } else {
            completion(result: false)
        }
    }
    
    static func createUser(uID: String) {
        User.currentUser.uID = uID
    }
    
    static func createUser(uID: String, realName: String) {
        User.currentUser.uID = uID
        User.currentUser.screenName = realName
    }
    
    static func createUser(uID: String, uScreenName: String) {
        User.currentUser.uID = uID
        User.currentUser.screenName = uScreenName
    }
}


