//
//  AccountSectionHeaderTableViewCell.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/18/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

class AccountSectionHeaderTableViewCell: UITableViewCell {

    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var rightAccessoryButton: UIButton?
    
    var sectionIndex: Int = 0 {
        didSet{
            self.rightAccessoryButton?.tag = sectionIndex
        }
    }
   
    override func awakeFromNib() {
        titleLabel?.theme_textColor = O3Theme.titleColorPicker
        contentView.theme_backgroundColor = O3Theme.backgroundLightgrey
        super.awakeFromNib()
    }
}
