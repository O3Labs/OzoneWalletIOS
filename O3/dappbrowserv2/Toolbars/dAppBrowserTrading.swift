//
//  dAppBrowserTrading.swift
//  O3
//
//  Created by Andrei Terentiev on 1/21/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import DeckTransition

extension dAppBrowserV2ViewController {
    @objc func loadOpenOrders() {
        O3APIClient(network: AppState.network).loadSwitcheoOrders(address: Authenticated.wallet!.address, status: SwitcheoOrderStatus.open) { result in
            switch result{
            case .failure(let error):
                #if DEBUG
                print(error)
                #endif
            case .success(let response):
                DispatchQueue.main.async {
                    self.openOrderButton?.isHidden =  response.switcheo.count == 0
                    self.openOrderButton?.badgeValue = String(format: "%d",response.switcheo.count)
                }
            }
        }
    }
    
    @objc func viewOpenOrders(_ sender: Any) {
        guard let nav = UIStoryboard(name: "Trading", bundle: nil).instantiateViewController(withIdentifier: "OrdersTabsViewControllerNav") as? UINavigationController else {
            return
        }
        let transitionDelegate = DeckTransitioningDelegate()
        nav.transitioningDelegate = transitionDelegate
        nav.modalPresentationStyle = .custom
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc func loadTradingAccountBalances() {
        O3APIClient(network: AppState.network).tradingBalances(address: Authenticated.wallet!.address) { result in
            switch result {
            case .failure(let error):
                print(error)
                return
            case .success(let tradingAccount):
                DispatchQueue.main.async {
                    self.viewModel.tradingAccount = tradingAccount
                }
            }
        }
    }
    
    func loadTradableAssets(completion: @escaping ([TradableAsset]) -> Void) {
        O3APIClient.shared.loadSupportedTokenSwitcheo { result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let response):
                completion(response)
            }
        }
    }
    
    func showActionSheetAssetInTradingAccount(asset: TradableAsset) {
        
        let alert = UIAlertController(title: asset.name, message: nil, preferredStyle: .actionSheet)
        
        let buyButton = UIAlertAction(title: "Buy", style: .default) { _ in
            tradingEvent.shared.startBuy(asset: asset.symbol, source: TradingActionSource.tokenDetail)
            self.openCreateOrder(action: CreateOrderAction.Buy, asset: asset)
        }
        alert.addAction(buyButton)
        
        //we can't actually sell NEO but rather use NEO to buy other asset
        if asset.symbol != "NEO" {
            let sellButton = UIAlertAction(title: "Sell", style: .default) { _ in
                tradingEvent.shared.startSell(asset: asset.symbol, source: TradingActionSource.tokenDetail)
                self.openCreateOrder(action: CreateOrderAction.Sell, asset: asset)
            }
            alert.addAction(sellButton)
        }
        
        
        let cancel = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { _ in
            
        }
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    func showBuyOptionsNEO() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let buyWithFiat = UIAlertAction(title: "With Fiat", style: .default) { _ in
            Controller().openDappBrowserV2(url: URL(string: "https://buy.o3.network/?a=" + (Authenticated.wallet?.address)!)!)
        }
        actionSheet.addAction(buyWithFiat)
        
        let buyWithCrypto = UIAlertAction(title: "With Crypto", style: .default) { _ in
            Controller().openDappBrowserV2(url: URL(string: "https://swap.o3.app")!)
        }
        actionSheet.addAction(buyWithCrypto)
        
        let cancel = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { _ in
            
        }
        actionSheet.addAction(cancel)
        present(actionSheet, animated: true, completion: nil)
    }
    
    func openCreateOrder(action: CreateOrderAction, asset: TradableAsset) {
        let nav = UIStoryboard(name: "Trading", bundle: nil).instantiateViewController(withIdentifier: "CreateOrderTableViewControllerNav") as! UINavigationController
        if let vc = nav.viewControllers.first as? CreateOrderTableViewController {
            vc.viewModel = CreateOrderViewModel()
            vc.viewModel.selectedAction = action
            let inTradingAccount = viewModel.tradingAccount?.switcheo.confirmed.first(where: { t -> Bool in
                return t.symbol.uppercased() == asset.symbol.uppercased()
            })
            vc.viewModel.wantAsset = inTradingAccount != nil ? inTradingAccount : asset
            vc.viewModel.offerAsset = viewModel?.tradingAccount?.switcheo.basePairs.filter({ t -> Bool in
                return t.symbol != asset.symbol
            }).first
            vc.viewModel.tradingAccount = viewModel.tradingAccount
            //override for sdusd
            if asset.symbol == "SDUSD" && action == CreateOrderAction.Sell {
                let tempAsset = vc.viewModel.wantAsset
                vc.viewModel.wantAsset = vc.viewModel.offerAsset
                vc.viewModel.offerAsset = tempAsset
                vc.viewModel.selectedAction = CreateOrderAction.Buy
            }
        }
        self.present(nav, animated: true, completion: nil)
    }
}
