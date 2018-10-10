//
//  Nep5SelectionCollectionViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 5/1/18.
//  Copyright © 2018 drei. All rights reserved.
//

import Foundation
import UIKit
import Crashlytics
import SwiftTheme
import DeckTransition

class Nep5SelectionCollectionViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate {
    let numberOfTokensPerRow: CGFloat = 3
    let gridSpacing: CGFloat = 0
    var supportedAssets = [Asset]()
    var filteredTokens = [Asset]()
    var selectedAsset: Asset?
    let transitionDelegate = DeckTransitioningDelegate()
    var tradableAssets: [TradableAsset]? = []
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    
    func addThemeObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.setSearchBarTheme(_:)), name: Notification.Name(rawValue: ThemeUpdateNotification), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: ThemeUpdateNotification), object: nil)
    }
    
    func loadTradableAssets() {
        O3APIClient.shared.loadSupportedTokenSwitcheo { result in
            switch result {
            case .failure(let error):
                #if DEBUG
                print(error)
                #endif
            case .success(let response):
                self.tradableAssets = response
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    func loadAssets() {
        O3Client().getAssetsForMarketPlace { result in
            switch result {
            case .failure:
                return
            case .success(let assets):
                self.supportedAssets = assets
                self.filteredTokens = self.supportedAssets
                DispatchQueue.main.async { self.collectionView?.reloadData() }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addThemeObserver()
        setLocalizedStrings()
        setThemedElements()
        collectionView.dataSource = self
        collectionView.delegate = self
        searchBar.change(textFont: UIFont(name: "Avenir-Book", size: CGFloat(14)))
        searchBar.delegate = self
        self.hideKeyboardWhenTappedAround()
        loadAssets()
        DispatchQueue.global(qos: .background).async {
            self.loadTradableAssets()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.hidesBottomBarWhenPushed = false
    }
    
    @IBAction func didTapButtonInHeader(_ sender: Any) {
        Controller().openSwitcheoDapp()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
       return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header", for: indexPath) as UICollectionReusableView
        
        if kind == UICollectionView.elementKindSectionHeader {
            
            return header
        }
        
        return UICollectionReusableView(frame: CGRect.zero)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredTokens.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tokenGridCell", for: indexPath) as? TokenGridCell else {
            fatalError("Undefined cell grid behavior")
        }
        
        let asset = filteredTokens[indexPath.row]
        cell.data = asset
        cell.tradableImageView.isHidden = true
        let tradable = self.tradableAssets?.contains(where: { t -> Bool in
            return t.symbol.uppercased() == asset.symbol.uppercased()
        })
        cell.tradableImageView.isHidden = !tradable!
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return gridSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let frameWidth = (view.frame.width - 8 - (CGFloat(max(0, numberOfTokensPerRow - 1)) * gridSpacing))
        return CGSize(width: frameWidth / numberOfTokensPerRow, height: frameWidth / numberOfTokensPerRow)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.hidesBottomBarWhenPushed = true
        selectedAsset = filteredTokens[indexPath.row]
        self.openTokenDetail(asset: selectedAsset!)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredTokens = searchText.isEmpty ? supportedAssets : supportedAssets.filter { (item: Asset) -> Bool in
            return item.name.lowercased().hasPrefix(searchText.lowercased()) ||
                item.symbol.lowercased().hasPrefix(searchText.lowercased())
        }
        collectionView.reloadData()
    }
    
    func setThemedElements() {
        collectionView.theme_backgroundColor = O3Theme.backgroundColorPicker
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
        setSearchBarTheme(nil)
        
        searchBar.theme_keyboardAppearance = O3Theme.keyboardPicker
        searchBar.theme_backgroundColor = O3Theme.backgroundColorPicker
        searchBar.theme_tintColor = O3Theme.textFieldTextColorPicker
    }
    
    @objc func setSearchBarTheme(_ sender: Any?) {
        var background: UIImage
        if UserDefaultsManager.themeIndex == 0 {
            background = UIImage(color: .white)!
            searchBar.setTextFieldColor(color: .white)
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        } else {
            background = UIImage(color: Theme.dark.backgroundColor)!
            searchBar.setTextFieldColor(color: Theme.dark.backgroundColor)
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        }
        searchBar.setBackgroundImage(background, for: .any, barMetrics: UIBarMetrics.default)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    func setLocalizedStrings() {
        searchBar.placeholder = MarketplaceStrings.searchTokens
    }
}


extension Nep5SelectionCollectionViewController {
    func openTokenDetail(asset: Asset) {
        tradingEvent.shared.viewTokenDetail(asset: asset.symbol, source: TradingActionSource.marketplace)
        let urlString = String(format: "%@?address=%@", asset.url!, Authenticated.account!.address)
        
        let nav = UIStoryboard(name: "Browser", bundle: nil).instantiateInitialViewController() as? UINavigationController
        if let vc = nav!.viewControllers.first as? DAppBrowserViewController {
            vc.url = URL(string: urlString)
            vc.showMoreButton = false
            vc.selectedAssetSymbol = asset.symbol
            present(nav!, animated: true, completion: nil)
        }
    }
}
