/*
ABReviewReminder.swift
ABReviewReminder is a utility that reminds the iPhone and iPad app users to review your app.

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

*
* Created by Adil Ben Moussa on 11/28/2015.
* https://github.com/adilbenmoussa
* Copyright 2015 Adil Ben Moussa. All rights reserved.
*/

import SystemConfiguration

////////////////////////////////////////
//   ABReviewReminder Delegate        //
////////////////////////////////////////
@objc
public protocol ABReviewReminderDelegate {
    
    // called when the use clicks on the rate app button
    optional func userDidOptToRate()
    
    // called when the use clicks on the decline rate app button
    optional func userDidDeclineToRate()
    
    // called when the use clicks on the remind me later button
    optional func userDidOptToRemindLater()
    
    // called when network status changes
    optional func reachabilityChangedWithNetworkStatus(newNetworkStatus: String)
}

// List of the possible options to use
public enum ABReviewReminderOptions : Int {
    /**
     * Debug (Bool | Optional) If set the alert will be shown every time the app starts
     * WARNING: don't forget to set debug flag back to false when deploying to production
     * Default is false.
     */
    case Debug
    
    /**
     * Delegate (ABReviewReminderDelegate | Optional) If set the ABReviewReminder events will be delegated
     * Default is nil.
     */
    case Delegate
    
    /**
     * DaysUntilPrompt (Int | Optional) The amount of days to wait to show the alert for a specific version of the app
     * Default is 30.
     */
    case DaysUntilPrompt
    
    /**
     * UsesUntilPrompt (Int | Optional) If set the alert will be shown every time the app starts
     * An example of a 'use' would be if the user launched the app. Bringing the app
     * into the foreground (on devices that support it) would also be considered
     * a 'use'. You tell ABReviewReminder about these events using the two methods:
     * ABReviewReminder.appLaunched() and when app triggers the UIApplicationWillEnterForegroundNotification event
     *
     *
     * Users need to 'use' the same version of the app this many times before
     * before they will be prompted to rate it.
     * Default is 20.
     */
    case UsesUntilPrompt
    
    /*
    * TimeBeforeReminding (Int | Optional) Once the rating alert is presented to the user, they might select
    *'Remind me later'. This value specifies how long (in days) ABReviewReminder
    * will wait before reminding them.
    * Default is 1.
    */
    case TimeBeforeReminding
    
    /**
     * AppVersionType (String | Optional) The app version type ABReviewReminder will track. Default the major version "CFBundleVersion"
     * Options: ["CFBundleVersion", "CFBundleShortVersionString"]
     * Default is "CFBundleVersion".
     */
    case AppVersionType
    
    /**
     * UseMainBundle (Bool | Optional) If set to true, the main bundle will always be used to load localized strings.
     * Set this to true if you have provided your own custom localizations in ABReviewReminderLocalizable.strings
     * in your main bundle.  
     * Default is false.
     */
    case UseMainBundle
}

// List of the possible Alert string overrides
public enum ABAlertStrings : Int {
    
    // This is the title of the message alert that users will see.
    case AlertTitle
    
    // This is the message your users will see once they've passed the day+launches threshold.
    case AlertMessage
    
    // The text of the button that declines reviewing the app.
    case AlertDeclineTitle
    
    // Text of button that will send user to app review page.
    case AlertRateTitle
    
    // Text for button to remind the user to review later.
    case AlertRateLaterTitle
}


// Network status
public enum ABNetworkStatus : String  {
    
    // case when the network is offline
    case Offline = "Offline"
    
    // case when the network is online
    case Online = "Online"
    
    // case when the network is unknow
    case Unknown = "Unknown"
}

////////////////////////////////////////
//   ABReviewReminder                 //
////////////////////////////////////////
public class ABReviewReminder {
    
    // Singlton instance
    private class var instance: ABReviewReminder {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: ABReviewReminder? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = ABReviewReminder()
            
