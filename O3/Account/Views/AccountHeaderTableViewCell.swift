//
//  AccountHeaderTableViewCell.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/13/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

class AccountHeaderTableViewCell: UITableViewCell {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var totalAmountLabel: UILabel?
    
    override func awakeFromNib() {
        titleLabel?.theme_textColor = O3Theme.titleColorPicker
        totalAmountLabel?.theme_textColor = O3Theme.titleColorPicker
        contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
        super.awakeFromNib()
    }
}
