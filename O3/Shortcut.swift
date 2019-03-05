//
//  Shortcut.swift
//  O3
//
//  Created by Apisit Toompakdee on 3/5/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import UIKit

enum ShortcutTypes: String {
    case send = "network.o3.app.default.actions.send"
    case receive = "network.o3.app.default.actions.receive"
    case apps = "network.o3.app.default.screens.apps"
    case news = "network.o3.app.default.screens.news"
}


class ShortcutParser {
    static let shared = ShortcutParser()
    
    private func shortcut(imageName: String, title: String, type: ShortcutTypes) -> UIApplicationShortcutItem {
        let icon = UIApplicationShortcutIcon(templateImageName: imageName)
        return UIApplicationShortcutItem(type: type.rawValue, localizedTitle: title, localizedSubtitle: nil, icon: icon, userInfo: nil)
    }
    private init() { }
    
    func registerShortcuts() {
        
        let send = shortcut(imageName: "ic_send", title: "Send", type: .send)
        let receive = shortcut(imageName: "qrCode-button", title: "Receive", type: .receive)
        let apps = shortcut(imageName: "rocket", title: "Apps", type: .apps)
        let news = shortcut(imageName: "newspaper", title: "News", type: .news)
        UIApplication.shared.shortcutItems = [send, receive, apps, news]
    }
    
    func handleShortcut(_ shortcut: UIApplicationShortcutItem) -> DeepLinkType? {
        //we can handle the text too here
        switch shortcut.type {
        case ShortcutTypes.send.rawValue:
            return DeepLinkType.send(address: "")
        case ShortcutTypes.receive.rawValue:
            return DeepLinkType.receive
        case ShortcutTypes.apps.rawValue:
            return DeepLinkType.apps(url: "")
        case ShortcutTypes.news.rawValue:
            return DeepLinkType.news
        default:
            return nil
        }
    }
    
}
