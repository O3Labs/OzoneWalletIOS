//
//  OrdersTabsViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/21/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import Tabman
import Pageboy

class OrdersTabsViewController: TabmanViewController, PageboyViewControllerDataSource {
    
    var viewControllers: [UIViewController] = []
    var showOnlyOpenOrdersForPair: String?
    
    func setupTabs() {
        
        let open = UIStoryboard(name: "Trading", bundle: nil).instantiateViewController(withIdentifier: "OrdersTableViewController") as! OrdersTableViewController
        open.orderStatus = SwitcheoOrderStatus.open
        let completed = UIStoryboard(name: "Trading", bundle: nil).instantiateViewController(withIdentifier: "OrdersTableViewController") as! OrdersTableViewController
        completed.orderStatus = SwitcheoOrderStatus.empty
        
        if showOnlyOpenOrdersForPair != nil {
            let pair = UIStoryboard(name: "Trading", bundle: nil).instantiateViewController(withIdentifier: "OrdersTableViewController") as! OrdersTableViewController
            pair.orderStatus = SwitcheoOrderStatus.open
            self.viewControllers.append(pair)
        }
        self.viewControllers.append(open)
        self.viewControllers.append(completed)
        
        self.dataSource = self
        
        self.bar.items = [Item(title: "Open"),
            Item(title: "All")]
        
        self.bar.appearance = TabmanBar.Appearance({ (appearance) in
            appearance.state.selectedColor = UserDefaultsManager.theme.primaryColor
            appearance.state.color = UserDefaultsManager.theme.lightTextColor
            appearance.text.font = O3Theme.topTabbarItemFont
            appearance.layout.edgeInset = 16
            appearance.style.background = .solid(color: UserDefaultsManager.theme.backgroundColor)
        })
        self.bar.location = .top
        self.bar.style = .buttonBar
        self.view.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTabs()
        navigationController?.hideHairline()
        self.title = "Orders"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-x"), style: .plain, target: self, action: #selector(dismiss(_: )))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(reloadData))
    }
    
    @objc func reloadData() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadOrders"), object: nil)
    }
    
    @objc func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
