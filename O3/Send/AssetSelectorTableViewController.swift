//
//  AssetSelectorTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 1/23/18.
//  Copyright © 2018 drei. All rights reserved.
//

import UIKit

protocol AssetSelectorDelegate: class {
    func assetSelected(selected: TransferableAsset, gasBalance: Double)
}

class AssetSelectorTableViewController: UITableViewController {

    var accountState: AccountState!
    weak var delegate: AssetSelectorDelegate?

    enum sections: Int {
        case nativeAssets = 0
        case nep5Tokens
    }
    var assets = [TransferableAsset.NEONoBalance(), TransferableAsset.GASNoBalance()]
    var tokens = [TransferableAsset]()

    func addThemedElements() {
        applyNavBarTheme()
        tableView.theme_separatorColor = O3Theme.tableSeparatorColorPicker
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addThemedElements()
        self.title = SendStrings.assetSelectorTitle
        self.loadAccountState()
    }

    func updateCacheAndLocalBalance(accountState: AccountState) {
        for asset in accountState.assets {
            if asset.id.contains(AssetId.neoAssetId.rawValue) {
                assets[0] = asset
            } else {
                assets[1] = asset
            }
        }
        tokens = []
        for token in accountState.nep5Tokens {
            tokens.append(token)
        }
    }

    func loadAccountState() {
        O3APIClient(network: AppState.network).getAccountState(address: Authenticated.account?.address ?? "") { result in
            DispatchQueue.main.async {
                switch result {
                case .failure:
                    return
                case .success(let accountState):
                    self.updateCacheAndLocalBalance(accountState: accountState)
                    self.tableView.reloadData()
                }
            }
        }
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == sections.nativeAssets.rawValue {
            return assets.count
        }

        return tokens.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == sections.nativeAssets.rawValue {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell-nativeasset") as? NativeAssetSelectorTableViewCell else {
                return UITableViewCell()
            }

            //NEO
            if indexPath.row == 0 {
                cell.titleLabel.text = "NEO"
                cell.amountLabel.text = assets[0].value.description
            }

            //GAS
            if indexPath.row == 1 {
                cell.titleLabel.text = "GAS"
                cell.amountLabel.text = assets[1].value.string(8, removeTrailing: true)
            }

            return cell
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell-nep5token") as? NEP5TokenSelectorTableViewCell else {
            return UITableViewCell()
        }

        let token = tokens[indexPath.row]
        cell.titleLabel.text = token.symbol
        cell.subtitleLabel.text = token.name
        cell.amountLabel.text = token.value.string(token.decimals, removeTrailing: true)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == sections.nativeAssets.rawValue {
            if indexPath.row == 0 {
                //neo
                delegate?.assetSelected(selected: assets[0], gasBalance: assets[1].value)
            } else if indexPath.row == 1 {
                //gas
                delegate?.assetSelected(selected: assets[1], gasBalance: assets[1].value)
            }
        } else if indexPath.section == sections.nep5Tokens.rawValue {
            delegate?.assetSelected(selected: tokens[indexPath.row], gasBalance: assets[1].value)
        }
        self.dismiss(animated: true, completion: nil)
    }
}
