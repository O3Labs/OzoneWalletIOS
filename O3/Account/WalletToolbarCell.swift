//
//  WalletToolbarr.swift
//  O3
//
//  Created by Andrei Terentiev on 6/5/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

protocol WalletToolbarDelegate: class {
    func sendTapped(qrData: String?)
    func requestTapped()
}

class WalletToolBarCell: UITableViewCell {
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var requestButton: UIButton!
    @IBOutlet weak var scanButton: UIButton!
    weak var delegate: WalletToolbarDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.theme_backgroundColor = O3Theme.backgroundLightgrey
    }

    @IBAction func sendTapped() {
        delegate?.sendTapped(qrData: nil)
    }

    @IBAction func requestTapped() {
        delegate?.requestTapped()
    }

    func setLocalizedStrings() {
        sendButton.setTitle(AccountStrings.send, for: UIControlState())
        requestButton.setTitle(AccountStrings.request, for: UIControlState())
        scanButton.setTitle(AccountStrings.scan, for: UIControlState())
    }
}
