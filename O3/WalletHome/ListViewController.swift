//
//  ListViewController.swift
//  JXPagingViewExample
//
//  Created by jiaxin on 2019/12/30.
//  Copyright © 2019 jiaxin. All rights reserved.
//

import UIKit

class ListViewController: UIViewController {
    
    lazy var tableView: UITableView = UITableView(frame: CGRect.zero, style: .plain)
    var isNeedHeader = false
    var isNeedFooter = false
    var listViewDidScrollCallback: ((UIScrollView) -> ())?
    var isHeaderRefreshed = false
    
    var displayedAssets = [PortfolioAsset]()
    var portfolio: PortfolioValue?
    var homeviewModel: HomeViewModel!
    var coinbaseAssets: [PortfolioAsset] = []
    var walletAssets: [PortfolioAsset] = []
    var typeString: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib.init(nibName: "CurrencyTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "CurrencyTableViewCell")
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        //列表的contentInsetAdjustmentBehavior失效，需要自己设置底部inset
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: UIApplication.shared.keyWindow!.jx_layoutInsets().bottom, right: 0)
        view.addSubview(tableView)
    
        beginFirstRefresh()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.frame = view.bounds
    }

    func beginFirstRefresh() {
        if !isHeaderRefreshed {
            if (self.isNeedHeader) {
            }else {
                self.isHeaderRefreshed = true
                self.tableView.reloadData()
            }
        }
    }

    @objc func headerRefresh() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(2)) {
            self.isHeaderRefreshed = true
            self.tableView.reloadData()
        }
    }

    @objc func loadMore() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(2)) {
            self.tableView.reloadData()
        }
    }
}

extension ListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isHeaderRefreshed {
            if typeString == "Wallets"{
                return walletAssets.count
            }else{
                return coinbaseAssets.count
            }
            
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CurrencyTableViewCell", for: indexPath) as! CurrencyTableViewCell
        var asset: PortfolioAsset
        if typeString == "Wallets"{
            asset = self.walletAssets[indexPath.row]
        }else{
            asset = self.coinbaseAssets[indexPath.row]
        }
        guard let latestPrice = portfolio?.price[asset.symbol],
            let firstPrice = portfolio?.firstPrice[asset.symbol] else {
                cell.data = CurrencyTableViewCell.Data(asset: asset,
                                                    referenceCurrency: (homeviewModel?.referenceCurrency)!,
                                                    latestPrice: PriceData(average: 0, averageBTC: 0, time: "24h"),
                                                    firstPrice: PriceData(average: 0, averageBTC: 0, time: "24h"))
                return cell
        }
        
        cell.data = CurrencyTableViewCell.Data(asset: asset,
                                            referenceCurrency: (homeviewModel?.referenceCurrency)!,
                                            latestPrice: latestPrice,
                                            firstPrice: firstPrice)
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.listViewDidScrollCallback?(scrollView)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var asset: PortfolioAsset
        asset = self.walletAssets[indexPath.row]
        
        var urlString = ""
        
        if let o3NativeAsset = asset as? O3WalletNativeAsset {
            var chain = "neo"
            if o3NativeAsset.assetType == O3WalletNativeAsset.AssetType.ontologyAsset {
                chain = "ont"
            }
            urlString = String(format: "https://o3.app/assets/%@/%@", chain, asset.symbol)
        } else {
            urlString = "https://www.coinbase.com/price/\(asset.name.lowercased())"
        }
    
        DispatchQueue.main.async {
            Controller().openDappBrowserV2(url: URL(string: urlString)!, assetSymbol: asset.symbol)
        }
    }
}

extension ListViewController: JXPagingViewListViewDelegate {
    func listView() -> UIView {
        return view
    }

    func listViewDidScrollCallback(callback: @escaping (UIScrollView) -> ()) {
        self.listViewDidScrollCallback = callback
    }

    func listScrollView() -> UIScrollView {
        return self.tableView
    }

    func listWillAppear() {
        print("\(self.title ?? ""):\(#function)")
    }

    func listDidAppear() {
        print("\(self.title ?? ""):\(#function)")
    }

    func listWillDisappear() {
        print("\(self.title ?? ""):\(#function)")
    }

    func listDidDisappear() {
        print("\(self.title ?? ""):\(#function)")
    }
}
