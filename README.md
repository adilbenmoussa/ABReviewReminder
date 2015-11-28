  <img src="https://raw.githubusercontent.com/adilbenmoussa/ABCircularProgressView/master/Images/swift-logo.jpg" width="400">
  
# ABReviewReminder
`ABReviewReminder` is a utility written in Swift 2.0 that reminds the iPhone and iPad app users (iOS 8.0 or later) to review your app. The code is released under the MIT, so feel free to modify and share your changes with the world. 

#### Screenshots:


## Usage
The easiest way to start using `ABReviewReminder` is to start the session providing your appId provided by Apple (1), and calling ABReviewReminder.appLaunched() (2) at the end of your app delegate's `application:didFinishLaunchingWithOptions:` method. 

```swift
ABReviewReminder.startSession("12345678") //1
ABReviewReminder.appLaunched() //2
```
### Configuration
`ABReviewReminder` provides:
	
1. [Options](#options) to configure the behavior.
2. [Strings](#strings) to customize the alert strings.
3. [Delegate methods](#delegate) for callbacks
4. [Custom actions](#actions) for adding your own custom actions to the alert.

```swift
// list of options to override the default behavior
let options:[ABReviewReminderOptions : AnyObject] =
[
    ABReviewReminderOptions.Debug: true,
    ABReviewReminderOptions.Delegate: self,
    ABReviewReminderOptions.DaysUntilPrompt: 1,
    ABReviewReminderOptions.UsesUntilPrompt: 10,
    ABReviewReminderOptions.TimeBeforeReminding: 2,
    ABReviewReminderOptions.AppVersionType: "CFBundleShortVersionString"
]

// list of string to provide costum strings for the alert
let strings:[ABAlertStrings : String] =
[
    ABAlertStrings.AlertTitle: "My custom alert title",
    ABAlertStrings.AlertMessage: "My custom alert message",
    ABAlertStrings.AlertDeclineTitle: "My custom decline button title",
    ABAlertStrings.AlertRateTitle: "My custom rate button title",
    ABAlertStrings.AlertRateLaterTitle: "My custom rate later button title"
]
        
ABReviewReminder.startSession("12345678", withOptions: options, strings: strings)
ABReviewReminder.appLaunched()
```
#### Options (`ABReviewReminderOptions`)<a name="options"></a>:
* `Debug: Bool` Default is `false` If set the alert will be shown every time the app starts.
WARNING: don't forget to set debug flag back to false when deploying to production.
* `Delegate: ABReviewReminderDelegate` Default is `nil` If set the ABReviewReminder events will be delegated.
* `DaysUntilPrompt: Int` Default is `30` The amount of days to wait to show the alert for a specific version of the app.
* `UsesUntilPrompt: Int` Default is `20`. If set the alert will be shown every time the app starts
An example of a 'use' would be if the user launched the app. 
Bringing the app into the foreground (on devices that support it) would also be considered a 'use'. You tell `ABReviewReminder` about these events using the two methods: ABReviewReminder.appLaunched() and when app triggers the UIApplicationWillEnterForegroundNotification event
Users need to 'use' the same version of the app this many times before before they will be prompted to rate it.
* `TimeBeforeReminding: Int` Default is `1` Once the rating alert is presented to the user, they might select 'Remind me later'. This value specifies how long (in days) `ABReviewReminder` will wait before reminding them.
* `AppVersionType: String` The app version type ABReviewReminder will track. Default the major version `CFBundleVersion`. Possible values: `["CFBundleVersion", "CFBundleShortVersionString"]`
* `UseMainBundle: Bool` Default is `false` If set to true, the main bundle will always be used to load localized strings. Set this to true if you have provided your own custom localizations in ABReviewReminderLocalizable.strings in your main bundle.  

#### Strings (`ABAlertStrings`)<a name="strings"></a>:
* `AlertTitle: String` This is the title of the message alert that users will see. 
* `AlertMessage: String` This is the message your users will see once they've passed the day+launches threshold.
* `AlertDeclineTitle: String` The text of the button that declines reviewing the app.
* `AlertRateTitle: String` Text of button that will send user to app review page.
* `AlertRateLaterTitle: String` Text for button to remind the user to review later. 

#### Custom actions<a name="actions"></a>:
`ABReviewReminder` provides class method `addAlertAction` to add you own costum action to the alert. `addAlertAction` does some health checks for the index were the action will be added. Note: The Reject action item will be always put at the end of the actions list. 

```swift
addAlertAction(action: UIAlertAction)
// OR
addAlertAction(action: UIAlertAction, atIndex index: Int)
```

```swift
let customAlertAction = UIAlertAction(title: "My Custom action", style: .Default, handler: {
    (alert: UIAlertAction!) -> Void in
    print("My Custom action button clicked.")
})
ABReviewReminder.startSession("12345678")
ABReviewReminder.addAlertAction(customAlertAction, atIndex: 1)
    
ABReviewReminder.appLaunched()
```

#### Delegate (`ABReviewReminderDelegate`)<a name="delegate"></a>:
* `optional func userDidOptToRate()` called when the use clicks on the rate app button.
* `optional func userDidDeclineToRate()` called when the use clicks on the decline rate app button.
* `optional func userDidOptToRemindLater()` called when the use clicks on the remind me later button.
* `optional func reachabilityChangedWithNetworkStatus(newNetworkStatus: String)` called when network status changes. Possible values of the newNetworkStatus are: `Offline|Online`



##Production examples:
Make sure you set `ABReviewReminderOptions.Debug: false` or remove it from the passed [options](#options) to ensure the request is not shown every time the app is launched. Also make sure that `ABReviewReminder.startSession` and `ABReviewReminder.appLaunched` functions are called in the `application:didFinishLaunchingWithOptions:` method.

This example states that the rating request is only shown when the app has been launched 5 times **and** after 7 days.

```swift
let options:[ABReviewReminderOptions : AnyObject] =
[
    ABReviewReminderOptions.Delegate: self,
    ABReviewReminderOptions.DaysUntilPrompt: 7,
    ABReviewReminderOptions.UsesUntilPrompt: 5,
    ABReviewReminderOptions.TimeBeforeReminding: 2
]

ABReviewReminder.startSession("12345678", withOptions: options)
ABReviewReminder.appLaunched()
```

If you wanted to show the request after 5 days only you can set the following:

```swift
let options:[ABReviewReminderOptions : AnyObject] =
[
    ABReviewReminderOptions.Delegate: self,
    ABReviewReminderOptions.DaysUntilPrompt: 5,
    ABReviewReminderOptions.UsesUntilPrompt: 0,
    ABReviewReminderOptions.TimeBeforeReminding: 2
]
ABReviewReminder.startSession("12345678", withOptions: options)
ABReviewReminder.appLaunched()
```


## Installation

###[CocoaPods][cocoapods]

Simply add the following lines to your `Podfile`:
```ruby
# required by Cocoapods 0.36.0.rc.1 for Swift Pods
use_frameworks! 

pod 'ABReviewReminder', '~> 1.0'
```

*(CocoaPods v0.36 or later required. See [this blog post](http://blog.cocoapods.org/Pod-Authors-Guide-to-CocoaPods-Frameworks/) for details.)*

##Requirements
- iOS 8.0
- Xcode 7, Swift 2.0

##Acknowledgments
`ABReviewReminder` is heavily inspired by the wonderfull Objective-C library [_Appirater_][appiratergroup]. Also all localizations in `ABReviewReminder` were copied from there. 

##License

Copyright (c) 2015 [Adil Ben Moussa][adilbenmoussa_github]

While not required, I greatly encourage and appreciate any improvements that you make
to this library be contributed back for the benefit of all who use Appirater.

The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.



[adilbenmoussa_github]: https://github.com/adilbenmoussa
[appiratergroup]: http://groups.google.com/group/appirater
[cocoapods]: http://cocoapods.org
