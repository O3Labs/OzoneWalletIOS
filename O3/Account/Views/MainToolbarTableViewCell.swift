//
//  MainToolbarTableViewCell.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/25/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

class MainToolbarTableViewCell: UITableViewCell {

    @IBOutlet var cardView: UIView?
    
    override func awakeFromNib() {
        theme_backgroundColor = O3Theme.backgroundLightgrey
        contentView.theme_backgroundColor = O3Theme.backgroundLightgrey
        cardView?.theme_backgroundColor = O3Theme.backgroundColorPicker
        super.awakeFromNib()
    }

}
