//
//  NewHomeVC.swift
//  O3
//
//  Created by 吕益凯 on 2020/6/11.
//  Copyright © 2020 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import ScrollableGraphView
import PKHUD
import SwiftTheme
import DeckTransition
import JXSegmentedView

extension JXPagingListContainerView: JXSegmentedViewListContainer {}

let IS_IPHONEX = UIApplication.shared.statusBarFrame.size.height > 20

class NewHomeVC: UIViewController, HomeViewModelDelegate, PagingViewTableHeaderViewDelegate{
    func setIsClaimingNeo(_ isClaiming: Bool) {
        self.isClaimingNeo = isClaiming
    }
    
    func setIsClaimingOnt(_ isClaiming: Bool) {
        self.isClaimingOnt = isClaiming
    }
    
    @objc func loadClaimableGAS(address: String) {
        if Authenticated.wallet == nil {
            return
        }
        
        if self.isClaimingNeo == true {
            return
        }
        if address == "" {
            userHeaderView.loadClaimableGASNeo()
        }else{
            userHeaderView.loadClaimableGASNeo(address: address)
        }
        
    }
    
    @objc func loadClaimableOng(address: String) {
        if Authenticated.wallet == nil {
            return
        }
        
        if self.isClaimingNeo == true {
            return
        }
        if address == "" {
            userHeaderView.loadClaimableOng()
        }else{
            userHeaderView.loadClaimableOng(address: address)
        }
    }
    
    
    @IBOutlet weak var walletNameSelectButton: UIButton!
    @IBOutlet weak var walletNameSelectLabel: UILabel!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var keyButton: UIButton!
    
    @IBOutlet weak var walletNameLabel: UILabel!
    @IBOutlet weak var totalNumberLabel: UILabel!
    @IBOutlet weak var watchButton: UIButton!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var sendAndReceiveBgView: UIView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var receiveButton: UIButton!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var homeTopBackgroundImageView: UIImageView!
    
    var refreshControl = UIRefreshControl()
    
