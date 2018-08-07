//
//  TokenGridCell.swift
//  O3
//
//  Created by Andrei Terentiev on 5/1/18.
//  Copyright © 2018 drei. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher

class TokenGridCell: UICollectionViewCell {
    @IBOutlet weak var tokenSymbolLabel: UILabel!
    @IBOutlet weak var tokenImageView: UIImageView!
    @IBOutlet weak var inWalletImageView: UIImageView!

    override func awakeFromNib() {
        tokenSymbolLabel.theme_textColor = O3Theme.lightTextColorPicker
        super.awakeFromNib()
    }

    var data: Asset? {
        didSet {
            guard let asset = data else {
                return
            }
            tokenSymbolLabel.text = asset.symbol.uppercased()
            tokenImageView.kf.setImage(with: URL(string: asset.logoURL))
        }
    }
}
