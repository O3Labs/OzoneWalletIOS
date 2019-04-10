//
//  AppDelegate.swift
//  O3
//
//  Created by Andrei Terentiev on 9/6/17.
//  Copyright © 2017 drei. All rights reserved.
//

import UIKit
import Channel
import CoreData
import Reachability
import Fabric
import Crashlytics
import SwiftTheme
import Neoutils
import UserNotifications
import Amplitude
import ZendeskSDK
import ZendeskCoreSDK
import ZendeskProviderSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    func setupChannel() {
        //O3 Development on Channel app_gUHDmimXT8oXRSpJvCxrz5DZvUisko_mliB61uda9iY
        Channel.setup(withApplicationId: "app_gUHDmimXT8oXRSpJvCxrz5DZvUisko_mliB61uda9iY")
    }

    static func setNavbarAppearance() {
        UINavigationBar.appearance().theme_largeTitleTextAttributes = O3Theme.largeTitleAttributesPicker
        UINavigationBar.appearance().theme_titleTextAttributes =
            O3Theme.regularTitleAttributesPicker
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().theme_barTintColor = O3Theme.navBarColorPicker
        UINavigationBar.appearance().theme_backgroundColor = O3Theme.navBarColorPicker
        UIApplication.shared.theme_setStatusBarStyle(O3Theme.statusBarStylePicker, animated: true)
    }

    func registerDefaults() {
        let userDefaultsDefaults: [String: Any] = [
            "networkKey": "main",
            "usedDefaultSeedKey": false,
            "activatedMultiWalletKey": false,
            "selectedThemeKey": Theme.light.rawValue,
            "referenceCurrencyKey": Currency.usd.rawValue,
            "reviewClaimsKey": 0,
            "numOrdersKey": 0
        ]
        UserDefaults.standard.register(defaults: userDefaultsDefaults)
    }

    let alertController = UIAlertController(title: OzoneAlert.noInternetError, message: nil, preferredStyle: .alert)
    @objc func reachabilityChanged(_ note: Notification) {
        switch reachability.connection {
        case .wifi:
            print("Reachable via WiFi")
            alertController.dismiss(animated: true, completion: nil)

        case .cellular:
            print("Reachable via cellular")
            alertController.dismiss(animated: true, completion: nil)
        case .none:
            print("Network not reachable")
            UIApplication.shared.keyWindow?.rootViewController?.presentFromEmbedded(alertController, animated: true, completion: nil)
        }
    }
    let reachability = Reachability()!
    func setupReachability() {
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(_:)), name: .reachabilityChanged, object: nil)
        do {
            try reachability.startNotifier()
        } catch {
            print("could not start reachability notifier")
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler:
        @escaping () -> Void) {
        guard let link = response.notification.request.content.userInfo["link"] as? String else {
            return
        }

        if Authenticated.wallet != nil {
            parsePushLink(link: link)
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            ////If your plist contain root as Dictionary
            if let dic = NSDictionary(contentsOfFile: path) as? [String: Any] {
                let amp = dic["Amplitude"] as! [String: Any]
                let ampApiKey = amp["APIKey"] as! String
                
                let zendesk = dic["Zendesk"] as! [String: Any]
                let zendeskKey = zendesk["APIKey"] as! String
                let zendeskClientId = zendesk["clientId"] as! String
                
                #if !DEBUG
                Amplitude.instance().initializeApiKey(ampApiKey)
                Zendesk.initialize(appId: zendeskKey,
                                   clientId: zendeskClientId,
                                   zendeskUrl: "https://o3labs.zendesk.com/")
                Support.initialize(withZendesk: Zendesk.instance)
                let ident = Identity.createAnonymous()
                Zendesk.instance?.setIdentity(ident)
                #endif
            }
        }
        
        
        #if DEBUG
        print("DEBUG BUILD")
        #else
        Fabric.with([Crashlytics.self])
        #endif

        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (_, _) in
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
        
        self.registerDefaults()
        self.setupChannel()
        self.setupReachability()
        AppDelegate.setNavbarAppearance()

        //check if there is an existing wallet in keychain
        //if so, present LoginToCurrentWalletViewController
        let walletExists =  UserDefaultsManager.o3WalletAddress != nil
        if walletExists {
            guard let login = UIStoryboard(name: "Onboarding", bundle: nil)
                .instantiateViewController(withIdentifier: "LoginToNep6ViewController") as? LoginToNep6ViewController else {
                    return false
            }

            if let window = self.window {
                login.delegate = self
                //pass the launchOptions to the login screen
                login.launchOptions = launchOptions
                window.rootViewController = login
                return false
            }
        }
        //Onboarding Theme
        return true
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "O3")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the   actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    lazy var accountPersistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Transaction")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func saveAccountContext () {
        let context = accountPersistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    // MARK: - deeplink
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if app.applicationState == .inactive {
            if url.scheme == "neo" {
                Router.parseNEP9URL(url: url)
                return true
            } else if (url.scheme == "o3network") {
                Router.parseO3NetworkScheme(url: url)
                return true
            } else if (url.scheme == "o3browser") {
                Router.parseO3BrowserScheme(url: url)
            }
        }
        return true
    }
}

extension AppDelegate: LoginToNEP6ViewControllerDelegate {
    
    func parsePushLink(link: String) {
        UIApplication.shared.keyWindow?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        guard let tabbar = UIApplication.appDelegate.window?.rootViewController as? O3TabBarController else {
            return
        }

        let url = URL(string: link)
        let components = url!.pathComponents
        guard let baseUrl = components.first else {
            return
        }
        if baseUrl != "o3.app" || components.count < 2 {
            return
        }

        guard let tabItem = Int(components[1]) else {
                return
        }
        tabbar.selectedIndex = tabItem

    }

    func authorized(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        if let url = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL {
            Router.parseNEP9URL(url: url)
            return
        }
        //handle deeplink when the app launches
        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            Deeplinker.handleShortcut(item: shortcutItem)
            Deeplinker.checkDeepLink()
            return
        }
        
        if let notification = launchOptions?[.remoteNotification] as? [String: AnyObject] {
            if let notificationLink = notification["link"] as? String {
                parsePushLink(link: notificationLink)
            }
            return
        }
    }
    
    // allow universal link to open the app
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            let url = userActivity.webpageURL!
            print(url.absoluteString)
        }
        return true
    }
     
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Swift.Void){
          completionHandler(Deeplinker.handleShortcut(item: shortcutItem))
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        Deeplinker.checkDeepLink()
    }
}
