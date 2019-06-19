//
//  AssetTableDelegate.swift
//  O3
//
//  Created by Andrei Terentiev on 6/19/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

extension HomeViewController {
    
    func getNotificationCell() -> UITableViewCell {
        if AppState.dismissBackupNotification() == false {
            guard let cell = assetsTable.dequeueReusableCell(withIdentifier: "notification-cell") as? PortfolioNotificationTableViewCell else {
                fatalError("Undefined Table Cell Behavior")
            }
            cell.selectionStyle = .none
            cell.delegate = self
            return cell
        } else {
            guard let cell = assetsTable.dequeueReusableCell(withIdentifier: "buyNeoCell") as? BuyNeoTableViewCell else {
                fatalError("Undefined Table Cell Behavior")
            }
            cell.selectionStyle = .none
            return cell
        }
    }
    
    func getNativeWalletCell(indexPath: IndexPath) -> UITableViewCell {
        guard let cell = assetsTable.dequeueReusableCell(withIdentifier: "portfolioAssetCell") as? PortfolioAssetCell else {
            fatalError("Undefined Table Cell Behavior")
        }
        
        let asset = self.displayedAssets[indexPath.row]
        guard let latestPrice = portfolio?.price[asset.symbol],
            let firstPrice = portfolio?.firstPrice[asset.symbol] else {
                cell.data = PortfolioAssetCell.Data(assetName: asset.symbol,
                                                    amount: Double(truncating: asset.value as NSNumber),
                                                    referenceCurrency: (homeviewModel?.referenceCurrency)!,
                                                    latestPrice: PriceData(average: 0, averageBTC: 0, time: "24h"),
                                                    firstPrice: PriceData(average: 0, averageBTC: 0, time: "24h"))
                return cell
        }
        
        cell.data = PortfolioAssetCell.Data(assetName: asset.symbol,
                                            amount: Double(truncating: asset.value as NSNumber),
                                            referenceCurrency: (homeviewModel?.referenceCurrency)!,
                                            latestPrice: latestPrice,
                                            firstPrice: firstPrice)
        cell.selectionStyle = .none
        return cell
    }
    
    func getLinkedAccountCell(indexPath: IndexPath) -> UITableViewCell {
        guard let cell = assetsTable.dequeueReusableCell(withIdentifier: "portfolioAssetCell") as? PortfolioAssetCell else {
            fatalError("Undefined Table Cell Behavior")
        }
        
        let asset = self.coinbaseAssets[indexPath.row]
        cell.data = PortfolioAssetCell.Data(assetName: asset.symbol,
                                            amount: (asset as! CoinbaseClient.CoinbasePortfolioAccount).value,
                                            referenceCurrency: (homeviewModel?.referenceCurrency)!,
                                            latestPrice: PriceData(average: 0, averageBTC: 0, time: "24h"),
                                            firstPrice: PriceData(average: 0, averageBTC: 0, time: "24h"))
        cell.selectionStyle = .none
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return getNotificationCell()
        } else if indexPath.section == 1 {
            return getNativeWalletCell(indexPath: indexPath)
        } else {
            return getLinkedAccountCell(indexPath: indexPath)
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            return
        }
        
        let asset = self.displayedAssets[indexPath.row]
        var chain = "neo"
        if asset.assetType == O3WalletNativeAsset.AssetType.ontologyAsset {
            chain = "ont"
        }
        let url = URL(string: String(format: "https://public.o3.network/%@/assets/%@?address=%@", chain, asset.symbol, Authenticated.wallet!.address))
        DispatchQueue.main.async {
            Controller().openDappBrowserV2(url: url!, assetSymbol: asset.symbol)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            var addressHasBalance = false
            for asset in self.displayedAssets {
                if asset.value > 0 {
                    addressHasBalance = true
                }
            }
            //notification area
            return 1
        } else if section == 2 {
            return self.coinbaseAssets.count
        }
        return self.displayedAssets.count
    }

}
