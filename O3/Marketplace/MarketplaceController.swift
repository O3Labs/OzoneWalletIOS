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
        addThemeObserver()
        self.bar.items = [Item(title: "Apps".uppercased()), Item(title: TokenSelectionStrings.NEP5.uppercased())]

        self.navigationController?.navigationBar.topItem?.title = MarketplaceStrings.Marketplace
        
        let nep5tokensViewController = UIStoryboard(name: "TokenSelection", bundle: nil).instantiateInitialViewController()!
        
        let dappListViewController = UIStoryboard(name: "Dapp", bundle: nil).instantiateInitialViewController()!

        self.viewControllers.append(dappListViewController)
        self.viewControllers.append(nep5tokensViewController)

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
        
        #if DEBUG
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Browser", style: .plain, target: self, action: #selector(openBrowserV2(_:)))
        #endif
    }
    
    @IBAction func openBrowserV2(_ sender: Any) {
        let nav = UIStoryboard(name: "dAppBrowser", bundle: nil).instantiateInitialViewController() as? UINavigationController
        if let vc = nav!.viewControllers.first as? dAppBrowserV2ViewController {
            let viewModel = dAppBrowserViewModel()
            viewModel.url = URL(string:"https://www.ftwlotto.com/o3")
            vc.viewModel = viewModel
        }
         let top = UIApplication.topViewController()
        
        top?.present(nav!, animated: true, completion: nil)
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