            // register the app events
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "appWillResignActive", name: UIApplicationWillResignActiveNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "appWillEnterForeground", name: UIApplicationWillEnterForegroundNotification, object: nil)
        }
        return Static.instance!
    }
    
    ////////////////////
    // MARK: Constants
    ////////////////////
    
    let kSavedVersion = "abrrSavedVersion"
    let kUseCount = "abrrUseCount"
    let kFirstUseDate = "abrrFirstUseDate"
    let kRatedCurrentVersion = "abrrRatedCurrentVersion"
    let kDeclinedToRate = "abrrDeclinedToRate"
    let kReminderRequestDate = "abrrReminderRequestDate"
    
    ////////////////////
    // MARK: Variables
    ////////////////////
    
    // Id of the app to review (Id was generate by Apple's Itunesconnect when creating a new app)
    private var _appId: String!
    
    // Default options
    private var _options:[ABReviewReminderOptions : AnyObject] =
    [   .Debug: false,
        .DaysUntilPrompt: 30,
        .UsesUntilPrompt: 20,
        .TimeBeforeReminding: 1,
        .AppVersionType: "CFBundleVersion",
        .UseMainBundle: false
    ]
    
    // Default strings
    private var _strings: [ABAlertStrings : String] = [:]
    
    // keep a reference to the alert controller
    private var _alertController: UIAlertController?

    // Keep a reference of the custom actions
    private var _actions: [UIAlertAction] = []
    
    // Keep a reference to the network status
    private var networkStatus: ABNetworkStatus = ABNetworkStatus.Unknown
    
    
    ////////////////////
    // MARK: Public methods
    ////////////////////
    
    // Starts the signlton ABReviewReminder session
    // @param appId (Mandatory) id of the app to review
    // @param options (Optional) options to extends the default options
    // @param strings (Optional) strings to override the default localization provided by ABReviewReminder
    public class func startSession(appId: String, withOptions options: [ABReviewReminderOptions : AnyObject]? = nil, strings: [ABAlertStrings : String]? = nil ) {
        instance._appId = appId
        instance.monitorNetworkChanges()
        instance.extendOptions(options)
        instance.initStrings(strings)
        instance.initActions()
        instance.debug("ABReviewReminder started session with appId: \(appId)")
    }
    
    
    // Tells ABReviewReminder that the app has launched.
    // You should call this method at the end of your application delegate's
    // application:didFinishLaunchingWithOptions: method.
    public class func appLaunched() {
        instance.appLaunched()
    }
    
    // Add a Alert custom action at the passed index
    // @param action The custom action to add
    // @param index  The position where the action will be added, default will be 0
    // Note: The Reject action item will be always put at the end of the actions list
    public class func addAlertAction(action: UIAlertAction, atIndex index: Int = 0){
        instance.addAlertAction(action, atIndex: index)
    }
    
    ////////////////////
    // MARK: Private methods
    ////////////////////
    
    @objc private class func appWillResignActive() {
        instance.debug("ABReviewReminder appWillResignActive")
        instance.hideAlert()
    }
    
    @objc private class func appWillEnterForeground() {
        instance.debug("ABReviewReminder appWillEnterForeground")
        if instance._appId == nil {
            //somehow the session has not started yet, so skip this
            return
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) { () -> Void in
            ABReviewReminder.instance.incrementAndRate()
        }
    }

    
    // Handle the app launched event
    private func appLaunched(){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) { () -> Void in
            ABReviewReminder.instance.incrementAndRate()
        }
    }
    
    // Handle the app entering the foreground event
    private func appEnteredForeground() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) { () -> Void in
            ABReviewReminder.instance.incrementAndRate()
        }
    }
    
    // Increments the use count
    private func incrementUseCount() {
        let currentVersion = Double(currentAppVersion())!
        let userDefaults = NSUserDefaults.standardUserDefaults()
        // a version has been found
        var savedVersion: Double? = userDefaults.doubleForKey(kSavedVersion)
        if (savedVersion == nil) {
            savedVersion = currentVersion
            userDefaults.setDouble(currentVersion, forKey: kSavedVersion)
        }
        
        debug("ABReviewReminder tracking the saved version: \(currentVersion)")
        
        // a new app version if found, so start tracking again
        if savedVersion != currentVersion {
            userDefaults.setDouble(currentVersion, forKey: kSavedVersion)
            userDefaults.setInteger(1, forKey: kUseCount)
            userDefaults.setDouble(NSDate().timeIntervalSince1970, forKey: kFirstUseDate)
            userDefaults.setBool(false, forKey: kRatedCurrentVersion)
            userDefaults.setBool(false, forKey: kDeclinedToRate)
            userDefaults.setDouble(0, forKey: kReminderRequestDate)
        }
        else{
            //retrieve the saved first used date if available
            let firstUseDate = userDefaults.objectForKey(kFirstUseDate) as? NSTimeInterval
            // set the date if not present
            if firstUseDate == nil {
                userDefaults.setDouble(NSDate().timeIntervalSince1970, forKey: kFirstUseDate)
            }
            
            // increment the use count
            var useCount = userDefaults.integerForKey(kUseCount)
            useCount++
            userDefaults.setInteger(useCount, forKey: kUseCount)
            debug("ABReviewReminder use count: \(useCount)")
        }
        
        userDefaults.synchronize()
    }
    
    private func incrementAndRate() {
        // network stauts not defined yet, so do nothing till we know more about the connection
        if networkStatus == ABNetworkStatus.Unknown {
            return
        }
        
        incrementUseCount()
        if ratingAlertIsAppropriate() && ratingConditionsHaveBeenMet() {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.showAlert()
            })
        }
    }
    
    // add the alert action at the passed index
    private func addAlertAction(action: UIAlertAction, atIndex index: Int = 0){
        var insertionIndex: Int!
        // health check
        if index < 0 {
            insertionIndex  = 0
            //force leaving the reject rate button at the last positions
        } else if index > _actions.count - 1 {
            insertionIndex = _actions.count - 1
        }
            // user choise
        else{
            insertionIndex = index
        }
        _actions.insert(action, atIndex: insertionIndex)
    }
    
    // is this an ok time to show the alert? (regardless of whether the rating conditions have been met)
    //
    // things checked here:
    // * connectivity with network
    // * whether user has rated before
    // * whether user has declined to rate
    // * whether rating alert is currently showing visibly
    private func ratingAlertIsAppropriate() ->Bool {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let connectionAvailable: Bool = networkStatus == ABNetworkStatus.Online
        let userHasDeclinedToRate: Bool = userDefaults.boolForKey(kDeclinedToRate)
        let userHasRatedCurrentVersion: Bool = userDefaults.boolForKey(kRatedCurrentVersion)
        let isRatingAlertVisible: Bool = _alertController != nil ? _alertController!.isBeingPresented() : false
        
        return connectionAvailable && !userHasDeclinedToRate && !userHasRatedCurrentVersion && !isRatingAlertVisible
    }
    
    // have the rating conditions been met/earned? (regardless of whether this would be a moment when it's appropriate to show a new rating alert)
    //
    // things checked here:
    // * time since first launch
    // * number of uses of app
    // * time since last reminder
    private func ratingConditionsHaveBeenMet() -> Bool {
        let debugMode: Bool = _options[ABReviewReminderOptions.Debug] as! Bool
        if debugMode {
            return true
        }
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let dateOfFirstLaunch = NSDate(timeIntervalSince1970: (userDefaults.objectForKey(kFirstUseDate) as? NSTimeInterval)!)
        let timeSinceFirstLaunch = NSDate().timeIntervalSinceDate(dateOfFirstLaunch)
        let daysUntilPrompt: Int = (_options[ABReviewReminderOptions.DaysUntilPrompt] as? Int)!
        let timeUntilRate: NSTimeInterval = 60 * 60 * 24 * Double(daysUntilPrompt)
        if timeSinceFirstLaunch < timeUntilRate {
            return false
        }
        
        // check if the user has used the app enough times
        let usesUntilPrompt: Int = (_options[ABReviewReminderOptions.UsesUntilPrompt] as? Int)!
        let useCount = userDefaults.integerForKey(kUseCount)
        if useCount < usesUntilPrompt {
            return false
        }
        
        // Check whether enough time has passed when the user wanted to be reminded later
        
        let dateSinceReminderRequest = NSDate(timeIntervalSince1970: (userDefaults.objectForKey(kReminderRequestDate) as? NSTimeInterval)!)
        let timeSinceReminderRequest: NSTimeInterval = NSDate().timeIntervalSinceDate(dateSinceReminderRequest)
        let timeBeforeReminding: Int = (_options[ABReviewReminderOptions.TimeBeforeReminding] as? Int)!
        let timeUntilReminder: NSTimeInterval = 60 * 60 * 24 * Double(timeBeforeReminding)
        if timeSinceReminderRequest < timeUntilReminder {
            return false
        }
        
        return true
    }
    
    // Show the alert
    private func showAlert() {
        let rootViewContoller = rootViewController()
        _alertController = UIAlertController(title: _strings[ABAlertStrings.AlertTitle], message: _strings[ABAlertStrings.AlertMessage], preferredStyle: .ActionSheet)

        for action in _actions {
            _alertController!.addAction(action)
        }
        
        //Present the AlertController
        if isIpad {
            let popPresenter: UIPopoverPresentationController = _alertController!.popoverPresentationController!
            popPresenter.sourceView = rootViewContoller.view
            popPresenter.sourceRect = CGRectMake(0, 0 , 50, 50)
        }
        
        rootViewContoller.presentViewController(_alertController!, animated: true, completion: nil)
    }
    
    // Hide the alert is visible
    private func hideAlert() {
        debug("ABReviewReminder hiding alert")
        _alertController?.dismissViewControllerAnimated(false, completion: nil)
    }

    
    ////////////////////
    // MARK: Utilities
    ////////////////////
    
    // check whether we are running on the iPad or not.
    private let isIpad = UIDevice.currentDevice().userInterfaceIdiom == .Pad
    
    // Extends the default options set by the passed new ones
    // @param newOptions New options to extend the default ones
    private func extendOptions(newOptions: [ABReviewReminderOptions : AnyObject]?) {
        if newOptions != nil {
            for (key, value) in newOptions! {
                _options.updateValue(value, forKey: key)
            }
        }
    }
    
    // Extends the default strings set by the passed new ones
    // @param newStrings New strings to extend the default ones
    private func initStrings(newStrings: [ABAlertStrings : String]?) {
        
        // get the current bundle to use
        let bundle = currentBundle()
        
        // get the applciation name to use
        let appName = currentAppName()
        
        // start the string overrides
        if newStrings != nil && newStrings![.AlertTitle] != nil {
            _strings[.AlertTitle] = newStrings![.AlertTitle]
        }
        else{
            _strings[.AlertTitle] = String(format: NSLocalizedString("Rate %@", tableName: "ABReviewReminderLocalizable", bundle: bundle, value: "", comment: ""), appName)
        }
        
        if newStrings != nil && newStrings![.AlertMessage] != nil {
            _strings[.AlertMessage] = newStrings![.AlertMessage]
        }
        else{
            _strings[.AlertMessage] = String(format: NSLocalizedString("If you enjoy using %@, would you mind taking a moment to rate it? It won't take more than a minute. Thanks for your support!", tableName: "ABReviewReminderLocalizable", bundle: bundle, value: "", comment: ""), appName)
        }
        
        if newStrings != nil && newStrings![.AlertDeclineTitle] != nil {
            _strings[.AlertDeclineTitle] = newStrings![.AlertDeclineTitle]
        }
        else{
            _strings[.AlertDeclineTitle] = NSLocalizedString("No, Thanks", tableName: "ABReviewReminderLocalizable", bundle: bundle, value: "", comment: "")
        }
        
        if newStrings != nil && newStrings![.AlertRateTitle] != nil {
            _strings[.AlertRateTitle] = newStrings![.AlertRateTitle]
        }
        else{
             _strings[.AlertRateTitle] = String(format: NSLocalizedString("Rate %@", tableName: "ABReviewReminderLocalizable", bundle: bundle, value: "", comment: ""), appName)
        }
        
        if newStrings != nil && newStrings![.AlertRateLaterTitle] != nil {
            _strings[.AlertRateLaterTitle] = newStrings![.AlertRateLaterTitle]
        }
        else{
            _strings[.AlertRateLaterTitle] = NSLocalizedString("Remind me later", tableName: "ABReviewReminderLocalizable", bundle: bundle, value: "", comment: "")
        }
    }
    
    // Init the alert action list
    private func initActions() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        // Rate action definiton and handeling
        let rateAction = UIAlertAction(title: _strings[.AlertRateTitle], style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.debug("ABReviewReminder Rate button clicked.")
            #if TARGET_IPHONE_SIMULATOR
                self.debug("ABReviewReminder NOTE: iTunes App Store is not supported on the iOS simulator. Unable to open App Store page.");
            #else
                userDefaults.setBool(true, forKey: self.kRatedCurrentVersion)
                userDefaults.synchronize()
                
                // open the app store to rate
                let reviewTemplateUrl: String = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=%@&type=Purple+Software&mt=8"
                let appReviewUrl  = String(format: NSLocalizedString(reviewTemplateUrl, comment: ""), self._appId)
                UIApplication.sharedApplication().openURL(NSURL(string: appReviewUrl)!)
                
                // notify the delegage if available
                if let delegate: ABReviewReminderDelegate = ABReviewReminder.instance._options[ABReviewReminderOptions.Delegate] as? ABReviewReminderDelegate {
                    delegate.userDidOptToRate?()
                }
            #endif
        })
        
        // Rate later action definiton and handeling
        let rateLaterAction = UIAlertAction(title: _strings[.AlertRateLaterTitle], style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.debug("ABReviewReminder Rate later button clicked.")
            userDefaults.setDouble(NSDate().timeIntervalSince1970, forKey: self.kReminderRequestDate)
            userDefaults.synchronize()
            
            // notify the delegage if available
            if let delegate: ABReviewReminderDelegate = ABReviewReminder.instance._options[ABReviewReminderOptions.Delegate] as? ABReviewReminderDelegate {
                delegate.userDidOptToRemindLater?()
            }
        })
        
        // Decline action definiton and handeling
        let declineRateAction = UIAlertAction(title: _strings[.AlertDeclineTitle], style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.debug("ABReviewReminder Decline rate button clicked.")
            
            userDefaults.setBool(true, forKey: self.kDeclinedToRate)
            userDefaults.synchronize()
            
            // notify the delegage if available
            if let delegate: ABReviewReminderDelegate = ABReviewReminder.instance._options[ABReviewReminderOptions.Delegate] as? ABReviewReminderDelegate {
                delegate.userDidDeclineToRate?()
            }
        })
        
        _actions.append(rateAction)
        _actions.append(rateLaterAction)
        _actions.append(declineRateAction)
    }
    
    // Monitor the network changes
    private func monitorNetworkChanges() {
        let host = "google.com"
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        let reachability = SCNetworkReachabilityCreateWithName(nil, host)!
        
        // handles the receives callbacks when the reachability of the target changes.
        SCNetworkReachabilitySetCallback(reachability, { (_, flags, _) in
            let currentNetworkStatus: ABNetworkStatus = ABReviewReminder.instance.networkStatus
            if !flags.contains(SCNetworkReachabilityFlags.ConnectionRequired) && flags.contains(SCNetworkReachabilityFlags.Reachable) {
                ABReviewReminder.instance.debug("ABReviewReminder Network status changed to Online")
                ABReviewReminder.instance.networkStatus = ABNetworkStatus.Online
            } else {
                ABReviewReminder.instance.debug("ABReviewReminder Network status changed to Offline")
                ABReviewReminder.instance.networkStatus = ABNetworkStatus.Offline
            }
            
            // we didn't know what kind of network it was, so try to increament and show the alert again
            if currentNetworkStatus == ABNetworkStatus.Unknown  && ABReviewReminder.instance.networkStatus != ABNetworkStatus.Unknown {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) { () -> Void in
                    ABReviewReminder.instance.incrementAndRate()
                }
            }
            
            // call the delegate with the new network change network status as bonus
            if let delegate: ABReviewReminderDelegate = ABReviewReminder.instance._options[ABReviewReminderOptions.Delegate] as? ABReviewReminderDelegate {
                delegate.reachabilityChangedWithNetworkStatus?(ABReviewReminder.instance.networkStatus.rawValue)
            }
            }, &context)
        
        SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), kCFRunLoopCommonModes)
    }
    
    
    // Gets the bundle to use
    private func currentBundle()-> NSBundle {
        var bundle: NSBundle!
        let useMainBundle: Bool = _options[ABReviewReminderOptions.UseMainBundle] as! Bool
        if useMainBundle {
            bundle = NSBundle.mainBundle()
        }
        else{
            let frameworkBundle = NSBundle(forClass: self.dynamicType)
            if let abreviewReminderBundleURL = frameworkBundle.URLForResource("ABReviewReminder", withExtension: "bundle") {
                // ABReviewReminder will likely only exist when used via CocoaPods
                bundle = NSBundle(URL: abreviewReminderBundleURL)
            }
            else{
                bundle = NSBundle.mainBundle()
            }
        }
        return bundle
    }
    
    // Prints only if the debug flag is set
    private func debug(items: Any...){
        let canDebug: Bool = _options[ABReviewReminderOptions.Debug] as! Bool
        if canDebug  {
            print(items)
        }
    }
    
    // Get App name to show, check whether the app is localized or not
    // @return The app name is going to be used in the alert
    private func currentAppName()-> String {
        if let localizedInfoDictionary = NSBundle.mainBundle().localizedInfoDictionary {
            if let localizedAppName = localizedInfoDictionary["CFBundleDisplayName"] as? String {
                // we found a lozalized app name so, return it
                return localizedAppName;
            }
        }
        return NSBundle.mainBundle().infoDictionary?["CFBundleName"] as! String
    }
    
    // Gets the current app version
    private func currentAppVersion()-> String{
        let versionType: String = (_options[ABReviewReminderOptions.AppVersionType] as? String)!
        return (NSBundle.mainBundle().infoDictionary?[versionType] as? String)!
    }
    
    // Get the root view controller
    private func rootViewController() -> UIViewController {
        let window: UIWindow = UIApplication.sharedApplication().keyWindow!
        if (window.windowLevel != UIWindowLevelNormal) {
            for window in UIApplication.sharedApplication().windows {
                if (window.windowLevel == UIWindowLevelNormal) {
                    break;
                }
            }
        }
        return iterateSubViewsForViewController(window) as! UIViewController
    }
    
    private func iterateSubViewsForViewController(parentView: UIView) -> AnyObject? {
        for subView in parentView.subviews {
            if let responder:UIViewController = subView.nextResponder() as? UIViewController{
                return topMostViewController(responder)
            }
            if let found = iterateSubViewsForViewController(subView) {
                return found
            }
        }
        return nil
    }
    
    
    private func topMostViewController(var controller: UIViewController) -> UIViewController {
        var isPresenting = false
        repeat {
            let presented = controller.presentedViewController
            isPresenting = presented != nil
            if(presented != nil) {
                controller = presented!
            }
        }
            while isPresenting
        
        return controller
    }
    
}
