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

class WalletSelectorTableViewController: UITableViewController {
    
    var wallets = NEP6.getFromFileSystem()?.getWalletAccounts() ?? []
    var watchAddresses = NEP6.getFromFileSystem()?.getWatchAccounts() ?? []
    
    var accountValues: [IndexPath: AccountValue] = [:]
    var combinedAccountValue: AccountValue?
    
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
    
    
    //naive solution is hit the network every time
    func loadPortfoliosForAll() {
        DispatchQueue.global().async {
            for i in 0..<self.wallets.count {
                let indexPath = IndexPath(row: i, section: 1)
                if self.getCachedPortfolioValue(for: self.wallets[i].address, indexPath: indexPath) == false {
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
            
            for i in 0..<self.watchAddresses.count {
                let indexPath = IndexPath(row: i, section: 2)
                if self.getCachedPortfolioValue(for: self.watchAddresses[i].address, indexPath: indexPath) == false {
                    self.group.enter()
                    O3APIClient(network: AppState.network).getAccountState(address: self.watchAddresses[i].address) { result in
                        switch result {
                        case .failure:
                            self.group.leave()
                            return
                        case .success(let accountState):
                            let indexPath = IndexPath(row: i, section: 2)
                            self.getPortfolioForAccountState(indexPath: indexPath, accountState: accountState, address: self.watchAddresses[i].address)
                        }
                    }
                }
            }
            self.group.wait()
            self.sumForCombined()
        }
    }
    
    func sumForCombined() {
        var accountValue: AccountValue?
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for key in accountValues.keys {
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
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
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
                DispatchQueue.main.async {
                    self.accountValues[indexPath] = accountValue
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    self.group.leave()
                }
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "walletSelectorTableViewCell") as? WalletSelectorTableViewCell else {
            fatalError("Something went terribly Wrong")
        }
        if indexPath.section == 0 {
            cell.data = WalletSelectorTableViewCell.Data(title: "Combined", subtitle: "Wallets + Addr", value: combinedAccountValue)
        } else if indexPath.section == 1 {
            cell.data = WalletSelectorTableViewCell.Data(title: wallets[indexPath.row].label, subtitle: wallets[indexPath.row].address, value: accountValues[indexPath])
        } else {
            cell.data = WalletSelectorTableViewCell.Data(title: watchAddresses[indexPath.row].label, subtitle: watchAddresses[indexPath.row].address, value: accountValues[indexPath])
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sectionHeader")
        let titleLabel = cell?.viewWithTag(1) as! UILabel
        if section == 0 {
            titleLabel.text = "Combined"
        } else if section == 1 {
            titleLabel.text = "Wallets"
        } else {
            titleLabel.text = "Watch Only"
        }
        titleLabel.theme_textColor = O3Theme.titleColorPicker
        cell?.theme_backgroundColor = O3Theme.backgroundLightgrey
        cell?.contentView.theme_backgroundColor = O3Theme.backgroundSectionHeader
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // wallet
        if indexPath.section == 1 {
            O3KeychainManager.getWalletForNep6(for: wallets[indexPath.row].address) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let wallet):
                        NEP6.makeNewDefault(key: self.wallets[indexPath.row].key!, wallet: wallet)
                        MultiwalletEvent.shared.walletUnlocked()
                        DispatchQueue.main.async { HUD.show(.progress) }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            HUD.hide()
                            self.dismiss(animated: true)
                        }
                        
                    case .failure(let e):
                        return
                    }
                }
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
