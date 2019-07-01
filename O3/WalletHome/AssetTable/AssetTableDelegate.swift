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
        
        let asset = self.walletAssets[indexPath.row]
        guard let latestPrice = portfolio?.price[asset.symbol],
            let firstPrice = portfolio?.firstPrice[asset.symbol] else {
                cell.data = PortfolioAssetCell.Data(asset: asset,
                                                    referenceCurrency: (homeviewModel?.referenceCurrency)!,
                                                    latestPrice: PriceData(average: 0, averageBTC: 0, time: "24h"),
                                                    firstPrice: PriceData(average: 0, averageBTC: 0, time: "24h"))
                return cell
        }
        
        cell.data = PortfolioAssetCell.Data(asset: asset,
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
        guard let latestPrice = portfolio?.price[asset.symbol],
            let firstPrice = portfolio?.firstPrice[asset.symbol] else {
                cell.data = PortfolioAssetCell.Data(asset: asset,
                                                    referenceCurrency: (homeviewModel?.referenceCurrency)!,
                                                    latestPrice: PriceData(average: 0, averageBTC: 0, time: "24h"),
                                                    firstPrice: PriceData(average: 0, averageBTC: 0, time: "24h"))
                return cell
        }
        
        cell.data = PortfolioAssetCell.Data(asset: asset,
                                            referenceCurrency: (homeviewModel?.referenceCurrency)!,
                                            latestPrice: latestPrice,
                                            firstPrice: firstPrice)
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
        
        var asset: PortfolioAsset
        if indexPath.section == 1 {
            asset = self.walletAssets[indexPath.row]
        } else {
            asset = self.coinbaseAssets[indexPath.row]
        }
        
        var urlString = ""
        
        if let o3NativeAsset = asset as? O3WalletNativeAsset {
            var chain = "neo"
            if o3NativeAsset.assetType == O3WalletNativeAsset.AssetType.ontologyAsset {
                chain = "ont"
            }
            urlString = String(format: "https://public.o3.network/%@/assets/%@?address=%@", chain, asset.symbol, Authenticated.wallet!.address)
        } else {
            urlString = "https://www.coinbase.com/price/\(asset.name.lowercased())"
        }
    
        DispatchQueue.main.async {
            Controller().openDappBrowserV2(url: URL(string: urlString)!, assetSymbol: asset.symbol)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if homeviewModel.currentIndex != 0 {
            return 0.0
        }
        
        if section == 0 {
            return 0
        } else if section == 1 {
            if walletAssets.count == 0 {
                return 0.0
            } else {
                return 34.0
            }
        } else {
            if coinbaseAssets.count == 0 {
                return 0.0
            } else {
                return 34.0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if homeviewModel.currentIndex != 0 {
            return UIView()
        }

        let sectionHeader = tableView.dequeueReusableCell(withIdentifier: "sectionHeader") as! UITableViewCell
        sectionHeader.theme_backgroundColor = O3Theme.backgroundSectionHeader
        
        if section == 0 {
            return UIView()
        } else if section == 1 {
            (sectionHeader.viewWithTag(1) as! UILabel).text = "Wallets"
            (sectionHeader.viewWithTag(1) as! UILabel).theme_textColor = O3Theme.sectionHeaderTextColor
            return sectionHeader
        } else {
            (sectionHeader.viewWithTag(1) as! UILabel).text = "Connected Accounts"
            (sectionHeader.viewWithTag(1) as! UILabel).theme_textColor = O3Theme.sectionHeaderTextColor
            return sectionHeader
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
        return self.walletAssets.count
    }

}
