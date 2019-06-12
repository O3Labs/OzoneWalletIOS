//
//  WalletHomeNavigationController.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/23/17.
//  Copyright © 2017 drei. All rights reserved.
//

import UIKit
import SwiftTheme

class NoHairlineNavigationController: UINavigationController {
    override func viewDidLoad() {
        UIApplication.shared.theme_setStatusBarStyle(ThemeStatusBarStylePicker(styles: Theme.light.statusBarStyle, Theme.dark.statusBarStyle), animated: true)
            self.setNeedsStatusBarAppearanceUpdate()
          self.navigationController?.hideHairline()
            self.navigationController?.navigationItem.largeTitleDisplayMode = .never
        self.navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
        super.viewDidLoad()
    }
}
