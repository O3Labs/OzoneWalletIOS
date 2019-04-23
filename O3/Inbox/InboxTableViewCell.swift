//
//  InboxTableViewCell.swift
//  O3
//
//  Created by Andrei Terentiev on 4/22/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class InboxTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var subtitleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setThemedElements()
    }
    
    func setThemedElements() {
        titleLabel.theme_textColor = O3Theme.titleColorPicker
        subtitleLabel.theme_textColor = O3Theme.titleColorPicker
        dateLabel.theme_textColor = O3Theme.lightTextColorPicker
    }
}
