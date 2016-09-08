//
//  AppDelegate.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import Firebase
import Fabric
import TwitterKit
import FBSDKCoreKit
import FBSDKLoginKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        var initialLoadComplete = false
        // setup firebase, check twitter and facebook tokens to login if available
        FIRApp.configure()
        Fabric.with([Twitter.self()])
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        FBSDKLoginManager.renewSystemCredentials { (result:ACAccountCredentialRenewResult, error:NSError!) -> Void in }
        FBSDKProfile.enableUpdatesOnAccessTokenChange(true)
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        let initialVC = FeedVC()
        self.window?.rootViewController = initialVC
        self.window?.makeKeyAndVisible()
        
        Database.checkCurrentUser { success in
            // get feed and show initial view controller
            if success && !initialLoadComplete {
                initialVC.pageType = .Home
                initialVC.feedItemType = .Question
                initialLoadComplete = true
            }
        }
        return true
    }
    
//    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
//        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
//    }
//
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        if Twitter.sharedInstance().application(app, openURL:url, options: options) {
            return true
        }
        let sourceApplication: String? = options[UIApplicationOpenURLOptionsSourceApplicationKey] as? String
        return FBSDKApplicationDelegate.sharedInstance().application(app, openURL: url, sourceApplication: sourceApplication, annotation: nil)
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

