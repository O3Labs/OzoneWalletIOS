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

class HomeViewModel {
    weak var delegate: HomeViewModelDelegate?

    var writableTokens = O3Cache.tokenAssets()
    var readOnlyTokens = O3Cache.readOnlyTokens()
    var neo = O3Cache.neo()
    var gas = O3Cache.gas()
    var readOnlyNeo = O3Cache.readOnlyNeo()
    var readOnlyGas = O3Cache.readOnlyGas()

    var watchAddresses = [WatchAddress]()
    var group = DispatchGroup()

    var portfolioType: PortfolioType = .writable
    var referenceCurrency: Currency = .usd
    var selectedInterval: PriceInterval = .oneDay

    func setPortfolioType(_ portfolioType: PortfolioType) {
        self.portfolioType = portfolioType
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
        var assets: [TransferableAsset] = getReadOnlyAssets()
        for asset in getWritableAssets() {
            if let index = assets.index(where: { (item) -> Bool in item.name == asset.name }) {
                assets[index].value = assets[index].value + asset.value
            } else {
                assets.append(asset)
            }
        }
        return assets
    }

    func getWritableAssets() -> [TransferableAsset] {
        return [neo, gas] + writableTokens
    }

    func getReadOnlyAssets() -> [TransferableAsset] {
        return [readOnlyNeo, readOnlyGas] + readOnlyTokens
    }

    func getTransferableAssets() -> [TransferableAsset] {
        var transferableAssetsToReturn: [TransferableAsset]  = []
        switch self.portfolioType {
        case .writable: transferableAssetsToReturn = getWritableAssets()
        case .readOnlyAndWritable: transferableAssetsToReturn = getCombinedReadOnlyAndWriteable()
        case .readOnly: transferableAssetsToReturn = getReadOnlyAssets()
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
        readOnlyTokens = []
        readOnlyGas = TransferableAsset.GAS()
        readOnlyGas.value = 0
        readOnlyNeo = TransferableAsset.NEO()
        readOnlyNeo.value = 0
    }

    func reloadBalances() {
        guard let address = Authenticated.account?.address else {
            return
        }
        do {
            watchAddresses = try UIApplication.appDelegate.persistentContainer.viewContext.fetch(WatchAddress.fetchRequest())
        } catch {

        }

        loadAccountState(address: address, isReadOnly: false)

        resetReadOnlyBalances()

        for watchAddress in watchAddresses {
            if NEOValidator.validateNEOAddress(watchAddress.address ?? "") {
                self.loadAccountState(address: (watchAddress.address)!, isReadOnly: true)
            }
        }
        group.notify(queue: .main) {
            O3Cache.setReadOnlyNEOForSession(neoBalance: Int(self.readOnlyNeo.value))
            O3Cache.setReadOnlyGasForSession(gasBalance: self.readOnlyGas.value)
            O3Cache.setReadOnlyTokensForSession(tokens: self.readOnlyTokens)
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
        O3Cache.setGASForSession(gasBalance: gas.value)
        O3Cache.setNEOForSession(neoBalance: Int(neo.value))
        O3Cache.setTokenAssetsForSession(tokens: writableTokens)
    }

    func addReadOnlyToken(_ token: TransferableAsset) {
        if let index = readOnlyTokens.index(where: { (item) -> Bool in item.name == token.name }) {
            readOnlyTokens[index].value += token.value
        } else {
            readOnlyTokens.append(token)
        }
    }

    func addReadOnlyAccountState(_ accountState: AccountState) {
        for asset in accountState.assets {
            if asset.id.contains(AssetId.neoAssetId.rawValue) {
                readOnlyNeo.value += asset.value
            } else {
                readOnlyGas.value += asset.value
            }
        }

        for token in accountState.nep5Tokens {
            addReadOnlyToken(token)
        }
    }

    func loadAccountState(address: String, isReadOnly: Bool) {
        self.group.enter()

        O3APIClient(network: AppState.network).getAccountState(address: address) { result in
            DispatchQueue.main.async {
                switch result {
                case .failure:
                    self.group.leave()
                    return
                case .success(let accountState):
                    if isReadOnly {
                        self.addReadOnlyAccountState(accountState)
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
