//
//  NewExploreTabViewController.swift
//  O3
//
//  Created by jcc on 2020/6/16.
//  Copyright © 2020 O3 Labs Inc. All rights reserved.
//

import UIKit
import Tabman
import Pageboy

class NewExploreTabViewController: TabmanViewController, PageboyViewControllerDataSource {
    
    var viewControllers: [UIViewController] = []
    
    
    func setupTabs(){
        let recommend = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NewExploreVC") as! NewExploreVC
        let recreation = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NewExploreVC") as! NewExploreVC
        let finance = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NewExploreVC") as! NewExploreVC
        
        self.viewControllers.append(recommend)
        self.viewControllers.append(recreation)
        self.viewControllers.append(finance)
        
        self.dataSource = self
        
        self.bar.items = [Item(title: "推荐"),
            Item(title: "娱乐"),Item(title: "金融")]
        
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsChildScrollViewInsets = false
        automaticallyAdjustsChildViewInsets = false
        self.setupTabs()
        navigationController?.hideHairline()
        
        self.title = "Explor"
        // Do any additional setup after loading the view.
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
