//
//  ManageWalletTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 10/31/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import DeckTransition
import MessageUI
import Neoutils

class ManageWalletTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    @IBOutlet weak var addressTitleLabel: UILabel!
    @IBOutlet weak var addressQrView: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    
    @IBOutlet weak var encryptedTitleLabel: UILabel!
    @IBOutlet weak var encryptedKeyLabel: UILabel!
    @IBOutlet weak var encryptedKeyQrView: UIImageView!
    
    @IBOutlet weak var backupWalletLabel: UILabel!
    @IBOutlet weak var showRawKeyLabel: UILabel!
    @IBOutlet weak var removeWalletLabel: UILabel!
    @IBOutlet weak var addKeyLabel: UILabel!
    
    @IBOutlet weak var addKeyTableViewCell: UITableViewCell!
    
    @IBOutlet weak var contentView1: UIView!
    @IBOutlet weak var contentView2: UIView!
    @IBOutlet weak var contentView3: UIView!
    @IBOutlet weak var contentView4: UIView!
    
    
    var isWatchOnly = false
    var account: NEP6.Account!
    
    // swiftlint:disable weak_delegate
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    // swiftlint:enable weak_delegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setThemedElements()
        setLocalizedStrings()
        
        if isWatchOnly {
            addKeyTableViewCell.isHidden = true
        }
        addressLabel.text = account.address
        addressQrView.image = UIImage(qrData: account.address, width: addressQrView.frame.width, height: addressQrView.frame.height, qrLogoName: "ic_QRaddress")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-x"), style: .plain, target: self, action: #selector(dismissTapped(_: )))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_edit"), style: .plain, target: self, action: #selector(editNameTapped(_: )))
        navigationItem.leftBarButtonItem?.theme_tintColor = O3Theme.primaryColorPicker
        navigationItem.rightBarButtonItem?.theme_tintColor = O3Theme.primaryColorPicker
        applyNavBarTheme()
        setEncryptedKey()
    }
    
    @objc func editNameTapped(_ sender: Any) {
        
    }
    
    @objc func dismissTapped(_ sender: Any) {
        self.view.window!.rootViewController?.dismiss(animated: true, completion: nil)
        
    }
    
    func setEncryptedKey() {
        if account.key != nil {
            encryptedKeyQrView.image = UIImage(qrData: account.address, width: encryptedKeyQrView.frame.width, height: encryptedKeyQrView.frame.height, qrLogoName: "ic_QRencryptedKey")
            encryptedKeyLabel.text = account.key!
        } else {
            encryptedKeyQrView.isHidden = true
            encryptedKeyLabel.isHidden = true
            encryptedTitleLabel.isHidden = true
        }
    }
    
    func backupEncryptedKey() {
        if !MFMailComposeViewController.canSendMail() {
            OzoneAlert.confirmDialog(OnboardingStrings.mailNotSetupTitle, message: OnboardingStrings.mailNotSetupMessage,
                                     cancelTitle: OzoneAlert.cancelNegativeConfirmString, confirmTitle: OzoneAlert.okPositiveConfirmString, didCancel: { return }) {
                                        //DO SOMETHING IF NO MAIL SETUP
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
        
        composeVC.addAttachmentData(NEP6.getFromFileSystemAsData(), mimeType: "application/json", fileName: "O3Wallet.json")
        composeVC.addAttachmentData(imageData!, mimeType: "image/png", fileName: "key.png")
        
        // Present the view controller modally.
        DispatchQueue.main.async {
            let transitionDelegate = DeckTransitioningDelegate()
            composeVC.transitioningDelegate = transitionDelegate
            composeVC.modalPresentationStyle = .custom
            self.present(composeVC, animated: true, completion: nil)
        }
    }
    
    func deleteWatchAddress() {
        let nep6 = NEP6.getFromFileSystem()!
        nep6.removeEncryptedKey(address: account.address)
        nep6.writeToFileSystem()
    }
    
    func deleteEncryptedKeyVerify() {
        let alertController = UIAlertController(title: "Make a password", message: "some message", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: OzoneAlert.okPositiveConfirmString, style: .default) { (_) in
            let inputPass = alertController.textFields?[0].text!
            var error: NSError?
            let decrypted =  NeoutilsNEP2Decrypt(self.account.key!, inputPass, &error)
    
            if error == nil {
                let nep6 = NEP6.getFromFileSystem()!
                nep6.removeEncryptedKey(address: self.account.address)
                nep6.writeToFileSystem()
            }
        }
        
        let cancelAction = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        UIApplication.shared.keyWindow?.rootViewController?.presentFromEmbedded(alertController, animated: true, completion: nil)

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            backupEncryptedKey()
        } else if indexPath.row == 1 {
            self.performSegue(withIdentifier: "segueToShowPrivateKey", sender: nil)
        } else if indexPath.row == 2 {
            self.performSegue(withIdentifier: "segueToConvertWallet", sender: nil)
        } else if indexPath.row == 3 {
            if account.isDefault {
                OzoneAlert.alertDialog(message: MultiWalletStrings.cannotDeletePrimary, dismissTitle: OzoneAlert.okPositiveConfirmString) { }
            } else if account.key == nil {
                OzoneAlert.confirmDialog(MultiWalletStrings.deleteEncryptedConfirm, message: MultiWalletStrings.deleteWatchAddress, cancelTitle: OzoneAlert.cancelNegativeConfirmString, confirmTitle: OzoneAlert.confirmPositiveConfirmString, didCancel: {}) {
                    self.deleteWatchAddress()
                }
            } else {
                deleteEncryptedKeyVerify()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToShowPrivateKey" {
            self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: segue.destination)
            segue.destination.modalPresentationStyle = .custom
            segue.destination.transitioningDelegate = self.halfModalTransitioningDelegate
        } else if let dest = segue.destination as? ConvertToWalletTableViewController {
            dest.watchAddress = account.address
        }
    }

    
    func setLocalizedStrings() {
        addressTitleLabel.text = MultiWalletStrings.address
        backupWalletLabel.text = MultiWalletStrings.backupWallet
        showRawKeyLabel.text = MultiWalletStrings.showRawKey
        removeWalletLabel.text = MultiWalletStrings.removeWallet
        addKeyLabel.text = MultiWalletStrings.addKey
        encryptedTitleLabel.text = MultiWalletStrings.encryptedKey
        self.title = account.label
    }
    
    func setThemedElements() {
        addressTitleLabel.theme_textColor = O3Theme.titleColorPicker
        addressLabel.theme_textColor = O3Theme.titleColorPicker
        encryptedTitleLabel.theme_textColor = O3Theme.titleColorPicker
        encryptedKeyLabel.theme_textColor = O3Theme.titleColorPicker
        
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        
        contentView1.theme_backgroundColor = O3Theme.backgroundColorPicker
        contentView2.theme_backgroundColor = O3Theme.backgroundColorPicker
        contentView3.theme_backgroundColor = O3Theme.backgroundColorPicker
        contentView4.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
}
