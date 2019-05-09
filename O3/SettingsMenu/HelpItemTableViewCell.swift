//
//  HelpItemTableViewCell.swift
//  O3
//
//  Created by Andrei Terentiev on 5/9/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class HelpItemTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        theme_backgroundColor = O3Theme.backgroundColorPicker
        contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
    
    var data: String? {
        didSet  {
            titleLabel.text = data!
        }
    }
}
