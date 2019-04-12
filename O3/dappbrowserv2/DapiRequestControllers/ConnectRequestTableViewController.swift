//
//  ConnectRequestTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 11/20/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import Neoutils
import PKHUD
import KeychainAccess

class ConnectRequestTableViewController: UITableViewController {
    
    var url: URL?
    var message: dAppMessage!
    var dappMetadata: dAppMetadata?
    var selectedAccount: NEP6.Account?
    
    var onConfirm: ((_ message: dAppMessage, _ wallet: Wallet, _ account: NEP6.Account?)->())?
    var onCancel: ((_ message: dAppMessage)->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Connect request"
        //set selected one to the main active one first
        let nep6 = NEP6.getFromFileSystem()
        let defaultAccount =  nep6?.accounts.first(where: { n -> Bool in
            return n.isDefault == true
        })
        selectedAccount = defaultAccount
    }
    
    @IBAction func didTapClose(_ sender: Any) {
        onCancel?(message)
        self.dismiss(animated: true, completion: nil)
    }
    
    func inputPassword(account: NEP6.Account?, didCancel: @escaping () -> Void, didConfirm:@escaping (_ wif: String) -> Void) {
        let encryptedKey = account!.key
        let name = account!.label
        //default selected account is the main active one so if user hasn't change
        if account?.isDefault == true {
            DispatchQueue.main.async { HUD.show(.progress) }
            let prompt = String(format: OnboardingStrings.nep6AuthenticationPrompt, (NEP6.getFromFileSystem()?.accounts[0].label)!)
            O3KeychainManager.getSigningKeyPassword(with: prompt) { result in
                switch result {
                case .success(let pass):
                    var error: NSError?
                    let wif = NeoutilsNEP2Decrypt(encryptedKey, pass, &error)
                    DispatchQueue.main.async { HUD.hide() }
                    if error == nil {
                        DispatchQueue.main.async { didConfirm(wif!) }
                    }
                case .failure(let _):
                    DispatchQueue.main.async {HUD.hide() }
                }
            }
        } else {
        
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
                DispatchQueue.main.async {
                    HUD.hide()
                    didCancel()
                }
            }
            
            alertController.addTextField { (textField) in
                textField.isSecureTextEntry = true
            }
            
            alertController.addAction(confirmAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func didTapCancel(_ sender: Any) {
        onCancel?(message)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapConnect(_ sender: Any) {
        inputPassword(account: selectedAccount, didCancel: {
            
        }) { wif in
            DispatchQueue.main.async {
                HUD.hide()
                let generator = UINotificationFeedbackGenerator()
                  generator.notificationOccurred(.success)
                let wallet = Wallet(wif: wif)
                dapiEvent.shared.accountConnected(url: self.url?.absoluteString ?? "", domain: self.url?.host ?? "")
                self.onConfirm?(self.message, wallet!, self.selectedAccount)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    //mark:-
    
    @IBAction func unwindToConnectRequest(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? ConnectWalletSelectorTableViewController {
            DispatchQueue.main.async {
                self.selectedAccount = sourceViewController.selectedAccount
                self.tableView.reloadData()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectWallet" {
            let vc = segue.destination as! ConnectWalletSelectorTableViewController
            vc.selectedAccount = selectedAccount
        }
    }
    
    //mark: - 
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 1
        }
        if section == 1 {
            return 1
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            return 80.0
        }
        if indexPath.section == 1 {
            return 60.0
        }
        return 0.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 && indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "dapp-metadata-cell") as! dAppMetaDataTableViewCell
            cell.dappMetadata = self.dappMetadata
            cell.permissionLabel?.text = String(format: "is requesting to connect to your wallet")
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "wallet-cell") as! ConnectRequestWalletUITableViewCell
        cell.titleLabel.text = selectedAccount?.label ?? "My O3 Wallet"
        cell.addressLabel.text = selectedAccount?.address ?? Authenticated.wallet?.address
        return cell
    }
}
