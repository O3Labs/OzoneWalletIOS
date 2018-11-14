//
//  AddNameEncryptedKey.swift
//  O3
//
//  Created by Andrei Terentiev on 10/26/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Lottie

class AddNameEncryptedKeyTableViewController: UITableViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nameInputField: UITextField!
    @IBOutlet weak var finishButton: ShadowedButton!
    @IBOutlet weak var animationContainerView: UIView!
    
    var address = ""
    var encryptedKey = ""
    
    var animation = LOTAnimationView(name: "wallet_generated")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        setThemedElements()
        animationContainerView.embed(animation)
        animation.loopAnimation = true
        animation.play()
    }
    
    @IBAction func finishButtonTapped(_ sender: Any) {
        var updatedNep6 = NEP6.getFromFileSystem()!
        
        do {
            try updatedNep6.addEncryptedKey(name: nameInputField.text!, address: address, key: encryptedKey)
                updatedNep6.writeToFileSystem()
                UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true)
        } catch {
            OzoneAlert.alertDialog(message: error.localizedDescription, dismissTitle: OzoneAlert.okPositiveConfirmString) {}
        }
    }
    
    @IBAction func nameFieldChanged(_ sender: Any) {
        if nameInputField.text == "" {
            finishButton.isEnabled = false
        } else {
            finishButton.isEnabled = true
        }
    }
    
    func setLocalizedStrings() {
        titleLabel.text = MultiWalletStrings.setWalletNameTitle
        finishButton.setTitle(MultiWalletStrings.multiWalletFinished, for: UIControl.State())
    }
    
    func setThemedElements() {
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        titleLabel.theme_textColor = O3Theme.titleColorPicker
        
        nameInputField.theme_backgroundColor = O3Theme.textFieldBackgroundColorPicker
        nameInputField.theme_textColor = O3Theme.textFieldTextColorPicker
        nameInputField.theme_placeholderAttributes = O3Theme.placeholderAttributesPicker
        nameInputField.theme_keyboardAppearance = O3Theme.keyboardPicker
    }
}
