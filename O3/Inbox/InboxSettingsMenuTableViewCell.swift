//
//  InboxSettingsMenuTableViewCell.swift
//  O3
//
//  Created by Andrei Terentiev on 4/23/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class InboxSettingsMenuTableViewCell: UITableViewCell {
    @IBOutlet weak var serviceLabel: UILabel!
    @IBOutlet weak var serviceSwitch: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setThemedElements()
    }
    
    func setThemedElements() {
        serviceSwitch.theme_backgroundColor = O3Theme.backgroundColorPicker
        theme_backgroundColor = O3Theme.cardColorPicker
        serviceLabel.theme_textColor = O3Theme.titleColorPicker
        
    }
}
