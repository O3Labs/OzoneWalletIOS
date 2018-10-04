//
//  ThemedUILabel.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/26/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

class ThemedUILabel: UILabel {

    override func awakeFromNib() {
        theme_textColor = O3Theme.titleColorPicker
        super.awakeFromNib()
    }
}
