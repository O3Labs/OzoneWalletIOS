//
//  HomeViewModel.swift
//  O3
//
//  Created by Andrei Terentiev on 2/6/18.
//  Copyright © 2018 drei. All rights reserved.
//

import Foundation
import UIKit

protocol HomeViewModelDelegate: class {
    func updateWithBalanceData(_ assets: [O3WalletNativeAsset])
    func updateWithPortfolioData(_ portfolio: PortfolioValue)
    func showLoadingIndicator()
    func hideLoadingIndicator()
}

struct WatchAddr: Hashable {
    let name: String
    let address: String
}

class HomeViewModel {
    weak var delegate: HomeViewModelDelegate?
    var accountBalances  = [NEP6.Account: [O3WalletNativeAsset]]()
    
    var addressCount = 0
    var currentIndex = 0
    
    //Added for ontology

    /*var neo = O3Cache.neo()
    var gas = O3Cache.gas()*/

    var accounts = [NEP6.Account]()
    var group = DispatchGroup()

    //var portfolioType: PortfolioType = .writable
    var referenceCurrency: Currency = .usd
    var selectedInterval: PriceInterval = .oneDay

    func setCurrentIndex(_ currentIndex: Int) {
        self.currentIndex = currentIndex
        self.delegate?.updateWithBalanceData(getTransferableAssets())
        loadPortfolioValue()
    }

    func setInterval(_ interval: PriceInterval) {
        self.selectedInterval = interval
        loadPortfolioValue()
    }

    func setReferenceCurrency(_ currency: Currency) {
        self.referenceCurrency = currency
    }

    func getCombinedAccounts() -> [O3WalletNativeAsset] {
        
        var assets = [O3WalletNativeAsset]()
        for addr in accounts {
            for asset in accountBalances[addr] ?? [] {
                if let index = assets.firstIndex(where: { (item) -> Bool in item.name == asset.name }) {
                    assets[index].value = assets[index].value + asset.value
                } else {
                    assets.append(asset)
                }
            }
        }
        return assets
    }

    func getAccountAssets(address: NEP6.Account) -> [O3WalletNativeAsset] {
        return accountBalances[address] ?? []
    }

    func getTransferableAssets() -> [O3WalletNativeAsset] {
        var transferableAssetsToReturn: [O3WalletNativeAsset]  = []
        switch currentIndex {
        case 0: transferableAssetsToReturn = getCombinedAccounts()
        default: transferableAssetsToReturn = accountBalances[accounts[currentIndex - 1]] ?? []
        }

        //Put NEO + GAS at the top
        var sortedAssets = [O3WalletNativeAsset]()
        if let indexNEO = transferableAssetsToReturn.firstIndex(where: { (item) -> Bool in
            item.symbol == "NEO"
        }) {
            sortedAssets.append(transferableAssetsToReturn[indexNEO])
            transferableAssetsToReturn.remove(at: indexNEO)
        }

        if let indexGAS = transferableAssetsToReturn.firstIndex(where: { (item) -> Bool in
            item.symbol == "GAS"
        }) {
            sortedAssets.append(transferableAssetsToReturn[indexGAS])
            transferableAssetsToReturn.remove(at: indexGAS)
        }
        transferableAssetsToReturn.sort {$0.name < $1.name}
        return sortedAssets + transferableAssetsToReturn
    }

    init(delegate: HomeViewModelDelegate) {
        self.delegate = delegate
        var unfiltered = NEP6.getFromFileSystem()!.getAccounts()
        unfiltered = unfiltered.filter { UserDefaultsManager.untrackedWatchAddr.contains($0.address) == false}
        var cachedCombinedAssets = [O3WalletNativeAsset]()
        for account in unfiltered {
            var totalAssets: [O3WalletNativeAsset] = [O3Cache.neoBalance(for: account.address)] +
                [O3Cache.gasBalance(for: account.address)] + O3Cache.ontologyBalances(for: account.address) +
                O3Cache.tokensBalance(for: account.address)
            for asset in totalAssets ?? [] {
                if let index = cachedCombinedAssets.firstIndex(where: { (item) -> Bool in item.name == asset.name }) {
                    cachedCombinedAssets[index].value = cachedCombinedAssets[index].value + asset.value
                } else {
                    cachedCombinedAssets.append(asset)
                }
            }
        }
        
        self.delegate?.updateWithBalanceData(cachedCombinedAssets)
        reloadBalances()
    }

