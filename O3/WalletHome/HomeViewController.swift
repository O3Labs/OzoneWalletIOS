//
//  HomeViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 9/11/17.
//  Copyright © 2017 drei. All rights reserved.
//

import Foundation
import UIKit
import ScrollableGraphView
import PKHUD
import SwiftTheme
import DeckTransition

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GraphPanDelegate, ScrollableGraphViewDataSource, HomeViewModelDelegate, EmptyPortfolioDelegate, AddressAddDelegate {

    @IBOutlet weak var walletHeaderCollectionView: UICollectionView!
    @IBOutlet weak var graphLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var assetsTable: UITableView!
    @IBOutlet weak var fiveMinButton: UIButton!
    @IBOutlet weak var fifteenMinButton: UIButton!
    @IBOutlet weak var thirtyMinButton: UIButton!
    @IBOutlet weak var sixtyMinButton: UIButton!
    @IBOutlet weak var oneDayButton: UIButton!
    @IBOutlet weak var allButton: UIButton!
    @IBOutlet weak var graphViewContainer: UIView!
    @IBOutlet var activatedLineLeftConstraint: NSLayoutConstraint?
    @IBOutlet weak var activatedLine: UIView!
    var emptyGraphView: UIView?
    
    var group: DispatchGroup?
    var activatedLineCenterXAnchor: NSLayoutConstraint?
    var graphView: ScrollableGraphView!
    var portfolio: PortfolioValue?
    var activatedIndex = 1
    var panView: GraphPanView!
    var selectedAsset = "neo"
    var firstTimeGraphLoad = true
    var firstTimeViewLoad = true
    var homeviewModel: HomeViewModel!
    var selectedPrice: PriceData?
    var displayedAssets = [O3WalletNativeAsset]()
    var watchAddresses = [NEP6.Account]()
    
    var coinbaseAssets = [PortfolioAsset]()
    
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?

    func addThemedElements() {
        applyNavBarTheme()
        graphLoadingIndicator.theme_activityIndicatorViewStyle = O3Theme.activityIndicatorColorPicker
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
        assetsTable.theme_separatorColor = O3Theme.tableSeparatorColorPicker
        walletHeaderCollectionView.theme_backgroundColor = O3Theme.backgroundColorPicker
        let themedTransparentButtons = [fiveMinButton, fifteenMinButton, thirtyMinButton, sixtyMinButton, oneDayButton, allButton]
        for button in themedTransparentButtons {
            button?.theme_backgroundColor = O3Theme.backgroundColorPicker
            button?.theme_setTitleColor(O3Theme.primaryColorPicker, forState: UIControl.State())
        }
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
            walletHeaderCollectionView.reloadData()
            homeviewModel.currentIndex = portfolioIndex
            self.walletHeaderCollectionView.scrollToItem(at: IndexPath(row: portfolioIndex, section: 0), at: .left, animated: false)
            getBalance()
        }
    }

    @objc func getBalance() {
        homeviewModel.reloadBalances()
    }
    
    func loadInbox() {
        let pubkey = O3KeychainManager.getO3PubKey()!
        O3APIClient(network: AppState.network).getMessages(pubKey: pubkey) { result in
            if UserDefaultsManager.needsInboxBadge == true {
                DispatchQueue.main.async { self.navigationItem.leftBarButtonItem!.setBadge(text: " ") }
            }
            switch result {
            case .failure(_) :
                return
            case .success(let messages):
                if messages.isEmpty == false {
                    if messages.first!.timestamp > UserDefaultsManager.lastInboxOpen {
                        DispatchQueue.main.async {
                            self.navigationItem.leftBarButtonItem!.setBadge(text: " ")
                            UserDefaultsManager.needsInboxBadge = true
                        }
                    }
                }
            }
        }
    }


    @objc func updateGraphAppearance(_ sender: Any) {
        DispatchQueue.main.async {
            
            let needEmptyView = self.graphViewContainer.subviews.last ?? UIView() == self.emptyGraphView ?? UIView()
            
            self.graphView.removeFromSuperview()
            self.panView.removeFromSuperview()
            self.setupGraphView()
            self.getBalance()
            if needEmptyView {
                self.graphViewContainer.bringSubviewToFront(self.emptyGraphView!)
            }
        }
    }

    func setupGraphView() {
        graphView = ScrollableGraphView.ozoneTheme(frame: graphViewContainer.bounds, dataSource: self)
        graphViewContainer.embed(graphView)

        panView = GraphPanView(frame: graphViewContainer.bounds)
        panView.delegate = self
        graphViewContainer.embed(panView)
    }

    func panDataIndexUpdated(index: Int, timeLabel: UILabel) {
        DispatchQueue.main.async {
            self.selectedPrice = self.portfolio?.data.reversed()[index]
            self.walletHeaderCollectionView.reloadData()

            let posixString = self.portfolio?.data.reversed()[index].time ?? ""
            timeLabel.text = posixString.intervaledDateString(self.homeviewModel.selectedInterval)
            timeLabel.sizeToFit()
        }
    }

    func panEnded() {
        selectedPrice = self.portfolio?.data.first
        DispatchQueue.main.async { self.walletHeaderCollectionView.reloadData() }
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.resetPage(_:)), name: Notification.Name(rawValue: "NEP6Updated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.getBalance), name: Notification.Name("ChangedNetwork"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.getBalance), name: Notification.Name("ChangedReferenceCurrency"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.jumpToPortfolio(_:)), name: Notification.Name("jumpToPortfolio"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.removeObservers), name: Notification.Name("loggedOut"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateGraphAppearance(_:)), name: NSNotification.Name(rawValue: ThemeUpdateNotification), object: nil)
    }

    @objc func removeObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.removeObservers), name: Notification.Name("loggedOut"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ChangedNetwork"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("jumpToPortfolio"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ChangedReferenceCurrency"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: ThemeUpdateNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "NEP6Updated"), object: nil)
    }

    deinit {
        removeObservers()
    }
    
    func roundIntervalLine() {
        activatedLine.clipsToBounds = false
        activatedLine.layer.cornerRadius = 3
        activatedLine.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    @objc func resetPage(_ sender: Any?) {
        DispatchQueue.main.async {
            self.walletHeaderCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: false)
        }
        watchAddresses = loadWatchAddresses()
        homeviewModel = HomeViewModel(delegate: self)
    }

    override func viewDidLoad() {
        //Force update users to NEP6
        
        
        watchAddresses = loadWatchAddresses()
        setLocalizedStrings()
        ThemeManager.setTheme(index: UserDefaultsManager.themeIndex)
        addThemedElements()
        addObservers()
        roundIntervalLine()
        activatedLineCenterXAnchor = activatedLine.centerXAnchor.constraint(equalTo: fifteenMinButton.centerXAnchor, constant: 0)
        activatedLineCenterXAnchor?.isActive = true
        homeviewModel = HomeViewModel(delegate: self)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "support"), style: .plain, target: self, action: #selector(leftBarButtonTapped))
        loadInbox()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_scan"), style: .plain, target: self, action: #selector(rightBarButtonTapped))
        self.navigationItem.leftBarButtonItem?.tintColor = Theme.light.primaryColor
        self.navigationItem.rightBarButtonItem?.tintColor = Theme.light.primaryColor

        let titleViewButton = UIButton(type: .system)
        titleViewButton.theme_setTitleColor(O3Theme.titleColorPicker, forState: UIControl.State())
        titleViewButton.titleLabel?.font = UIFont(name: "Avenir-Heavy", size: 16)!
        titleViewButton.setTitle("Portfolio", for: .normal)
        titleViewButton.semanticContentAttribute = .forceRightToLeft
        titleViewButton.setImage(UIImage(named: "ic_chevron_down"), for: UIControl.State())
        
        titleViewButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        titleViewButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -20)
        // Create action listener
        titleViewButton.addTarget(self, action: #selector(showMultiWalletDisplay), for: .touchUpInside)
        navigationItem.titleView = titleViewButton

        walletHeaderCollectionView.delegate = self
        walletHeaderCollectionView.dataSource = self
        //avoid table rendering by setting the delegate & datasource to nil
        assetsTable.delegate = nil
        assetsTable.dataSource = nil
        assetsTable.tableFooterView = UIView(frame: .zero)

        //control the size of the graph area here
        self.assetsTable.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height * 0.45)
        setupGraphView()
        showDisclaimer()
        super.viewDidLoad()
        loadCoinbase()
    
    }
    
    @objc func showMultiWalletDisplay() {
        Controller().openPortfolioSelector()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !firstTimeViewLoad {
            self.getBalance()
            if UserDefaultsManager.needsInboxBadge {
                self.navigationItem.leftBarButtonItem!.setBadge(text: " ")
            } else {
                self.navigationItem.leftBarButtonItem!.setBadge(text: "")
            }
        }
        firstTimeViewLoad = false
    }

    func showLoadingIndicator() {
        DispatchQueue.main.async {
            self.graphLoadingIndicator.layer.zPosition = 1
            self.graphLoadingIndicator.startAnimating()
        }
    }

    func hideLoadingIndicator() {
        DispatchQueue.main.async {
            self.graphLoadingIndicator.stopAnimating()
        }
    }

    func updateWithBalanceData(_ assets: [O3WalletNativeAsset]) {
        self.displayedAssets = assets
        DispatchQueue.main.async {
            self.assetsTable.delegate = self
            self.assetsTable.dataSource = self
            self.assetsTable.reloadData()
        }
    }

    func updateWithPortfolioData(_ portfolio: PortfolioValue) {
        DispatchQueue.main.async {
            self.portfolio = portfolio
            self.selectedPrice = portfolio.data.first
            self.walletHeaderCollectionView.reloadData()
            self.assetsTable.reloadData()
            if portfolio.data.first?.average == 0.0 &&
                portfolio.data.last?.average == 0.0 &&
                self.homeviewModel.currentIndex == 0 {
                self.setEmptyGraphView()
            } else {
                self.emptyGraphView?.isHidden = true
            }
            self.graphView.reload()
        }

        //A hack otherwise graph wont appear
        if self.firstTimeGraphLoad {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.graphView.reload()
                self.firstTimeGraphLoad = false
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
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
        guard let cell = assetsTable.dequeueReusableCell(withIdentifier: "portfolioAssetCell") as? PortfolioAssetCell else {
            fatalError("Undefined Table Cell Behavior")
        }
        if indexPath.section == 1 {
            let asset = self.displayedAssets[indexPath.row]
            guard let latestPrice = portfolio?.price[asset.symbol],
                let firstPrice = portfolio?.firstPrice[asset.symbol] else {
                    cell.data = PortfolioAssetCell.Data(assetName: asset.symbol,
                                                        amount: Double(truncating: asset.value as NSNumber),
                                                        referenceCurrency: (homeviewModel?.referenceCurrency)!,
                                                        latestPrice: PriceData(average: 0, averageBTC: 0, time: "24h"),
                                                        firstPrice: PriceData(average: 0, averageBTC: 0, time: "24h"))
                    return cell
            }
            
            cell.data = PortfolioAssetCell.Data(assetName: asset.symbol,
                                                amount: Double(truncating: asset.value as NSNumber),
                                                referenceCurrency: (homeviewModel?.referenceCurrency)!,
                                                latestPrice: latestPrice,
                                                firstPrice: firstPrice)
            cell.selectionStyle = .none
            return cell
        } else {
            let asset = self.coinbaseAssets[indexPath.row]
            cell.data = PortfolioAssetCell.Data(assetName: asset.symbol,
                                                amount: Double((asset as! CoinbaseClient.CoinbasePortfolioAccount).balance) ?? 0,
                                                referenceCurrency: (homeviewModel?.referenceCurrency)!,
                                                latestPrice: PriceData(average: 0, averageBTC: 0, time: "24h"),
                                                firstPrice: PriceData(average: 0, averageBTC: 0, time: "24h"))
            cell.selectionStyle = .none
            return cell
        }
        
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            return
        }

        let asset = self.displayedAssets[indexPath.row]
        var chain = "neo"
        if asset.assetType == O3WalletNativeAsset.AssetType.ontologyAsset {
            chain = "ont"
        }
        let url = URL(string: String(format: "https://public.o3.network/%@/assets/%@?address=%@", chain, asset.symbol, Authenticated.wallet!.address))
        DispatchQueue.main.async {
            Controller().openDappBrowserV2(url: url!, assetSymbol: asset.symbol)
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
        return self.displayedAssets.count
    }
    
    func loadCoinbase() {
        CoinbaseClient.shared.getAllPortfolioAssets { result in
            switch result {
            case .failure(_):
                return
            case .success(let response):
                DispatchQueue.main.async {
                    self.coinbaseAssets = response
                    self.assetsTable.reloadData()
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if AppState.dismissBackupNotification() {
                return 60.0
            } else {
                return 116.0
            }
            
        }
        return 60.0
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 {
            return true
        }

        return true
    }

    @IBAction func tappedIntervalButton(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.view.needsUpdateConstraints()
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: {
                self.activatedLineCenterXAnchor?.isActive = false
                self.activatedLineCenterXAnchor = self.activatedLine.centerXAnchor.constraint(equalTo: sender.centerXAnchor, constant: 0)
                self.activatedLineCenterXAnchor?.isActive = true
                self.view.layoutIfNeeded()
            }, completion: { (_) in
                self.homeviewModel?.setInterval(PriceInterval(rawValue: sender.tag.tagToPriceIntervalString())!)
            })
        }
    }

    // MARK: - Graph delegate
    func value(forPlot plot: Plot, atIndex pointIndex: Int) -> Double {
        if pointIndex > portfolio!.data.count {
            return 0
        }
        return homeviewModel?.referenceCurrency == .btc ? portfolio!.data.reversed()[pointIndex].averageBTC : portfolio!.data.reversed()[pointIndex].average
    }

    func label(atIndex pointIndex: Int) -> String {
        return ""//String(format:"%@",portfolio!.data[pointIndex].time)
    }

    func numberOfPoints() -> Int {
        if portfolio == nil {
            return 0
        }
        return portfolio!.data.count
    }

    func setLocalizedStrings() {
        
        self.navigationController?.navigationBar.topItem?.title = PortfolioStrings.portfolio
        fiveMinButton.setTitle(PortfolioStrings.sixHourInterval, for: UIControl.State())
        fifteenMinButton.setTitle(PortfolioStrings.oneDayInterval, for: UIControl.State())
        thirtyMinButton.setTitle(PortfolioStrings.oneWeekInterval, for: UIControl.State())
        sixtyMinButton.setTitle(PortfolioStrings.oneMonthInterval, for: UIControl.State())
        oneDayButton.setTitle(PortfolioStrings.threeMonthInterval, for: UIControl.State())
        allButton.setTitle(PortfolioStrings.allInterval, for: UIControl.State())
    }
    
    func showDisclaimer() {
        if (UserDefaultsManager.hasAgreedAnalytics == false) {
            let nav = UIStoryboard(name: "Disclaimers", bundle: nil).instantiateViewController(withIdentifier: "analyticsWarningNav")
            self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: nav)
            nav.modalPresentationStyle = .custom
            nav.transitioningDelegate = self.halfModalTransitioningDelegate
            self.present(nav, animated: true, completion: nil)
        }
    }
    
    @objc func leftBarButtonTapped() {
        let inboxController = UIStoryboard(name: "Inbox", bundle: nil).instantiateInitialViewController()!
        self.present(inboxController, animated: true)
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
        self.present(nav, animated: true, completion: nil)
    }
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, WalletHeaderCellDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var unfiltered = NEP6.getFromFileSystem()!.getAccounts()
        unfiltered = unfiltered.filter { UserDefaultsManager.untrackedWatchAddr.contains($0.address) == false}
        return unfiltered.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "walletHeaderCollectionCell", for: indexPath) as? WalletHeaderCollectionCell else {
            fatalError("Undefined collection view behavior")
        }
        cell.delegate = self

        var account: NEP6.Account? = nil
        var type: WalletHeaderCollectionCell.HeaderType
        var unfiltered = NEP6.getFromFileSystem()!.getAccounts()
        unfiltered = unfiltered.filter { UserDefaultsManager.untrackedWatchAddr.contains($0.address) == false}
        
        if indexPath.row == 0 {
            type = WalletHeaderCollectionCell.HeaderType.combined
        } else {
            type = WalletHeaderCollectionCell.HeaderType.account
            account = unfiltered[indexPath.row - 1]
        }
        
        
        if indexPath.row == unfiltered.count {
            cell.rightButton.isHidden = true
        } else {
            cell.rightButton.isHidden = false
        }
        
        var data =  WalletHeaderCollectionCell.Data (
            type: type,
            account: account,
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
    
    func setEmptyGraphView() {
        if emptyGraphView == nil {
            emptyGraphView = EmptyPortfolioView(frame: graphViewContainer.bounds).loadNib()
            (emptyGraphView as! EmptyPortfolioView).emptyDelegate = self
            graphViewContainer.embed(emptyGraphView!)
            graphViewContainer.bringSubviewToFront(emptyGraphView!)
        }

        (emptyGraphView as! EmptyPortfolioView).emptyLabel.text = PortfolioStrings.emptyBalance
        (emptyGraphView as! EmptyPortfolioView).rightActionButton.setTitle(PortfolioStrings.depositTokens, for: UIControl.State())
        (emptyGraphView as! EmptyPortfolioView).leftActionButton.setTitle("Buy NEO", for: UIControl.State())
        (emptyGraphView as! EmptyPortfolioView).leftActionButton.isHidden = false
        (emptyGraphView as! EmptyPortfolioView).rightActionButton.isHidden = false
        (emptyGraphView as! EmptyPortfolioView).dividerLine.isHidden = false
    
        emptyGraphView?.isHidden = false
    }
    
    func addressAdded(_ address: String, nickName: String) {
        let context = UIApplication.appDelegate.persistentContainer.viewContext
        let watchAddress = WatchAddress(context: context)
        watchAddress.address = address
        watchAddress.nickName = nickName
        UIApplication.appDelegate.saveContext()
        NotificationCenter.default.post(name: Notification.Name("UpdatedWatchOnlyAddress"), object: nil)
    }
    
    func displayEnableMultiWallet() {
        if NEP6.getFromFileSystem() == nil {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "activateMultiWalletTableViewController") as? ActivateMultiWalletTableViewController {
                let vcWithNav = (UINavigationController(rootViewController: vc))
                self.present(vcWithNav, animated: true, completion: {})
            }
        } else {
            let vc = UIStoryboard(name: "AddNewMultiWallet", bundle: nil).instantiateInitialViewController()!
            self.present(vc, animated: true, completion: {})
        }
    }
    
    func displayDepositTokens() {
        let modal = UIStoryboard(name: "Account", bundle: nil).instantiateViewController(withIdentifier: "MyAddressNavigationController")
        let transitionDelegate = DeckTransitioningDelegate()
        modal.transitioningDelegate = transitionDelegate
        modal.modalPresentationStyle = .custom
        present(modal, animated: true, completion: nil)
    }
    
    func buyNeoButtonTapped() {
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
        present(actionSheet, animated: true, completion: nil)
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

extension HomeViewController: PortfolioNotificationTableViewCellDelegate {

    func didDismiss() {
        DispatchQueue.main.async {
            AppState.setDismissBackupNotification(dismiss: true)
            self.assetsTable.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        }
    }
}

extension HomeViewController: QRScanDelegate {
    func qrScanned(data: String) {
        //if there is more type of string we have to check it here
        if data.hasPrefix("neo") {
            DispatchQueue.main.async {
                //Controller().openSend(to:)
            }
        } else if (URL(string: data) != nil) {
            Controller().openDappBrowserV2(url: URL(string: data)!)
        } else {
            //Controller().openSend()
        }
    }
}
