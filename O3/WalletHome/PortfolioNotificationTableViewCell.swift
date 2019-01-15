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
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        DispatchQueue.main.async {
            controller.dismiss(animated: true, completion: nil)
            if result == .cancelled || result == .failed {
                OzoneAlert.alertDialog(message: OnboardingStrings.failedToSendEmailDescription, dismissTitle: OzoneAlert.okPositiveConfirmString) {
                    return
                }
            } else {
                AppState.setDismissBackupNotification(dismiss: true)
                (self.delegate as! HomeViewController).assetsTable.reloadData()
                controller.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    
    @IBAction func didTapAction(_ sender: Any) {
        if !MFMailComposeViewController.canSendMail() {
            OzoneAlert.confirmDialog(OnboardingStrings.mailNotSetupTitle, message: OnboardingStrings.mailNotSetupMessage,
                                     cancelTitle: OzoneAlert.cancelNegativeConfirmString, confirmTitle: OzoneAlert.okPositiveConfirmString, didCancel: { return }) {
                                        Controller().openWalletInfoPage()
            }
            return
        }
        
        let nep6 = NEP6.getFromFileSystem()!
        var nep2String = ""
        for wallet in nep6.accounts {
            if wallet.isDefault {
                nep2String = wallet.key!
            }
        }
        
        let image = UIImage(qrData: nep2String, width: 200, height: 200, qrLogoName: "ic_QRkey")
        let imageData = image.pngData() ?? nil
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        // Configure the fields of the interface.
        composeVC.setSubject(OnboardingStrings.emailSubject)
        composeVC.setMessageBody(String.localizedStringWithFormat(String(OnboardingStrings.emailBody), nep2String), isHTML: false)
        
        //composeVC.addAttachmentData(NEP6.getFromFileSystemAsData(), mimeType: "application/json", fileName: "O3Wallet.json")
        composeVC.addAttachmentData(imageData!, mimeType: "image/png", fileName: "key.png")
        
        // Present the view controller modally.
        UIApplication.shared.keyWindow?.rootViewController?.present(composeVC, animated: true, completion: nil)
    }

    @IBAction func didTapDismiss(_ sender: Any) {
        self.delegate?.didDismiss()
    }

}
