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

class SecurityCenterTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    @IBOutlet weak var addressTitleLabel: UILabel!
    @IBOutlet weak var securityStatusImageView: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    
    @IBOutlet weak var quickSwapLabel: UILabel!
    @IBOutlet weak var backupWalletLabel: UILabel!
    @IBOutlet weak var manualBackupLabel: UILabel!
    
    
    @IBOutlet weak var quickSwapContentView: UIView!
    @IBOutlet weak var exportWalletContentView: UIView!
    @IBOutlet weak var manualBackupContentView: UIView!
    @IBOutlet weak var editNameContentView: UIView!
    
    @IBOutlet weak var quickSwapSwitch: UISwitch!
    
    @IBOutlet weak var securityStatusTitleLabel: UILabel!
    @IBOutlet weak var securityStatusSubtitleLabel: UILabel!
    @IBOutlet weak var editNameLabel: UILabel!
    
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
        addressLabel.text = account.address
        addressTitleLabel.text = account.label
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-x"), style: .plain, target: self, action: #selector(dismissTapped(_: )))
        navigationItem.leftBarButtonItem?.theme_tintColor = O3Theme.primaryColorPicker
        self.title = "Security Center"
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
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
    
    override func viewWillAppear(_ animated: Bool) {
        setLocalizedStrings()
        setThemedElements()
        super.viewWillAppear(animated)
    }
    
    func setupQuickSwapSelector() {
        quickSwapSwitch.isUserInteractionEnabled = false
        let containsPass = O3KeychainManager.containsNep6Password(for: account.address)
        DispatchQueue.main.async { self.quickSwapSwitch.setOn(containsPass, animated: false)}
    }
    
    @objc func editNameTapped() {
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
    
    @objc func dismissTapped(_ sender: Any) {
        self.view.window!.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        DispatchQueue.main.async {
            controller.dismiss(animated: true, completion: nil)
            if result == .cancelled || result == .failed {
                OzoneAlert.alertDialog(message: OnboardingStrings.failedToSendEmailDescription, dismissTitle: OzoneAlert.okPositiveConfirmString) {
                    return
                }
            } else {
                UserDefaultsManager.setWalletBackupTime(address: self.account.address, timeStamp: Int(Date().timeIntervalSince1970))
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
        
        composeVC.addAttachmentData(imageData!, mimeType: "image/png", fileName: "key.png")
        
        self.present(composeVC, animated: true, completion: nil)
    }
    
    func deleteWatchAddress() {
        let nep6 = NEP6.getFromFileSystem()!
        nep6.removeEncryptedKey(address: account.address)
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true)
    }
    
    func deleteEncryptedKeyVerify() {
        let deleteString = String(format: MultiWalletStrings.deleteWatchAddressTitle, account.label)
        OzoneAlert.confirmDialog(deleteString   , message: MultiWalletStrings.deleteEncryptedConfirm, cancelTitle: OzoneAlert.cancelNegativeConfirmString, confirmTitle: OzoneAlert.confirmPositiveConfirmString, didCancel: {}) {
                let nep6 = NEP6.getFromFileSystem()!
                nep6.removeEncryptedKey(address: self.account.address)
            
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
            backupEncryptedKey()
        } else if indexPath.row == 1 {
            performManualBackup()
        } else if indexPath.row == 2 {
            editNameTapped()
        } else if indexPath.row == 3 {
            toggleQuickSwap()
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
        backupWalletLabel.text = "Backup this Wallet"
        manualBackupLabel.text = "Show my Keys (Manual Backup)"
        editNameLabel.text = "Rename Wallet"
        quickSwapLabel.text = "Enable Quick Swap"
        
        if let timestamp = UserDefaultsManager.getWalletBackupTime(address: account.address) {
            let dateformatter = DateFormatter()
            dateformatter.dateStyle = .short
            dateformatter.timeStyle = .none
            var methodString = ""
            let methods = AppState.getManualVerifyType(address: account.address)
            if methods.isEmpty {
                methodString = "via email"
            } else {
                switch (methods.first!) {
                case .screenshot:
                    methodString = "via screenshot"
                case .other:
                    methodString = "via other method"
                case .byHand:
                    methodString = "by hand"
                }
            }
            let dateString = dateformatter.string(from: Date(timeIntervalSince1970: Double(timestamp)))
            securityStatusTitleLabel.text = "You've confirmed backup of this wallet on \(dateString) \(methodString)"
            securityStatusSubtitleLabel.text = "We reccomend that you regularly update your backup in case your device is lost or broken"
        } else {
            securityStatusTitleLabel.text = "Wallet Backup Not Detected"
            securityStatusSubtitleLabel.text = "Please confirm your backup with one of the options below"
        }
    }
    
    func setThemedElements() {
        addressTitleLabel.theme_textColor = O3Theme.titleColorPicker
        addressLabel.theme_textColor = O3Theme.lightTextColorPicker
        quickSwapLabel.theme_textColor = O3Theme.primaryColorPicker
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        
        quickSwapContentView.theme_backgroundColor = O3Theme.backgroundColorPicker
        exportWalletContentView.theme_backgroundColor = O3Theme.backgroundColorPicker
        manualBackupContentView.theme_backgroundColor =
            O3Theme.backgroundColorPicker
        editNameContentView.theme_backgroundColor =
        O3Theme.backgroundColorPicker
        
        if UserDefaultsManager.getWalletBackupTime(address: account.address) == nil {
            securityStatusTitleLabel.theme_textColor = O3Theme.negativeLossColorPicker
            securityStatusImageView.image = UIImage(named: "ic_nobackup")
        } else {
            securityStatusTitleLabel.theme_textColor = O3Theme.positiveGainColorPicker
            securityStatusImageView.image = UIImage(named: "ic_backup")
        }
        
        securityStatusSubtitleLabel.theme_textColor = O3Theme.lightTextColorPicker
    }
}
