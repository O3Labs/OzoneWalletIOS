//
//  AccountAssetTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 1/21/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import PKHUD
import Cache
import SwiftTheme
import Crashlytics
import StoreKit

class AccountAssetTableViewController: UITableViewController {
    private enum sections: Int {
        case unclaimedGAS = 0
        case assets
    }

    var claims: Claimable?
    var isClaiming: Bool = false
    /// var refreshClaimableGasTimer = Timer()

    var tokenAssets = O3Cache.tokenAssets()
    var neoBalance: Int = Int(O3Cache.neo().value)
    var gasBalance: Double = O3Cache.gas().value
    var mostRecentClaimAmount = 0.0

    @objc func reloadCells() {
        DispatchQueue.main.async { self.tableView.reloadData() }
    }

    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(reloadAllData), name: NSNotification.Name(rawValue: "tokenSelectorDismissed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadCells), name: NSNotification.Name(rawValue: ThemeUpdateNotification), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: ThemeUpdateNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "tokenSelectiorDismissed"), object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        addObservers()
        self.view.theme_backgroundColor = O3Theme.backgroundColorPicker
        self.tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        applyNavBarTheme()
        loadClaimableGAS()

        //refreshClaimableGasTimer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(AccountAssetTableViewController.loadClaimableGAS), userInfo: nil, repeats: true)
        tableView.refreshControl = UIRefreshControl()
        self.tableView.refreshControl?.beginRefreshing()
        tableView.refreshControl?.addTarget(self, action: #selector(reloadAllData), for: .valueChanged)
    }

    @objc func reloadAllData() {
        loadAccountState()
        loadClaimableGAS()
        DispatchQueue.main.async { self.tableView.reloadData() }
    }

    func claimGas() {
        self.enableClaimButton(enable: false)
        Authenticated.account?.claimGas(network: AppState.network, seedURL: AppState.bestSeedNodeURL) { success, error in

            if error != nil {
                //if error then try again in 10 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    self.claimGas()
                }
            }

            if success == true {
                DispatchQueue.main.async {
                    OzoneAlert.alertDialog(message: OzoneAlert.errorTitle, dismissTitle: SendStrings.transactionFailedTitle) {
                        return
                    }
                }
            }

            Answers.logCustomEvent(withName: "Gas Claimed",
                                   customAttributes: ["Amount": self.mostRecentClaimAmount])
            DispatchQueue.main.async {
                HUD.hide()
                OzoneAlert.alertDialog(message: AccountStrings.successfulClaimPrompt, dismissTitle: OzoneAlert.okPositiveConfirmString) {
                    UserDefaultsManager.numClaims += 1
                    if UserDefaultsManager.numClaims == 1 || UserDefaultsManager.numClaims % 10 == 0 {
                        SKStoreReviewController.requestReview()
                    }
                }

                //save latest claim time interval here to limit user to only claim every 5 minutes
                let now = Date().timeIntervalSince1970
                UserDefaults.standard.set(now, forKey: "lastetClaimDate")
                UserDefaults.standard.synchronize()

                self.isClaiming = false
                self.loadClaimableGAS()
            }
        }
    }

    func enableClaimButton(enable: Bool) {
        let indexPath = IndexPath(row: 0, section: sections.unclaimedGAS.rawValue)
        guard let cell = tableView.cellForRow(at: indexPath) as? UnclaimedGASTableViewCell else {
            return
        }
        cell.claimButton.isEnabled = enable && isClaiming == false
    }