    func resetReadOnlyBalances() {
        accountBalances = [:]
    }
    

    func reloadBalances() {
        
        resetReadOnlyBalances()
        accounts = []
        
        var unfiltered = NEP6.getFromFileSystem()!.getAccounts()
        accounts = unfiltered.filter { UserDefaultsManager.untrackedWatchAddr.contains($0.address) == false}
        
        for account in accounts {
            if NEOValidator.validateNEOAddress(account.address ?? "") {
                self.loadAccountState(account: account)
            }
        }
    
        group.notify(queue: .main) {
            self.loadPortfolioValue()
            self.delegate?.updateWithBalanceData(self.getTransferableAssets())
        }
    }

    /*func addWritableAccountState(_ accountState: AccountState) {
        for asset in accountState.assets {
            if asset.id.contains(AssetId.neoAssetId.rawValue) {
                neo = asset
            } else {
                gas = asset
            }
        }
        writableTokens = []
        for token in accountState.nep5Tokens {
            writableTokens.append(token)
        }
        //assign writable ontology asset
        writableOntologyAssets = accountState.ontology

        O3Cache.setGASForSession(gasBalance: gas.value)
        O3Cache.setNEOForSession(neoBalance: Int(neo.value))
        O3Cache.setTokenAssetsForSession(tokens: writableTokens)
        O3Cache.setOntologyAssetsForSession(tokens: accountState.ontology)
    }*/

    func addTokenBalance(_ token: O3WalletNativeAsset, account: NEP6.Account) {
        if accountBalances[account] == nil {
            accountBalances[account] = []
        }
        
        if let index = accountBalances[account]!.firstIndex(where: { (item) -> Bool in item.name == token.name }) {
            accountBalances[account]![index].value += token.value
        } else {
            accountBalances[account]!.append(token)
        }
    }

    func addAccountState(_ accountState: AccountState, account: NEP6.Account) {
        if accountBalances.keys.contains(account) {
            accountBalances[account] = []
        }
        
        for asset in accountState.assets {
            addTokenBalance(asset, account: account)
        }

        for token in accountState.nep5Tokens {
            addTokenBalance(token, account: account)
        }
        
        for ontAsset in accountState.ontology {
            addTokenBalance(ontAsset, account: account)
        }
        
        let neo = accountState.assets.first { $0.name.uppercased() == "NEO" }
        let gas = accountState.assets.first { $0.name.uppercased() == "GAS" }
        O3Cache.setGasBalance(gasBalance: gas?.value ?? 0, address: account.address)
        O3Cache.setNeoBalance(neoBalance: Int(neo?.value ?? 0), address: account.address)
        O3Cache.setTokensBalance(tokens: accountState.nep5Tokens, address: account.address)
        O3Cache.setOntologyBalance(tokens: accountState.ontology, address: account.address)
    }

    func loadAccountState(account: NEP6.Account) {
        self.group.enter()
        
        O3APIClient(network: AppState.network).getAccountState(address: account.address) { result in
            DispatchQueue.main.async {
                switch result {
                case .failure:
                    self.group.leave()
                    return
                case .success(let accountState):
                    self.addAccountState(accountState, account: account)
                    self.group.leave()
                }
            }
        }
    }

    func loadPortfolioValue() {
        delegate?.showLoadingIndicator()
        DispatchQueue.global().async {
            O3Client.shared.getPortfolioValue(self.getTransferableAssets(), interval: self.selectedInterval.rawValue) {result in
                switch result {
                case .failure:
                    self.delegate?.hideLoadingIndicator()
                case .success(let portfolio):
                    self.delegate?.hideLoadingIndicator()
                    self.delegate?.updateWithPortfolioData(portfolio)
                }
            }
        }
    }
}
