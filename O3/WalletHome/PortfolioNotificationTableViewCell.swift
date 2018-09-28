//
//  PortfolioNotificationTableViewCell.swift
//  O3
//
//  Created by Apisit Toompakdee on 8/7/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

protocol PortfolioNotificationTableViewCellDelegate {
    func didDismiss()
}

class PortfolioNotificationTableViewCell: UITableViewCell {

    @IBOutlet weak var cardView: CardView?

    override func awakeFromNib() {
        contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
        theme_backgroundColor = O3Theme.backgroundColorPicker
        super.awakeFromNib()
    }

    var delegate: PortfolioNotificationTableViewCellDelegate?

    @IBAction func didTapAction(_ sender: Any) {
        Controller().openSwitcheoDapp()
    }

    @IBAction func didTapDismiss(_ sender: Any) {
        self.delegate?.didDismiss()
    }

}
