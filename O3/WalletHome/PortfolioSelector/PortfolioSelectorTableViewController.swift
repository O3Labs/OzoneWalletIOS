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
    
    var accountValues: [IndexPath: AccountValue] = [:]
    var watchAddrs: [IndexPath: NEP6.Account] = [:]
    var combinedAccountValue: AccountValue?
    
    var selectedWatchAddr = ""
    
    var group: DispatchGroup = DispatchGroup()
    var insertSection = false
    var walletSectionNum = 1
    
    var coinbase_dapp_url = URL(string:"https://coinbase-oauth-redirect.o3.app/?coinbaseurl=https%3A%2F%2Fwww.coinbase.com%2Foauth%2Fauthorize%3Fresponse_type%3Dcode%26account%3Dall%26meta%5Bsend_limit_amount%5D%3D1%26meta%5Bsend_limit_currency%5D%3DUSD%26meta%5Bsend_limit_period%5D%3Dday%26client_id%3Db48a163039580762e2267c2821a5d03eeda2dde2d3053d63dd1873809ee21df6%26redirect_uri%3Dhttps%253A%252F%252Fcoinbase-oauth-redirect.o3.app%252F%26scope%3Dwallet%253Aaccounts%253Aread%252Cwallet%253Atransactions%253Aread%252Cwallet%253Atransactions%253Asend%252Cwallet%253Auser%253Aread%252Cwallet%253Auser%253Aemail%252Cwallet%253Aaddresses%253Aread%252Cwallet%253Aaddresses%253Acreate")!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-x"), style: .plain, target: self, action: #selector(dismissTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_add_wallet"), style: .plain, target: self, action: #selector(openAddWallet))
        sortWatchAddresses()
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
    
    func sortWatchAddresses() {
        var sorted = [NEP6.Account]()
        for account in watchAddresses {
            if UserDefaultsManager.untrackedWatchAddr.contains(account.address) {
                continue
            }
            sorted.append(account)
        }
        
        for account in watchAddresses {
            if UserDefaultsManager.untrackedWatchAddr.contains(account.address) == false {
                continue
            }
            sorted.append(account)
        }
        watchAddresses = sorted
    }
    
    func getTrackedWatchAddrCount() -> Int {
        var count = 0
        for account in watchAddresses {
            if UserDefaultsManager.untrackedWatchAddr.contains(account.address) {
                continue
            }
            count += 1
        }
        return count
    }
    
    func updateWallets() {
        wallets = NEP6.getFromFileSystem()?.getWalletAccounts() ?? []
        watchAddresses = NEP6.getFromFileSystem()?.getWatchAccounts() ?? []
        sortWatchAddresses()
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
    
    func loadConnectedAccountPortfolios() {
        var indexPath: IndexPath
        indexPath = IndexPath(row: 0, section: 3)
        if ExternalAccounts.getCoinbaseTokenFromDisk() != nil {
            if self.getCachedPortfolioValue(for: ExternalAccounts.Platforms.COINBASE.rawValue, indexPath: indexPath) == false {
                DispatchQueue.global().async {
                    self.group.enter()
                    CoinbaseClient.shared.getAllPortfolioAssets { result in
                        switch result {
                        case .failure:
                            self.group.leave()
                            return
                        case .success(let assets):
                            O3Client().getAccountValue(assets) { result in
                                switch result {
                                case .failure:
                                    self.group.leave()
                                    return
                                case .success(let accountValue):
                                    O3Cache.setCachedPortfolioValue(for: ExternalAccounts.Platforms.COINBASE.rawValue, portfolioValue: accountValue)
                                    self.accountValues[indexPath] = accountValue
                                    DispatchQueue.main.async {
                                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                                    }
                                    self.group.leave()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func loadWatchAddressPortfolios() {
        for i in 0..<self.watchAddresses.count {
            var indexPath: IndexPath
            indexPath = IndexPath(row: i, section: 2)

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
        loadWalletPortfolios()
        loadWatchAddressPortfolios()
        loadConnectedAccountPortfolios()
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
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return wallets.count
        } else if section == 2 {
            if watchAddresses.count == 0 {
                return 1
            } else {
                return watchAddresses.count
            }
        } else {
            return 1
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 34.0
    }
    
    func getCombinedCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "portfolioSelectorTableViewCell") as? PortfolioSelectorTableViewCell else {
            fatalError("Something went terribly Wrong")
        }
        let trackedWalletCount = self.wallets.count + getTrackedWatchAddrCount()
        cell.data = PortfolioSelectorTableViewCell.Data(title: "Total", subtitle: "\(trackedWalletCount) Addresses", value: combinedAccountValue, isDefault: false)
        return cell
        
    }
    
    func getWalletCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "portfolioSelectorTableViewCell") as? PortfolioSelectorTableViewCell else {
            fatalError("Something went terribly Wrong")
        }
        cell.data = PortfolioSelectorTableViewCell.Data(title: wallets[indexPath.row].label, subtitle: wallets[indexPath.row].address, value: accountValues[indexPath], isDefault: wallets[indexPath.row].isDefault)
        
        return cell
    }
    
    func getWatchAddressCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if watchAddresses.count > 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "portfolioSelectorTableViewCell") as? PortfolioSelectorTableViewCell else {
                fatalError("Something went terribly Wrong")
            }
            
            var addressSubtitle = watchAddrs[indexPath]!.address
            if UserDefaultsManager.untrackedWatchAddr.contains(watchAddrs[indexPath]!.address) {
                addressSubtitle = addressSubtitle + " (Hidden)"
            }
            
            cell.data = PortfolioSelectorTableViewCell.Data(title: watchAddrs[indexPath]!.label, subtitle: addressSubtitle, value: accountValues[indexPath],
                                                            isDefault: false)
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "noPortfolioTableViewCell") as? NoPortfolioTableViewCell else {
                fatalError("Something went terribly Wrong")
            }
            let button = cell.viewWithTag(1) as! UIButton
            cell.theme_backgroundColor = O3Theme.backgroundColorPicker
            button.setTitle("+ Add Watch Address", for: UIControl.State())
            return cell
        }
    }
    
    func getConnectedAccountCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if ExternalAccounts.getCoinbaseTokenFromDisk() == nil {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "noPortfolioTableViewCell") as? NoPortfolioTableViewCell else {
                fatalError("Something went terribly Wrong")
            }
            let button = cell.viewWithTag(1) as! UIButton
            cell.theme_backgroundColor = O3Theme.backgroundColorPicker
            button.setTitle("+ Add Coinbase Account", for: UIControl.State())
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "portfolioSelectorTableViewCell") as? PortfolioSelectorTableViewCell else {
                fatalError("Something went terribly Wrong")
            }
            let metadata = ExternalAccounts.getFromFileSystem().getAccountMetadata(ExternalAccounts.Platforms.COINBASE)
            var email = ""
            if metadata?.keys.contains("email") ?? false {
                email = metadata?["email"] ?? ""
            }
            cell.data = PortfolioSelectorTableViewCell.Data(title: "Coinbase", subtitle: email, value: accountValues[indexPath],
                                                            isDefault: false)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return getCombinedCell(tableView, cellForRowAt: indexPath)
        } else if indexPath.section == 1 {
            return getWalletCell(tableView, cellForRowAt: indexPath)
        } else if indexPath.section == 2 {
            return getWatchAddressCell(tableView, cellForRowAt: indexPath)
        } else {
            return getConnectedAccountCell(tableView, cellForRowAt: indexPath)
        }
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
        } else if section == 3 {
            titleLabel.text = "Connected Accounts"
        }
        
        titleLabel.theme_textColor = O3Theme.sectionHeaderTextColor
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
        let isTracked = UserDefaultsManager.untrackedWatchAddr.contains(self.watchAddrs[indexPath]!.address) == false
        
        var totalTitle = "Hide from Total"
        if isTracked == false {
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
        
        let copyAction = UIAlertAction(title: "Copy Address", style: .default) { _ in
            UIPasteboard.general.string = self.watchAddresses[indexPath.row].address
        }
        alert.addAction(copyAction)
        
        let addRemoveTotalAction = UIAlertAction(title: totalTitle, style: .default) { _ in
            if isTracked {
                UserDefaultsManager.untrackedWatchAddr = UserDefaultsManager.untrackedWatchAddr + [self.watchAddrs[indexPath]!.address]
                NotificationCenter.default.post(name: Notification.Name("NEP6Updated"), object: nil)
                self.handlePortfolioTapped(indexPath: IndexPath(row: 0, section: 0))
            } else {
                
                var newUntracked = UserDefaultsManager.untrackedWatchAddr
                newUntracked.remove(at: newUntracked.firstIndex {$0 == self.watchAddrs[indexPath]!.address }!)
                UserDefaultsManager.untrackedWatchAddr = newUntracked
                NotificationCenter.default.post(name: Notification.Name("NEP6Updated"), object: nil)
                self.handlePortfolioTapped(indexPath: IndexPath(row: 0, section: 0))
            }
        }
        
        alert.addAction(addRemoveTotalAction)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            DispatchQueue.main.async {
                let untrackedIndex = UserDefaultsManager.untrackedWatchAddr.firstIndex(of: self.watchAddresses[indexPath.row].address)
                if untrackedIndex != nil {
                    UserDefaultsManager.untrackedWatchAddr.remove(at: untrackedIndex!)
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
        var absoluteIndex = 0
        if indexPath.section == 0 {
            absoluteIndex = 0
        } else if indexPath.section == 1 {
            absoluteIndex = indexPath.row + indexPath.section
        } else if indexPath.section == 2 {
            absoluteIndex = wallets.count
            for row in 0..<indexPath.row {
                if UserDefaultsManager.untrackedWatchAddr.contains(self.watchAddrs[IndexPath(row: row, section: 2)]!.address) {
                    continue
                } else {
                    absoluteIndex += 1
                }
            }
        } else {
            absoluteIndex = wallets.count + watchAddrs.count - UserDefaultsManager.untrackedWatchAddr.count + 1
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "jumpToPortfolio"), object: nil, userInfo: ["portfolioIndex": absoluteIndex])
        self.dismiss(animated: true)
    }
    
    func handleExternalAccountTapped(indexPath: IndexPath) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let jumpPortfolioAction = UIAlertAction(title: "Jump to Portfolio", style: .default) { _ in
            self.handlePortfolioTapped(indexPath: indexPath)
        }
        alert.addAction(jumpPortfolioAction)
        
        let manageCoinbaseAction = UIAlertAction(title: "Manage Account", style: .default) { _ in
            Controller().openCoinbaseSettings()
        }
        alert.addAction(manageCoinbaseAction)
    
        
        let cancel = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { _ in
            
        }
        alert.addAction(cancel)
        
        
        present(alert, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1{
            
        }
        if indexPath.section == 1 || indexPath.section == 0 {
            handlePortfolioTapped(indexPath: indexPath)
        } else if indexPath.section == 2  {
            if watchAddresses.count > 0 {
                handleWatchAddressTapped(indexPath: indexPath)
            } else {
                Controller().openAddNewWallet()
            }
        } else if indexPath.section == 3 {
            if ExternalAccounts.getCoinbaseTokenFromDisk() != nil {
                handleExternalAccountTapped(indexPath: indexPath)
            } else {
                Controller().openDappBrowserV2(url: coinbase_dapp_url)
            }
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
