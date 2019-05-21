//
//  WalletSelectorTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 4/30/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import PKHUD
import Channel

class WalletSelectorTableViewController: UITableViewController {
    
    var wallets = NEP6.getFromFileSystem()?.getWalletAccounts() ?? []
    var watchAddresses = NEP6.getFromFileSystem()?.getWatchAccounts() ?? []
    
    var trackedCount = 0
    var untrackedCount = 0
    
    var accountValues: [IndexPath: AccountValue] = [:]
    var watchAddrs: [IndexPath: NEP6.Account] = [:]
    var combinedAccountValue: AccountValue?
    
    var selectedWatchAddr = ""
    
    var group: DispatchGroup = DispatchGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-x"), style: .plain, target: self, action: #selector(dismissTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_add_wallet"), style: .plain, target: self, action: #selector(openAddWallet))
        loadPortfoliosForAll()
        setThemedElements()
        setLocalizedStrings()
    }
    
    func getCachedPortfolioValue(for address: String, indexPath: IndexPath) -> Bool {
        let accountValue = O3Cache.getCachedPortfolioValue(for: address)
        if accountValue == nil {
            return false
        } else {
            self.accountValues[indexPath] = accountValue!
            DispatchQueue.main.async { self.tableView.reloadRows(at: [indexPath], with: .automatic) }
            return true
        }
    }
    
    func updateWallets() {
        wallets = NEP6.getFromFileSystem()?.getWalletAccounts() ?? []
        watchAddresses = NEP6.getFromFileSystem()?.getWatchAccounts() ?? []
    }
    
    func loadPortfoliosForAll() {
            for i in 0..<self.wallets.count {
                let indexPath = IndexPath(row: i, section: 1)
                if self.getCachedPortfolioValue(for: self.wallets[i].address, indexPath: indexPath) == false {
                    DispatchQueue.global().async {
                        self.group.enter()
                        O3APIClient(network: AppState.network).getAccountState(address: self.wallets[i].address) { result in
                            switch result {
                            case .failure:
                                self.group.leave()
                                return
                            case .success(let accountState):
                                self.getPortfolioForAccountState(indexPath: indexPath, accountState: accountState, address: self.wallets[i].address)
                            }
                        }
                    }
                }
            }
            
            self.trackedCount = 0
            self.untrackedCount = 0
            for i in 0..<self.watchAddresses.count {
                var indexPath: IndexPath
                if UserDefaultsManager.untrackedWatchAddr.contains(self.watchAddresses[i].address) {
                    if UserDefaultsManager.untrackedWatchAddr.count == NEP6.getFromFileSystem()?.getWatchAccounts().count {
                        indexPath = IndexPath(row: self.untrackedCount, section: 2)
                    } else {
                        indexPath = IndexPath(row: self.untrackedCount, section: 3)
                    }
                    
                    self.untrackedCount = self.untrackedCount + 1
                } else {
                    indexPath = IndexPath(row: self.trackedCount, section: 2)
                    self.trackedCount = self.trackedCount + 1
                }
                self.watchAddrs[indexPath] = self.watchAddresses[i]
                if self.getCachedPortfolioValue(for: self.watchAddresses[i].address, indexPath: indexPath) == false {
                    DispatchQueue.global().async {
                        self.group.enter()
                        O3APIClient(network: AppState.network).getAccountState(address: self.watchAddresses[i].address) { result in
                            switch result {
                            case .failure:
                                self.group.leave()
                                return
                            case .success(let accountState):
                                if UserDefaultsManager.untrackedWatchAddr.contains(self.watchAddresses[i].address) {
                                    if UserDefaultsManager.untrackedWatchAddr.count == NEP6.getFromFileSystem()?.getWatchAccounts().count {
                                        indexPath = IndexPath(row: self.untrackedCount, section: 2)
                                    } else {
                                        indexPath = IndexPath(row: self.untrackedCount, section: 3)
                                    }
                                    self.untrackedCount = self.untrackedCount + 1
                                } else {
                                    indexPath = IndexPath(row: self.trackedCount, section: 2)
                                    self.trackedCount = self.trackedCount + 1
                                }
                                self.watchAddrs[indexPath] = self.watchAddresses[i]
                                self.getPortfolioForAccountState(indexPath: indexPath, accountState: accountState, address: self.watchAddresses[i].address)
                            }
                        }
                    }
                }
            }
            self.group.wait()
            self.sumForCombined()
    }
    
    func sumForCombined() {
        var accountValue: AccountValue?
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for key in accountValues.keys {
            if watchAddrs[key] != nil && UserDefaultsManager.untrackedWatchAddr.contains(watchAddrs[key]!.address) {
                continue
            }
            if accountValue == nil {
                accountValue = accountValues[key]
            } else {
                let currentNumber = (formatter.number(from: accountValue!.total))!
                let toAddNumber = (formatter.number(from: accountValues[key]!.total))!
                let total = currentNumber.floatValue + toAddNumber.floatValue
                accountValue = AccountValue(total: formatter.string(from: NSNumber(value: total)) ?? "0", currency: accountValues[key]!.currency)
                
            }
        }
        combinedAccountValue = accountValue
        let indexPath = IndexPath(row: 0, section: 0)
        DispatchQueue.main.async {
                self.tableView.reloadData()
        }
    }
    
    func getPortfolioForAccountState(indexPath: IndexPath, accountState: AccountState, address: String) {
        O3Client().getAccountValue(accountState.assets + accountState.nep5Tokens + accountState.ontology) { result in
            switch result {
            case .failure:
                self.group.leave()
                return
            case .success(let accountValue):
                O3Cache.setCachedPortfolioValue(for: address, portfolioValue: accountValue)
                self.group.leave()
                DispatchQueue.main.async {
                    self.accountValues[indexPath] = accountValue
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if trackedCount == 0 && untrackedCount == 0 {
            return 2
        } else if trackedCount > 0 && untrackedCount == 0 {
            return 3
        } else if trackedCount == 0 && untrackedCount > 0 {
            return 3
        }
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return wallets.count
        } else if section == 2 {
            if trackedCount > 0 {
                return trackedCount
            } else {
                return untrackedCount
            }
        } else {
            return untrackedCount
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 26.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "walletSelectorTableViewCell") as? WalletSelectorTableViewCell else {
            fatalError("Something went terribly Wrong")
        }
        if indexPath.section == 0 {
            cell.data = WalletSelectorTableViewCell.Data(title: "Total", subtitle: "Wallets + Watch Addresses", value: combinedAccountValue, isDefault: false)
        } else if indexPath.section == 1 {
            cell.data = WalletSelectorTableViewCell.Data(title: wallets[indexPath.row].label, subtitle: wallets[indexPath.row].address, value: accountValues[indexPath], isDefault: wallets[indexPath.row].isDefault)
        } else {
            cell.data = WalletSelectorTableViewCell.Data(title: watchAddrs[indexPath]!.label, subtitle: watchAddrs[indexPath]!.address, value: accountValues[indexPath],
                                                         isDefault: false)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sectionHeader")
        let titleLabel = cell?.viewWithTag(1) as! UILabel
        if section == 0 {
            return UIView()
        } else if section == 1 {
            titleLabel.text = "Wallets"
        }else if section == 2 {
            if trackedCount > 0 {
                titleLabel.text = "Watch Addresses"
            } else {
                titleLabel.text = "Watch Addresses (Hidden)"
            }
        } else {
            titleLabel.text = "Watch Addresses (Hidden)"
        }
        titleLabel.theme_textColor = O3Theme.titleColorPicker
        cell?.theme_backgroundColor = O3Theme.backgroundLightgrey
        cell?.contentView.theme_backgroundColor = O3Theme.backgroundSectionHeader
        return cell
    }
    
    func handleWalletTapped(indexPath: IndexPath) {
        O3KeychainManager.getWalletForNep6(for: wallets[indexPath.row].address) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let wallet):
                    NEP6.makeNewDefault(key: self.wallets[indexPath.row].key!, wallet: wallet)
                    MultiwalletEvent.shared.walletUnlocked()
                    DispatchQueue.main.async { HUD.show(.progress) }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        HUD.hide()
                        Controller().focusOnTab(tabIndex: 1)
                        self.dismiss(animated: true)
                    }
                    
                case .failure(let e):
                    return
                }
            }
        }
    }
    
    func handleEditNameAction(indexPath: IndexPath) {
        let alertController = UIAlertController(title: MultiWalletStrings.editName, message: MultiWalletStrings.enterNewName, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: OzoneAlert.okPositiveConfirmString, style: .default) { (_) in
            let inputNewName = alertController.textFields?[0].text!
            let nep6 = NEP6.getFromFileSystem()!
            nep6.editName(address: self.watchAddresses[indexPath.row].address   , newName: inputNewName!)
            nep6.writeToFileSystem()
            self.updateWallets()
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
        let cancelAction = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = MultiWalletStrings.myWalletPlaceholder
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        UIApplication.shared.keyWindow?.rootViewController?.presentFromEmbedded(alertController, animated: true, completion: nil)
    }
    
    func handleWatchAddressTapped(indexPath: IndexPath) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let editNameAction = UIAlertAction(title: "Edit Name", style: .default) { _ in
            self.handleEditNameAction(indexPath: indexPath)
        }
        alert.addAction(editNameAction)
        
        var totalTitle = "Hide from Total"
        if indexPath.section == 3 || untrackedCount == watchAddresses.count {
            totalTitle = "Show in Total"
        }
        
        let addRemoveTotalAction = UIAlertAction(title: totalTitle, style: .default) { _ in
            let isTracked = indexPath.section == 2 && UserDefaultsManager.untrackedWatchAddr.count != NEP6.getFromFileSystem()?.getWatchAccounts().count
            
            if isTracked {
                UserDefaultsManager.untrackedWatchAddr = UserDefaultsManager.untrackedWatchAddr + [self.watchAddrs[indexPath]!.address]
                
                self.trackedCount = self.trackedCount - 1
                self.untrackedCount = self.untrackedCount + 1
                var section = 2
                if self.trackedCount != 0 {
                    section = 3
                }
                let newIndex = IndexPath(row: self.untrackedCount - 1, section: section)

                let value = self.watchAddrs[indexPath]!
                self.watchAddrs.removeValue(forKey: indexPath)
                self.watchAddrs[newIndex] = value
                
                let accountValue = self.accountValues[indexPath]!
                self.accountValues.removeValue(forKey: indexPath)
                self.accountValues[newIndex] = accountValue
                self.sumForCombined()
                
            } else {
                var newUntracked = UserDefaultsManager.untrackedWatchAddr
                newUntracked.remove(at: newUntracked.firstIndex {$0 == self.watchAddrs[indexPath]!.address }!)
                UserDefaultsManager.untrackedWatchAddr = newUntracked
            
                let newIndex = IndexPath(row: self.trackedCount, section: 2)
                self.trackedCount = self.trackedCount + 1
                self.untrackedCount = self.untrackedCount - 1
                
                let value = self.watchAddrs[indexPath]!
                self.watchAddrs.removeValue(forKey: indexPath)
                self.watchAddrs[newIndex] = value
                
                let accountValue = self.accountValues[indexPath]!
                self.accountValues.removeValue(forKey: indexPath)
                self.accountValues[newIndex] = accountValue
                self.sumForCombined()

            }
           // DispatchQueue.main.async { self.tableView.reloadData() }
            

        }
        alert.addAction(addRemoveTotalAction)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            let nep6 = NEP6.getFromFileSystem()!
            nep6.removeEncryptedKey(address: self.watchAddresses[indexPath.row].address)
            nep6.writeToFileSystem()
            Channel.shared().unsubscribe(fromTopic: self.watchAddresses[indexPath.row].address, block: {})
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        alert.addAction(deleteAction)
        
        let cancel = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { _ in
            
        }
        alert.addAction(cancel)
        
        present(alert, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // wallet
        if indexPath.section == 1 {
            handleWalletTapped(indexPath: indexPath)
        } else if indexPath.section == 2  || indexPath.section == 3 {
            handleWatchAddressTapped(indexPath: indexPath)
        }
    }
    
    @objc func openAddWallet() {
        Controller().openAddNewWallet()
    }
    
    func setThemedElements() {
        tableView.theme_separatorColor = O3Theme.tableSeparatorColorPicker
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
    
    func setLocalizedStrings() {
        navigationItem.title = "My Wallets"
    }
}
