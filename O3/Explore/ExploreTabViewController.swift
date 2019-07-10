//
//  ExploreTabViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 7/2/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Tabman
import Pageboy
import SwiftTheme

class ExploreTabViewController: TabmanViewController, PageboyViewControllerDataSource {
    var viewControllers = [UIViewController]()


    func addThemeObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.changedTheme), name: Notification.Name(rawValue: ThemeUpdateNotification), object: nil)
        /*NotificationCenter.default.addObserver(self, selector: #selector(self.updateWalletInfo), name: Notification.Name(rawValue: "NEP6Updated"), object: nil)*/
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: ThemeUpdateNotification), object: nil)
        //NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "NEP6Updated"), object: nil)
    }
    
    func initiateControllerTabs() {
        let exploreHomeViewController = UIStoryboard(name: "Explore", bundle: nil).instantiateViewController(withIdentifier: "exploreViewController") as! ExploreViewController
        let exploreDappsViewController = UIStoryboard(name: "Explore", bundle: nil).instantiateViewController(withIdentifier: "exploreViewController") as! ExploreViewController
        let exploreAssetsViewController = UIStoryboard(name: "Explore", bundle: nil).instantiateViewController(withIdentifier: "exploreViewController") as! ExploreViewController
        var themeString = ""
        
        if UserDefaultsManager.theme == Theme.dark {
            themeString = "dark=true"
        } else {
            themeString = "dark=false"
        }
        
        if AppState.network == .test {
            exploreHomeViewController.urlString = "https://testnet.o3.app/?hide=true&\(themeString)"
            exploreDappsViewController.urlString = "https://testnet.o3.app/dapps?hide=true&\(themeString)"
            exploreAssetsViewController.urlString = "https://testnet.o3.app/assets?hide=true&\(themeString)"
        } else {
            exploreHomeViewController.urlString = "https://o3.app/?hide=true&\(themeString)"
            exploreDappsViewController.urlString = "https://o3.app/dapps?hide=true&\(themeString)"
            exploreAssetsViewController.urlString = "https://o3.app/assets?hide=true&\(themeString)"
        }
        
        exploreAssetsViewController.view.layoutSubviews()
        exploreDappsViewController.view.layoutSubviews()
        exploreHomeViewController.view.layoutSubviews()
        self.viewControllers.append(exploreHomeViewController)
        self.viewControllers.append(exploreDappsViewController)
        self.viewControllers.append(exploreAssetsViewController)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initiateControllerTabs()
        self.dataSource = self
        setThemedElements()
        self.bar.location = .top
        self.bar.style = .buttonBar
        setLocalizedStrings()
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
    
    
    
    @objc func changedTheme(_ sender: Any?) {
        self.bar.appearance = TabmanBar.Appearance({ (appearance) in
            appearance.state.selectedColor = UserDefaultsManager.theme.primaryColor
            appearance.state.color = UserDefaultsManager.theme.lightTextColor
            appearance.layout.edgeInset = 16
            appearance.text.font = O3Theme.topTabbarItemFont
            appearance.style.background = .solid(color: UserDefaultsManager.theme.backgroundColor)
            appearance.indicator.useRoundedCorners = true
            appearance.interaction.isScrollEnabled = false
        })
    }
    
    func setThemedElements() {
        changedTheme(nil)
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
    
    func setLocalizedStrings() {
        self.bar.items = [Item(title: "Home"), Item(title:"Dapps"), Item(title:"Assets")]
        self.navigationItem.title = "Explore"
    }
}
