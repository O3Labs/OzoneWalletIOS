//
//  DeepLink.swift
//  O3
//
//  Created by Apisit Toompakdee on 3/5/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import UIKit

//idk whats going on here, looks like this is made specifically for widget.
// maybe refactor in the future. For now will use router as the source of truth
// for uri schemes
enum DeepLinkType {
    case send(address: String)
    case receive
    case apps(url: String)
    case news
}

let Deeplinker = DeepLinkManager()

class DeepLinkManager {
    fileprivate init() {}
    private var deeplinkType: DeepLinkType?
    
    func checkDeepLink(){
        guard let deeplinkType = deeplinkType else {
            return
        }
        DeeplinkNavigator.shared.proceedDeepLink(deeplinkType)
        self.deeplinkType = nil
    }
    
    @discardableResult
    func handleShortcut(item: UIApplicationShortcutItem) -> Bool {
        deeplinkType = ShortcutParser.shared.handleShortcut(item)
        return deeplinkType != nil
    }
}


class DeeplinkNavigator {
    static let shared = DeeplinkNavigator()
    private init() { }
    
    func proceedDeepLink(_ type: DeepLinkType) {
        
        switch type {
        case .send(address: let address):
            Controller().openSend(to: address, selectedAsset: TransferableAsset.NEO(), amount: nil)
        case .receive:
            Controller().openMyAddress()
        case .apps(url: let url):
           Controller().focusOnTab(tabIndex: 2)
        case .news:
           Controller().focusOnTab(tabIndex: 3)
        }
    }
}
