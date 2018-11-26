//
//  UnlockMultiWalletTableViewCell.swift
//  O3
//
//  Created by Andrei Terentiev on 11/5/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class UnlockMultiWalletTableViewCell: UITableViewCell {
    @IBOutlet weak var walletLabel: UILabel!
    @IBOutlet weak var walletIsDefaultView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        walletLabel.theme_textColor = O3Theme.primaryColorPicker
        contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
}