    lazy var pagingView: JXPagingView = preferredPagingView()
    lazy var userHeaderView: PagingViewTableHeaderView = preferredTableHeaderView()
    let dataSource: JXSegmentedTitleDataSource = JXSegmentedTitleDataSource()
    lazy var segmentedView: JXSegmentedView = JXSegmentedView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: CGFloat(headerInSectionHeight)))
    var titles = ["Assets"]
    var tableHeaderViewHeight: Int = 200
    var headerInSectionHeight: Int = 50
    var isNeedHeader = false
    var isNeedFooter = false
    
    var isSecureText = false//是否隐藏
    var buyButtonBottom = IS_IPHONEX ? 88.0 : 44.0
    var buyButton = UIButton()
    
    var wallets = NEP6.getFromFileSystem()?.getWalletAccounts() ?? []
    
    //算钱包value
    var accountValues: [IndexPath: AccountValue] = [:]
    var watchAddrs: [IndexPath: NEP6.Account] = [:]
    var combinedAccountValue: AccountValue?
    var group: DispatchGroup = DispatchGroup()
    var walletSectionNum = 1
    
    var firstTimeGraphLoad = true
    var firstTimeViewLoad = true
    var portfolio: PortfolioValue?
    var homeviewModel: HomeViewModel!
    var selectedPrice: PriceData?
    var displayedAssets = [PortfolioAsset]()
    var watchAddresses = [NEP6.Account]()
    var coinbaseAssets: [PortfolioAsset] {
        get {
            var assets = displayedAssets.filter { asset -> Bool in
                return self.homeviewModel.coinbaseAccountBalances.contains {
                    return $0.symbol.lowercased() == asset.symbol.lowercased()
                }
            }
            
            if UserDefaultsManager.isDustHidden && homeviewModel.currentIndex == 0 {
                assets = assets.filter { asset -> Bool in
                    let price = portfolio?.price[asset.symbol]?.averageBTC ?? 0.0
                    let amount = asset.value
                    return price * amount >= 0.00005
                }
            }
            
            if UserDefaultsManager.portfolioSortType == .atozSort {
                assets.sort { asset1, asset2 -> Bool in
                    return asset1.symbol < asset2.symbol
                }
            } else if UserDefaultsManager.portfolioSortType == .valueSort {
                assets.sort { asset1, asset2 -> Bool in
                    let price1 = portfolio?.price[asset1.symbol]?.averageBTC ?? 0.0
                    let amount1 = asset1.value
                    
                    let price2 = portfolio?.price[asset2.symbol]?.averageBTC ?? 0.0
                    let amount2 = asset2.value
                    
                    return price1 * amount1 > price2 * amount2
                }
            }
            
            return assets
        }
    }
    
    var walletAssets: [PortfolioAsset] {
        get {
            var assets = displayedAssets.filter { asset -> Bool in
                return self.homeviewModel.coinbaseAccountBalances.contains {
                    $0.symbol.lowercased() == asset.symbol.lowercased()
                    } == false
            }
            if UserDefaultsManager.isDustHidden && homeviewModel.currentIndex == 0 {
                assets = assets.filter { asset -> Bool in
                    let price = portfolio?.price[asset.symbol]?.averageBTC ?? 0.0
                    let amount = asset.value
                    return price * amount >= 0.00005
                }
            }
            
            if UserDefaultsManager.portfolioSortType == .atozSort {
                assets.sort { asset1, asset2 -> Bool in
                    return asset1.symbol < asset2.symbol
                }
            } else if UserDefaultsManager.portfolioSortType == .valueSort {
                assets.sort { asset1, asset2 -> Bool in
                    let price1 = portfolio?.price[asset1.symbol]?.averageBTC ?? 0.0
                    let amount1 = asset1.value
                    
                    let price2 = portfolio?.price[asset2.symbol]?.averageBTC ?? 0.0
                    let amount2 = asset2.value
                    
                    return price1 * amount1 > price2 * amount2
                }
            }
            
            return assets
        }
    }
    
    private enum accounts: Int {
        case o3Account = 0
        case tradingAccount
    }
    //同步
    var claims: Claimable?
    var isClaimingNeo: Bool = false
    var isClaimingOnt: Bool = false
    
    var ongAmount = 0.0
    var tokenAssets = O3Cache.tokensBalance(for: Authenticated.wallet!.address)
    var neoBalance: Int = Int(O3Cache.neoBalance(for: Authenticated.wallet!.address).value)
    var gasBalance: Double = O3Cache.gasBalance(for: Authenticated.wallet!.address).value
    var ontologyAssets: [O3WalletNativeAsset] = O3Cache.ontologyBalances(for: Authenticated.wallet!.address)
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isTranslucent = false
        
        addObservers()
        homeTopBackgroundImageView.contentMode = .scaleToFill
        
        homeviewModel = HomeViewModel(delegate: self)
        
        watchAddresses = loadWatchAddresses()
        self.loadAccountValue(account: accounts.o3Account, list: [O3Cache.neoBalance(for: Authenticated.wallet!.address), O3Cache.gasBalance(for: Authenticated.wallet!.address)] + O3Cache.ontologyBalances(for: Authenticated.wallet!.address) + O3Cache.tokensBalance(for: Authenticated.wallet!.address))
        loadAccountState()
        
        walletNameSelectLabel.text = wallets.first {$0.isDefault}!.label
        walletNameLabel.text = "\(wallets.first {$0.isDefault}!.label)≈"
        addressLabel.text = wallets.first {$0.isDefault}!.address
        
        
        dataSource.titles = titles
        dataSource.titleSelectedColor = UIColor(red: 105/255, green: 144/255, blue: 239/255, alpha: 1)
        dataSource.titleNormalColor = UIColor.black
        dataSource.isTitleColorGradientEnabled = true
        dataSource.isItemSpacingAverageEnabled = false
        dataSource.isTitleZoomEnabled = true
        
        segmentedView.backgroundColor = UIColor.white
        segmentedView.delegate = self
        segmentedView.isContentScrollViewClickTransitionAnimationEnabled = false
        segmentedView.dataSource = dataSource
        
        let lineView = JXSegmentedIndicatorLineView()
        lineView.indicatorColor = UIColor(red: 105/255, green: 144/255, blue: 239/255, alpha: 1)
        lineView.indicatorWidth = 30
        segmentedView.indicators = [lineView]
        
        let lineWidth = 1/UIScreen.main.scale
        let bottomLineView = UIView()
        bottomLineView.backgroundColor = UIColor.lightGray
        bottomLineView.frame = CGRect(x: 0, y: segmentedView.bounds.height - lineWidth, width: segmentedView.bounds.width, height: lineWidth)
        bottomLineView.autoresizingMask = .flexibleWidth
        segmentedView.addSubview(bottomLineView)
        
        pagingView.mainTableView.gestureDelegate = self
        self.contentView.addSubview(pagingView)
        
        segmentedView.listContainer = pagingView.listContainerView
        
        //扣边返回处理，下面的代码要加上
        pagingView.listContainerView.scrollView.panGestureRecognizer.require(toFail: self.navigationController!.interactivePopGestureRecognizer!)
        pagingView.mainTableView.panGestureRecognizer.require(toFail: self.navigationController!.interactivePopGestureRecognizer!)
        
        // Create action listener
        walletNameSelectButton.addTarget(self, action: #selector(showMultiWalletDisplay), for: .touchUpInside)
        copyButton.addTarget(self, action: #selector(copyAddress), for: .touchUpInside)
        let clickTap = UITapGestureRecognizer(target: self, action: #selector(copyAddress))
        addressLabel.isUserInteractionEnabled = true
        addressLabel.addGestureRecognizer(clickTap)
        scanButton.addTarget(self, action: #selector(rightBarButtonTapped), for: .touchUpInside)
        watchButton.addTarget(self, action: #selector(switchIsSecureText), for: .touchUpInside)
        
        buyButton = UIButton(frame: CGRect.init(x: UIScreen.main.bounds.size.width-100, y: UIScreen.main.bounds.size.height-110-CGFloat(self.buyButtonBottom), width: 99.0, height: 110.0))
        buyButton.setImage(UIImage.init(named: "home_buyNeo"), for: .normal)
        buyButton.addTarget(self, action: #selector(buyNeoClick), for: .touchUpInside)
        self.view.addSubview(buyButton)
        self.view.bringSubviewToFront(buyButton)
        
        // shadowCode
        sendAndReceiveBgView.layer.shadowColor = UIColor.blue.cgColor
        sendAndReceiveBgView.layer.shadowRadius = 25
        sendAndReceiveBgView.layer.shadowOpacity = 0.2
        sendAndReceiveBgView.layer.shadowOffset = CGSize.init(width: 0, height: 10)
        
        refreshControl.addTarget(self, action: #selector(reloadAllData),
                                 
                                 for: .valueChanged)
        
        refreshControl.attributedTitle = NSAttributedString(string: "loading...")
        
        pagingView.mainTableView.addSubview(refreshControl)
        
        
        addThemedElements()
    }
    
    @objc func addThemedElements(){
        homeTopBackgroundImageView.theme_image = O3Theme.homeTopBackgroundImagePick
        sendAndReceiveBgView.theme_backgroundColor = O3Theme.newHomeHeaderBackgroundColorPicker
        pagingView.mainTableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        self.view.theme_backgroundColor = O3Theme.backgroundColorPicker
        self.sendButton.setTitleColor(UserDefaultsManager.theme.newTitleNormalColor, for: .normal)
        self.receiveButton.setTitleColor(UserDefaultsManager.theme.newTitleNormalColor, for: .normal)
        self.sendButton.setImage(UserDefaultsManager.theme.sendButtonImage, for: .normal)
        self.receiveButton.theme_setImage(O3Theme.receiveButtonImagePicker, forState: .normal)
        dataSource.titleNormalColor = UserDefaultsManager.theme.titleTextColor
        dataSource.titleSelectedColor = UserDefaultsManager.theme.titleTextColor
        segmentedView.theme_backgroundColor = O3Theme.backgroundColorPicker
        
        refreshControl.theme_backgroundColor = O3Theme.backgroundColorPicker
        refreshControl.theme_tintColor = O3Theme.titleColorPicker
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
        
    }
    @objc func showMultiWalletDisplay() {
        DispatchQueue.main.async {
            Controller().openPortfolioSelector()
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !firstTimeViewLoad {
            self.getBalance()
        }
        firstTimeViewLoad = false
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = (segmentedView.selectedIndex == 0)
        
        loadClaimableGAS(address: "")
        loadClaimableOng(address: "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.refreshControl.endRefreshing()
        if !self.pagingView.mainTableView.isScrollEnabled {
            self.pagingView.mainTableView.isScrollEnabled = true
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        pagingView.frame = self.contentView.bounds
    }
    func preferredTableHeaderView() -> PagingViewTableHeaderView {
        let FYactiveHeadView = Bundle.main.loadNibNamed("PagingViewTableHeaderView", owner: nil, options: nil)?.last as! PagingViewTableHeaderView
        return FYactiveHeadView
    }
    func preferredPagingView() -> JXPagingView {
        return JXPagingView(delegate: self)
    }
    
    //transition period for multi wallet to use the old watch address feature
    //TODO: After multi wallet activation restore the old watcha ddreses
    func loadWatchAddresses() -> [NEP6.Account] {
        if NEP6.getFromFileSystem() == nil {
            return []
        } else {
            var unfiltered = NEP6.getFromFileSystem()!.getWatchAccounts()
            unfiltered = unfiltered.filter { UserDefaultsManager.untrackedWatchAddr.contains($0.address)}
            return unfiltered
        }
    }
    
    @objc func jumpToPortfolio(_ notification: NSNotification) {
        if let portfolioIndex = notification.userInfo?["portfolioIndex"] as? Int {
            //            homeviewModel.currentIndex = portfolioIndex
            if portfolioIndex == 0{
                homeviewModel.currentIndex = portfolioIndex
            }else{
                homeviewModel.currentIndex = 1
            }
            getBalance()
            updateWallets()
            self.addressLabel.text = self.wallets.first {$0.isDefault}!.address
            
            loadClaimableGAS(address: wallets.first {$0.isDefault}!.address)
            loadClaimableOng(address: wallets.first {$0.isDefault}!.address)
            if portfolioIndex == 0{
                walletNameSelectLabel.text = "Total"
                walletNameLabel.text = "Total≈"
            }else{
                walletNameSelectLabel.text = wallets.first {$0.isDefault}!.label
                walletNameLabel.text = "\(wallets.first {$0.isDefault}!.label)≈"
            }
        }
        
    }
    
    func updateWallets() {
        wallets = NEP6.getFromFileSystem()?.getWalletAccounts() ?? []
    }
    
    //MARK:- Observers
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadAllData), name: Notification.Name(rawValue: "NEP6Updated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.getBalance), name: Notification.Name("ChangedNetwork"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.getBalance), name: Notification.Name("ChangedReferenceCurrency"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.jumpToPortfolio(_:)), name: Notification.Name("jumpToPortfolio"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.removeObservers), name: Notification.Name("loggedOut"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.addThemedElements), name: NSNotification.Name(rawValue: ThemeUpdateNotification), object: nil)
    }
    
    @objc func removeObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.removeObservers), name: Notification.Name("loggedOut"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ChangedNetwork"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("jumpToPortfolio"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ChangedReferenceCurrency"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: ThemeUpdateNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "NEP6Updated"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: ThemeUpdateNotification), object: nil)
    }
    
    deinit {
        removeObservers()
    }
    
    @objc func reloadAllData(){
        
        self.updateWallets()
        DispatchQueue.main.async {
            self.pagingView.mainTableView.isScrollEnabled = false
            self.walletNameSelectLabel.text = self.wallets.first {$0.isDefault}!.label
            self.walletNameLabel.text = "\(self.wallets.first {$0.isDefault}!.label)≈"
            self.addressLabel.text = self.wallets.first {$0.isDefault}!.address
        }
        
        loadAccountState()
        self.getBalance()
    }
    
    @objc func getBalance() {
        homeviewModel.reloadBalances()
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
                        self.userHeaderView.ongBalance = accountState.ontology[index].value
                    }
                    self.updateCacheAndLocalBalance(accountState: accountState)
                }
            }
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
            //            self.tableView.reloadData()
        }
        self.loadAccountValue(account: accounts.o3Account, list: [O3Cache.neoBalance(for: Authenticated.wallet!.address), O3Cache.gasBalance(for: Authenticated.wallet!.address)] + self.ontologyAssets + self.tokenAssets)
    }
    private func loadAccountValue(account: accounts,  list: [O3WalletNativeAsset]) {
        
        if list.count == 0 {
            let fiat = Fiat(amount: 0.0)
            //            self.tableView.reloadData()
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
                DispatchQueue.main.async {
                    let index = list.firstIndex{$0.symbol == "ONG"}
                    if let index = index {
                        self.userHeaderView.ongBalance = list[index].value
                    }
                    self.loadClaimableGAS(address: self.wallets.first {$0.isDefault}!.address)
                    self.loadClaimableOng(address: self.wallets.first {$0.isDefault}!.address)
                    //somehow calling reloadSections makes the uitableview flickering
                    //using reloadData instead ¯\_(ツ)_/¯
                    //                    self.tableView.reloadData()
                }
            }
        }
    }
    
    
    //更新数据源
    func updateWithPortfolioData(_ portfolio: PortfolioValue) {
        DispatchQueue.main.async {
            if self.coinbaseAssets.count>0{
                //                self.titles = ["Assets", "Token"]
                self.titles = ["Assets"]
            }else{
                self.titles = ["Assets"]
            }
            self.dataSource.titles = self.titles
            self.portfolio = portfolio
            self.selectedPrice = portfolio.data.first
            self.totalNumberLabel.text = self.selectedPrice?.averageFiatMoney().formattedString()
            self.segmentedView.reloadData()
            self.pagingView.reloadData()
            self.loadClaimableGAS(address: self.wallets.first {$0.isDefault}!.address)
            self.loadClaimableOng(address: self.wallets.first {$0.isDefault}!.address)
            self.refreshControl.endRefreshing()
        }
        
        //A hack otherwise graph wont appear
        if self.firstTimeGraphLoad {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.firstTimeGraphLoad = false
            }
        }
    }
    
    @objc func rightBarButtonTapped() {
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
        DispatchQueue.main.async {
            self.present(nav, animated: true, completion: nil)
        }
    }
    
    @objc func switchIsSecureText(){
        self.isSecureText = !self.isSecureText
        if self.isSecureText {
            self.totalNumberLabel.text = "********"
        }else{
            self.totalNumberLabel.text = self.selectedPrice?.averageFiatMoney().formattedString()
        }
    }
    
    
    //MARK:- HomeViewModelDelegate
    func updateWithBalanceData(_ assets: [PortfolioAsset]) {
        self.displayedAssets = assets
        DispatchQueue.main.async {
            self.segmentedView.reloadData()
            self.pagingView.reloadData()
        }
    }
    
    
    
    func showLoadingIndicator() {
        
    }
    func hideLoadingIndicator(result: String) {
        DispatchQueue.main.async {
            self.pagingView.mainTableView.isScrollEnabled = true
            if result == "fail"{
                HUD.flash(.label("please try again later"), delay: 1.0)
                
            }
            self.refreshControl.endRefreshing()
        }
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
    
    @IBAction func tappedLeftBarButtonItem(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func copyAddress(){
        let pas = UIPasteboard.general
        pas.string = self.addressLabel.text
        HUD.flash(.label("Copy Success"), delay:1)
    }
    
    @objc func buyNeoClick(){
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let buyWithFiat = UIAlertAction(title: "With Fiat", style: .default) { _ in
            Controller().openDappBrowserV2(url: URL(string: "https://buy.o3.network/?a=" + (Authenticated.wallet?.address)!)!)
        }
        actionSheet.addAction(buyWithFiat)
        
        let buyWithCrypto = UIAlertAction(title: "With Crypto", style: .default) { _ in
            Controller().openDappBrowserV2(url: URL(string: "https://swap.o3.app")!)
        }
        actionSheet.addAction(buyWithCrypto)
        
        let cancel = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { _ in
            
        }
        actionSheet.addAction(cancel)
        actionSheet.popoverPresentationController?.sourceView = self.buyButton
        present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func sendClick(_ sender: UIButton) {
        self.sendTapped()
    }
    
    @IBAction func receiveClick(_ sender: UIButton) {
        let modal = UIStoryboard(name: "Account", bundle: nil).instantiateViewController(withIdentifier: "MyAddressNavigationController")
        
        let transitionDelegate = DeckTransitioningDelegate()
        modal.transitioningDelegate = transitionDelegate
        modal.modalPresentationStyle = .custom
        present(modal, animated: true, completion: nil)
    }
}

extension NewHomeVC: JXPagingViewDelegate {
    
    func tableHeaderViewHeight(in pagingView: JXPagingView) -> Int {
        return tableHeaderViewHeight
    }
    
    func tableHeaderView(in pagingView: JXPagingView) -> UIView {
        return userHeaderView
    }
    
    func heightForPinSectionHeader(in pagingView: JXPagingView) -> Int {
        return headerInSectionHeight
    }
    
    func viewForPinSectionHeader(in pagingView: JXPagingView) -> UIView {
        return segmentedView
    }
    
    func numberOfLists(in pagingView: JXPagingView) -> Int {
        return titles.count
    }
    
    func pagingView(_ pagingView: JXPagingView, initListAtIndex index: Int) -> JXPagingViewListViewDelegate {
        let list = ListViewController()
        list.title = titles[index]
        list.typeString = titles[index]
        list.isNeedHeader = isNeedHeader
        list.isNeedFooter = isNeedFooter
        
        list.portfolio = portfolio
        list.homeviewModel = homeviewModel
        list.coinbaseAssets = coinbaseAssets
        list.walletAssets = walletAssets
        
        return list
    }
    
}

extension NewHomeVC: JXSegmentedViewDelegate {
    func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int) {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = (index == 0)
    }
}

extension NewHomeVC: JXPagingMainTableViewGestureDelegate {
    func mainTableViewGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        //禁止segmentedView左右滑动的时候，上下和左右都可以滚动
        if otherGestureRecognizer == segmentedView.collectionView.panGestureRecognizer {
            return false
        }
        return gestureRecognizer.isKind(of: UIPanGestureRecognizer.self) && otherGestureRecognizer.isKind(of: UIPanGestureRecognizer.self)
    }
}

