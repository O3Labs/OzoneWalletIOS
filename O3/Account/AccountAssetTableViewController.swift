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
import Kingfisher

class AccountAssetTableViewController: UITableViewController, ClaimingGasCellDelegate {
    
    private enum sections: Int {
        case unclaimedGAS = 0
        case toolbar
        case inbox
        case neoAssets
        case ontologyAssets
        case nep5tokens
        case tradingAccountSection
    }
    
    private enum accounts: Int {
        case o3Account = 0
        case tradingAccount
    }
    
    var sendModal: SendWhereTableViewController?
    
    var claims: Claimable?
    var isClaimingNeo: Bool = false
    var isClaimingOnt: Bool = false
    
    var tokenAssets = O3Cache.tokensBalance(for: Authenticated.wallet!.address)
    var neoBalance: Int = Int(O3Cache.neoBalance(for: Authenticated.wallet!.address).value)
    var gasBalance: Double = O3Cache.gasBalance(for: Authenticated.wallet!.address).value
    var ontologyAssets: [O3WalletNativeAsset] = O3Cache.ontologyBalances(for: Authenticated.wallet!.address)
    var mostRecentClaimAmount = 0.0
    var tradingAccount: TradingAccount?
    var addressInbox: Inbox?
    var sectionHeaderCollapsedState: [Int: Bool] = [:]
    
    private var accountValues: [accounts: String] = [:]
    
    var ongAmount = 0.0
    
