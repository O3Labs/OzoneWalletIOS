//
//  NewMultiWalletViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 10/25/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation

import UIKit
import DeckTransition
import MessageUI

class NewMultiWalletViewController: UIViewController, MFMailComposeViewControllerDelegate {
    @IBOutlet weak var encryptedKeyLabel: UILabel!
    @IBOutlet weak var backupButton: UIButton!
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var encryptedKeyQrImageView: UIImageView!
    
    func setEncryptedKeyInfo() {
        let nep2String = (NEP6.getFromFileSystem()?.getAccounts()[0].key)!
        encryptedKeyLabel.text = nep2String
        let image = UIImage(qrData: nep2String, width: 200, height: 200, qrLogoName: "ic_QRencryptedKey")
        encryptedKeyQrImageView.image = image
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        setThemedElements()
        setEncryptedKeyInfo()
    }
    
    @IBAction func backupButtonTapped(_ sender: Any) {
        if !MFMailComposeViewController.canSendMail() {
            OzoneAlert.confirmDialog(OnboardingStrings.mailNotSetupTitle, message: OnboardingStrings.mailNotSetupMessage,
                                     cancelTitle: OzoneAlert.cancelNegativeConfirmString, confirmTitle: OzoneAlert.okPositiveConfirmString, didCancel: { return }) {
                                        //DO SOMETHING IF NO MAIL SETUP
            }
            return
        }
    
        let nep6 = NEP6.getFromFileSystem()!
        var nep2String = ""
        for wallet in nep6.getAccounts() {
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
        self.present(composeVC, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        DispatchQueue.main.async {
            controller.dismiss(animated: true, completion: nil)
            if result == .cancelled || result == .failed {
                OzoneAlert.alertDialog(message: OnboardingStrings.failedToSendEmailDescription, dismissTitle: OzoneAlert.okPositiveConfirmString) {
                    return
                }
            } else {
                UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
            }
        }
    }

    
    @IBAction func doneButtonTapped(_ sender: Any) {
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    func setLocalizedStrings() {
        backupButton.setTitle(MultiWalletStrings.backupEncryptedKey, for: UIControl.State())
        finishButton.setTitle(MultiWalletStrings.multiWalletFinished, for: UIControl.State())
        descriptionLabel.text = MultiWalletStrings.multiWalletGeneratedDescription
    }
    
    func setThemedElements() {
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
        encryptedKeyLabel.theme_textColor = O3Theme.titleColorPicker
        descriptionLabel.theme_textColor = O3Theme.titleColorPicker
    }
}
