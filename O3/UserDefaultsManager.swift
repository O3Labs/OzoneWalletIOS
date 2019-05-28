//
//  UserDefaultsManager.swift
//  O3
//
//  Created by Andrei Terentiev on 10/9/17.
//  Copyright © 2017 drei. All rights reserved.
//

import Foundation

class UserDefaultsManager {

    private static let networkKey = "networkKey"

    static var network: Network {
        #if TESTNET
            return .test
        #endif
        #if PRIVATENET
            return .privateNet
        #endif

        return .main
    }

    private static let useDefaultSeedKey = "usedDefaultSeedKey"
    static var useDefaultSeed: Bool {
        get {
            #if TESTNET
                return false
            #endif
            #if PRIVATENET
                return false
            #endif
            return UserDefaults.standard.bool(forKey: useDefaultSeedKey)
        }
        set {
            if newValue {
                if let bestNode = NEONetworkMonitor.autoSelectBestNode(network: AppState.network) {
                    UserDefaults.standard.set(newValue, forKey: useDefaultSeedKey)
                    AppState.bestSeedNodeURL = bestNode
                    UserDefaultsManager.seed = bestNode
                }
            } else {
                UserDefaults.standard.set(newValue, forKey: useDefaultSeedKey)
                UserDefaults.standard.synchronize()
            }
        }
    }

    private static let seedKey = "seedKey"
    static var seed: String {
        get {
            return UserDefaults.standard.string(forKey: seedKey)!
        }
        set {
            UserDefaults.standard.set(newValue, forKey: seedKey)
            UserDefaults.standard.synchronize()
            NotificationCenter.default.post(name: Notification.Name("ChangedNetwork"), object: nil)
        }
    }

    private static let selectedThemeIndexKey = "selectedThemeIndex"
    static var themeIndex: Int {
        get {
            let intValue = UserDefaults.standard.integer(forKey: selectedThemeIndexKey)
            if intValue != 0 && intValue != 1 {
                return 0
            }
            return intValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: selectedThemeIndexKey)
            UserDefaults.standard.synchronize()
        }
    }

    static var theme: Theme {
        return themeIndex == 0 ? Theme.light: Theme.dark
    }

    private static let launchedBeforeKey = "launchedBeforeKey"
    static var launchedBefore: Bool {
        get {
            let value = UserDefaults.standard.bool(forKey: launchedBeforeKey)
            return value
        }
        set {
            UserDefaults.standard.set(newValue, forKey: launchedBeforeKey)
            UserDefaults.standard.synchronize()
        }
    }

    private static let o3WalletAddressKey = "o3WalletAddressKey"
    static var o3WalletAddress: String? {
        get {
            let stringValue = UserDefaults.standard.string(forKey: o3WalletAddressKey)
            return stringValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: o3WalletAddressKey)
            UserDefaults.standard.synchronize()
        }
    }

    private static let referenceFiatCurrencyKey = "referenceCurrencyKey"
    static var referenceFiatCurrency: Currency {
        get {
            let stringValue = UserDefaults.standard.string(forKey: referenceFiatCurrencyKey)
            if stringValue == nil {
                return Currency.usd
            }
            return Currency(rawValue: stringValue!)!
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: referenceFiatCurrencyKey)
            UserDefaults.standard.synchronize()
            NotificationCenter.default.post(name: Notification.Name("ChangedReferenceCurrency"), object: nil)
        }
    }

    private static let reviewClaimsKey = "reviewClaimsKey"
    static var numClaims: Int {
        get {
            let intValue = UserDefaults.standard.integer(forKey: reviewClaimsKey)
            return intValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: reviewClaimsKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private static let numOrdersKey = "numOrdersKey"
    static var numOrders: Int {
        get {
            let intValue = UserDefaults.standard.integer(forKey: numOrdersKey)
            return intValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: numOrdersKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private static let hasAgreedDappDisclaimerKey = "hasAgreedDapps"
    static var hasAgreedDapps: Bool {
        get {
            let boolValue = UserDefaults.standard.bool(forKey: hasAgreedDappDisclaimerKey)
            return boolValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasAgreedDappDisclaimerKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private static let hasAgreedAnalyticsDisclaimerKey = "hasAgreedAnalytics"
    static var hasAgreedAnalytics: Bool {
        get {
            let boolValue = UserDefaults.standard.bool(forKey: hasAgreedAnalyticsDisclaimerKey)
            return boolValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasAgreedAnalyticsDisclaimerKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private static let hasAgreedInboxDisclaimerKey = "hasAgreedInbox"
    static var hasAgreedInbox: Bool {
        get {
            let boolValue = UserDefaults.standard.bool(forKey: hasAgreedInboxDisclaimerKey)
            return boolValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasAgreedInboxDisclaimerKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    enum Subscriptions: String {
        // O3 services are the equivalent of subscribing to all addresses associated with nep6
        case o3 = "o3"
        case neoeconomy = "neoeconomy"
    }
    
    private static let subscribedServicesKey = "SubscribedServices"
    static var subscribedServices: [String] {
        get {
            guard let arrayValue = UserDefaults.standard.array(forKey: subscribedServicesKey) as? [String] else {
                return []
            }
            return arrayValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: subscribedServicesKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private static let untrackedWatchAddrKey = "untrackedWatchAddr"
    static var untrackedWatchAddr: [String] {
        get {
            guard let arrayValue = UserDefaults.standard.array(forKey: untrackedWatchAddrKey) as? [String] else {
                return []
            }
            return arrayValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: untrackedWatchAddrKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private static let lastInboxOpenKey = "lastInboxOpen"
    static var lastInboxOpen: Int {
        get {
            guard let intValue = UserDefaults.standard.integer(forKey: lastInboxOpenKey) as? Int else {
                return 0
            }
            return intValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: lastInboxOpenKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private static let needsInboxBadgeKey = "needsInboxBadge"
    static var needsInboxBadge: Bool {
        get {
            if UserDefaultsManager.hasAgreedInbox == false {
                return true
            }
            
            guard let boolValue = UserDefaults.standard.bool(forKey: needsInboxBadgeKey) as? Bool else {
                return false
            }
            return boolValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: needsInboxBadgeKey)
            UserDefaults.standard.synchronize()
        }
    }
}
