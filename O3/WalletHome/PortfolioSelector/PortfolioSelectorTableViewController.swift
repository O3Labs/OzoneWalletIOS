//
//  PortfolioSelectorTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 6/19/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import PKHUD

class PortfolioSelectorTableViewController: UITableViewController {
    var wallets = NEP6.getFromFileSystem()?.getWalletAccounts() ?? []
    var watchAddresses = NEP6.getFromFileSystem()?.getWatchAccounts() ?? []
    
    var trackedCount = 0
    var untrackedCount = 0
    
    var accountValues: [IndexPath: AccountValue] = [:]
    var watchAddrs: [IndexPath: NEP6.Account] = [:]
    var combinedAccountValue: AccountValue?
    
    var selectedWatchAddr = ""
    
    var group: DispatchGroup = DispatchGroup()
    var insertSection = false
    var walletSectionNum = 1
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-x"), style: .plain, target: self, action: #selector(dismissTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_add_wallet"), style: .plain, target: self, action: #selector(openAddWallet))
        loadPortfoliosForAll()
        setThemedElements()
        setLocalizedStrings()
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
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
    
    func loadWalletPortfolios() {
        for i in 0..<self.wallets.count {
            let indexPath = IndexPath(row: i, section: walletSectionNum)
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
    }
    
    func loadWatchAddressPortfolios() {
        self.trackedCount = 0
        self.untrackedCount = 0
        for i in 0..<self.watchAddresses.count {
            var indexPath: IndexPath
            indexPath = IndexPath(row: self.untrackedCount, section: 2)
            if UserDefaultsManager.untrackedWatchAddr.contains(self.watchAddresses[i].address) {
                self.untrackedCount = self.untrackedCount + 1
            } else {
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
                            self.watchAddrs[indexPath] = self.watchAddresses[i]
                            self.getPortfolioForAccountState(indexPath: indexPath, accountState: accountState, address: self.watchAddresses[i].address)
                        }
                    }
                }
            }
        }
        
    }
    
    func loadPortfoliosForAll() {
        accountValues = [:]
        watchAddrs = [:]
        self.trackedCount = 0
        self.untrackedCount = 0
        loadWalletPortfolios()
        loadWatchAddressPortfolios()
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
            if self.insertSection {
                self.tableView.insertSections(IndexSet(integer: 2), with: .automatic)
                self.insertSection = false
            }
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
                self.accountValues[indexPath] = accountValue
                DispatchQueue.main.async {
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
                self.group.leave()
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if trackedCount == 0 && untrackedCount == 0 {
            return 2
        } else {
            return 3
        }
        /*} else if trackedCount == 0 && untrackedCount > 0 {
            return 3
        }
        return 4*/
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return wallets.count
        } else {
            return watchAddresses.count
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "portfolioSelectorTableViewCell") as? PortfolioSelectorTableViewCell else {
            fatalError("Something went terribly Wrong")
        }
        
        if indexPath.section == 0 {
            cell.data = PortfolioSelectorTableViewCell.Data(title: "Total", subtitle: "\(self.trackedCount + self.wallets.count) Addresses", value: combinedAccountValue, isDefault: false)
        } else if indexPath.section == 1 {
            cell.data = PortfolioSelectorTableViewCell.Data(title: wallets[indexPath.row].label, subtitle: wallets[indexPath.row].address, value: accountValues[indexPath], isDefault: wallets[indexPath.row].isDefault)
        } else {
            cell.data = PortfolioSelectorTableViewCell.Data(title: watchAddrs[indexPath]!.label, subtitle: watchAddrs[indexPath]!.address, value: accountValues[indexPath],
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
        } else if section == 2 {
            titleLabel.text = "Watch Addresses"
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
            nep6.editName(address: self.watchAddresses[indexPath.row].address, newName: inputNewName!)
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
        
        var totalTitle = "Hide from Total"
        if indexPath.section == 3 || untrackedCount == watchAddresses.count {
            totalTitle = "Show in Total"
        } else {
            let jumpPortfolioAction = UIAlertAction(title: "Jump to Portfolio", style: .default) { _ in
                self.handlePortfolioTapped(indexPath: indexPath)
            }
            alert.addAction(jumpPortfolioAction)
        }
        
        let editNameAction = UIAlertAction(title: "Edit Name", style: .default) { _ in
            self.handleEditNameAction(indexPath: indexPath)
        }
        alert.addAction(editNameAction)
        
        let addRemoveTotalAction = UIAlertAction(title: totalTitle, style: .default) { _ in
            let isTracked = indexPath.section == 2 && UserDefaultsManager.untrackedWatchAddr.count != NEP6.getFromFileSystem()?.getWatchAccounts().count
            
            if isTracked {
                UserDefaultsManager.untrackedWatchAddr = UserDefaultsManager.untrackedWatchAddr + [self.watchAddrs[indexPath]!.address]
                self.handlePortfolioTapped(indexPath: IndexPath(row: 0, section: 0))
            } else {
                
                var newUntracked = UserDefaultsManager.untrackedWatchAddr
                newUntracked.remove(at: newUntracked.firstIndex {$0 == self.watchAddrs[indexPath]!.address }!)
                UserDefaultsManager.untrackedWatchAddr = newUntracked
                self.handlePortfolioTapped(indexPath: IndexPath(row: 0, section: 0))
            }
        }
        
        alert.addAction(addRemoveTotalAction)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            DispatchQueue.main.async {
                let isTracked = indexPath.section == 2 && UserDefaultsManager.untrackedWatchAddr.count != NEP6.getFromFileSystem()?.getWatchAccounts().count
                if isTracked {
                    self.trackedCount = self.trackedCount - 1
                } else {
                    self.untrackedCount = self.untrackedCount - 1
                }
                
                
                let nep6 = NEP6.getFromFileSystem()!
                nep6.removeEncryptedKey(address: self.watchAddresses[indexPath.row].address)
                self.watchAddresses = NEP6.getFromFileSystem()?.getWatchAccounts() ?? []
                self.accountValues.removeValue(forKey: indexPath)
                self.sumForCombined()
            }
        }
        alert.addAction(deleteAction)
        
        let cancel = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { _ in
            
        }
        alert.addAction(cancel)
        
        
        present(alert, animated: true, completion: nil)
    }
    
    func handlePortfolioTapped(indexPath: IndexPath) {
        var absoluteIndex = indexPath.row
        for section in 0..<indexPath.section {
            absoluteIndex += tableView.numberOfRows(inSection: section)
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "jumpToPortfolio"), object: nil, userInfo: ["portfolioIndex": absoluteIndex])
        self.dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 || indexPath.section == 0 {
            handlePortfolioTapped(indexPath: indexPath)
        } else if indexPath.section == 2  {
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
