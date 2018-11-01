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
    func updateWithBalanceData(_ assets: [TransferableAsset])
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
    var writableTokens = O3Cache.tokenAssets()
    var readOnlyAssets  = [WatchAddr: [TransferableAsset]]()
    
    var addressCount = 0
    var currentIndex = 0
    
    //Added for ontology
    var writableOntologyAssets = O3Cache.ontologyAssets()

    var neo = O3Cache.neo()
    var gas = O3Cache.gas()

    var watchAddresses = [WatchAddr]()
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

    func getCombinedReadOnlyAndWriteable() -> [TransferableAsset] {
        if watchAddresses.count == 0 {
            return [TransferableAsset(id: AssetId.neoAssetId.rawValue, name: "NEO", symbol: "NEO",
                                      decimals: 0, value: 0, assetType: .neoAsset),
                    TransferableAsset(id: AssetId.neoAssetId.rawValue, name: "GAS", symbol: "GAS",
                                      decimals: 0, value: 0, assetType: .neoAsset)]
        }
        
        var assets: [TransferableAsset] = getWritableAssets()
        for addr in watchAddresses {
            for asset in readOnlyAssets[addr] ?? [] {
                if let index = assets.index(where: { (item) -> Bool in item.name == asset.name }) {
                    assets[index].value = assets[index].value + asset.value
                } else {
                    assets.append(asset)
                }
            }
        }
        return assets
    }

    func getWritableAssets() -> [TransferableAsset] {
        return [neo, gas] + writableTokens + writableOntologyAssets
    }

    func getReadOnlyAssets(address: WatchAddr) -> [TransferableAsset] {
        return readOnlyAssets[address] ?? []
    }

    func getTransferableAssets() -> [TransferableAsset] {
        var transferableAssetsToReturn: [TransferableAsset]  = []
        switch currentIndex {
        case 0: transferableAssetsToReturn = getWritableAssets()
        case watchAddresses.count + 1: transferableAssetsToReturn = getCombinedReadOnlyAndWriteable()
        default: transferableAssetsToReturn = readOnlyAssets[watchAddresses[currentIndex - 1]] ?? []
        }

        //Put NEO + GAS at the top
        var sortedAssets = [TransferableAsset]()
        if let indexNEO = transferableAssetsToReturn.index(where: { (item) -> Bool in
            item.symbol == "NEO"
        }) {
            sortedAssets.append(transferableAssetsToReturn[indexNEO])
            transferableAssetsToReturn.remove(at: indexNEO)
        }

        if let indexGAS = transferableAssetsToReturn.index(where: { (item) -> Bool in
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
        self.delegate?.updateWithBalanceData(self.getTransferableAssets())
        reloadBalances()
    }

    func resetReadOnlyBalances() {
        readOnlyAssets = [:]
    }

    func reloadBalances() {
        guard let address = Authenticated.wallet?.address else {
            return
        }
        loadAccountState(address: address, isReadOnly: false)
        resetReadOnlyBalances()
        watchAddresses = []
        if  NEP6.getFromFileSystem() == nil {
            group.notify(queue: .main) {
                self.loadPortfolioValue()
                self.delegate?.updateWithBalanceData(self.getTransferableAssets())
            }
            return
        }
        
        let accounts = NEP6.getFromFileSystem()!.accounts
        for account in accounts {
            if account.isDefault == false {
                watchAddresses.append(WatchAddr(name: account.label, address: account.address))
            }
        }
        
        for watchAddress in watchAddresses {
            if NEOValidator.validateNEOAddress(watchAddress.address ?? "") {
                self.loadAccountState(address: (watchAddress.address), isReadOnly: true, watchAddress: watchAddress)
            }
        }
    
        group.notify(queue: .main) {
            self.loadPortfolioValue()
            self.delegate?.updateWithBalanceData(self.getTransferableAssets())
        }
    }

    func addWritableAccountState(_ accountState: AccountState) {
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
    }

    func addReadOnlyToken(_ token: TransferableAsset, address: WatchAddr) {
        if readOnlyAssets[address] == nil {
            readOnlyAssets[address] = []
        }
        
        if let index = readOnlyAssets[address]!.index(where: { (item) -> Bool in item.name == token.name }) {
            readOnlyAssets[address]![index].value += token.value
        } else {
            readOnlyAssets[address]!.append(token)
        }
    }

    func addReadOnlyAccountState(_ accountState: AccountState, address: WatchAddr) {
        for asset in accountState.assets {
            addReadOnlyToken(asset, address: address)
        }

        for token in accountState.nep5Tokens {
            addReadOnlyToken(token, address: address)
        }
        
        for ontAsset in accountState.ontology {
            addReadOnlyToken(ontAsset, address: address)
        }
    }

    func loadAccountState(address: String, isReadOnly: Bool, watchAddress: WatchAddr? = nil) {
        self.group.enter()

        O3APIClient(network: AppState.network).getAccountState(address: address) { result in
            DispatchQueue.main.async {
                switch result {
                case .failure:
                    self.group.leave()
                    return
                case .success(let accountState):
                    if isReadOnly {
                        self.addReadOnlyAccountState(accountState, address: watchAddress!)
                    } else {
                        self.addWritableAccountState(accountState)
                    }
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
