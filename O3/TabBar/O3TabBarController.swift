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

class O3TabBarController: UITabBarController {
    // swiftlint:disable weak_delegate
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    // swiftlint:enable weak_delegate

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.theme_barStyle = O3Theme.tabBarStylePicker
        tabBar.items?[4].image = UIImage(named: "cog")?.withRenderingMode(.alwaysOriginal)
        tabBar.items?[4].title = ""
        tabBar.items?[4].imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: -10, right: 0)
        tabBar.items?[4].isEnabled = true

        let tabOverrideView = UIView(frame: tabBar.subviews[4].frame)
        tabOverrideView.isUserInteractionEnabled = true
        tabOverrideView.backgroundColor = UIColor.clear

        let button = UIButton(frame: tabOverrideView.frame)
        button.addTarget(self, action: #selector(tappedSettingsTab), for: .touchUpInside)
        button.backgroundColor = UIColor.clear
        tabOverrideView.embed(button)
        self.tabBar.addSubview(tabOverrideView)
    }

    @IBAction func unwindToTabbar(segue: UIStoryboardSegue) {
    }

    @objc func tappedSettingsTab() {
       self.performSegue(withIdentifier: "segueToSettings", sender: nil)
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let index = tabBar.items?.index(of: item) else { return }
        let tabTappedMessages = ["Portfolio", "Wallet", "Marketplace", "News", "Settings" ]
        Answers.logCustomEvent(withName: "Tab Tapped",
                               customAttributes: ["Tab Name": tabTappedMessages[index]])

        if index == 4 {
           self.performSegue(withIdentifier: "segueToSettings", sender: nil)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: segue.destination)

        segue.destination.modalPresentationStyle = .custom
        segue.destination.transitioningDelegate = self.halfModalTransitioningDelegate
    }
}
