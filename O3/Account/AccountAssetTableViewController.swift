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
import DeckTransition

class AccountAssetTableViewController: UITableViewController, WalletToolbarDelegate, QRScanDelegate {
    private enum sections: Int {
        case unclaimedGAS = 0
        case toolbar
        case inbox
        case neoAssets
        case ontologyAssets
        case nep5tokens
    }

    var sendModal: SendTableViewController?

    var claims: Claimable?
    var isClaiming: Bool = false
    /// var refreshClaimableGasTimer = Timer()

    var tokenAssets = O3Cache.tokenAssets()
    var neoBalance: Int = Int(O3Cache.neo().value)
    var gasBalance: Double = O3Cache.gas().value
    var ontologyAssets: [TransferableAsset] = O3Cache.ontologyAssets()
    var mostRecentClaimAmount = 0.0
    var qrController: QRScannerController?

    var addressInbox: Inbox?

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
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(reloadAllData), for: .valueChanged)

        self.loadInbox()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadClaimableGAS()
    }

    func loadInbox() {
        O3APIClient(network: AppState.network).getInbox(address: Authenticated.account!.address) { result in
            switch result {
            case .failure(let error):
                print(error)
                return
            case .success(let inbox):
                DispatchQueue.main.async {
                    self.addressInbox = inbox
                    self.tableView.reloadSections([sections.inbox.rawValue], with: .automatic)
                }
            }
        }
    }

    @objc func reloadAllData() {
        loadAccountState()
        loadClaimableGAS()
        loadInbox()
        DispatchQueue.main.async {
            self.tableView.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        }
    }

    @objc func loadClaimableGAS() {
        if Authenticated.account == nil {
            return
        }

        if self.isClaiming == true {
            return
        }
        let indexPath = IndexPath(row: 0, section: sections.unclaimedGAS.rawValue)
        guard let cell = self.tableView.cellForRow(at: indexPath) as? ClaimableGASTableViewCell else {
            return
        }
        cell.loadClaimableGAS()
    }

    func updateCacheAndLocalBalance(accountState: AccountState) {
        for asset in accountState.assets {
            if asset.id.contains(AssetId.neoAssetId.rawValue) {
                neoBalance = Int(asset.value)
            } else {
                gasBalance = asset.value
            }
        }
        ontologyAssets = accountState.ontology

        tokenAssets = []
        for token in accountState.nep5Tokens {
            tokenAssets.append(token)
        }
        O3Cache.setGASForSession(gasBalance: gasBalance)
        O3Cache.setNEOForSession(neoBalance: neoBalance)
        O3Cache.setTokenAssetsForSession(tokens: tokenAssets)
        O3Cache.setOntologyAssetsForSession(tokens: ontologyAssets)
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
        return 6
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == sections.unclaimedGAS.rawValue {
            return 1
        } else if section == sections.inbox.rawValue {
            return addressInbox?.items.count ?? 0
        } else if section == sections.toolbar.rawValue {
            return 1
        } else if section == sections.neoAssets.rawValue {
            return 2
        } else if section == sections.ontologyAssets.rawValue {
            return ontologyAssets.count
        }
        return tokenAssets.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == sections.unclaimedGAS.rawValue {
            return 166.0
        } else if indexPath.section == sections.toolbar.rawValue {
            return 44.0
        }
        if indexPath.section == sections.inbox.rawValue {
            return 190.0
        }

        // All the asset cell has the same height
        return 66.0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == sections.unclaimedGAS.rawValue {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell-claimable-gas") as? ClaimableGASTableViewCell else {
                let cell =  UITableViewCell()
                cell.theme_backgroundColor = O3Theme.backgroundColorPicker
                return cell
            }
            return cell
        }

        if indexPath.section == sections.toolbar.rawValue {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "walletToolbarCell") as? WalletToolBarCell else {
                let cell =  UITableViewCell()
                cell.theme_backgroundColor = O3Theme.backgroundColorPicker
                return cell
            }
            cell.delegate = self
            return cell
        }
        if indexPath.section == sections.inbox.rawValue {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell-inbox-item") as? InboxItemTableViewCell else {
                let cell =  UITableViewCell()
                cell.theme_backgroundColor = O3Theme.backgroundColorPicker
                return cell
            }
            let item = addressInbox?.items[indexPath.row]
            cell.inboxItem = item
            return cell
        }

        if indexPath.section == sections.neoAssets.rawValue {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell-nativeasset") as? NativeAssetTableViewCell else {
                let cell =  UITableViewCell()
                cell.theme_backgroundColor = O3Theme.backgroundColorPicker
                return cell
            }

            if indexPath.row == 0 {
                cell.titleLabel.text = "NEO"
                cell.amountLabel.text = neoBalance.description
                let imageURL = "https://cdn.o3.network/img/neo/NEO.png"
                cell.iconImageView?.kf.setImage(with: URL(string: imageURL))
            }

            if indexPath.row == 1 {
                cell.titleLabel.text = "GAS"
                cell.amountLabel.text = gasBalance.string(8, removeTrailing: true)
                let imageURL = "https://cdn.o3.network/img/neo/GAS.png"
                cell.iconImageView?.kf.setImage(with: URL(string: imageURL))
            }

            return cell
        }

        if indexPath.section == sections.nep5tokens.rawValue {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell-nep5token") as? NEP5TokenTableViewCell else {
                let cell =  UITableViewCell()
                cell.theme_backgroundColor = O3Theme.backgroundColorPicker
                return cell
            }
            let list = tokenAssets
            let token = list[indexPath.row]
            cell.amountLabel.text = token.value.string(token.decimals, removeTrailing: true)
            cell.titleLabel.text = token.symbol
            cell.subtitleLabel.text = token.name
            let imageURL = String(format: "https://cdn.o3.network/img/neo/%@.png", token.symbol.uppercased())
            cell.iconImageView?.kf.setImage(with: URL(string: imageURL))
            return cell
        }

        //ontology asset using the same nep5 token cell
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell-nep5token") as? NEP5TokenTableViewCell else {
            let cell =  UITableViewCell()
            cell.theme_backgroundColor = O3Theme.backgroundColorPicker
            return cell
        }
        let list = ontologyAssets
        let token = list[indexPath.row]
        cell.amountLabel.text = token.value.string(token.decimals, removeTrailing: true)
        cell.titleLabel.text = token.symbol
        cell.subtitleLabel.text = token.name
        let imageURL = String(format: "https://cdn.o3.network/img/neo/%@.png", token.symbol.uppercased())
        cell.iconImageView?.kf.setImage(with: URL(string: imageURL))
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

    @IBAction func tappedLeftBarButtonItem(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    func sendTapped(qrData: String? = nil) {
        DispatchQueue.main.async {
            self.qrController?.dismiss(animated: false, completion: nil)
            self.qrController = nil
            guard let sendModal = UIStoryboard(name: "Send", bundle: nil).instantiateViewController(withIdentifier: "SendTableViewController") as? SendTableViewController else {
                    fatalError("Presenting improper modal controller")
            }
            sendModal.incomingQRData = qrData
            let nav = WalletHomeNavigationController(rootViewController: sendModal)
            nav.navigationBar.prefersLargeTitles = true
            nav.navigationItem.largeTitleDisplayMode = .automatic
            sendModal.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "times"), style: .plain, target: self, action: #selector(self.tappedLeftBarButtonItem(_:)))
            let transitionDelegate = DeckTransitioningDelegate()
            nav.transitioningDelegate = transitionDelegate
            nav.modalPresentationStyle = .custom
            self.present(nav, animated: true, completion: nil)
        }
    }

    func requestTapped() {
        let modal = UIStoryboard(name: "Account", bundle: nil).instantiateViewController(withIdentifier: "MyAddressNavigationController")

        let transitionDelegate = DeckTransitioningDelegate()
        modal.transitioningDelegate = transitionDelegate
        modal.modalPresentationStyle = .custom
        present(modal, animated: true, completion: nil)
    }

    func scanTapped() {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "segueToQR", sender: nil)
        }
    }

    func postToChannel(channel: String) {

        let headers = ["content-type": "application/json"]
        let parameters = ["address": Authenticated.account!.address,
                          "device": "iOS" ] as [String: Any]

        let postData = try? JSONSerialization.data(withJSONObject: parameters, options: [])

        let request = NSMutableURLRequest(url: NSURL(string: "https://platform.o3.network/api/v1/channel/" + channel)! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (_, response, error) -> Void in
            if error != nil {
                return
            } else {
                _ = response as? HTTPURLResponse
            }
        })

        dataTask.resume()

    }

    func qrScanned(data: String) {
        //if there is more type of string we have to check it here
        if data.hasPrefix("o3://channel") {
            //post to utility communication channel
            let channel = URL(string: data)?.lastPathComponent
            postToChannel(channel: channel!)
            return
        }
        DispatchQueue.main.async {
            self.sendTapped(qrData: data)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? QRScannerController {
            dest.delegate = self
            qrController = dest
        }
    }
}
