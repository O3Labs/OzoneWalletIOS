//
//  LoginV2TableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 6/8/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Neoutils
import SwiftTheme
import KeychainAccess
import Channel
import PKHUD
import SkyFloatingLabelTextField
import DeckTransition
import Lottie

class LoginV2TableViewController: UITableViewController, UITextFieldDelegate, QRScanDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var keyField: O3FloatingTextField!
    
    

    @IBOutlet weak var passwordField: O3FloatingTextField!
    @IBOutlet weak var passwordFieldHeight: NSLayoutConstraint!
    @IBOutlet weak var passwordRevealButton: UIButton!
    
    
    @IBOutlet weak var confirmPassWordField: O3FloatingTextField!
    @IBOutlet weak var confirmPasswordFieldHeight: NSLayoutConstraint!
    @IBOutlet weak var confirmPasswordRevealButton: UIButton!
    
    @IBOutlet weak var containerView: UIView!
    let lottieAnimation = AnimationView(name: "an_create_wallet")
    
    var alreadyScanned = false
    var qrView: UIView!
    var invalidateFromQr = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        lottieAnimation.play()
        lottieAnimation.loopMode = .loop
        containerView.embed(lottieAnimation)
    
        navigationController!.hideHairline()
        keyField.delegate = self
        keyField.addTarget(self, action: #selector(keyFieldChanged(_:)), for: .editingChanged)
        
        passwordField.delegate = self
        passwordField.addTarget(self, action: #selector(passwordFieldChanged(_:)), for: .editingChanged)
        
        confirmPassWordField.delegate = self
        confirmPassWordField.addTarget(self, action: #selector(confirmPasswordFieldChanged(_:)), for: .editingChanged)
        
        passwordFieldHeight.constant = CGFloat(0)
        passwordField.isHidden = true
        confirmPasswordFieldHeight.constant = CGFloat(0)
        confirmPassWordField.isHidden = true
        
        loginButton.isEnabled = false
        self.navigationController!.hideHairline()
        let qrView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height * 0.5))
        tableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height * 0.5)
        tableView.tableHeaderView?.embed(qrView)
        
    }
    
    @IBAction func revealPasswordTapped(_ sender: Any) {
        if passwordField.isSecureTextEntry {
            passwordRevealButton.alpha = 1.0
        } else {
            passwordRevealButton.alpha = 0.3
        }
        passwordField.isSecureTextEntry = !passwordField.isSecureTextEntry
    }
    
    @IBAction func revealConfirmPasswordTapped(_ sender: Any) {
        if confirmPassWordField.isSecureTextEntry {
            confirmPasswordRevealButton.alpha = 1.0
        } else {
            confirmPasswordRevealButton.alpha = 0.3
        }
        
        confirmPassWordField.isSecureTextEntry = !confirmPassWordField.isSecureTextEntry
    }
    

    func textViewDidChange(_ textView: UITextView) {
        if textView.text.trim() == "" {
            loginButton.isEnabled = false
            loginButton.backgroundColor = Theme.light.disabledColor
        } else {
            loginButton.isEnabled = true
            loginButton.backgroundColor = Theme.light.accentColor
        }
    }

    func instantiateMainAsNewRoot() {
        DispatchQueue.main.async {
            HUD.hide()
            self.view.endEditing(true)
            AppState.setDismissBackupNotification(dismiss: true)
            UIApplication.shared.keyWindow?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        }
    }

    @IBAction func cancelTapped(_ sender: Any) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }

    func invalidKeyDetected() {
        DispatchQueue.main.async {
            OzoneAlert.alertDialog(message: OnboardingStrings.invalidKey, dismissTitle: OzoneAlert.okPositiveConfirmString) {
                self.alreadyScanned = false
            }
        }
    }
    
    func setLoginButtonState(enabled: Bool) {
        if enabled {
            loginButton.isEnabled = true
            loginButton.backgroundColor = Theme.light.accentColor
        } else {
            loginButton.isEnabled = false
            loginButton.backgroundColor = Theme.light.disabledColor
        }
    }
    
    func saveNEP6AndContinue(address: String, encryptedKey: String, wallet: Wallet!, password: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let newAccount = NEP6.Account(address: address,
                                          label: "My O3 Wallet", isDefault: true, lock: false,
                                          key: encryptedKey)
            let nep6 = NEP6(name: "Registered O3 Accounts", version: "1.0", accounts: [newAccount])
            O3KeychainManager.setNep6DecryptionPassword(for: newAccount.address, pass: password) { result in
                switch result {
                case .success(_):
                    nep6.writeToFileSystem()
                    Authenticated.wallet = wallet
                    MultiwalletEvent.shared.walletAdded(type: "import_key", method: "import")
                    self.instantiateMainAsNewRoot()
                case .failure(_):
                    fatalError("Something went terribly wrong")
                }
            }
        }
    }

    @IBAction func loginTapped(_ sender: Any) {
        DispatchQueue.main.async { HUD.show(.progress)}
        var error: NSError?
        var wallet: Wallet?
        var encryptedKey: String?
        var address: String?
        let key = keyField.text!
        let password = passwordField.text!
        DispatchQueue.global(qos: .userInitiated).async {
            if key.starts(with: "6P") {
                let wif = NeoutilsNEP2Decrypt(key, password, &error)
                if error != nil {
                    DispatchQueue.main.async {
                        HUD.hide()
                        OzoneAlert.alertDialog("Failed to decrypt key", message: "Either the password or key is incorrect, please double check it", dismissTitle: OzoneAlert.okPositiveConfirmString) {}
                        return
                    }
                }
                
                wallet = Wallet(wif: wif!)
                address = wallet!.address
                encryptedKey = key

            } else {
                var nep2 = NeoutilsNEP2Encrypt(key, password, &error)
                if error != nil {
                    DispatchQueue.main.async {
                        OzoneAlert.alertDialog("Failed to encrypt key", message: "Please use alphanumeric characters for your password", dismissTitle: OzoneAlert.okPositiveConfirmString) {}
                        HUD.hide()
                        return
                    }
                }
                
                wallet = Wallet(wif: key)
                address = nep2!.address()
                encryptedKey = nep2!.encryptedKey()
            }
            self.saveNEP6AndContinue(address: address!, encryptedKey: encryptedKey!, wallet: wallet!, password: password)
        }
    }

    
    @IBAction func didTapScan(_ sender: Any) {
        guard let modal = UIStoryboard(name: "QR", bundle: nil).instantiateInitialViewController() as? QRScannerController else {
            fatalError("Presenting improper modal controller")
        }
        modal.delegate = self
        let nav = WalletHomeNavigationController(rootViewController: modal)
        nav.navigationBar.prefersLargeTitles = false
        nav.setNavigationBarHidden(true, animated: false)
        let transitionDelegate = DeckTransitioningDelegate()
        nav.transitioningDelegate = transitionDelegate
        nav.modalPresentationStyle = .custom
        self.present(nav, animated: true, completion: nil)
    }
    
    func qrScanned(data: String) {
        keyField.text = data
        keyFieldChanged(nil)
        invalidateFromQr = true
    }
    
    func enteredEncryptedKey() {
        self.passwordField.isHidden = false
        self.passwordFieldHeight.constant = CGFloat(44.0)
        self.passwordRevealButton.isHidden = false
        keyField.errorMessage = nil
    }
    
    func enteredWif() {
        self.passwordField.isHidden = false
        self.passwordFieldHeight.constant = CGFloat(44.0)
        self.passwordRevealButton.isHidden = false
        
        self.confirmPassWordField.isHidden = false
        self.confirmPasswordFieldHeight.constant = CGFloat(44.0)
        self.confirmPasswordRevealButton.isHidden = false
        
        keyField.errorMessage = nil
    }
    
    func enteredInvalidKey() {
        self.passwordField.isHidden = true
        self.passwordFieldHeight.constant = CGFloat(0.0)
        self.passwordRevealButton.isHidden = true
        
        self.confirmPassWordField.isHidden = true
        self.confirmPasswordRevealButton.isHidden = true
        self.confirmPasswordFieldHeight.constant = CGFloat(0.0)
        
        if (keyField.text!.count >= 52 || invalidateFromQr) {
            keyField.errorMessage = "Invalid Key"
        } else {
            keyField.errorMessage = nil
        }
        loginButton.isEnabled = false
        invalidateFromQr = false
    }
    
    
    
    @objc func keyFieldChanged(_ textfield: SkyFloatingLabelTextField?) {
        let key = keyField.text!
        if key.count == 52 {
            let wallet = Wallet(wif: key)
            if (wallet != nil) {
                enteredWif()
            }
        } else if key.count == 58 && key.starts(with: "6P") {
            enteredEncryptedKey()
        } else {
            enteredInvalidKey()
        }
    }

    
    @objc func passwordFieldChanged(_ textfield: UITextField) {
        let key = keyField.text!
        if key.count == 52 {
            if (passwordField.text!.count > 5 && passwordField.text!.count < 8) {
                passwordField.errorMessage = "Your password must be at least 8 characters"
            } else {
                passwordField.errorMessage = nil
            }
        } else {
            if passwordField.text!.count > 0 {
                setLoginButtonState(enabled: true)
            } else {
                setLoginButtonState(enabled: false)
            }
        }
    }
    
    @objc func confirmPasswordFieldChanged(_ textfield: UITextField) {
        if (confirmPassWordField.text! != passwordField.text) {
            confirmPassWordField.errorMessage = "Your passwords don't match"
            setLoginButtonState(enabled: false)
        } else {
            confirmPassWordField.errorMessage = nil
            setLoginButtonState(enabled: true)
        }
    }

    func setLocalizedStrings() {
        keyField.placeholder = OnboardingStrings.privateKeyTitle
        loginButton.setTitle(OnboardingStrings.loginTitle, for: UIControl.State())
        
        passwordField.placeholder = OnboardingStrings.createPasswordHint
        confirmPassWordField.placeholder = OnboardingStrings.reenterPasswordHint
        titleLabel.text = "Login with an existing wallet"
        subtitleLabel.text = "You can either use your WIF or Encrypted Key"
    }
}
