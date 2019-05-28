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
import Channel

class ManageWalletTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    @IBOutlet weak var addressTitleLabel: UILabel!
    @IBOutlet weak var addressQrView: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    
    @IBOutlet weak var encryptedTitleLabel: UILabel!
    @IBOutlet weak var encryptedKeyLabel: UILabel!
    @IBOutlet weak var encryptedKeyQrView: UIImageView!
    
    @IBOutlet weak var quickSwapLabel: UILabel!
    @IBOutlet weak var backupWalletLabel: UILabel!
    @IBOutlet weak var showRawKeyLabel: UILabel!
    @IBOutlet weak var removeWalletLabel: UILabel!
    @IBOutlet weak var addKeyLabel: UILabel!
    @IBOutlet weak var manualBackupLabel: UILabel!
    
    @IBOutlet weak var addKeyTableViewCell: UITableViewCell!
    
    @IBOutlet weak var contentView1: UIView!
    @IBOutlet weak var contentView2: UIView!
    @IBOutlet weak var contentView3: UIView!
    @IBOutlet weak var contentView4: UIView!
    @IBOutlet weak var contentView5: UIView!
    @IBOutlet weak var contentView6: UIView!

    @IBOutlet weak var quickSwapSwitch: UISwitch!
    
    
    
    @IBOutlet weak var unlockWatchAddressDescription: UILabel!
    @IBOutlet weak var unlockWatchAddressButton: ShadowedButton!
    
    
    var isWatchOnly = false
    var account: NEP6.Account!
    var pkey = ""
    
    // swiftlint:disable weak_delegate
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    // swiftlint:enable weak_delegate
    
    
    func addWalletChangeObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateAccount(_:)), name: Notification.Name(rawValue: "NEP6Updated"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "NEP6Updated"), object: nil)
    }
    
    @objc func updateAccount(_ sender: Any?) {
        let nep6 = NEP6.getFromFileSystem()!
        if let accountIndex = nep6.getAccounts().firstIndex(where: {$0.address == account.address}) {
            account = nep6.getAccounts()[accountIndex]
            setWalletDetails()
        }
        tableView.reloadData()
    }
    
    func setWalletDetails() {
        if isWatchOnly {
            addKeyTableViewCell.isHidden = true
        }
        
        addressLabel.text = account.address
        addressQrView.image = UIImage(qrData: account.address, width: addressQrView.frame.width, height: addressQrView.frame.height, qrLogoName: "ic_QRaddress")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-x"), style: .plain, target: self, action: #selector(dismissTapped(_: )))
        navigationItem.leftBarButtonItem?.theme_tintColor = O3Theme.primaryColorPicker
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_edit"), style: .plain, target: self, action: #selector(editNameTapped(_: )))
        navigationItem.rightBarButtonItem?.theme_tintColor = O3Theme.primaryColorPicker
        setEncryptedKey()
        self.title = account.label
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //watch addr
        if account.key == nil {
            if indexPath.row == 5 {
                return CGFloat(44)
            } else {
                return CGFloat(0)
            }
        }
        
        if account.isDefault {
            if indexPath.row == 1 {
                return CGFloat(0)
            }
        }
        
        return CGFloat(44)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addWalletChangeObserver()
        setThemedElements()
        setLocalizedStrings()
        setWalletDetails()
        applyNavBarTheme()
        setupQuickSwapSelector()
    }
    
    func setupQuickSwapSelector() {
        quickSwapSwitch.isUserInteractionEnabled = false
        let containsPass = O3KeychainManager.containsNep6Password(for: account.address)
        DispatchQueue.main.async { self.quickSwapSwitch.setOn(containsPass, animated: false)}
    }
    
    @objc func editNameTapped(_ sender: Any) {
        let alertController = UIAlertController(title: MultiWalletStrings.editName, message: MultiWalletStrings.enterNewName, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: OzoneAlert.okPositiveConfirmString, style: .default) { (_) in
            let inputNewName = alertController.textFields?[0].text!
            let nep6 = NEP6.getFromFileSystem()!
            nep6.editName(address: self.account.address, newName: inputNewName!)
        }
        
        let cancelAction = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = MultiWalletStrings.myWalletPlaceholder
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        UIApplication.shared.keyWindow?.rootViewController?.presentFromEmbedded(alertController, animated: true, completion: nil)
    }
    
    @IBAction func unlockWatchAddressTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "segueToConvertWallet", sender: nil)
    }
    
    @objc func dismissTapped(_ sender: Any) {
        self.view.window!.rootViewController?.dismiss(animated: true, completion: nil)
        
    }
    
    func setEncryptedKey() {
        if account.key != nil {
            encryptedKeyQrView.image = UIImage(qrData: account.key!, width: encryptedKeyQrView.frame.width, height: encryptedKeyQrView.frame.height, qrLogoName: "ic_QRencryptedKey")
            encryptedKeyLabel.text = account.key!
            unlockWatchAddressButton.isHidden = true
            unlockWatchAddressDescription.isHidden = true
            encryptedKeyQrView.isHidden = false
            encryptedKeyLabel.isHidden = false
            encryptedTitleLabel.isHidden = false
        } else {
            unlockWatchAddressButton.isHidden = false
            unlockWatchAddressDescription.isHidden = false
            encryptedKeyQrView.isHidden = true
            encryptedKeyLabel.isHidden = true
            encryptedTitleLabel.isHidden = true
        }
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
    
    func backupEncryptedKey() {
        if !MFMailComposeViewController.canSendMail() {
            OzoneAlert.confirmDialog(OnboardingStrings.mailNotSetupTitle, message: OnboardingStrings.mailNotSetupMessage,
                                     cancelTitle: OzoneAlert.cancelNegativeConfirmString, confirmTitle: OzoneAlert.okPositiveConfirmString, didCancel: { return }) {
                                        //DO SOMETHING IF NO MAIL SETUP
            }
            return
        }
    
        let image = UIImage(qrData: account.key!, width: 200, height: 200, qrLogoName: "ic_QRkey")
        let imageData = image.pngData() ?? nil
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        // Configure the fields of the interface.
        composeVC.setSubject(OnboardingStrings.emailSubject)
        composeVC.setMessageBody(String.localizedStringWithFormat(String(OnboardingStrings.emailBody), account.key!), isHTML: false)
        
        //composeVC.addAttachmentData(NEP6.getFromFileSystemAsData(), mimeType: "application/json", fileName: "O3Wallet.json")
        composeVC.addAttachmentData(imageData!, mimeType: "image/png", fileName: "key.png")
        
        self.present(composeVC, animated: true, completion: nil)
    }
    
    func deleteWatchAddress() {
        let nep6 = NEP6.getFromFileSystem()!
        nep6.removeEncryptedKey(address: account.address)
        Channel.shared().unsubscribe(fromTopic: account.address, block: {})
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true)
    }
    
    func deleteEncryptedKeyVerify() {
        let deleteString = String(format: MultiWalletStrings.deleteWatchAddressTitle, account.label)
        OzoneAlert.confirmDialog(deleteString   , message: MultiWalletStrings.deleteEncryptedConfirm, cancelTitle: OzoneAlert.cancelNegativeConfirmString, confirmTitle: OzoneAlert.confirmPositiveConfirmString, didCancel: {}) {
                let nep6 = NEP6.getFromFileSystem()!
                nep6.removeEncryptedKey(address: self.account.address)
                Channel.shared().unsubscribe(fromTopic: self.account.address, block: {})
            
                UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true)
        }
    }
    
    func setWalletToDefault() {
        let alertController = UIAlertController(title: "Unlock " + self.account.label, message: "Please enter the password for this wallet. This will set it to default and lock all other wallets.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: OzoneAlert.okPositiveConfirmString, style: .default) { (_) in
            let inputPass = alertController.textFields?[0].text!
            var error: NSError?
                _ = NeoutilsNEP2Decrypt(self.account.key, inputPass, &error)
                if error == nil {
                    NEP6.makeNewDefault(address: self.account.address, pass: inputPass!)
                    OzoneAlert.alertDialog("Success", message: "This is now your new default wallet", dismissTitle: "Ok") {}
                    MultiwalletEvent.shared.walletUnlocked()
                } else {
                    OzoneAlert.alertDialog("Incorrect passphrase", message: "Please check your passphrase and try again", dismissTitle: "Ok") {}
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
    
    func toggleQuickSwap() {
        if quickSwapSwitch.isOn {
            OzoneAlert.confirmDialog(message: "Turning off quick swap means you will need to reenter the password to access this wallet", cancelTitle: OzoneAlert.cancelNegativeConfirmString, confirmTitle: OzoneAlert.confirmPositiveConfirmString, didCancel: {}) {
                O3KeychainManager.removeNep6DecryptionPassword(for: self.account.address) {
                    result in
                    switch result {
                    case .success(_):
                        DispatchQueue.main.async { self.quickSwapSwitch.setOn(false, animated: true) }
                    case .failure(_):
                        return
                    }
                }
            }
        } else {
            let alertController = UIAlertController(title: "Enable Quick swap for " + self.account.label, message: "Please enter the password for this wallet", preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: OzoneAlert.okPositiveConfirmString, style: .default) { (_) in
                let inputPass = alertController.textFields?[0].text!
                var error: NSError?
                let decryptedKey = NeoutilsNEP2Decrypt(self.account.key, inputPass, &error)
                if error == nil {
                    O3KeychainManager.setNep6DecryptionPassword(for: self.account.address, pass: inputPass!) { result in
                        switch result {
                        case .success(_):
                            DispatchQueue.main.async { self.quickSwapSwitch.setOn(true, animated: true) }
                        case .failure(_):
                            return
                        }
                    }
                } else {
                    OzoneAlert.alertDialog("Incorrect passphrase", message: "Please check your passphrase and try again", dismissTitle: "Ok") {}
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
    }
    
    func showPrivateKey() {
        let alertController = UIAlertController(title: "Show key for " + self.account.label, message: "Please enter the password for this wallet", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: OzoneAlert.okPositiveConfirmString, style: .default) { (_) in
            let inputPass = alertController.textFields?[0].text!
            var error: NSError?
            let decryptedKey = NeoutilsNEP2Decrypt(self.account.key, inputPass, &error)
            if error == nil {
                self.pkey = decryptedKey!
                self.performSegue(withIdentifier: "segueToShowPrivateKey", sender: nil)
            } else {
                OzoneAlert.alertDialog("Incorrect passphrase", message: "Please check your passphrase and try again", dismissTitle: "Ok") {}
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
    
    func performManualBackup() {
        guard let verifyVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "verifyManualBackupViewController") as? VerifyManualBackupViewController else {
            fatalError("Something went terribly wrong")
        }
        verifyVC.account = account
        let nav = UINavigationController()
        nav.viewControllers = [verifyVC]
        self.present(nav, animated: true, completion: nil)

    }
    
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
          toggleQuickSwap()
        } else if indexPath.row == 1 {
            if account.key == nil {
                showPrivateKey()
            } else {
                setWalletToDefault()
            }
        } else if indexPath.row == 2 {
            backupEncryptedKey()
        } else if indexPath.row == 3 {
            showPrivateKey()
        } else if indexPath.row == 4 {
            performManualBackup()
        } else if indexPath.row == 5 {
            if account.isDefault {
                OzoneAlert.alertDialog(message: MultiWalletStrings.cannotDeletePrimary, dismissTitle: OzoneAlert.okPositiveConfirmString) { }
            } else if account.key == nil {
                let deleteString = String(format: MultiWalletStrings.deleteWatchAddressTitle, account.label)
                OzoneAlert.confirmDialog(deleteString, message: MultiWalletStrings.deleteWatchAddress, cancelTitle: OzoneAlert.cancelNegativeConfirmString, confirmTitle: OzoneAlert.confirmPositiveConfirmString, didCancel: {}) {
                    self.deleteWatchAddress()
                }
            } else {
                deleteEncryptedKeyVerify()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? UINavigationController {
            let childvc = dest.children[0] as! PrivateKeyViewController
            childvc.privateKey = pkey
            self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: segue.destination)
            segue.destination.modalPresentationStyle = .custom
            segue.destination.transitioningDelegate = self.halfModalTransitioningDelegate
        } else if let dest = segue.destination as? ConvertToWalletTableViewController {
            dest.watchAddress = account.address
        }
    }

    
    func setLocalizedStrings() {
        addressTitleLabel.text = MultiWalletStrings.address
        backupWalletLabel.text = "Export Wallet Backup"
        showRawKeyLabel.text = MultiWalletStrings.showRawKey
        removeWalletLabel.text = MultiWalletStrings.removeWallet
        addKeyLabel.text = MultiWalletStrings.addKey
        encryptedTitleLabel.text = MultiWalletStrings.encryptedKey
        unlockWatchAddressDescription.text = MultiWalletStrings.addKeyDescription
        unlockWatchAddressButton.setTitle(MultiWalletStrings.addKey, for: UIControl.State())
        manualBackupLabel.text = "Verify Manual Backup"
        quickSwapLabel.text = "Enable Quick Swap"
    }
    
    func setThemedElements() {
        addressTitleLabel.theme_textColor = O3Theme.titleColorPicker
        addressLabel.theme_textColor = O3Theme.titleColorPicker
        encryptedTitleLabel.theme_textColor = O3Theme.titleColorPicker
        encryptedKeyLabel.theme_textColor = O3Theme.titleColorPicker
        unlockWatchAddressDescription.theme_textColor = O3Theme.titleColorPicker
        quickSwapLabel.theme_textColor = O3Theme.titleColorPicker
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        
        contentView1.theme_backgroundColor = O3Theme.backgroundColorPicker
        contentView2.theme_backgroundColor = O3Theme.backgroundColorPicker
        contentView3.theme_backgroundColor = O3Theme.backgroundColorPicker
        contentView4.theme_backgroundColor = O3Theme.backgroundColorPicker
        contentView5.theme_backgroundColor =
            O3Theme.backgroundColorPicker
        contentView6.theme_backgroundColor =
            O3Theme.backgroundColorPicker
    }
}
