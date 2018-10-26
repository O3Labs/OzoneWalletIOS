//
//  AddWalletTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 10/26/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Neoutils

class AddWalletTableViewController: UITableViewController {
    @IBOutlet weak var animationContainerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var walletInputField: UITextField!
    @IBOutlet weak var addWalletButton: ShadowedButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        setThemedElements()
        addWalletButton.isEnabled = false
    }
    
    func isInputAddress() -> Bool {
        return NeoutilsValidateNEOAddress(walletInputField.text!)
    }
    
    func isInputWif() -> Bool {
        if let account = Account(wif: walletInputField.text!) {
            return true
        }
        return false
    }
    
    func isInputEncryptedKey() -> Bool {
        return walletInputField.text!.count == 58 && walletInputField.text!.hasPrefix("6P")
    }
    
    @IBAction func walletInputChanged(_ sender: Any) {
        if walletInputField.text == "" {
            addWalletButton.isEnabled = false
        } else {
            addWalletButton.isEnabled = true
        }
    }
    
    
    @IBAction func addWalletButtonTapped(_ sender: Any) {
        if isInputAddress() {
            self.performSegue(withIdentifier: "segueToAddedWatchAddress", sender: nil)
        } else if isInputEncryptedKey() {
            self.performSegue(withIdentifier: "segueToVerifyEncryptedKey", sender: nil)
        } else if isInputWif() {
            self.performSegue(withIdentifier: "segueToAddedWif", sender: nil)
        } else  {
            OzoneAlert.alertDialog(message: MultiWalletStrings.invalidWalletEntry, dismissTitle: OzoneAlert.okPositiveConfirmString) {
            }
        }
    }
    
    func setLocalizedStrings() {
        titleLabel.text = MultiWalletStrings.addWalletDecription
    }
    
    func setThemedElements() {
        titleLabel.theme_textColor = O3Theme.titleColorPicker
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        walletInputField.theme_backgroundColor = O3Theme.textFieldBackgroundColorPicker
        walletInputField.theme_textColor = O3Theme.textFieldTextColorPicker
        walletInputField.theme_placeholderAttributes = O3Theme.placeholderAttributesPicker
        walletInputField.theme_keyboardAppearance = O3Theme.keyboardPicker
    }
}
