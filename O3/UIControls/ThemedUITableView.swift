//
//  ThemedUITableView.swift
//  O3
//
//  Created by Apisit Toompakdee on 10/2/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

class ThemedUITableView: UITableView {

    override func awakeFromNib() {
        theme_backgroundColor = O3Theme.backgroundColorPicker
        theme_separatorColor = O3Theme.tableSeparatorColorPicker
        super.awakeFromNib()
    }

}
