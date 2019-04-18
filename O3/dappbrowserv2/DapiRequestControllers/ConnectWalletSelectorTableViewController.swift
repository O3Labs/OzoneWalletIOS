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
            DispatchQueue.main.async { HUD.show(.progress) }
            O3KeychainManager.getWalletForNep6(for: (self.selectedAccount?.address)!) { result in
                DispatchQueue.main.async {
                    HUD.hide()
                    switch result {
                    case .success(let wallet):
                        self.selectedWallet = wallet
                        self.performSegue(withIdentifier: "unwindToDappBrowser", sender: nil)
                    case .failure:
                        self.dismiss(animated: true, completion: nil)

                    }
                }
            }
        }
    }
}
