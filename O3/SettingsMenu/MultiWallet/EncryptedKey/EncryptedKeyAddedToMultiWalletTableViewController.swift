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

class EncryptedKeyAddedToMultiWalletTableViewController: UITableViewController {
    @IBOutlet weak var animationContainerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var passwordInputField: UITextField!
    @IBOutlet weak var continueButton: ShadowedButton!
    
    let lottieView = LOTAnimationView(name: "wallet_generated")
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
    }
    
    @IBAction func passwordInputChanged(_ sender: Any) {
        if passwordInputField.text == "" {
            continueButton.isEnabled = false
        } else {
            continueButton.isEnabled = true
        }
    }
    
    @IBAction func continueTapped(_ sender: Any) {
        var error: NSError?
        let wif = NeoutilsNEP2Decrypt(encryptedKey, passwordInputField.text!, &error)
        address = Account(wif: wif!)!.address
        if error != nil {
            OzoneAlert.alertDialog(message: MultiWalletStrings.failedToDecrypt, dismissTitle: OzoneAlert.okPositiveConfirmString) {}
        } else {
            performSegue(withIdentifier: "segueToAddNameForEncryptedKey", sender: nil)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? AddNameEncryptedKeyTableViewController {
            dest.address = address
            dest.encryptedKey = encryptedKey
        }
    }
    
    func setLocalizedStrings() {
        titleLabel.text = MultiWalletStrings.encryptedKeyDetected
        passwordInputField.placeholder = MultiWalletStrings.encryptedPasswordHint
        continueButton.setTitle(MultiWalletStrings.continueAction, for: UIControl.State())
    }
    
    func setThemedElements() {
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        titleLabel.theme_textColor = O3Theme.titleColorPicker
        passwordInputField.theme_backgroundColor = O3Theme.textFieldBackgroundColorPicker
        passwordInputField.theme_textColor = O3Theme.textFieldTextColorPicker
        passwordInputField.theme_placeholderAttributes = O3Theme.placeholderAttributesPicker
        passwordInputField.theme_keyboardAppearance = O3Theme.keyboardPicker
    }
}
