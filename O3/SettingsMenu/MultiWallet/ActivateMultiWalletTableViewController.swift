//
//  ActivateMultiWalletTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 10/25/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Neoutils
import KeychainAccess
import Lottie

class ActivateMultiWalletTableViewController: UITableViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var passwordInputField: UITextField!
    @IBOutlet weak var verifyPasswordInputField: UITextField!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var generateNEP6Button: ShadowedButton!
    
    @IBOutlet weak var passwordInputShowButton: UIButton!
    @IBOutlet weak var passwordVerifyShowButton: UIButton!
    
    @IBOutlet weak var animationContainerView: UIView!
    let animation = AnimationView(name: "EnterPasswordKey")
    
    var passwordInputIsSecure = true
    var passwordVerifyIsSecure = true
    
    var allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.~`!@#$%^&*()+=-/;:\"\'{}[]<>^?, ")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyNavBarTheme()
        setLocalizedStrings()
        setThemedElements()
        animation.loopMode = .loop
        animationContainerView.embed(animation)
        animation.play()
        generateNEP6Button.isEnabled = false
        

    }
    
    @objc func dismissPage(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func passwordEntryChanged(_ sender: Any) {
        if passwordInputField.text != "" && verifyPasswordInputField.text != "" {
            generateNEP6Button.isEnabled = true
        } else {
            generateNEP6Button.isEnabled = false
        }
    }
    
    @IBAction func verifyEntryChanged(_ sender: Any) {
        if passwordInputField.text != "" && verifyPasswordInputField.text != "" {
            generateNEP6Button.isEnabled = true
        } else {
            generateNEP6Button.isEnabled = false
        }
    }
    
    
    func validatePassword() -> Bool {
        let passwordText = passwordInputField.text?.trim() ?? ""
        let verifyPasswordText = verifyPasswordInputField.text?.trim() ?? ""
        if !(passwordText.count >= 8) {
            OzoneAlert.alertDialog(message: OnboardingStrings.invalidPasswordLength, dismissTitle: OzoneAlert.okPositiveConfirmString) {
                self.passwordInputField.text = ""
                self.verifyPasswordInputField.text = ""
            }
            return false
        }
        
        if passwordText.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            self.passwordInputField.text = ""
            self.verifyPasswordInputField.text = ""
            return false
        }
        
        if passwordText != verifyPasswordText {
            OzoneAlert.alertDialog(message: OnboardingStrings.passwordMismatch, dismissTitle: OzoneAlert.okPositiveConfirmString) {
                self.passwordInputField.text = ""
                self.verifyPasswordInputField.text = ""
            }
            return false
        }
        
        return true
    }
    
    
    
    @IBAction func passwordInputShowButtonTapped(_ sender: Any) {
        passwordInputIsSecure = !passwordInputIsSecure
        passwordInputField.isSecureTextEntry = passwordInputIsSecure
        let tmp = passwordInputField.text
        passwordInputField.text = ""
        passwordInputField.text = tmp
        if passwordInputIsSecure {
            passwordInputShowButton.alpha = CGFloat(0.3)
        } else {
            passwordInputShowButton.alpha = CGFloat(1.0)
        }
    }
    
    @IBAction func generateEncryptedKeyTapped(_ sender: Any) {
        if !validatePassword() {
            return
        }
        var error: NSError?
        let nep2 = NeoutilsNEP2Encrypt(Authenticated.wallet!.wif, self.passwordInputField.text, &error)
        let newAccount = NEP6.Account(address: Authenticated.wallet!.address,
                                          label: "My O3 Wallet", isDefault: true, lock: false,
                                          key: nep2!.encryptedKey())
        let nep6 = NEP6(name: "Registered O3 Accounts", version: "1.0", accounts: [newAccount])
        
        O3KeychainManager.setNep6DecryptionPassword(for: newAccount.address, pass: self.passwordInputField.text!) { result in
            switch result {
            case .success:
                nep6.writeToFileSystem()
                O3KeychainManager.removeLegacyWifKey { result in
                    switch result {
                    case .success:
                        self.performSegue(withIdentifier: "segueToNep6Complete", sender: nil)
                    case .failure:
                        return
                    }
                }
            case .failure:
                return
            }
        }
    }
    
    @IBAction func passwordVerifyShowButtonTapped(_ sender: Any) {
        passwordVerifyIsSecure = !passwordVerifyIsSecure
        verifyPasswordInputField.isSecureTextEntry = passwordVerifyIsSecure
        let tmp = verifyPasswordInputField.text
        verifyPasswordInputField.text = ""
        verifyPasswordInputField.text = tmp
        if passwordVerifyIsSecure {
            passwordVerifyShowButton.alpha = CGFloat(0.3)
        } else {
            passwordVerifyShowButton.alpha = CGFloat(1.0)
        }
    }
    
    
    func setLocalizedStrings() {
        titleLabel.text = MultiWalletStrings.activateMultiWalletTitle
        passwordInputField.placeholder = "Enter New Password"
        verifyPasswordInputField.placeholder = MultiWalletStrings.verifyPasswordInputHint
        infoLabel.text = MultiWalletStrings.activateMultiWalletInfo
        generateNEP6Button.setTitle(MultiWalletStrings.generateEncryptedKey, for: UIControl.State())
        self.title = "O3 Security Update"
    }
    
    func setThemedElements() {
        titleLabel.theme_textColor = O3Theme.titleColorPicker
        infoLabel.theme_textColor = O3Theme.lightTextColorPicker
        passwordInputField.theme_placeholderAttributes = O3Theme.placeholderAttributesPicker
        passwordInputField.theme_textColor = O3Theme.textFieldTextColorPicker
        passwordInputField.theme_keyboardAppearance = O3Theme.keyboardPicker
        passwordInputField.theme_backgroundColor = O3Theme.textFieldBackgroundColorPicker
        
        verifyPasswordInputField.theme_placeholderAttributes = O3Theme.placeholderAttributesPicker
        verifyPasswordInputField.theme_textColor = O3Theme.textFieldTextColorPicker
        verifyPasswordInputField.theme_keyboardAppearance = O3Theme.keyboardPicker
        verifyPasswordInputField.theme_backgroundColor = O3Theme.textFieldBackgroundColorPicker
        
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
}
