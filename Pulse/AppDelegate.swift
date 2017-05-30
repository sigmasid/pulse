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
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Register for remote notifications. This shows a permission dialog on first run, to
        // show the dialog at a more appropriate time move this registration accordingly.
        // [START register_for_notifications]
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            
            // For iOS 10 data message (sent via FCM)
            FIRMessaging.messaging().remoteMessageDelegate = self
            
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        // setup firebase, check twitter and facebook tokens to login if available
        FIROptions.default().deepLinkURLScheme = "co.checkpulse.pulse"
        FIRApp.configure()
        Fabric.with([Twitter.self()])
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        FBSDKLoginManager.renewSystemCredentials { (result:ACAccountCredentialRenewResult, error:Error?) -> Void in }
        FBSDKProfile.enableUpdates(onAccessTokenChange: true)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = MasterTabVC()
        window?.makeKeyAndVisible()
        
        
        // [START add_token_refresh_observer]
        // Add observer for InstanceID token refresh callback.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.tokenRefreshNotification),
                                               name: .firInstanceIDTokenRefresh,
                                               object: nil)
        // [END add_token_refresh_observer]
        
        return true
    }

    //CHECKS IF LINK CAN BE HANDLED BY FB, TWTR OR DYNAMIC LINKS AND RETURNS TRUE IF YES
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
    
    //HANDLE FIREBASE DYNAMIC LINKS
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        let dynamicLink = FIRDynamicLinks.dynamicLinks()?.dynamicLink(fromCustomSchemeURL: url)
        if let dynamicLinkURL = dynamicLink?.url, let masterTabVC = self.window?.rootViewController as? MasterTabVC {
            masterTabVC.handleLink(link: dynamicLinkURL)
            return true
        }
        
        return false
    }
    
    //FOR HANDLING UNIVERSAL LINKS
    @available(iOS 8.0, *)
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard let dynamicLinks = FIRDynamicLinks.dynamicLinks() else { return false }
        
        let handled = dynamicLinks.handleUniversalLink(userActivity.webpageURL!) { (dynamiclink, error) in
            if let dynamicLinkURL = dynamiclink?.url, let masterTabVC = self.window?.rootViewController as? MasterTabVC {
                masterTabVC.handleLink(link: dynamicLinkURL)
            }
        }
        
        return handled
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        FIRMessaging.messaging().disconnect()
        
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        connectToFcm()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        Database.cleanupListeners() 
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        
        if let linkString = userInfo["link"] as? String, let linkURL = URL(string: linkString), let masterTabVC = self.window?.rootViewController as? MasterTabVC {
            masterTabVC.handleLink(link: linkURL)
        }
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    // [START refresh_token]
    func tokenRefreshNotification(_ notification: Notification) {
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            Database.updateNotificationToken(tokenID: refreshedToken)
        }
        
        // Connect to FCM since connection may have failed when attempted before having a token.
        connectToFcm()
    }
    // [END refresh_token]
    
    // [START connect_to_fcm]
    func connectToFcm() {
        // Won't connect since there is no token
        guard FIRInstanceID.instanceID().token() != nil else {
            return
        }
        
        // Disconnect previous FCM connection if it exists.
        FIRMessaging.messaging().disconnect()
        
        FIRMessaging.messaging().connect { (error) in
        }
    }
    // [END connect_to_fcm]
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Database.updateNotificationToken(tokenID: nil)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if let tokenID = FIRInstanceID.instanceID().token() {
            Database.updateNotificationToken(tokenID: tokenID)
        }
        // With swizzling disabled you must set the APNs token here.
        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.sandbox)
    }
}

// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        if let linkString = userInfo["link"] as? String, let linkURL = URL(string: linkString), let masterTabVC = self.window?.rootViewController as? MasterTabVC {
            masterTabVC.handleLink(link: linkURL)
        }
        
        // Change this to your preferred presentation option
        completionHandler([])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        if let linkString = userInfo["link"] as? String, let linkURL = URL(string: linkString), let masterTabVC = self.window?.rootViewController as? MasterTabVC {
            masterTabVC.handleLink(link: linkURL)
        }
        
        completionHandler()
    }
}
// [END ios_10_message_handling]

// [START ios_10_data_message_handling]
extension AppDelegate : FIRMessagingDelegate {
    // Receive data message on iOS 10 devices while app is in the foreground.
    func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
        let userInfo = remoteMessage.appData
        
        if let linkString = userInfo["link"] as? String, let linkURL = URL(string: linkString), let masterTabVC = self.window?.rootViewController as? MasterTabVC {
            masterTabVC.handleLink(link: linkURL)
        }
    }
}
// [END ios_10_data_message_handling]

