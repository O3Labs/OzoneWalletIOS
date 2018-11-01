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
import Lottie

class AddWalletTableViewController: UITableViewController, QRScanDelegate {
    @IBOutlet weak var animationContainerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var walletInputField: UITextField!
    @IBOutlet weak var addWalletButton: ShadowedButton!
    
    let lottieView = LOTAnimationView(name: "wallet_generated")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        initiateNavBar()
        setThemedElements()
        animationContainerView.embed(lottieView)
        lottieView.loopAnimation = true
        lottieView.play()
        addWalletButton.isEnabled = false
        let buttonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "times"), style: .plain, target: self, action: #selector(dismissPage(_:)))
        buttonItem.tintColor = Theme.light.primaryColor
        navigationItem.leftBarButtonItem = buttonItem
    }
    
    @objc func dismissPage(_ sender: Any) {
        //parent is nav controller presenter will be the one above it
        if let parentVC = self.presentingViewController as? ManageWalletsTableViewController {
            self.view.window!.rootViewController?.dismiss(animated: true, completion: nil)
        } else {
            self.dismiss(animated: true)
        }
    }
    
    @objc func scanTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "segueToQR", sender: nil)
    }

    func initiateNavBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_scan"), style: .plain, target: self, action: #selector(scanTapped(_:)))
    }
    
    func isInputAddress() -> Bool {
        return NeoutilsValidateNEOAddress(walletInputField.text!)
    }
    
    func isInputWif() -> Bool {
        if let account = Wallet(wif: walletInputField.text!) {
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
    
    func qrScanned(data: String) {
        walletInputField.text = data
        if data != "" {
            addWalletButton.isEnabled = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? QRScannerController {
            dest.delegate = self
        }
        
        if let dest = segue.destination as? AddNameWatchAddressTableViewController {
            dest.address = walletInputField.text!
        }
        
        if let dest = segue.destination as? EncryptedKeyAddedToMultiWalletTableViewController {
            dest.encryptedKey = walletInputField.text!
        }
    }
    
    func setLocalizedStrings() {
        titleLabel.text = MultiWalletStrings.addWalletDecription
        addWalletButton.setTitle(MultiWalletStrings.continueAction, for: UIControl.State())
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
