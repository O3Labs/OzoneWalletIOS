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
    
    @IBOutlet weak var totalNumberLabel: UILabel!
    @IBOutlet weak var watchButton: UIButton!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var sendAndReceiveBgView: UIView!
    
    @IBOutlet weak var contentView: UIView!
    
    lazy var pagingView: JXPagingView = preferredPagingView()
    lazy var userHeaderView: PagingViewTableHeaderView = preferredTableHeaderView()
    let dataSource: JXSegmentedTitleDataSource = JXSegmentedTitleDataSource()
    lazy var segmentedView: JXSegmentedView = JXSegmentedView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: CGFloat(headerInSectionHeight)))
    var titles = ["Wallets"]
    var tableHeaderViewHeight: Int = 200
    var headerInSectionHeight: Int = 50
    var isNeedHeader = false
    var isNeedFooter = false
    
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
    
    //同步
    var claims: Claimable?
    var isClaimingNeo: Bool = false
    var isClaimingOnt: Bool = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isTranslucent = false
        
        addObservers()

        homeviewModel = HomeViewModel(delegate: self)
        
        watchAddresses = loadWatchAddresses()

        walletNameSelectLabel.text = wallets.first {$0.isDefault}!.label
        addressLabel.text = wallets.first {$0.isDefault}!.address
        loadWalletPortfolios()
        sumForCombined()

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
        scanButton.addTarget(self, action: #selector(rightBarButtonTapped), for: .touchUpInside)

        let button:UIButton = UIButton(frame: CGRect.init(x: UIScreen.main.bounds.size.width-100, y: UIScreen.main.bounds.size.height-110-44, width: 99.0, height: 110.0))
        button.setImage(UIImage.init(named: "home_buyNeo"), for: .normal)
        button.addTarget(self, action: #selector(buyNeoClick), for: .touchUpInside)
        self.view.addSubview(button)
        self.view.bringSubviewToFront(button)
        
       
        
        // shadowCode
        sendAndReceiveBgView.layer.shadowColor = UIColor.blue.cgColor
        sendAndReceiveBgView.layer.shadowRadius = 25
        sendAndReceiveBgView.layer.shadowOpacity = 0.2
        sendAndReceiveBgView.layer.shadowOffset = CGSize.init(width: 0, height: 10)
    }
    @objc func showMultiWalletDisplay() {
        Controller().openPortfolioSelector()
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
            homeviewModel.currentIndex = portfolioIndex
            getBalance()
            if portfolioIndex == 0{
                walletNameSelectLabel.text = "Total"
                addressLabel.text = wallets.first {$0.isDefault}!.address
                sumForCombined()
                
                let formatter = NumberFormatter()
                formatter.currencySymbol = combinedAccountValue?.currency
                formatter.locale = Locale(identifier: "en_US_POSIX")
                let number = formatter.number(from: combinedAccountValue?.total ?? "0")
                let fiat = Fiat(amount: number?.floatValue ?? 0.0)
                totalNumberLabel.text = fiat.formattedString()
                loadClaimableGAS(address: wallets.first {$0.isDefault}!.address)
                loadClaimableOng(address: wallets.first {$0.isDefault}!.address)
                
            }else{
                walletNameSelectLabel.text = wallets[portfolioIndex - 1].label
                addressLabel.text = wallets[portfolioIndex - 1].address
                let indexPath = IndexPath(row: portfolioIndex - 1, section: walletSectionNum)
                totalNumberLabel.text = accountValues[indexPath]?.total
                
                loadClaimableGAS(address: wallets[portfolioIndex - 1].address)
                loadClaimableOng(address: wallets[portfolioIndex - 1].address)
            }
        }
        
    }
    
    //MARK:- Observers
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.jumpToPortfolio(_:)), name: Notification.Name("jumpToPortfolio"), object: nil)
    }

    @objc func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("jumpToPortfolio"), object: nil)
    }

    deinit {
        removeObservers()
    }
    
    @objc func getBalance() {
        homeviewModel.reloadBalances()
    }
    //计算综合
    func sumForCombined() {
        var accountValue: AccountValue?
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for key in accountValues.keys {
            if watchAddrs[key] != nil && UserDefaultsManager.untrackedWatchAddr.contains(watchAddrs[key]!.address) {
                continue
            }
            if accountValue == nil {
                accountValue = accountValues[key]
            } else {
                let currentNumber = (formatter.number(from: accountValue!.total))!
                let toAddNumber = (formatter.number(from: accountValues[key]!.total))!
                let total = currentNumber.floatValue + toAddNumber.floatValue
                accountValue = AccountValue(total: formatter.string(from: NSNumber(value: total)) ?? "0", currency: accountValues[key]!.currency)
                
            }
        }
        combinedAccountValue = accountValue

    }
    
    func loadWalletPortfolios() {
        for i in 0..<self.wallets.count {
            let indexPath = IndexPath(row: i, section: walletSectionNum)
            if self.getCachedPortfolioValue(for: self.wallets[i].address, indexPath: indexPath) == false {
                DispatchQueue.global().async {
                    self.group.enter()
                    O3APIClient(network: AppState.network).getAccountState(address: self.wallets[i].address) { result in
                        switch result {
                        case .failure:
                            self.group.leave()
                            return
                        case .success(let accountState):
                            self.getPortfolioForAccountState(indexPath: indexPath, accountState: accountState, address: self.wallets[i].address)
                        }
                    }
                }
            }
        }
    }
    func getPortfolioForAccountState(indexPath: IndexPath, accountState: AccountState, address: String) {
        O3Client().getAccountValue(accountState.assets + accountState.nep5Tokens + accountState.ontology) { result in
            switch result {
            case .failure:
                self.group.leave()
                return
            case .success(let accountValue):
                O3Cache.setCachedPortfolioValue(for: address, portfolioValue: accountValue)
                self.accountValues[indexPath] = accountValue
                DispatchQueue.main.async {
                    if address == self.wallets.first(where: {$0.isDefault})!.address{
                        self.totalNumberLabel.text = accountValue.total
                    }
                }
                self.group.leave()
            }
        }
    }

    
    func getCachedPortfolioValue(for address: String, indexPath: IndexPath) -> Bool {
        let accountValue = O3Cache.getCachedPortfolioValue(for: address)
        if accountValue == nil {
            return false
        } else {
            DispatchQueue.main.async {
                self.accountValues[indexPath] = accountValue!
                if address == self.wallets.first(where: {$0.isDefault})!.address{
                    self.totalNumberLabel.text = accountValue?.total
                }
            }
            return true
        }
    }
   
    
    
    func updateWithPortfolioData(_ portfolio: PortfolioValue) {
        DispatchQueue.main.async {
            if self.coinbaseAssets.count>0{
                self.titles = ["Wallets", "Connected Accounts"]
            }else{
                self.titles = ["Wallets"]
            }
            self.dataSource.titles = self.titles
            self.portfolio = portfolio
            self.selectedPrice = portfolio.data.first
            self.segmentedView.reloadData()
            self.pagingView.reloadData()

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
        self.present(nav, animated: true, completion: nil)
    }
    
    
    //MARK:- HomeViewModelDelegate
      func updateWithBalanceData(_ assets: [PortfolioAsset]) {
          self.displayedAssets = assets
          DispatchQueue.main.async {
              
          }
      }
      
      
      
      func showLoadingIndicator() {
          
      }
      
      func hideLoadingIndicator() {
          
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