extension NewHomeVC: QRScanDelegate {
    func qrScanned(data: String) {
        //if there is more type of string we have to check it here
        //        if data.hasPrefix("neo") {
        DispatchQueue.main.async {
            self.startSendRequest   (qrData: data)
        }
        //        }
        //        else if (URL(string: data) != nil) {
        //            //dont present from top
        //            let nav = UIStoryboard(name: "dAppBrowser", bundle: nil).instantiateInitialViewController() as? UINavigationController
        //            if let vc = nav!.viewControllers.first as?
        //                dAppBrowserV2ViewController {
        //                let viewModel = dAppBrowserViewModel()
        //                viewModel.url = URL(string: data)
        //                vc.viewModel = viewModel
        //                DispatchQueue.main.async {
        //                    self.present(nav!, animated: true)
        //                }
        //            }
        //        }
        //        else {
        //            DispatchQueue.main.async {
        //                self.startSendRequest()
        //            }
        //        }
    }
    
    func startSendRequest(qrData: String? = nil) {
        DispatchQueue.main.async {
            guard let sendModal = UIStoryboard(name: "Send", bundle: nil).instantiateViewController(withIdentifier: "sendWhereTableViewController") as? SendWhereTableViewController else {
                fatalError("Presenting improper modal controller")
            }
            sendModal.incomingQRData = qrData
            let nav = NoHairlineNavigationController(rootViewController: sendModal)
            nav.navigationBar.prefersLargeTitles = false
            nav.navigationItem.largeTitleDisplayMode = .never
            sendModal.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-x"), style: .plain, target: self, action: #selector(self.dismissTapped))
            let transitionDelegate = DeckTransitioningDelegate()
            nav.transitioningDelegate = transitionDelegate
            nav.modalPresentationStyle = .custom
            self.present(nav, animated: true, completion: nil)
        }
    }
}

