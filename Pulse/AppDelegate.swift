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
import FirebaseDynamicLinks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // setup firebase, check twitter and facebook tokens to login if available
        
        FIROptions.default().deepLinkURLScheme = "co.checkpulse.pulse"
        FIRApp.configure()
        Fabric.with([Twitter.self()])
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        FBSDKLoginManager.renewSystemCredentials { (result:ACAccountCredentialRenewResult, error:Error?) -> Void in }
        FBSDKProfile.enableUpdates(onAccessTokenChange: true)
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let initialVC = MasterTabVC()
        self.window?.rootViewController = initialVC
        self.window?.makeKeyAndVisible()
        
        return true
    }
    
//    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
//        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
//    }
//
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {

        let TwitterDidHandle = Twitter.sharedInstance().application(app, open:url, options: options)
        
        let sourceApplication: String? = options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String
        let FBDidHandle = FBSDKApplicationDelegate.sharedInstance()
                            .application(app,
                            open: url,
                            sourceApplication: sourceApplication,
                            annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        
        let DeepLinkDidHandle =  application(app, open: url, sourceApplication: nil, annotation: [:])
        
        return TwitterDidHandle || FBDidHandle || DeepLinkDidHandle
        
        
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        let dynamicLink = FIRDynamicLinks.dynamicLinks()?.dynamicLink(fromCustomSchemeURL: url)
        if let dynamicLink = dynamicLink {
            return true
        }
        
        return false
    }
    
    @available(iOS 8.0, *)
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard let dynamicLinks = FIRDynamicLinks.dynamicLinks() else {
            return false
        }
        let handled = dynamicLinks.handleUniversalLink(userActivity.webpageURL!) { (dynamiclink, error) in
        }
        
        return handled
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        Database.cleanupListeners() 
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

