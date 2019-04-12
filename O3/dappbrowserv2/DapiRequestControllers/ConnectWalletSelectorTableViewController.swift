//
//  ConnectWalletSelectorTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 11/26/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import PKHUD
import Neoutils

class ConnectWalletSelectorTableViewController: UITableViewController {
    
    var accounts: [NEP6.Account]! {
        //only account with encrypted key
        return NEP6.getFromFileSystem()?.accounts.filter({ n -> Bool in
            return n.key != nil
        })
    }
    var selectedAccount: NEP6.Account?
    
    //this one is used for wallet switching in dapp browser
    var selectedWallet: Wallet?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Select wallet"
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "wallet-cell", for: indexPath) as! ConnectRequestWalletUITableViewCell

        let account = accounts[indexPath.row]
        cell.titleLabel.text = account.label
        cell.addressLabel.text = account.address
        
        if account.address.isEqual(to: selectedAccount?.address) {
            cell.accessoryType = .checkmark
            cell.selectionStyle = .none
        } else {
            cell.accessoryType = .none
            cell.selectionStyle = .default
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let account = accounts?[indexPath.row]
        //don't do anything if user selected the same one
        if account!.address.isEqual(to: selectedAccount?.address) {
            if self.navigationController?.viewControllers == nil {
                self.dismiss(animated: true, completion: nil)
            }
            return
        }
        selectedAccount = account
        if self.navigationController?.viewControllers == nil {
            inputPassword(account: account!, didCancel: {
                self.dismiss(animated: true, completion: nil)
            }) { wif in
                let wallet = Wallet(wif: wif)
                self.selectedWallet = wallet
                self.performSegue(withIdentifier: "unwindToDappBrowser", sender: nil)
            }
        }
    }

    func inputPassword(account: NEP6.Account, didCancel: @escaping () -> Void, didConfirm:@escaping (_ wif: String) -> Void) {
        let encryptedKey = account.key
        let name = account.label
        
        //default selected account is the main active one so if user hasn't change
        if account.isDefault == true {
            DispatchQueue.main.async { HUD.show(.progress) }
            let prompt = String(format: OnboardingStrings.nep6AuthenticationPrompt, (NEP6.getFromFileSystem()?.accounts[0].label)!)
            O3KeychainManager.getSigningKeyPassword(with: prompt) { result in
                DispatchQueue.main.async { O3HUD.start() }
                switch result {
                case .success(let nep6Pass):
                    let nep6 = NEP6.getFromFileSystem()!
                    var error: NSError?
                    let defaultAccount = nep6.accounts.first { $0.isDefault }!
                    let account = Wallet(wif: NeoutilsNEP2Decrypt(defaultAccount.key, nep6Pass, &error))!
                    let wif = NeoutilsNEP2Decrypt(encryptedKey, nep6Pass, &error)
                    if error == nil {
                        didConfirm(wif!)
                    }
                    DispatchQueue.main.async { HUD.hide() }
                case .failure(_):
                    DispatchQueue.main.async { HUD.hide() }
                    return
                }
            }
        }
        
        let alertController = UIAlertController(title: String(format: "Unlock %@", name), message: "Enter the password you used to secure this wallet", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: OzoneAlert.okPositiveConfirmString, style: .default) { (_) in
            DispatchQueue.main.async {
                HUD.show(.progress)
            }
            let inputPass = alertController.textFields?[0].text
            DispatchQueue.global(qos: .userInitiated).async {
                let start = NSDate()
                var error: NSError?
                let wif = NeoutilsNEP2Decrypt(encryptedKey, inputPass, &error)
                let end = NSDate()
                
                let timeInterval: Double = end.timeIntervalSince(start as Date)
                print("Time to evaluate problem \(timeInterval) seconds")
                if error == nil {
                    DispatchQueue.main.async {
                        HUD.hide()
                        didConfirm(wif!)
                    }
                } else {
                    DispatchQueue.main.async {
                        HUD.hide()
                        OzoneAlert.alertDialog("Incorrect passphrase", message: "Please check your passphrase and try again", dismissTitle: "Ok") {}
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { (_) in
            didCancel()
        }
        
        alertController.addTextField { (textField) in
            textField.isSecureTextEntry = true
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}
