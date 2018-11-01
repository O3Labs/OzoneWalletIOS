//
//  ManageWalletsTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 10/30/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class ManageWalletsTableViewController: UITableViewController {
    let nep6 = NEP6.getFromFileSystem()
    var selectedAccount: NEP6.Account!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyNavBarTheme()
        setLocalizedStrings()
        setThemedElements()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 + nep6!.accounts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == nep6!.accounts.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "addWalletTableViewCell") as! AddWalletTableViewCell
            return cell
        } else {
            let account = nep6!.accounts[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "manageWalletTableViewCell") as! ManageWalletTableViewCell
            cell.walletLabel.text = account.label
            if account.isDefault == false {
                if account.key == nil {
                    cell.walletIsDefaultView.image = UIImage(named: "ic_watch")
                } else {
                    cell.walletIsDefaultView.image = UIImage(named: "ic_locked")
                }
            } else {
                cell.walletIsDefaultView.image = UIImage(named: "ic_unlocked")

            }
            
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        DispatchQueue.main.async {
            if indexPath.row == self.nep6!.accounts.count {
                self.performSegue(withIdentifier: "segueToAddItemToMultiWallet", sender: nil)
            } else {
                self.selectedAccount = self.nep6!.accounts[indexPath.row]
                self.performSegue(withIdentifier: "segueToManageWallet", sender: nil)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToManageWallet" {
            guard let nav = segue.destination as? UINavigationController,
                let child = nav.children[0] as? ManageWalletTableViewController else {
                    fatalError("Something went terribly wrong")
            }
            child.account = selectedAccount
        }
    }
    
    func setLocalizedStrings() {
        self.title = MultiWalletStrings.Wallets
    }
    
    func setThemedElements() {
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        
    }
}
