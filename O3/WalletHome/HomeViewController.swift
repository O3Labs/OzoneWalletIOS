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
            homeviewModel.currentIndex = portfolioIndex
            walletHeaderCollectionView.reloadData()
            self.walletHeaderCollectionView.scrollToItem(at: IndexPath(row: portfolioIndex, section: 0), at: .left, animated: false)
            getBalance()
        }
    }

    @objc func getBalance() {
        homeviewModel.reloadBalances()
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

    func updateWithBalanceData(_ assets: [PortfolioAsset]) {
        self.displayedAssets = assets
        DispatchQueue.main.async {
            self.assetsTable.delegate = self
            self.assetsTable.dataSource = self
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
            self.startSendRequest   (qrData: data)
            }
        } else if (URL(string: data) != nil) {
            //dont present from top
            let nav = UIStoryboard(name: "dAppBrowser", bundle: nil).instantiateInitialViewController() as? UINavigationController
            if let vc = nav!.viewControllers.first as?
                dAppBrowserV2ViewController {
                let viewModel = dAppBrowserViewModel()
                viewModel.url = URL(string: data)
                vc.viewModel = viewModel
                DispatchQueue.main.async {
                    self.present(nav!, animated: true)
                }
            }
        } else {
            DispatchQueue.main.async {
                self.startSendRequest()
            }
        }
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
