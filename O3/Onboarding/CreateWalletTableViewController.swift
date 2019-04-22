//
//  CreateWalletTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 1/9/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Lottie
import Neoutils
import KeychainAccess
import PKHUD

class CreateWalletTableViewController: UITableViewController, UITextFieldDelegate {
    @IBOutlet weak var lottieContainer: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    @IBOutlet weak var enterPasswordField: O3FloatingTextField!
    @IBOutlet weak var confirmPasswordField: O3FloatingTextField!
    
    @IBOutlet weak var createButton: UIButton!
    
    @IBOutlet weak var passwordButton: UIButton!
    @IBOutlet weak var confirmPasswordButton: UIButton!
    
    
    let lottieView = LOTAnimationView(name: "an_create_wallet")

    override func viewDidLoad() {
        super.viewDidLoad()
        lottieContainer.embed(lottieView)
        lottieView.loopAnimation = true
        lottieView.play()
        
        enterPasswordField.delegate = self
        enterPasswordField.addTarget(self, action: #selector(passwordFieldChanged(_:)), for: .editingChanged)
        
        confirmPasswordField.delegate = self
        confirmPasswordField.addTarget(self, action: #selector(confirmPasswordFieldChanged(_:)), for: .editingChanged)
        
        setLocalizedStrings()
    }
    
    @objc func passwordFieldChanged(_ textfield: UITextField) {
        if (enterPasswordField.text!.count > 5 && enterPasswordField.text!.count < 8) {
            enterPasswordField.errorMessage = "Your password must be at least 8 characters"
        } else {
            enterPasswordField.errorMessage = nil
        }
    }
    
    @objc func confirmPasswordFieldChanged(_ textfield: UITextField) {
        if (confirmPasswordField.text! != enterPasswordField.text) {
            confirmPasswordField.errorMessage = "Your passwords don't match"
        } else {
            confirmPasswordField.errorMessage = nil
            createButton.isEnabled = true
            createButton.backgroundColor = Theme.light.accentColor
        }
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func revealPasswordTapped(_ sender: Any) {
        if enterPasswordField.isSecureTextEntry {
            passwordButton.alpha = 1.0
        } else {
            passwordButton.alpha = 0.3
        }
        enterPasswordField.isSecureTextEntry = !enterPasswordField.isSecureTextEntry
    }
    
    @IBAction func revealConfirmPasswordTapped(_ sender: Any) {
        if confirmPasswordField.isSecureTextEntry {
            confirmPasswordButton.alpha = 1.0
        } else {
            confirmPasswordButton.alpha = 0.3
        }
        
        confirmPasswordField.isSecureTextEntry = !confirmPasswordField.isSecureTextEntry
    }
    
    
    @IBAction func createButtonTapped(_ sender: Any) {
        DispatchQueue.main.async { HUD.show(.progress) }
        let password = self.enterPasswordField.text!
        DispatchQueue.global(qos: .userInitiated).async {
            let wallet = Wallet()
            var error: NSError?
                let nep2 = NeoutilsNEP2Encrypt(wallet?.wif, password, &error)!
            
            let newAccount = NEP6.Account(address: nep2.address(),
                                          label: "My O3 Wallet", isDefault: true, lock: false,
                                          key: nep2.encryptedKey())
            let nep6 = NEP6(name: "Registered O3 Accounts", version: "1.0", accounts: [newAccount])
            
            O3KeychainManager.setNep6DecryptionPassword(for: newAccount.address, pass: password) { result in
                switch (result) {
                case .success(_):
                    nep6.writeToFileSystem()
                    Authenticated.wallet = wallet
                    DispatchQueue.main.async {
                        HUD.hide()
                        self.performSegue(withIdentifier: "segueToWelcome", sender: nil)
                        MultiwalletEvent.shared.walletAdded(type: "new_key", method: "new")
                    }
                case .failure(_):
                    fatalError("Something went terribly wrong")
                }
            }
        }
    }
    
    func setLocalizedStrings() {
        titleLabel.text = "Let's get started!"
        subtitleLabel.text = "Enter a password for your new wallet. This password is not stored on O3 servers and cannot be recovered if lost."
        createButton.setTitle("Create a New Wallet", for: UIControl.State())
        
        enterPasswordField.placeholder = OnboardingStrings.createPasswordHint
        confirmPasswordField.placeholder = OnboardingStrings.reenterPasswordHint
    }
}
