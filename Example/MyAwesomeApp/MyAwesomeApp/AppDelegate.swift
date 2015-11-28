//
//  AppDelegate.swift
//  MyAwesomeApp
//
//  Created by A Ben Moussa on 11/28/15.
//  Copyright © 2015 Adil Ben Moussa. All rights reserved.
//

import UIKit
import ABReviewReminder

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        let options:[ABReviewReminderOptions : AnyObject] =
        [
            ABReviewReminderOptions.Debug: true,
            ABReviewReminderOptions.Delegate: self,
            ABReviewReminderOptions.DaysUntilPrompt: 10,
            ABReviewReminderOptions.UsesUntilPrompt: 2,
            ABReviewReminderOptions.AppVersionType: "CFBundleShortVersionString"
        ]
        
        let strings:[ABAlertStrings : String] =
        [
            ABAlertStrings.AlertTitle: "My custom alert title",
            ABAlertStrings.AlertMessage: "My custom alert message",
            ABAlertStrings.AlertDeclineTitle: "My custom decline button title",
            ABAlertStrings.AlertRateTitle: "My custom rate button title",
            ABAlertStrings.AlertRateLaterTitle: "My custom rate later button title"
        ]
        
        let customAlertAction = UIAlertAction(title: "My Custom action", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("My Custom action button clicked.")
        })
        
        
        //option 1
        /*
        ABReviewReminder.startSession("12345678")
        ABReviewReminder.addAlertAction(customAlertAction, atIndex: 1)
        ABReviewReminder.appLaunched()
        */
        
        //option 2
        /*
        ABReviewReminder.startSession("12345678", withOptions: options)
        ABReviewReminder.addAlertAction(customAlertAction, atIndex: 1)
        ABReviewReminder.appLaunched()
        */
        
        //option 3
        ABReviewReminder.startSession("12345678", withOptions: options, strings: strings)
        ABReviewReminder.addAlertAction(customAlertAction, atIndex: 1)
        ABReviewReminder.appLaunched()
        
        return true
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

