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
    var accountValues: [IndexPath: AccountValue] = [:]
    var combinedAccountValue: AccountValue?
    
    var selectedWatchAddr = ""
    
    var group: DispatchGroup = DispatchGroup()
    var insertSection = false
    
    
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
    }
    
    func loadWalletPortfolios() {
        for i in 0..<self.wallets.count {
            let indexPath = IndexPath(row: i, section: 0)
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
    
    func loadPortfoliosForAll() {
        accountValues = [:]
        loadWalletPortfolios()
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
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wallets.count
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
    
        cell.data = WalletSelectorTableViewCell.Data(title: wallets[indexPath.row].label, subtitle: wallets[indexPath.row].address, value: accountValues[indexPath], isDefault: wallets[indexPath.row].isDefault)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        handleWalletTapped(indexPath: indexPath)
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
