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

    override func viewDidLoad() {
        super.viewDidLoad()
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
            cell.walletIsDefaultView.isHidden == !account.isDefault
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == nep6!.accounts.count {
            self.performSegue(withIdentifier: "segueToAddItemToMultiWallet", sender: nil)
        } else {
            //something else
        }
    }
    
    func setLocalizedStrings() {
        
    }
    
    func setThemedElements() {
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        
    }
}
