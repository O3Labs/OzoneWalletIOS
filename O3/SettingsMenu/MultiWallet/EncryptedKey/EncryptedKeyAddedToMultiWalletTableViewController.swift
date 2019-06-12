//
//  EncryptedKeyAddedToMultiWalletTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 10/26/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Lottie
import Neoutils
import PKHUD

class EncryptedKeyAddedToMultiWalletTableViewController: UITableViewController {
    @IBOutlet weak var animationContainerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var passwordInputField: UITextField!
    @IBOutlet weak var nameInputField: UITextField!
    @IBOutlet weak var continueButton: ShadowedButton!
    @IBOutlet weak var quickSwapTitleLabel: UILabel!
    @IBOutlet weak var quickSwapSubtitleLabel: UILabel!
    @IBOutlet weak var quickSwapSwitch: UISwitch!
    
    let lottieView = LOTAnimationView(name: "EnterPasswordKey")
    var encryptedKey = ""
    var address = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        setThemedElements()
        animationContainerView.embed(lottieView)
        lottieView.loopAnimation = true
        lottieView.play()
        continueButton.isEnabled = false
        passwordInputField.isSecureTextEntry = true
    }
    
    @IBAction func passwordInputChanged(_ sender: Any) {
        if passwordInputField.text != "" && nameInputField.text != "" {
            continueButton.isEnabled = true
        } else {
            continueButton.isEnabled = false
        }
    }
    @IBAction func nameInputChanged(_ sender: Any) {
        if passwordInputField.text != "" && nameInputField.text != "" {
            continueButton.isEnabled = true
        } else {
            continueButton.isEnabled = false
        }
    }
    
    @IBAction func continueTapped(_ sender: Any) {
        DispatchQueue.main.async { HUD.show(.progress) }
        let nameText = nameInputField.text?.trim() ?? ""
        let index = NEP6.getFromFileSystem()!.getAccounts().firstIndex { $0.label == nameText}
        if index != nil {
            OzoneAlert.alertDialog(message: MultiWalletStrings.cannotAddDuplicate, dismissTitle: OzoneAlert.okPositiveConfirmString) {
                self.nameInputField.text = ""
            }
            DispatchQueue.main.async { HUD.hide() }
            return
        }
        
        let password = passwordInputField.text!
        var error: NSError?
        let wif = NeoutilsNEP2Decrypt(encryptedKey, password, &error)
        if error != nil || wif == nil {
            OzoneAlert.alertDialog(message: MultiWalletStrings.failedToDecrypt, dismissTitle: OzoneAlert.okPositiveConfirmString) {}
            DispatchQueue.main.async { HUD.hide() }
            return
        }
        address = Wallet(wif: wif!)!.address

        
        var updatedNep6 = NEP6.getFromFileSystem()!
        do {
            try updatedNep6.addEncryptedKey(name: nameInputField.text!, address: address, key: encryptedKey)
            MultiwalletEvent.shared.walletAdded(type: "import_key", method: "import")
            if quickSwapSwitch.isOn {
                O3KeychainManager.setNep6DecryptionPassword(for: address, pass: password ) { result in
                    DispatchQueue.main.async {
                        HUD.hide()
                        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true)
                    }
                }
            }
        } catch {
            DispatchQueue.main.async { HUD.hide() }
            OzoneAlert.alertDialog(message: error.localizedDescription, dismissTitle: OzoneAlert.okPositiveConfirmString) {}
        }
    }
    
    func setLocalizedStrings() {
        titleLabel.text = "Please enter a name and the password for this wallet" 
        quickSwapTitleLabel.text = "Enable Quick Swap"
        quickSwapSubtitleLabel.text = "Access this wallet using pincode/touchid"
        passwordInputField.placeholder = MultiWalletStrings.encryptedPasswordHint
        nameInputField.placeholder = "My O3 Wallet"
        continueButton.setTitle(MultiWalletStrings.continueAction, for: UIControl.State())
    }
    
    func setThemedElements() {
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        titleLabel.theme_textColor = O3Theme.titleColorPicker
        quickSwapTitleLabel.theme_textColor = O3Theme.titleColorPicker
        quickSwapSubtitleLabel.theme_textColor = O3Theme.lightTextColorPicker
        passwordInputField.theme_backgroundColor = O3Theme.textFieldBackgroundColorPicker
        passwordInputField.theme_textColor = O3Theme.textFieldTextColorPicker
        passwordInputField.theme_placeholderAttributes = O3Theme.placeholderAttributesPicker
        passwordInputField.theme_keyboardAppearance = O3Theme.keyboardPicker
        
        nameInputField.theme_backgroundColor = O3Theme.textFieldBackgroundColorPicker
        nameInputField.theme_textColor = O3Theme.textFieldTextColorPicker
        nameInputField.theme_placeholderAttributes = O3Theme.placeholderAttributesPicker
        nameInputField.theme_keyboardAppearance = O3Theme.keyboardPicker
    }
}
