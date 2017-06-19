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
class AppDelegate: UIResponder, UIApplicationDelegate, FirstLaunchDelegate {

    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    lazy var firstLoadVC :FirstLoadVC! = FirstLoadVC()
    
    var firstLaunchComplete : Bool = UserDefaults.standard.bool(forKey: "firstLaunchComplete")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Register for remote notifications. Check if permissions have been shown before registering.
        if GlobalFunctions.hasAskedNotificationPermission {
            registerForNotifications(application: application)
        }
        
        // setup firebase, check twitter and facebook tokens to login if available
        FirebaseOptions.defaultOptions()?.deepLinkURLScheme = "co.checkpulse.pulse"
        FirebaseApp.configure()
        
        Fabric.with([Twitter.self()])
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        FBSDKLoginManager.renewSystemCredentials { (result:ACAccountCredentialRenewResult, error:Error?) -> Void in }
        FBSDKProfile.enableUpdates(onAccessTokenChange: true)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        let masterTabVC = MasterTabVC()
        
        if !firstLaunchComplete {
            masterTabVC.showAppIntro = true
            masterTabVC.introDelegate = self
        }
        
        window?.rootViewController = masterTabVC
        window?.makeKeyAndVisible()
        
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
        let dynamicLink = DynamicLinks.dynamicLinks()?.dynamicLink(fromCustomSchemeURL: url)
        if let dynamicLinkURL = dynamicLink?.url, let masterTabVC = self.window?.rootViewController as? MasterTabVC {
            masterTabVC.handleLink(link: dynamicLinkURL)
            return true
        }
        
        return false
    }
    
    //FOR HANDLING UNIVERSAL LINKS
    @available(iOS 8.0, *)
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard let dynamicLinks = DynamicLinks.dynamicLinks() else { return false }
        
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

    func applicationDidBecomeActive(_ application: UIApplication) {
        connectToFcm()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        PulseDatabase.cleanupListeners()
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
        if let refreshedToken = InstanceID.instanceID().token() {
            PulseDatabase.updateNotificationToken(tokenID: refreshedToken)
        }
        
        // Connect to FCM since connection may have failed when attempted before having a token.
        connectToFcm()
    }
    // [END refresh_token]
    
    func registerForNotifications(application: UIApplication) {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            
            // For iOS 10 data message (sent via FCM)
            Messaging.messaging().delegate = self
            
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        application.registerForRemoteNotifications()
    }
    
    // [START connect_to_fcm]
    func connectToFcm() {
        // Won't connect since there is no token
        guard InstanceID.instanceID().token() != nil else {
            return
        }
        
        Messaging.messaging().shouldEstablishDirectChannel = true
    }
    
    // [END connect_to_fcm]
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        PulseDatabase.updateNotificationToken(tokenID: nil)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if let tokenID = InstanceID.instanceID().token() {
            PulseDatabase.updateNotificationToken(tokenID: tokenID)
        }
        // With swizzling disabled you must set the APNs token here.
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func doneWithIntro(mode : IntroType) {
        let defaults = UserDefaults.standard

        defaults.setValue(true, forKey: "firstLaunchComplete")
        print(defaults.bool(forKey: "firstLaunchComplete"))
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
extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        
    }
    
    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        let userInfo = remoteMessage.appData
        
        if let linkString = userInfo["link"] as? String, let linkURL = URL(string: linkString), let masterTabVC = self.window?.rootViewController as? MasterTabVC {
            masterTabVC.handleLink(link: linkURL)
        }
    }
    
    func application(received remoteMessage: MessagingRemoteMessage) {
        let userInfo = remoteMessage.appData
        
        if let linkString = userInfo["link"] as? String, let linkURL = URL(string: linkString), let masterTabVC = self.window?.rootViewController as? MasterTabVC {
            masterTabVC.handleLink(link: linkURL)
        }
    }
    
    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
    }
}
// [END ios_10_data_message_handling]

