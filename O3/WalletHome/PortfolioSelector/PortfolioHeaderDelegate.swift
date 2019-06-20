//
//  PortfolioHeaderDelegate.swift
//  O3
//
//  Created by Andrei Terentiev on 6/19/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, WalletHeaderCellDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var filteredBlockchainAddrs = NEP6.getFromFileSystem()!.getAccounts()
        filteredBlockchainAddrs = filteredBlockchainAddrs.filter {
            UserDefaultsManager.untrackedWatchAddr.contains($0.address) == false
        }
        return filteredBlockchainAddrs.count + ExternalAccounts.getFromFileSystem().getAccounts().count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "walletHeaderCollectionCell", for: indexPath) as? WalletHeaderCollectionCell else {
            fatalError("Undefined collection view behavior")
        }
        cell.delegate = self
        
        var blockchainAccount: NEP6.Account? = nil
        var externalAccount: ExternalAccounts.Account? = nil
        
        var type: WalletHeaderCollectionCell.HeaderType
        var filteredBlockchainAddrs = NEP6.getFromFileSystem()!.getAccounts()
        filteredBlockchainAddrs = filteredBlockchainAddrs.filter {
            UserDefaultsManager.untrackedWatchAddr.contains($0.address) == false
        }
        
        var externalAccounts = ExternalAccounts.getFromFileSystem().getAccounts()
        
        if indexPath.row == 0 {
            type = WalletHeaderCollectionCell.HeaderType.combined
        } else if indexPath.row < filteredBlockchainAddrs.count + 1 {
            type = WalletHeaderCollectionCell.HeaderType.blockchainAddress
            blockchainAccount = filteredBlockchainAddrs[indexPath.row - 1]
        } else {
            type = WalletHeaderCollectionCell.HeaderType.linkedAccount
            externalAccount = externalAccounts[indexPath.row - filteredBlockchainAddrs.count - 1]
        }
        
        
        if indexPath.row == filteredBlockchainAddrs.count + externalAccounts.count {
            cell.rightButton.isHidden = true
        } else {
            cell.rightButton.isHidden = false
        }
        
        var data =  WalletHeaderCollectionCell.Data (
            type: type,
            blockchainAccount: blockchainAccount,
            externalAccount: externalAccount,
            latestPrice: PriceData(average: 0, averageBTC: 0, time: "24h"),
            previousPrice: PriceData(average: 0, averageBTC: 0, time: "24h"),
            referenceCurrency: (homeviewModel?.referenceCurrency)!,
            selectedInterval: (homeviewModel?.selectedInterval)!
        )
        
        //portfolio prices can only be loaded when the cell actually appeaRS
        if (homeviewModel.currentIndex != indexPath.row) {
            cell.data = data
            return cell
        }
        
        guard let latestPrice = selectedPrice,
            let previousPrice = portfolio?.data.last else {
                cell.data = data
                return cell
        }
        data.latestPrice = latestPrice
        data.previousPrice = previousPrice
        cell.data = data
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenSize = UIScreen.main.bounds
        return CGSize(width: screenSize.width, height: 75)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == assetsTable {
            return
        }
        
        var visibleRect = CGRect()
        visibleRect.origin = walletHeaderCollectionView.contentOffset
        visibleRect.size = walletHeaderCollectionView.bounds.size
        
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        let visibleIndexPath: IndexPath? = walletHeaderCollectionView.indexPathForItem(at: visiblePoint)
        if visibleIndexPath != nil {
            self.homeviewModel?.setCurrentIndex(visibleIndexPath!.row)
        }
    }
    
    func emptyPortfolioRightButtonTapped() {
        if homeviewModel.currentIndex != 0 {
            displayEnableMultiWallet()
        } else {
            displayDepositTokens()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        Controller().openPortfolioSelector()
        
    }
    
    func didTapLeft() {
        DispatchQueue.main.async {
            let index = self.walletHeaderCollectionView.indexPathsForVisibleItems[0].row
            self.walletHeaderCollectionView.scrollToItem(at: IndexPath(row: index - 1, section: 0), at: .left, animated: true)
            self.homeviewModel?.setCurrentIndex(index - 1)
        }
    }
    
    func didTapRight() {
        DispatchQueue.main.async {
            let index = self.walletHeaderCollectionView.indexPathsForVisibleItems[0].row
            self.walletHeaderCollectionView.scrollToItem(at: IndexPath(row:
                index + 1, section: 0), at: .right, animated: true)
            self.homeviewModel?.setCurrentIndex(index + 1)
        }
    }
}