    @objc func reloadCells() {
        DispatchQueue.main.async { self.tableView.reloadData() }
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(reloadAllData), name: Notification.Name(rawValue: "NEP6Updated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadAllData), name: NSNotification.Name(rawValue: "tokenSelectorDismissed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadCells), name: NSNotification.Name(rawValue: ThemeUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.loadTradingAccountBalances), name: NSNotification.Name(rawValue: "needsReloadTradingBalances"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.viewOpenOrders), name: NSNotification.Name(rawValue: "viewTradingOrders"), object: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "NEP6Updated"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: ThemeUpdateNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "tokenSelectiorDismissed"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "needsReloadTradingBalances"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "viewTradingOrders"), object: nil)
    }
    
    @objc func tappedWalletSwap() {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addObservers()
        self.view.theme_backgroundColor = O3Theme.backgroundColorPicker
        self.tableView.theme_backgroundColor = O3Theme.backgroundLightgrey
        self.tableView.theme_separatorColor = O3Theme.tableSeparatorColorPicker
        applyNavBarTheme()
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(reloadAllData), for: .valueChanged)
                
        
        //first state of the section
        sectionHeaderCollapsedState[sections.neoAssets.rawValue] = true
        sectionHeaderCollapsedState[sections.tradingAccountSection.rawValue] = true
        
        //load everything from cache first
        self.loadAccountValue(account: accounts.o3Account, list: [O3Cache.neoBalance(for: Authenticated.wallet!.address), O3Cache.gasBalance(for: Authenticated.wallet!.address)] + O3Cache.ontologyBalances(for: Authenticated.wallet!.address) + O3Cache.tokensBalance(for: Authenticated.wallet!.address))
        loadAccountState()
        
        self.loadInbox()
        self.loadTradingAccountBalances()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadClaimableGAS()
        loadClaimableOng()
        setLocalizedStrings()
    }
    
    private func loadAccountValue(account: accounts,  list: [O3WalletNativeAsset]) {
        
        if list.count == 0 {
            let fiat = Fiat(amount: 0.0)
            self.accountValues[account] = fiat.formattedString()
            self.tableView.reloadData()
            return
        }
        
        O3Client.shared.getAccountValue(list) { result in
            switch result {
            case .failure:
                return
            case .success(let value):
                let formatter = NumberFormatter()
                formatter.currencySymbol = value.currency
                formatter.locale = Locale(identifier: "en_US_POSIX")
                let number = formatter.number(from: value.total)
                DispatchQueue.main.async {
                    let fiat = Fiat(amount: number?.floatValue ?? 0.0)
                    self.accountValues[account] = fiat.formattedString()
                    let index = list.firstIndex{$0.symbol == "ONG"}
                    if let index = index {
                        self.ongAmount = list[index].value
                    }
                    
                    //somehow calling reloadSections makes the uitableview flickering
                    //using reloadData instead ¯\_(ツ)_/¯
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func loadInbox() {
        O3APIClient(network: AppState.network).getInbox(address: Authenticated.wallet!.address) { result in
            switch result {
            case .failure(let error):
                print(error)
                return
            case .success(let inbox):
                DispatchQueue.main.async {
                    self.addressInbox = inbox
                    self.tableView.reloadSections([sections.inbox.rawValue], with: .none)
                }
            }
        }
    }
    
    var numberOfOpenOrders: Int = 0
    @objc func loadTradingAccountBalances() {
        O3APIClient(network: AppState.network).tradingBalances(address: Authenticated.wallet!.address) { result in
            switch result {
            case .failure(let error):
                print(error)
                return
            case .success(let tradingAccount):
                DispatchQueue.main.async {
                    self.tradingAccount = tradingAccount
                    self.tableView.reloadSections([sections.tradingAccountSection.rawValue], with: .automatic)
                    var list: [O3WalletNativeAsset] = []
                    for v in self.tradingAccount!.switcheo.confirmed{
                        list.append(v.toTransferableAsset())
                    }
                    self.loadAccountValue(account: accounts.tradingAccount, list: list)
                }
            }
        }
        
        self.loadOpenOrders { value in
            DispatchQueue.main.async {
                self.numberOfOpenOrders = value
                self.tableView.reloadSections([sections.tradingAccountSection.rawValue, sections.tradingAccountSection.rawValue], with: .automatic)
            }
        }
    }
    
    @objc func reloadAllData() {
        loadAccountState()
        loadClaimableGAS()
        loadClaimableOng()
        loadInbox()
        loadTradingAccountBalances()
        DispatchQueue.main.async {
            self.tableView.refreshControl?.endRefreshing()
            // self.tableView.reloadData()
        }
        setLocalizedStrings()
    }
    
    func setIsClaimingNeo(_ isClaiming: Bool) {
        self.isClaimingNeo = isClaiming
    }
    
    func setIsClaimingOnt(_ isClaiming: Bool) {
        self.isClaimingOnt = isClaiming
    }
    
    @objc func loadClaimableGAS() {
        if Authenticated.wallet == nil {
            return
        }
        
        if self.isClaimingNeo == true {
            return
        }
        let indexPath = IndexPath(row: 0, section: sections.unclaimedGAS.rawValue)
        guard let cell = self.tableView.cellForRow(at: indexPath) as? ClaimableGASTableViewCell else {
            return
        }
        cell.loadClaimableGASNeo()

    }
    
    @objc func loadClaimableOng() {
        if Authenticated.wallet == nil {
            return
        }
        
        if self.isClaimingNeo == true {
            return
        }
        let indexPath = IndexPath(row: 0, section: sections.unclaimedGAS.rawValue)
        guard let cell = self.tableView.cellForRow(at: indexPath) as? ClaimableGASTableViewCell else {
            return
        }
        cell.loadClaimableOng()
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
        O3Cache.setGasBalance(gasBalance: gasBalance, address: Authenticated.wallet!.address)
        O3Cache.setNeoBalance(neoBalance: neoBalance, address: Authenticated.wallet!.address)
        O3Cache.setTokensBalance(tokens: tokenAssets, address: Authenticated.wallet!.address)
        O3Cache.setOntologyBalance(tokens: ontologyAssets, address: Authenticated.wallet!.address)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        self.loadAccountValue(account: accounts.o3Account, list: [O3Cache.neoBalance(for: Authenticated.wallet!.address), O3Cache.gasBalance(for: Authenticated.wallet!.address)] + self.ontologyAssets + self.tokenAssets)
    }
    
    func loadAccountState() {
        O3APIClient(network: AppState.network).getAccountState(address: Authenticated.wallet?.address ?? "") { result in
            DispatchQueue.main.async {
                switch result {
                case .failure:
                    return
                case .success(let accountState):
                    let index = accountState.ontology.firstIndex{$0.symbol == "ONG"}
                    if let index = index {
                        self.ongAmount = accountState.ontology[index].value
                    }
                    self.updateCacheAndLocalBalance(accountState: accountState)
                }
            }
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 9
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == sections.unclaimedGAS.rawValue {
            return 1
        } else if section == sections.toolbar.rawValue {
            return 1
        } else if section == sections.inbox.rawValue {
            return 0
        }  else if section == sections.neoAssets.rawValue {
            return sectionHeaderCollapsedState[sections.neoAssets.rawValue]  == true ? 0 : 2
        } else if section == sections.ontologyAssets.rawValue {
            return sectionHeaderCollapsedState[sections.neoAssets.rawValue]  == true ? 0 : ontologyAssets.count
        } else if section == sections.nep5tokens.rawValue {
            return sectionHeaderCollapsedState[sections.neoAssets.rawValue]  == true ? 0 : tokenAssets.count
        } else if section == sections.tradingAccountSection.rawValue {
            return sectionHeaderCollapsedState[sections.tradingAccountSection.rawValue]  == true ? 0 : tradingAccount?.switcheo.confirmed.count ?? 0
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == sections.unclaimedGAS.rawValue {
            return 172.0
        } else if indexPath.section == sections.toolbar.rawValue {
            return 60.0
        } else if indexPath.section == sections.inbox.rawValue {
            return 190.0
        }
        
        if indexPath.section == sections.neoAssets.rawValue {
            return 66.0
        }
        
        if indexPath.section == sections.tradingAccountSection.rawValue {
            return 66.0
        }
        return 66.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == sections.unclaimedGAS.rawValue {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell-claimable-gas") as? ClaimableGASTableViewCell else {
                let cell = UITableViewCell(frame: CGRect.zero)
                cell.contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
                cell.theme_backgroundColor = O3Theme.backgroundColorPicker
                return cell
            }
            cell.ongBalance = ongAmount
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            cell.delegate = self
            return cell
        }
        
        if indexPath.section == sections.toolbar.rawValue {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell-toolbar") as? MainToolbarTableViewCell else {
                let cell =  UITableViewCell(frame: CGRect.zero)
                cell.contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
                cell.theme_backgroundColor = O3Theme.backgroundColorPicker
                return cell
            }
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            return cell
        }
        
        if indexPath.section == sections.inbox.rawValue {
            /*guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell-inbox-item") as? InboxItemTableViewCell else {
                let cell =  UITableViewCell(frame: CGRect.zero)
                cell.theme_backgroundColor = O3Theme.backgroundColorPicker
                return cell
            }
            let item = addressInbox?.items[indexPath.row]
            cell.inboxItem = item
            return cell*/
            return UITableViewCell()
        }
        
        if indexPath.section == sections.neoAssets.rawValue {
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell-nativeasset") as? NativeAssetTableViewCell else {
                let cell =  UITableViewCell(frame: CGRect.zero)
                cell.theme_backgroundColor = O3Theme.backgroundLightgrey
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
                let cell =  UITableViewCell(frame: CGRect.zero)
                cell.theme_backgroundColor = O3Theme.backgroundLightgrey
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
        
        if indexPath.section == sections.tradingAccountSection.rawValue {
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell-nep5token") as? NEP5TokenTableViewCell else {
                let cell =  UITableViewCell(frame: CGRect.zero)
                cell.theme_backgroundColor = O3Theme.backgroundLightgrey
                return cell
            }
            let list = self.tradingAccount?.switcheo.confirmed
            let token = list![indexPath.row]
            
            //trading account returns value in string
            let valueDecimal = Decimal(string: token.value!)
            let dividedBalance = (valueDecimal! / pow(10, token.decimals))
            let value = Double(truncating: (dividedBalance as NSNumber?)!)
            
            cell.amountLabel.text = value.string(token.decimals, removeTrailing: true)
            cell.titleLabel.text = token.symbol
            cell.subtitleLabel.text = token.name
            let imageURL = String(format: "https://cdn.o3.network/img/neo/%@.png", token.symbol.uppercased())
            cell.iconImageView?.kf.setImage(with: URL(string: imageURL))
            return cell
        }
        
        //ontology asset using the same nep5 token cell
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell-nep5token") as? NEP5TokenTableViewCell else {
            let cell =  UITableViewCell(frame: CGRect.zero)
            cell.theme_backgroundColor = O3Theme.backgroundLightgrey
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
        if indexPath.section == sections.unclaimedGAS.rawValue
            || indexPath.section == sections.inbox.rawValue
            || indexPath.section == sections.toolbar.rawValue {
            return false
        }
        
        return true
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == sections.neoAssets.rawValue ||  section == sections.tradingAccountSection.rawValue{
            return 108.0
        }
        
        if section == sections.ontologyAssets.rawValue || section == sections.nep5tokens.rawValue {
            return 0.0
        }
        
        return 0.0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if section == sections.neoAssets.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: "o3-account-header") as! AccountHeaderTableViewCell
        
            cell.totalAmountLabel?.text = accountValues[accounts.o3Account]
            cell.assetCountTitleLabel?.isHidden = self.tokenAssets.count == 0
            cell.assetCountTitleLabel?.text = String(format: "+%d more", self.tokenAssets.count)
            cell.sectionIndex = section
            cell.toggleStateButton?.tag = section
            return cell.contentView
        }
        
        if section == sections.tradingAccountSection.rawValue {
            var list: [O3WalletNativeAsset] = []
            if self.tradingAccount != nil {
                for v in self.tradingAccount!.switcheo.confirmed {
                    list.append(v.toTransferableAsset())
                }
            }
            
            if list.count == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "trading-account-header-empty") as! AccountHeaderTableViewCell
                if self.numberOfOpenOrders == 0 {
                    cell.moreButton?.badgeValue = ""
                } else {
                    cell.moreButton?.badgeValue = String(format:"%d", self.numberOfOpenOrders)
                }
                return cell
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "trading-account-header") as! AccountHeaderTableViewCell
            
            cell.totalAmountLabel?.text = accountValues[accounts.tradingAccount]
            cell.sectionIndex = section
            cell.toggleStateButton?.tag = section
            if self.numberOfOpenOrders == 0 {
                cell.moreButton?.badgeValue = ""
            } else {
                cell.moreButton?.badgeValue = String(format:"%d", self.numberOfOpenOrders)
            }
            
            if self.tradingAccount != nil {
                cell.subTitleLabel?.isHidden = list.count > 0
                cell.list = list
            } else {
                cell.subTitleLabel?.isHidden = false
            }
            return cell.contentView
        }
        return nil
    }
    
    func showActionSheetAssetInTradingAccount(asset: TradableAsset) {
        
        let alert = UIAlertController(title: asset.name, message: nil, preferredStyle: .actionSheet)
        
        let buyButton = UIAlertAction(title: "Buy", style: .default) { _ in
            tradingEvent.shared.startBuy(asset: asset.symbol, source: TradingActionSource.asset)
            self.openCreateOrder(action: CreateOrderAction.Buy, asset: asset)
        }
        alert.addAction(buyButton)
        
        //we can't actually sell NEO but rather use NEO to buy other asset
        let sellButton = UIAlertAction(title: "Sell", style: .default) { _ in
            tradingEvent.shared.startSell(asset: asset.symbol, source: TradingActionSource.asset)
            self.openCreateOrder(action: CreateOrderAction.Sell, asset: asset)
        }
        alert.addAction(sellButton)
        
        let withdrawButton = UIAlertAction(title: "Withdraw", style: .default) { _ in
            tradingEvent.shared.startWithdraw(asset: asset.symbol, source: TradingActionSource.asset)
            self.openWithDrawOrDeposit(action: WithdrawDepositTableViewController.Action.Withdraw, asset: asset)
        }
        
        alert.addAction(withdrawButton)
        
        let cancel = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { _ in
            
        }
        alert.addAction(cancel)
        alert.popoverPresentationController?.sourceView = self.tableView
        present(alert, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == sections.unclaimedGAS.rawValue
            || indexPath.section == sections.inbox.rawValue
            || indexPath.section == sections.toolbar.rawValue {
            return
        }
        
        //offer the option to buy more/sell and withdraw
        if  indexPath.section == sections.tradingAccountSection.rawValue {
            let asset = self.tradingAccount?.switcheo.confirmed[indexPath.row]
            showActionSheetAssetInTradingAccount(asset: asset!)
            return
        }
        
        var blockchain = "neo"
        var symbol = "neo"
        if indexPath.section == sections.neoAssets.rawValue {
            symbol = indexPath.row == 0 ? "neo" : "gas"
        } else if indexPath.section == sections.nep5tokens.rawValue {
            symbol = tokenAssets[indexPath.row].symbol
        } else if indexPath.section == sections.ontologyAssets.rawValue {
            blockchain = "ont"
            symbol = ontologyAssets[indexPath.row].symbol
        }
        
        tradingEvent.shared.viewTokenDetail(asset: symbol, source: TradingActionSource.o3Account)
        let urlString = String(format: "https://o3.app/assets/%@/%@", blockchain, symbol)
        Controller().openDappBrowserV2(url: URL(string: urlString)!, assetSymbol: symbol )
    }
    
    //MARK: -
    func setLocalizedStrings() {
        if NEP6.getFromFileSystem()?.getAccounts().count ?? 0 > 0 {
            DispatchQueue.main.async { self.navigationController?.navigationBar.topItem?.title = NEP6.getFromFileSystem()?.getAccounts()[0].label }
        } else {
            self.navigationController?.navigationBar.topItem?.title = "My O3 Wallet"
        }
    }
    
    @IBAction func tappedLeftBarButtonItem(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapSend(_ sender: Any) {
        self.sendTapped()
    }
    
    @IBAction func didTapRequest(_ sender: Any) {
        let modal = UIStoryboard(name: "Account", bundle: nil).instantiateViewController(withIdentifier: "MyAddressNavigationController")
        
        let transitionDelegate = DeckTransitioningDelegate()
        modal.transitioningDelegate = transitionDelegate
        modal.modalPresentationStyle = .custom
        present(modal, animated: true, completion: nil)
    }
    
    @IBAction func didTapScan(_ sender: Any) {
        guard let modal = UIStoryboard(name: "QR", bundle: nil).instantiateInitialViewController() as? QRScannerController else {
            fatalError("Presenting improper modal controller")
        }
        modal.delegate = self
        let nav = NoHairlineNavigationController(rootViewController: modal)
        nav.navigationBar.prefersLargeTitles = false
        nav.setNavigationBarHidden(true, animated: false)
        let transitionDelegate = DeckTransitioningDelegate()
        nav.transitioningDelegate = transitionDelegate
        nav.modalPresentationStyle = .custom
        self.present(nav, animated: true, completion: nil)
    }
    
    func sendTapped(qrData: String? = nil) {
        DispatchQueue.main.async {
            guard let sendModal = UIStoryboard(name: "Send", bundle: nil).instantiateViewController(withIdentifier: "sendWhereTableViewController") as? SendWhereTableViewController else {
                fatalError("Presenting improper modal controller")
            }
            sendModal.incomingQRData = qrData
            let nav = NoHairlineNavigationController(rootViewController: sendModal)
            nav.navigationBar.prefersLargeTitles = false
            nav.navigationItem.largeTitleDisplayMode = .never
            sendModal.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-x"), style: .plain, target: self, action: #selector(self.tappedLeftBarButtonItem(_:)))
            let transitionDelegate = DeckTransitioningDelegate()
            nav.transitioningDelegate = transitionDelegate
            nav.modalPresentationStyle = .custom
            self.present(nav, animated: true, completion: nil)
        }
    }
    
}

extension AccountAssetTableViewController {
    @objc func viewOpenOrders() {
        guard let nav = UIStoryboard(name: "Trading", bundle: nil).instantiateViewController(withIdentifier: "OrdersTabsViewControllerNav") as? UINavigationController else {
            return
        }
        guard (nav.viewControllers.first as? OrdersTabsViewController) != nil else {
            return
        }
        let transitionDelegate = DeckTransitioningDelegate()
        nav.transitioningDelegate = transitionDelegate
        nav.modalPresentationStyle = .custom
        self.present(nav, animated: true, completion: nil)
    }
    
    func openCreateOrder(action: CreateOrderAction, asset: TradableAsset) {
        let nav = UIStoryboard(name: "Trading", bundle: nil).instantiateViewController(withIdentifier: "CreateOrderTableViewControllerNav") as! UINavigationController
        self.tradingAccount?.switcheo.loadSupportedTokens(completion: { tokens in
            
            DispatchQueue.main.async {
                
                
                if let vc = nav.viewControllers.first as? CreateOrderTableViewController {
                    vc.viewModel = CreateOrderViewModel()
                    
                    vc.viewModel.selectedAction = action
                    //override the precision here
                    let wantToken = tokens.first(where: { t -> Bool in
                        return t.id == asset.id
                    })!
                    
                    vc.viewModel.wantAsset = asset
                    vc.viewModel.wantAsset.precision = wantToken.precision
                    vc.viewModel.offerAsset = self.tradingAccount?.switcheo.basePairs.filter({ t -> Bool in
                        return t.symbol != asset.symbol
                    }).first
                    vc.viewModel.tradingAccount = self.tradingAccount
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
        })
    }
    
    func openWithDrawOrDeposit(action: WithdrawDepositTableViewController.Action, asset: TradableAsset?) {
        let nav = UIStoryboard(name: "Trading", bundle: nil).instantiateViewController(withIdentifier: "withdrawDepositNav") as! UINavigationController
        let transitionDelegate = DeckTransitioningDelegate()
        nav.transitioningDelegate = transitionDelegate
        nav.modalPresentationStyle = .custom
        
        if let vc = nav.viewControllers.first as? WithdrawDepositTableViewController {
            vc.selectedAction = action
            if asset != nil {
                vc.selectedAsset = asset
            }
            if action == WithdrawDepositTableViewController.Action.Withdraw {
                vc.withdrawableAsset = self.tradingAccount?.switcheo.confirmed
            }
            vc.delegate = self
        }
        self.present(nav, animated: true, completion: nil)
    }
    
    @IBAction func didTapDeposit(_ sender: Any) {
        openWithDrawOrDeposit(action: WithdrawDepositTableViewController.Action.Deposit, asset: nil)
    }
    
    @IBAction func didTapMoreTradingAccount(_ sender: Any) {
        
        let alert = UIAlertController(title: "Trading account", message: nil, preferredStyle: .actionSheet)
        
        if self.tradingAccount?.switcheo.confirmed.count ?? 0 > 0 {
            let depositButton = UIAlertAction(title: "Deposit", style: .default) { _ in
                tradingEvent.shared.startDeposit(asset: "NEO", source: TradingActionSource.tradingAccount)
                self.openWithDrawOrDeposit(action: WithdrawDepositTableViewController.Action.Deposit, asset: nil)
            }
            alert.addAction(depositButton)
            
            let withdrawButton = UIAlertAction(title: "Withdraw", style: .default) { _ in
                tradingEvent.shared.startWithdraw(asset: "", source: TradingActionSource.tradingAccount)
                self.openWithDrawOrDeposit(action: WithdrawDepositTableViewController.Action.Withdraw, asset: nil)
            }
            alert.addAction(withdrawButton)
        }
        
        
        var orderTitle = String(format: "Orders")
        if self.numberOfOpenOrders > 0 {
            orderTitle = String(format: "Orders (%d)", numberOfOpenOrders)
        }
        
        let orders = UIAlertAction(title: orderTitle, style: .default) { _ in
            self.viewOpenOrders()
        }
        alert.addAction(orders)
        
        let cancel = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { _ in
            
        }
        alert.addAction(cancel)
        alert.popoverPresentationController?.sourceView = self.tableView
        present(alert, animated: true, completion: nil)
    }
    
}

extension AccountAssetTableViewController: WithdrawDepositTableViewControllerDelegate {
    func didFinishAction(action: WithdrawDepositTableViewController.Action) {
        if action == WithdrawDepositTableViewController.Action.Deposit {
            self.loadAccountState()
        }
        loadTradingAccountBalances()
    }
}

extension AccountAssetTableViewController {
    @IBAction func sectionHeaderRightButtonTapped(_ sender: UIButton) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: {
                sender.transform = sender.isSelected ? CGAffineTransform.identity : CGAffineTransform(rotationAngle: CGFloat(-0.999*Double.pi))
            }) { completed in
                
            }
            sender.isSelected = !sender.isSelected
            if sender.tag == sections.neoAssets.rawValue {
                self.sectionHeaderCollapsedState[sections.neoAssets.rawValue] = !self.sectionHeaderCollapsedState[sections.neoAssets.rawValue]!
                self.tableView.reloadData()
            } else if sender.tag == sections.tradingAccountSection.rawValue {
                self.sectionHeaderCollapsedState[sections.tradingAccountSection.rawValue] = !self.sectionHeaderCollapsedState[sections.tradingAccountSection.rawValue]!
                self.tableView.reloadData()
            }
        }
    }
}

extension AccountAssetTableViewController {
    func loadOpenOrders(completion: @escaping(Int)->Void) {
        O3APIClient(network: AppState.network).loadSwitcheoOrders(address: Authenticated.wallet!.address, status: SwitcheoOrderStatus.open) { result in
            switch result{
            case .failure(let error):
                #if DEBUG
                print(error)
                #endif
                completion(0)
            case .success(let response):
                completion(response.switcheo.count)
            }
        }
    }
}


extension AccountAssetTableViewController: QRScanDelegate {
    func qrScanned(data: String) {
        DispatchQueue.main.async {
            self.sendTapped(qrData: data)
        }
    }
}
