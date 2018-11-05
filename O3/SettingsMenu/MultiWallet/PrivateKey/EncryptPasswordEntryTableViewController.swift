//
//  EncryptPasswordEntryTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 11/5/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Neoutils

class EncryptPasswordEntryTableViewController: UITableViewController {
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var nameEntryTextField: UITextField!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var subtitleLabel: UILabel!
    
    @IBOutlet weak var passwordInputShowButton: UIButton!
    @IBOutlet weak var passwordVerifyShowButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var continueButton: UIButton!
    
    
    var passwordInputIsSecure = true
    var passwordVerifyIsSecure = true
    var wif = ""
    
    var allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.~`!@#$%^&*()+=-/;:\"\'{}[]<>^?,")
    var nep2: NeoutilsNEP2?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        setThemedElements()
    }
    
    func validatePasswordAndName() -> Bool {
        let passwordText = passwordTextField.text?.trim() ?? ""
        let verifyPasswordText = confirmPasswordTextField.text?.trim() ?? ""
        if !(passwordText.count >= 8) {
            OzoneAlert.alertDialog(message: OnboardingStrings.invalidPasswordLength, dismissTitle: OzoneAlert.okPositiveConfirmString) {
                self.passwordTextField.text = ""
                self.confirmPasswordTextField.text = ""
            }
            return false
        }
        
        if passwordText.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            self.passwordTextField.text = ""
            self.confirmPasswordTextField.text = ""
            return false
        }
        
        if passwordText != verifyPasswordText {
            OzoneAlert.alertDialog(message: OnboardingStrings.passwordMismatch, dismissTitle: OzoneAlert.okPositiveConfirmString) {
                self.passwordTextField.text = ""
                self.confirmPasswordTextField.text = ""
            }
            return false
        }
        
        let nameText = nameEntryTextField.text?.trim() ?? ""
        let index = NEP6.getFromFileSystem()!.accounts.firstIndex { $0.label == nameText}
        if index != nil {
            OzoneAlert.alertDialog(message: "Already have dat name bruh", dismissTitle: OzoneAlert.okPositiveConfirmString) {
                self.nameEntryTextField.text = ""
            }
            return false
        }
        
        return true
    }
    
    @IBAction func continutButtonTapped(_ sender: Any) {
        DispatchQueue.main.async {
            if !self.validatePasswordAndName() {
                return
            }
            
            var updatedNep6 = NEP6.getFromFileSystem()!
            do {
                var error: NSError?
                self.nep2 = NeoutilsNEP2Encrypt(self.wif, self.passwordTextField.text!, &error)
                try updatedNep6.addEncryptedKey(name: self.nameEntryTextField.text!, address: self.nep2!.address(), key: self.nep2!.encryptedKey())
                updatedNep6.writeToFileSystem()
                self.performSegue(withIdentifier: "segueToFinishedEncryption", sender: nil)
            } catch {
                OzoneAlert.alertDialog(message: error.localizedDescription, dismissTitle: OzoneAlert.okPositiveConfirmString) {}
            }
        }
    }
    
    @IBAction func nameFieldChanged(_ sender:Any) {
       if nameEntryTextField.text != "" && passwordTextField.text != "" && confirmPasswordTextField.text != "" {
            continueButton.isEnabled = true
        } else {
            continueButton.isEnabled = false
        }
    }
    @IBAction func passwordFieldChanged(_ sender: Any) {
       if nameEntryTextField.text != "" && passwordTextField.text != "" && confirmPasswordTextField.text != "" {
            continueButton.isEnabled = true
        } else {
            continueButton.isEnabled = false
        }
    }
    @IBAction func verifyFieldChanged(_ sender: Any) {
        if nameEntryTextField.text != "" && passwordTextField.text != "" && confirmPasswordTextField.text != "" {
            continueButton.isEnabled = true
        } else {
            continueButton.isEnabled = false
        }
    }

    @IBAction func passwordShowButtonTapped(_ sender: Any) {
        passwordInputIsSecure = !passwordInputIsSecure
        passwordTextField.isSecureTextEntry = passwordInputIsSecure
        let tmp = passwordTextField.text
        passwordTextField.text = ""
        passwordTextField.text = tmp
        if passwordInputIsSecure {
            passwordInputShowButton.alpha = CGFloat(0.3)
        } else {
            passwordInputShowButton.alpha = CGFloat(1.0)
        }
    }
    
    @IBAction func verifyPasswordShowButtonTapped(_ sender: Any) {
        passwordVerifyIsSecure = !passwordVerifyIsSecure
        confirmPasswordTextField.isSecureTextEntry = passwordVerifyIsSecure
        let tmp = confirmPasswordTextField.text
        confirmPasswordTextField.text = ""
        confirmPasswordTextField.text = tmp
        if passwordVerifyIsSecure {
            passwordVerifyShowButton.alpha = CGFloat(0.3)
        } else {
            passwordVerifyShowButton.alpha = CGFloat(1.0)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? EncryptionCompletedViewController {
            dest.encryptedKey = nep2!.encryptedKey()
        }
    }
    
    
    func setLocalizedStrings() {
        titleLabel.text = MultiWalletStrings.activateMultiWalletTitle
        subtitleLabel.text = MultiWalletStrings.activateMultiWalletSubtitle
        passwordTextField.placeholder = MultiWalletStrings.passwordInputHint
        confirmPasswordTextField.placeholder = MultiWalletStrings.verifyPasswordInputHint
        descriptionLabel.text = MultiWalletStrings.activateMultiWalletInfo
    }
    func setThemedElements() {
        titleLabel.theme_textColor = O3Theme.titleColorPicker
        subtitleLabel.theme_textColor = O3Theme.titleColorPicker
        descriptionLabel.theme_textColor = O3Theme.lightTextColorPicker
        passwordTextField.theme_placeholderAttributes = O3Theme.placeholderAttributesPicker
        passwordTextField.theme_textColor = O3Theme.textFieldTextColorPicker
        passwordTextField.theme_keyboardAppearance = O3Theme.keyboardPicker
        passwordTextField.theme_backgroundColor = O3Theme.textFieldBackgroundColorPicker
        
        confirmPasswordTextField.theme_placeholderAttributes = O3Theme.placeholderAttributesPicker
        confirmPasswordTextField.theme_textColor = O3Theme.textFieldTextColorPicker
        confirmPasswordTextField.theme_keyboardAppearance = O3Theme.keyboardPicker
        confirmPasswordTextField.theme_backgroundColor = O3Theme.textFieldBackgroundColorPicker
        
        nameEntryTextField.theme_placeholderAttributes = O3Theme.placeholderAttributesPicker
        nameEntryTextField.theme_textColor = O3Theme.textFieldTextColorPicker
        nameEntryTextField.theme_keyboardAppearance = O3Theme.keyboardPicker
        nameEntryTextField.theme_backgroundColor = O3Theme.textFieldBackgroundColorPicker
        
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
    
}
