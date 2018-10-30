//
//  AddWalletTableViewCell.swift
//  O3
//
//  Created by Andrei Terentiev on 10/30/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class AddWalletTableViewCell: UITableViewCell {
    @IBOutlet weak var addWalletLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addWalletLabel.theme_textColor = O3Theme.primaryColorPicker
        addWalletLabel.text = SettingsStrings.addWallet
    }
}
