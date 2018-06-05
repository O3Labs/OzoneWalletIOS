//
//  MarketPlaceTabmanController.swift
//  O3
//
//  Created by Andrei Terentiev on 6/4/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import Tabman
import Pageboy
import SwiftTheme

class MarketplaceController: TabmanViewController, PageboyViewControllerDataSource {
    var viewControllers: [UIViewController] = []

    func addThemeObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.changedTheme), name: Notification.Name(rawValue: ThemeUpdateNotification), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: ThemeUpdateNotification), object: nil)
    }

    @objc func changedTheme(_ sender: Any) {
        self.bar.appearance = TabmanBar.Appearance({ (appearance) in
            appearance.state.selectedColor = UserDefaultsManager.theme.primaryColor
            appearance.state.color = UserDefaultsManager.theme.lightTextColor
            appearance.layout.edgeInset = 16
            appearance.text.font = O3Theme.topTabbarItemFont
            appearance.style.background = .solid(color: UserDefaultsManager.theme.backgroundColor)
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        applyNavBarTheme()
        super.viewWillAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.bar.items = [Item(title: TokenSelectionStrings.NEP5),
                          Item(title: TokenSaleStrings.tokenSalesTitle)]
        self.navigationController?.navigationBar.topItem?.title = MarketplaceStrings.Marketplace
        let tokenSalesViewController = UIStoryboard(name: "TokenSale", bundle: nil).instantiateInitialViewController()!
        let nep5tokensViewController = UIStoryboard(name: "TokenSelection", bundle: nil).instantiateInitialViewController()!

        self.viewControllers.append(nep5tokensViewController)

        if O3Cache.gas().value != 0 || O3Cache.neo().value != 0 {
            self.viewControllers.append(tokenSalesViewController)
        }

        view.theme_backgroundColor = O3Theme.backgroundColorPicker
        self.bar.appearance = TabmanBar.Appearance({ (appearance) in
            appearance.state.selectedColor = UserDefaultsManager.theme.primaryColor
            appearance.state.color = UserDefaultsManager.theme.lightTextColor
            appearance.text.font = O3Theme.topTabbarItemFont
            appearance.layout.edgeInset = 16
            appearance.style.background = .solid(color: UserDefaultsManager.theme.backgroundColor)
        })
        self.bar.location = .top
        self.bar.style = .buttonBar
        self.dataSource = self
    }

    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return viewControllers.count
    }

    func viewController(for pageboyViewController: PageboyViewController, at index: PageboyViewController.PageIndex) -> UIViewController? {
        return viewControllers[index]
    }

    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return nil
    }
}
