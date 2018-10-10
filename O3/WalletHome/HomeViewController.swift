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
import Channel
import PKHUD
import SwiftTheme

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GraphPanDelegate, ScrollableGraphViewDataSource, HomeViewModelDelegate {
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
    var displayedAssets = [TransferableAsset]()

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

    func loadWatchAddresses() -> [WatchAddress] {
        do {
            let watchAddresses: [WatchAddress] = try
                UIApplication.appDelegate.persistentContainer.viewContext.fetch(WatchAddress.fetchRequest())
            return watchAddresses
        } catch {
            return []
        }
    }

    @objc func getBalance() {
        homeviewModel.reloadBalances()
    }

    @objc func updateGraphAppearance(_ sender: Any) {
        DispatchQueue.main.async {
            self.graphView.removeFromSuperview()
            self.panView.removeFromSuperview()
            self.setupGraphView()
            self.getBalance()
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
        NotificationCenter.default.addObserver(self, selector: #selector(self.getBalance), name: Notification.Name("ChangedNetwork"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.getBalance), name: Notification.Name("ChangedReferenceCurrency"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.getBalance), name: Notification.Name("UpdatedWatchOnlyAddress"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.removeObservers), name: Notification.Name("loggedOut"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateGraphAppearance(_:)), name: NSNotification.Name(rawValue: ThemeUpdateNotification), object: nil)
    }

    @objc func removeObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.removeObservers), name: Notification.Name("loggedOut"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ChangedNetwork"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("UpdatedWatchOnlyAddress"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ChangedReferenceCurrency"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: ThemeUpdateNotification), object: nil)
    }

    deinit {
        removeObservers()
    }

    override func viewDidLoad() {
        setLocalizedStrings()
        ThemeManager.setTheme(index: UserDefaultsManager.themeIndex)
        addThemedElements()
        addObservers()
        activatedLineCenterXAnchor = activatedLine.centerXAnchor.constraint(equalTo: fifteenMinButton.centerXAnchor, constant: 0)
        activatedLineCenterXAnchor?.isActive = true
        homeviewModel = HomeViewModel(delegate: self)

        if UserDefaults.standard.string(forKey: "subscribedAddress") != Authenticated.account?.address {
            Channel.shared().unsubscribe(fromTopic: "*") {
                Channel.shared().subscribe(toTopic: (Authenticated.account?.address)!)
                UserDefaults.standard.set(Authenticated.account?.address, forKey: "subscribedAddress")
                UserDefaults.standard.synchronize()
            }
        }

        walletHeaderCollectionView.delegate = self
        walletHeaderCollectionView.dataSource = self
        //avoid table rendering by setting the delegate & datasource to nil
        assetsTable.delegate = nil
        assetsTable.dataSource = nil
        assetsTable.tableFooterView = UIView(frame: .zero)

        //control the size of the graph area here
        self.assetsTable.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height * 0.45)
        setupGraphView()

        super.viewDidLoad()

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !firstTimeViewLoad {
            self.getBalance()
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

    func updateWithBalanceData(_ assets: [TransferableAsset]) {
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

            guard let cell = assetsTable.dequeueReusableCell(withIdentifier: "notification-cell") as? PortfolioNotificationTableViewCell else {
                fatalError("Undefined Table Cell Behavior")
            }
            cell.selectionStyle = .none
            cell.delegate = self
            return cell
        }
        guard let cell = assetsTable.dequeueReusableCell(withIdentifier: "portfolioAssetCell") as? PortfolioAssetCell else {
            fatalError("Undefined Table Cell Behavior")
        }
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
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToAssetDetail" {
            guard let dest = segue.destination as? AssetDetailViewController else {
                fatalError("Undefined behavior during segue")
            }
            dest.selectedAsset = self.selectedAsset
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            return
        }

        let asset = homeviewModel.getTransferableAssets()[indexPath.row]
        var chain = "neo"
        if asset.assetType == TransferableAsset.AssetType.ontologyAsset {
            chain = "ont"
        }
        let url = URL(string: String(format: "https://public.o3.network/%@/assets/%@?address=%@", chain, asset.symbol, Authenticated.account!.address))
        DispatchQueue.main.async {
            Controller().openDappBrowser(url: url!, modal: true, assetSymbol: asset.symbol)
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        //news
        //assets
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            //check balance to show the banner
            if O3Cache.neo().value <= 0 && O3Cache.gas().value <= 0 {
                return 0
            }
            return AppState.dismissPortfolioNotification() == true ? 0 : 1
        }
        return self.displayedAssets.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 160.0
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
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.navigationBar.topItem?.title = PortfolioStrings.portfolio
        fiveMinButton.setTitle(PortfolioStrings.sixHourInterval, for: UIControl.State())
        fifteenMinButton.setTitle(PortfolioStrings.oneDayInterval, for: UIControl.State())
        thirtyMinButton.setTitle(PortfolioStrings.oneWeekInterval, for: UIControl.State())
        sixtyMinButton.setTitle(PortfolioStrings.oneMonthInterval, for: UIControl.State())
        oneDayButton.setTitle(PortfolioStrings.threeMonthInterval, for: UIControl.State())
        allButton.setTitle(PortfolioStrings.allInterval, for: UIControl.State())
    }
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, WalletHeaderCellDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "walletHeaderCollectionCell", for: indexPath) as? WalletHeaderCollectionCell else {
            fatalError("Undefined collection view behavior")
        }
        cell.delegate = self
        var portfolioType = PortfolioType.readOnly
        switch indexPath.row {
        case 0:
            portfolioType = .readOnly
        case 1:
            portfolioType = .writable
        case 2:
            portfolioType = .readOnlyAndWritable
        default: fatalError("Undefined wallet header cell")
        }

        var data = WalletHeaderCollectionCell.Data (
            portfolioType: portfolioType,
            index: indexPath.row,
            latestPrice: PriceData(average: 0, averageBTC: 0, time: "24h"),
            previousPrice: PriceData(average: 0, averageBTC: 0, time: "24h"),
            referenceCurrency: (homeviewModel?.referenceCurrency)!,
            selectedInterval: (homeviewModel?.selectedInterval)!
        )

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
            self.homeviewModel?.setPortfolioType(self.indexToPortfolioType(visibleIndexPath!.row))
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch (homeviewModel?.referenceCurrency)! {
        case .btc:
            homeviewModel?.setReferenceCurrency(UserDefaultsManager.referenceFiatCurrency)
        default:
            homeviewModel?.setReferenceCurrency(.btc)
        }

        DispatchQueue.main.async {
            collectionView.reloadData()
            self.assetsTable.reloadData()
            self.graphView.reload()
        }
    }

    func indexToPortfolioType(_ index: Int) -> PortfolioType {
        switch index {
        case 0:
            return .writable
        case 1:
            return .readOnly
        case 2:
            return .readOnlyAndWritable
        default:
            fatalError("Invalid Portfolio Index")
        }
    }

    func didTapLeft(index: Int, portfolioType: PortfolioType) {
        DispatchQueue.main.async {
            self.walletHeaderCollectionView.scrollToItem(at: IndexPath(row: index - 1, section: 0), at: .left, animated: true)
            self.homeviewModel?.setPortfolioType(self.indexToPortfolioType(index - 1))
        }
    }

    func didTapRight(index: Int, portfolioType: PortfolioType) {
        DispatchQueue.main.async {
            self.walletHeaderCollectionView.scrollToItem(at: IndexPath(row: index + 1, section: 0), at: .right, animated: true)
            self.homeviewModel?.setPortfolioType(self.indexToPortfolioType(index + 1))
        }
    }
}

extension HomeViewController: PortfolioNotificationTableViewCellDelegate {

    func didDismiss() {
        DispatchQueue.main.async {
            AppState.setDismissPortfolioNotification(dismiss: true)
            self.assetsTable.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        }
    }
}
