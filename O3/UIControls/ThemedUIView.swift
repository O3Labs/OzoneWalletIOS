//
//  ThemedUIView.swift
//  O3
//
//  Created by Apisit Toompakdee on 10/3/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

class ThemedUIView: UIView {

    override func awakeFromNib() {
        theme_backgroundColor = O3Theme.backgroundColorPicker
        super.awakeFromNib()
    }

}
