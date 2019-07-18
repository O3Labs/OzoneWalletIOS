//
//  ManageCoinbaseTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 6/13/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class ManageCoinbaseTableViewController: UITableViewController {
    @IBOutlet weak var linkedAccountTableViewCell: UITableViewCell!
    @IBOutlet weak var limitTableViewCell: UITableViewCell!
    @IBOutlet weak var disconnectTableViewCell: UITableViewCell!
    
    @IBOutlet weak var connectedAccountLabel: UILabel!
    
    
    @IBOutlet weak var connectedAccountValueLabel: UILabel!
    
    @IBOutlet weak var updateLimitLabel: UILabel!
    @IBOutlet weak var disconnectAccountLabel: UILabel!
    
    var coinbase_dapp_url = URL(string: "https://coinbase-oauth-redirect.o3.app/?coinbaseurl=https%3A%2F%2Fwww.coinbase.com%2Foauth%2Fauthorize%3Fresponse_type%3Dcode%26account%3Dall%26meta%5Bsend_limit_amount%5D%3D1%26meta%5Bsend_limit_currency%5D%3DUSD%26meta%5Bsend_limit_period%5D%3Dday%26client_id%3Db48a163039580762e2267c2821a5d03eeda2dde2d3053d63dd1873809ee21df6%26redirect_uri%3Dhttps%253A%252F%252Fcoinbase-oauth-redirect.o3.app%252F%26scope%3Dwallet%253Aaccounts%253Aread%252Cwallet%253Atransactions%253Aread%252Cwallet%253Atransactions%253Asend%252Cwallet%253Auser%253Aread%252Cwallet%253Auser%253Aemail%252Cwallet%253Aaddresses%253Aread%252Cwallet%253Aaddresses%253Acreate")!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setThemedElements()
        setLocalizedStrings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if ExternalAccounts.getCoinbaseTokenFromDisk() != nil {
            loadCoinbaseAccountDetails()
        }
        super.viewWillAppear(true)
    }
    
    func loadCoinbaseAccountDetails() {
        CoinbaseClient.shared.getUser { result in
            switch result {
            case .failure(let e):
                return
            case .success(let user):
                DispatchQueue.main.async { self.connectedAccountValueLabel.text = user["email"] }
            }
        }
    }
    
    func setLocalizedStrings() {
        connectedAccountLabel.text = "Connected account"
        updateLimitLabel.text = "Update spending limit"
        disconnectAccountLabel.text = "Disconnect account"
        title = "Manage Coinbase"
    }
    
    func setThemedElements() {
        connectedAccountLabel.theme_textColor = O3Theme.titleColorPicker
        updateLimitLabel.theme_textColor = O3Theme.titleColorPicker
        disconnectAccountLabel.theme_textColor = O3Theme.titleColorPicker
        connectedAccountValueLabel.theme_textColor = O3Theme.lightTextColorPicker
        
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        tableView.theme_separatorColor = O3Theme.tableSeparatorColorPicker
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            Controller().openDappBrowserV2(url: coinbase_dapp_url)
        } else if indexPath.row == 1 {
            Controller().openDappBrowserV2(url: coinbase_dapp_url)
            CoinbaseEvent().updateLimit()
        } else if indexPath.row == 2 {
            var externalAccounts = ExternalAccounts.getFromFileSystem()
            externalAccounts.removeAccount(platform: ExternalAccounts.Platforms.COINBASE)
            externalAccounts.writeToFileSystem()
            CoinbaseEvent().removedCoinbase()
            DispatchQueue.main.async {
                //trigger this to reload the portfolio screen
                self.dismiss(animated: true)
            }
        }
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        dismissTapped()
    }
    
}