    func prepareClaimingGAS() {

        self.isClaiming = true
        //refreshClaimableGasTimer.invalidate()
     //   refreshClaimableGasTimer = Timer()

        //select best node
        if let bestNode = NEONetworkMonitor.autoSelectBestNode(network: AppState.network) {
            AppState.bestSeedNodeURL = bestNode
        }

        //we are able to claim gas only when there is data in the .claims array
        if self.claims != nil && self.claims!.claims.count > 0 {
            DispatchQueue.main.async {
                self.claimGas()
            }
            return
        }

        //to be able to claim. we need to send the entire NEO to ourself.
        var customAttributes: [TransactionAttritbute] = []
        let remark = String(format: "O3XFORCLAIM")
        customAttributes.append(TransactionAttritbute(remark: remark))

        Authenticated.account?.sendAssetTransaction(network: AppState.network, seedURL: AppState.bestSeedNodeURL, asset: AssetId.neoAssetId, amount: Double(self.neoBalance), toAddress: (Authenticated.account?.address)!, attributes: customAttributes) { completed, _ in
            if completed == false {
                HUD.hide()
                self.enableClaimButton(enable: true)
                return
            }
            DispatchQueue.main.async {
                //if completed then mark the flag that we are claiming GAS
                self.isClaiming = true

                //disable button and invalidate the timer to refresh claimable GAS

               // self.refreshClaimableGasTimer.invalidate()
               // self.refreshClaimableGasTimer = Timer()

                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    self.claimGas()
                }
            }
        }
    }

    @objc func loadClaimableGAS() {
        if Authenticated.account == nil {
            return
        }

        if self.isClaiming == true {
            return
        }

        O3APIClient(network: AppState.network).getClaims(address: (Authenticated.account?.address)!) { result in
            DispatchQueue.main.async { self.tableView.refreshControl?.endRefreshing() }
            switch result {
            case .failure:
                return
            case .success(let claims):
                self.claims = claims
                self.mostRecentClaimAmount = NSDecimalNumber(decimal: claims.gas).doubleValue
                DispatchQueue.main.async {
                    self.showClaimableGASAmount(amount: self.mostRecentClaimAmount)
                }
            }
        }
    }

    func showClaimableGASAmount(amount: Double) {
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: 0, section: sections.unclaimedGAS.rawValue)
            guard let cell = self.tableView.cellForRow(at: indexPath) as? UnclaimedGASTableViewCell else {
                return
            }
            cell.amountLabel.text = amount.string(8, removeTrailing: true)

            //only enable button if latestClaimDate is more than 5 minutes
            let latestClaimDateInterval: Double = UserDefaults.standard.double(forKey: "lastetClaimDate")
            let latestClaimDate: Date = Date(timeIntervalSince1970: latestClaimDateInterval)
            let diff = Date().timeIntervalSince(latestClaimDate)
            if diff > (5 * 60) {
                cell.claimButton.isEnabled = true
            } else {
                cell.claimButton.isEnabled = false
            }
            cell.claimButton.isEnabled = amount > 0
        }
    }

    func updateCacheAndLocalBalance(accountState: AccountState) {
        for asset in accountState.assets {
            if asset.id.contains(AssetId.neoAssetId.rawValue) {
                neoBalance = Int(asset.value)
            } else {
                gasBalance = asset.value
            }
        }
        tokenAssets = []
        for token in accountState.nep5Tokens {
            tokenAssets.append(token)
        }
        O3Cache.setGASForSession(gasBalance: gasBalance)
        O3Cache.setNEOForSession(neoBalance: neoBalance)
        O3Cache.setTokenAssetsForSession(tokens: tokenAssets)
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
        if section == sections.unclaimedGAS.rawValue {
            return 1
        }
        return 2 + tokenAssets.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == sections.unclaimedGAS.rawValue {
            return 108.0
        }
        return 52.0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == sections.unclaimedGAS.rawValue {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell-unclaimedgas") as? UnclaimedGASTableViewCell else {
                let cell =  UITableViewCell()
                cell.theme_backgroundColor = O3Theme.backgroundColorPicker
                return cell
            }
            cell.delegate = self
            return cell
        }

        if indexPath.section == sections.assets.rawValue && indexPath.row < 2 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell-nativeasset") as? NativeAssetTableViewCell else {
                let cell =  UITableViewCell()
                cell.theme_backgroundColor = O3Theme.backgroundColorPicker
                return cell
            }

            if indexPath.row == 0 {
                cell.titleLabel.text = "NEO"
                cell.amountLabel.text = neoBalance.description
            }

            if indexPath.row == 1 {
                cell.titleLabel.text = "GAS"
                cell.amountLabel.text = gasBalance.string(8, removeTrailing: true)
            }

            return cell
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell-nep5token") as? NEP5TokenTableViewCell else {
            let cell =  UITableViewCell()
            cell.theme_backgroundColor = O3Theme.backgroundColorPicker
            return cell
        }
        let list = tokenAssets
        let token = list[indexPath.row - 2]
        cell.amountLabel.text = token.value.string(token.decimals, removeTrailing: true)
        cell.titleLabel.text = token.symbol
        cell.subtitleLabel.text = token.name
        return cell
    }
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == sections.unclaimedGAS.rawValue {
            return false
        }
        return false
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func setLocalizedStrings() {
        self.navigationController?.navigationBar.topItem?.title = AccountStrings.accountTitle
    }
}

extension AccountAssetTableViewController: UnclaimGASDelegate {
    func claimButtonTapped() {
        DispatchQueue.main.async {
            if self.neoBalance == 0 {
                return
            }
            HUD.show(.labeledProgress(title: AccountStrings.claimingInProgressTitle, subtitle: AccountStrings.claimingInProgressSubtitle))
            self.enableClaimButton(enable: false)
            self.prepareClaimingGAS()
        }
    }
}
