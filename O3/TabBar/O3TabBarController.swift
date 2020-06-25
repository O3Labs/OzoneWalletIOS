//
//  O3TabBar.swift
//  O3
//
//  Created by Andrei Terentiev on 9/30/17.
//  Copyright © 2017 drei. All rights reserved.
//

import Foundation
import UIKit
import DeckTransition
import SwiftTheme
import Crashlytics
//统计功能注释
//import Amplitude

class O3TabBarController: UITabBarController {
    // swiftlint:disable weak_delegate
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    // swiftlint:enable weak_delegate

    let transitionDelegate = DeckTransitioningDelegate()

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.theme_barStyle = O3Theme.tabBarStylePicker
        tabBar.items?.last?.image = UIImage(named: "cog")
        tabBar.items?.last?.title = ""
        tabBar.items?.last?.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: -10, right: 0)
        tabBar.items?.last?.isEnabled = true
        
        ShortcutParser.shared.registerShortcuts()
        //统计功能注释
//        Amplitude.instance().logEvent("Loaded_Main_Tab")
        NotificationCenter.default.addObserver(self, selector: #selector(self.addThemedElements), name: NSNotification.Name(rawValue: ThemeUpdateNotification), object: nil)
    }
    @objc func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: ThemeUpdateNotification), object: nil)
    }

    deinit {
        removeObservers()
    }
    
    @objc func addThemedElements(){
//        tabBar.theme_barStyle = O3Theme.tabBarStylePicker
        
    }
    
    @IBAction func unwindToTabbar(segue: UIStoryboardSegue) {
    }
}
