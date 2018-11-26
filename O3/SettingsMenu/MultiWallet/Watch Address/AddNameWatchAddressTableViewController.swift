
//
//  File.swift
//  O3
//
//  Created by Andrei Terentiev on 10/29/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Lottie
import Channel

class AddNameWatchAddressTableViewController: UITableViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nameInputField: UITextField!
    @IBOutlet weak var continueButton: ShadowedButton!
    @IBOutlet weak var animationContainer: UIView!
    
    var address = ""
    
    let lottieView = LOTAnimationView(name: "wallet_generated")
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        setThemedElements()
        animationContainer.embed(lottieView)
        lottieView.loopAnimation = true
        lottieView.play()
        continueButton.isEnabled = false
    }
    
    @IBAction func nameFieldChanged(_ sender: Any) {
        if nameInputField.text == "" {
            continueButton.isEnabled = false
        } else {
            continueButton.isEnabled = true
        }
    }
    
    @IBAction func continueTapped(_ sender: Any) {
        let nameText = nameInputField.text?.trim() ?? ""
        let index = NEP6.getFromFileSystem()!.accounts.firstIndex { $0.label == nameText}
        if index != nil {
            OzoneAlert.alertDialog(message: MultiWalletStrings.cannotAddDuplicate, dismissTitle: OzoneAlert.okPositiveConfirmString) {
                self.nameInputField.text = ""
            }
            return
        }
        
        var updatedNep6 = NEP6.getFromFileSystem()!
        updatedNep6.addWatchAddress(address: address, name: nameInputField.text!)
        updatedNep6.writeToFileSystem()
        Channel.shared().subscribe(toTopic: address)
        self.performSegue(withIdentifier: "segueToWatchAddressFinished", sender: nil)
        

    }
    
    func setLocalizedStrings() {
        titleLabel.text = MultiWalletStrings.setWalletNameTitle
        continueButton.setTitle(MultiWalletStrings.continueAction, for: UIControl.State())
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
