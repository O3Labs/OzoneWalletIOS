//
//  PrivateKeyCollectionViewCell.swift
//  O3
//
//  Created by Andrei Terentiev on 6/6/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

protocol PrivateKeyCardDelegate: class {
   func backupTapped()
}

class PrivateKeyCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var privateKeyLabel: UILabel!
    @IBOutlet weak var privateKeyImageView: UIImageView!
    @IBOutlet weak var backupButton: UIButton!

    weak var delegate: PrivateKeyCardDelegate?

    @IBAction func backupTapped(_ sender: Any) {
        delegate?.backupTapped()
    }

    var data: String? {
        didSet {
            self.privateKeyImageView.image = UIImage(qrData: data!, width: self.privateKeyImageView.frame.width, height: self.privateKeyImageView.frame.height)
            self.privateKeyLabel.text = data!
        }
    }
}
