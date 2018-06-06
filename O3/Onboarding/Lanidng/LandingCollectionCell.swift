//
//  LandingCollectionCell.swift
//  O3
//
//  Created by Andrei Terentiev on 6/4/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class LandingCollectionCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    struct Data {
        var title: String
        var subtitle: String
    }

    var data: Data? {
        didSet {
            titleLabel.text = data?.title
            subtitleLabel.text = data?.subtitle
        }
    }
}
