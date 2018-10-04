//
//  DappTableViewCell.swift
//  O3
//
//  Created by Apisit Toompakdee on 10/2/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

class DappTableViewCell: UITableViewCell {

    @IBOutlet var dappIconImageView: UIImageView!
    @IBOutlet var subtitleLabel: ThemedUILabel!
    @IBOutlet var titleLabel: ThemedUILabel!
    
    override func awakeFromNib() {
        contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
        theme_backgroundColor = O3Theme.backgroundColorPicker
        super.awakeFromNib()
    }
    
    func configure(dapp: Dapp) {
        titleLabel.text = dapp.name
        subtitleLabel.text = dapp.description
        dappIconImageView.kf.setImage(with: URL(string: dapp.iconURL))
    }
}
