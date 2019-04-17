//
//  VerifyManualBackupViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 1/10/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import M13Checkbox
import KeychainAccess
import Neoutils

class VerifyManualBackupViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var screenshotLabel: UILabel!
    @IBOutlet weak var byHandLabel: UILabel!
    @IBOutlet weak var otherLabel: UILabel!
    @IBOutlet weak var useRawKeyLabel: UILabel!
    
    @IBOutlet weak var keyLabel: UILabel!
    @IBOutlet weak var keyQR: UIImageView!
    
    
    @IBOutlet weak var rawSwitch: UISwitch!
    @IBOutlet weak var screenshotCheckbox: M13Checkbox!
    @IBOutlet weak var byHandCheckbox: M13Checkbox!
    @IBOutlet weak var otherCheckbox: M13Checkbox!
    
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    var account: NEP6.Account!
    
    var encryptedKeyDescriptionText = "Verify your backup by saving your  private or encrypted key in another secure place.\n\nYour encrypted key is password protected, and your funds can only be recovered if you have it, AND your password"
    
    var wifKeyDescriptionText = "Verify your backup by saving your  private or encrypted key in another secure place.\n\nYour raw private key is not password protected, anyone with access to this private key can recover your funds."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        screenshotCheckbox.addTarget(self, action: #selector(checkboxValueChanged(_:)), for: .valueChanged)
        byHandCheckbox.addTarget(self, action: #selector(checkboxValueChanged(_:)), for: .valueChanged)
        otherCheckbox.addTarget(self, action: #selector(checkboxValueChanged(_:)), for: .valueChanged)
        
        for state in AppState.getManualVerifyType(address: account.address) {
            switch state {
                case .screenshot: screenshotCheckbox.setCheckState(.checked, animated: true)
                case .byHand: byHandCheckbox.setCheckState(.checked, animated: true)
                case .other: otherCheckbox.setCheckState(.checked, animated: true)
                default: break
            }
        }
        
        keyLabel.text = account.key!
        keyQR.image = UIImage(qrData: account.key!, width: 125, height: 125, qrLogoName: "ic_QRencryptedKey")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-x"), style: .plain, target: self, action: #selector(dismissPage(_:)))
        self.navigationItem.leftBarButtonItem?.tintColor = Theme.light.primaryColor
        setThemedElements()
        setButtonEnableState()
        setLocalizedStrings()

    }
    
    @objc func dismissPage(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    func attemptUnlockPassword() {
        let alertController = UIAlertController(title: "Show key for " + self.account.label, message: "Please enter the password for this wallet", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: OzoneAlert.okPositiveConfirmString, style: .default) { (_) in
            let inputPass = alertController.textFields?[0].text!
            var error: NSError?
            let decryptedKey = NeoutilsNEP2Decrypt(self.account.key, inputPass, &error)
            if error == nil {
                self.keyLabel.text = decryptedKey!
                self.keyQR.image = UIImage(qrData: decryptedKey!, width: 200, height: 200, qrLogoName: "ic_QRkey")
                self.titleLabel.text = self.wifKeyDescriptionText
            } else {
                OzoneAlert.alertDialog("Incorrect passphrase", message: "Please check your passphrase and try again", dismissTitle: "Ok") {}
                self.rawSwitch.isOn = false
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
    
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        if sender.isOn {
            if account.isDefault {
                let prompt = String(format: OnboardingStrings.nep6AuthenticationPrompt, account.label)
                O3KeychainManager.authenticateWithBiometricOrPass(message: prompt) { result in
                    switch result {
                    case .success(let _):
                        self.keyLabel.text = (Authenticated.wallet?.wif)!
                        self.keyQR.image = UIImage(qrData: (Authenticated.wallet?.wif)!, width: 200, height: 200, qrLogoName: "ic_QRkey")
                        self.titleLabel.text = self.wifKeyDescriptionText
                    case .failure(let _):
                        sender.isOn = false
                    }
                }
            } else {
                attemptUnlockPassword()
            }
        } else {
            titleLabel.text = encryptedKeyDescriptionText
            keyLabel.text = account.key!
            keyQR.image = UIImage(qrData: account.key!, width: 200, height: 200, qrLogoName: "ic_QRencryptedKey")
        }
    }
    
    func setButtonEnableState() {
        if screenshotCheckbox.checkState == .checked || byHandCheckbox.checkState == .checked || otherCheckbox.checkState == .checked {
            verifyButton.isEnabled = true
            verifyButton.theme_setTitleColor(O3Theme.primaryColorPicker, forState: UIControl.State())
        } else {
            verifyButton.isEnabled = false
            verifyButton.theme_setTitleColor(O3Theme.lightTextColorPicker, forState: UIControl.State())
        }
    }
    
    @objc func checkboxValueChanged(_ sender: M13Checkbox) {
        setButtonEnableState()
    }
    
    @IBAction func verifyTapped(_ sender: Any) {
        AppState.setDismissBackupNotification(dismiss: true)
        var types = [AppState.verificationType]()
        if screenshotCheckbox.checkState == .checked {
            types.append(AppState.verificationType.screenshot)
        }
        if byHandCheckbox.checkState == .checked {
            types.append(AppState.verificationType.byHand)
        }
        if otherCheckbox.checkState == .checked {
            types.append(AppState.verificationType.other)
        }
        AppState.setManualVerifyType(address: account.address, types: types)
        
        self.dismiss(animated: true)
    }
    
    func setLocalizedStrings() {
        screenshotLabel.text = "I took a screenshot"
        byHandLabel.text = "I copied it by hand"
        otherLabel.text = "I saved it another way"
        
        cancelButton.setTitle("Cancel", for: UIControl.State())
        verifyButton.setTitle("Verify Backup", for: UIControl.State())
        
        titleLabel.text = encryptedKeyDescriptionText
        title = "Manual Backup"
    }
    
    func setThemedElements() {
        //applyBottomSheetNavBarTheme(title: "Verify Backup")
        navigationController?.hideHairline()
        titleLabel.theme_textColor = O3Theme.titleColorPicker
        screenshotLabel.theme_textColor = O3Theme.titleColorPicker
        byHandLabel.theme_textColor = O3Theme.titleColorPicker
        otherLabel.theme_textColor = O3Theme.titleColorPicker
        useRawKeyLabel.theme_textColor = O3Theme.titleColorPicker
        keyLabel.theme_textColor = O3Theme.titleColorPicker
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
}
