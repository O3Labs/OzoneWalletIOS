//
//  ConnectWalletSelectorTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 11/26/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

class ConnectWalletSelectorTableViewController: UITableViewController {
    
    var accounts: [NEP6.Account]! {
        //only account with encrypted key
        return NEP6.getFromFileSystem()?.accounts.filter({ n -> Bool in
            return n.key != nil
        })
    }
    var selectedAccount: NEP6.Account!
    
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

        let wallet = accounts[indexPath.row]
        cell.titleLabel.text = wallet.label
        cell.addressLabel.text = wallet.address
        
        if wallet.address.isEqual(to: selectedAccount.address) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let wallet = accounts?[indexPath.row]
        selectedAccount = wallet
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "unwind" {
            
        }
    }
    
}
