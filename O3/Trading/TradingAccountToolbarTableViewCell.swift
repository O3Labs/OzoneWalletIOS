//
//  TradingAccountToolbarTableViewCell.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/13/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

class TradingAccountToolbarTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
        theme_backgroundColor = O3Theme.backgroundColorPicker
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
