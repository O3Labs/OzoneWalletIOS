//
//  NewExploreTableViewCell.swift
//  O3
//
//  Created by jcc on 2020/6/16.
//  Copyright © 2020 O3 Labs Inc. All rights reserved.
//

import UIKit

class NewExploreTableViewCell: UITableViewCell {

    @IBOutlet weak var exploreImageView: UIImageView!
    @IBOutlet weak var exploreTitleLabel: UILabel!
    @IBOutlet weak var exploreDetailLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
