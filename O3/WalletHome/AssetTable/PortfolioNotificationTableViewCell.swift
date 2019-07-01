//
//  PortfolioNotificationTableViewCell.swift
//  O3
//
//  Created by Apisit Toompakdee on 8/7/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import MessageUI

protocol PortfolioNotificationTableViewCellDelegate {
    func didDismiss()
}

class PortfolioNotificationTableViewCell: UITableViewCell, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var cardView: CardView?

    override func awakeFromNib() {
        contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
        theme_backgroundColor = O3Theme.backgroundColorPicker
        cardView?.backgroundColor = Theme.light.negativeLossColor
        super.awakeFromNib()
    }

    var delegate: PortfolioNotificationTableViewCellDelegate?
    
    @IBAction func didTapAction(_ sender: Any) {
        Controller().openSecurityCenter()
        AppState.setDismissBackupNotification(dismiss: true)
    }
}
