//
//  TradableAssetSelectorTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/11/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit


protocol TradableAssetSelectorTableViewControllerDelegate {
    func assetSelected(selected: TradableAsset, data: Any?)
}

class TradableAssetSelectorTableViewController: UITableViewController {

    var assets: [TradableAsset]!
    var delegate: TradableAssetSelectorTableViewControllerDelegate?
    var data: Any?
    
    func setupTheme() {
        self.view.theme_backgroundColor = O3Theme.backgroundLightgrey
        self.tableView.theme_backgroundColor = O3Theme.backgroundLightgrey
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTheme()
        self.title = "Select asset"
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assets.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell-token") as? NEP5TokenSelectorTableViewCell else {
            return UITableViewCell()
        }
        
        let token = assets[indexPath.row]
        cell.titleLabel.text = token.symbol
        cell.subtitleLabel.text = token.name
        cell.amountLabel.text = token.formattedAmountInString()
        let imageURL = String(format: "https://cdn.o3.network/img/neo/%@.png", token.symbol.uppercased())
        cell.iconImageView?.kf.setImage(with: URL(string: imageURL))
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.assetSelected(selected: assets[indexPath.row], data: self.data)
        self.dismiss(animated: true, completion: nil)
    }

}
