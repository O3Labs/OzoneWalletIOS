//
//  DAppBrowserViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 6/20/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import WebKit
import Neoutils
import KeychainAccess
import Lottie
//统计功能注释
//import Amplitude
import DeckTransition

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}

class DAppBrowserViewController: UIViewController {
    
    @IBOutlet var containerView: UIView?
    @IBOutlet var toolbar: UIView?
    @IBOutlet var openOrderButton: BadgeUIButton?
    
    var webView: WKWebView?
    var callbackMethodName: String = "callback"
    let availableCommands = ["init", "requestToConnect", "getPlatform", "getAccounts", "getBalances", "isAppAvailable", "requestToSign", "getDeviceInfo", "verifySession"]
    
    var loggedIn = false
    //create new session ID everytime user open this page
    var sessionID: String?
    var currentURL: URL?
    var url: URL?
    var selectedAssetSymbol: String?
    
    var showMoreButton: Bool? {
        didSet {
            if showMoreButton == true {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "ellipsis-v"), style: .plain, target: self, action: #selector(didTapRight(_:)))
            }
        }
    }
    
    private  func loadTradableAssets(completion: @escaping ([TradableAsset]) -> Void) {
        O3APIClient.shared.loadSupportedTokenSwitcheo { result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let response):
                completion(response)
            }
        }
    }
    
    @objc private func loadOpenOrders() {
        O3APIClient(network: AppState.network).loadSwitcheoOrders(address: Authenticated.wallet!.address, status: SwitcheoOrderStatus.open) { result in
            switch result{
            case .failure(let error):
                #if DEBUG
                print(error)
                #endif
            case .success(let response):
                DispatchQueue.main.async {
                    self.openOrderButton?.isHidden =  response.switcheo.count == 0
                    self.openOrderButton?.badgeValue = String(format: "%d",response.switcheo.count)
                }
            }
        }
    }
    
    private var tradableAsset: TradableAsset?
    private var tradingAccount: TradingAccount?
    @objc private func loadTradingAccountBalances() {
        O3APIClient(network: AppState.network).tradingBalances(address: Authenticated.wallet!.address) { result in
            switch result {
            case .failure(let error):
                print(error)
                return
            case .success(let tradingAccount):
                DispatchQueue.main.async {
                    self.tradingAccount = tradingAccount
                }
            }
        }
    }
    
    @objc @IBAction func viewOpenOrders(_ sender: Any) {
        guard let nav = UIStoryboard(name: "Trading", bundle: nil).instantiateViewController(withIdentifier: "OrdersTabsViewControllerNav") as? UINavigationController else {
            return
        }
        let transitionDelegate = DeckTransitioningDelegate()
        nav.transitioningDelegate = transitionDelegate
        nav.modalPresentationStyle = .custom
        self.present(nav, animated: true, completion: nil)
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(loadOpenOrders), name: NSNotification.Name(rawValue: "needsReloadOpenOrders"), object: nil)
         NotificationCenter.default.addObserver(self, selector: #selector(viewOpenOrders(_:)), name: NSNotification.Name(rawValue: "viewTradingOrders"), object: nil)
        
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "needsReloadOpenOrders"), object: nil)
          NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "viewTradingOrders"), object: nil)
    }
    
    override func loadView() {
        super.loadView()
        
        self.toolbar?.isHidden = true
        
        let contentController = WKUserContentController()
        //only on message handler
        contentController.add(self, name: "sendMessageHandler")
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        self.webView = WKWebView( frame: self.containerView!.bounds, configuration: config)
        self.containerView?.addSubview(self.webView!)
        
        if selectedAssetSymbol != nil {
            addObservers()
            loadTradableAssets { list in
                let tradableAsset = list.first(where: { t -> Bool in
                    return t.symbol.uppercased() == self.selectedAssetSymbol!.uppercased()
                })
                DispatchQueue.main.async {
                    if tradableAsset != nil {
                        //TODO: READD THIS WHEN SDUSD IS A BASE PAIR
                        if tradableAsset?.symbol.uppercased() != "NEO" {
                            self.toolbar?.isHidden = false
                        }
                        self.tradableAsset = tradableAsset
                        self.toolbar?.isHidden = false
                        self.loadTradingAccountBalances()
                        DispatchQueue.global(qos: .background).async {
                            self.loadOpenOrders()
                        }
                    }
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.webView?.frame = self.containerView!.bounds
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
        toolbar?.theme_backgroundColor = O3Theme.backgroundColorPicker
        self.title = ""
        self.hidesBottomBarWhenPushed = true
        self.navigationController?.hideHairline()
        
        if Authenticated.wallet == nil {
            return
        }
        
        if url == nil {
            self.dismiss(animated: false, completion: nil)
            return
        }
        var req = URLRequest(url: url!)
        if (url?.absoluteString.hasPrefix("https://public.o3.network")) == true {
            let queryItems = [NSURLQueryItem(name: "theme", value: UserDefaultsManager.themeIndex == 0 ? "light" : "dark")]
            let urlComps = NSURLComponents(url: url!, resolvingAgainstBaseURL: false)!
            urlComps.queryItems = queryItems as [URLQueryItem]
             req = URLRequest(url: urlComps.url!)
        }
       
        self.webView?.backgroundColor = UIColor.clear
        self.webView?.isOpaque = false
        self.webView!.load(req)
        self.webView?.navigationDelegate = self
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-x"), style: .plain, target: self, action: #selector(didTapLeft(_:)))
        
        let loadingView = LOTAnimationView(name: "loader_portfolio")
        loadingView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        loadingView.play()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingView)
    }
    

    @objc func didTapLeft(_ sender: Any) {
        if self.loggedIn == true {
            let message = String(format: "You are connected to %@\nDisconnect and close O3 dapp browser?", self.currentURL!.host!)
            OzoneAlert.confirmDialog(message: message, cancelTitle: "Stay", confirmTitle: "Close", didCancel: {
                
            }) {
                self.close()
            }
            
            return
        }
        self.close()
    }
    
    @objc func didTapRight(_ sender: Any) {
        
        let message = String(format: "%@", (webView!.url?.absoluteString)!)
        var dialogTitle: String? = webView?.title!
        
        if self.loggedIn == true {
            dialogTitle = String(format: "You are connected to %@", self.currentURL!.host!)
        }
        
        let alert = UIAlertController(title: dialogTitle, message: message, preferredStyle: .actionSheet)
        
        let share = UIAlertAction(title: AccountStrings.shareAction, style: .default) { _ in
            self.share()
        }
        alert.addAction(share)
        
        //only show log out button when user logged in
        if  self.loggedIn == true {
            let logout = UIAlertAction(title: "Logout and return to O3", style: .default) { _ in
                self.logout()
            }
            alert.addAction(logout)
        }
        
        let cancel = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { _ in
            
        }
        alert.addAction(cancel)
        
        alert.popoverPresentationController?.sourceView = sender as? UIView
        present(alert, animated: true, completion: nil)
    }
    
    func share() {
        let shareURL = URL(string: "https://o3.network/")
        let activityViewController = UIActivityViewController(activityItems: [shareURL as Any], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @objc func close() {
        self.view.window!.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func logout() {
        //notify the connected app that user has loggedout
        self.loggedIn = false
        sessionRevoked()
        self.close()
    }
    
    func sessionRevoked() {
        sessionID = nil
        self.callback(command: "revokedSession", data: [:], errorMessage: nil, withSession: true)
    }
    
    func callback(command: String, data: [String: Any]?, errorMessage: String?, withSession: Bool) {
        var dic: [String: Any] = [
            "command": command
        ]
        
        if data != nil {
            dic["data"] = data
        }
        
        if errorMessage != nil {
            dic["error"] = ["message": errorMessage]
        }
        
        if withSession == true {
            dic["sessionID"] = sessionID
        }
        
        let jsonData = try? JSONSerialization.data(withJSONObject: dic, options: [])
        let jsonString = String(data: jsonData!, encoding: String.Encoding.utf8)!
        self.webView?.evaluateJavaScript("o3.callback(\(jsonString))") { _, error in
            guard error == nil else {
                return
            }
        }
    }
}

//tradable asset
extension DAppBrowserViewController {
    
    @IBAction func tradeTapped(_ sender: Any) {
        if (self.tradableAsset?.symbol.lowercased() != "neo") {
            showActionSheetAssetInTradingAccount(asset: self.tradableAsset!, sender)
        } else {
            showBuyOptionsNEO(sender)
        }
    }
    
    func openCreateOrder(action: CreateOrderAction, asset: TradableAsset) {
        let nav = UIStoryboard(name: "Trading", bundle: nil).instantiateViewController(withIdentifier: "CreateOrderTableViewControllerNav") as! UINavigationController
        if let vc = nav.viewControllers.first as? CreateOrderTableViewController {
            vc.viewModel = CreateOrderViewModel()
            vc.viewModel.selectedAction = action
            let inTradingAccount = self.tradingAccount?.switcheo.confirmed.first(where: { t -> Bool in
                return t.symbol.uppercased() == asset.symbol.uppercased()
            })
            vc.viewModel.wantAsset = inTradingAccount != nil ? inTradingAccount : asset
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
    
    func showBuyOptionsNEO(_ sender: Any) {
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
        actionSheet.popoverPresentationController?.sourceView = sender as? UIView
        present(actionSheet, animated: true, completion: nil)
    }
    
    func showActionSheetAssetInTradingAccount(asset: TradableAsset, _ sender: Any) {
        
        let alert = UIAlertController(title: asset.name, message: nil, preferredStyle: .actionSheet)
        
        let buyButton = UIAlertAction(title: "Buy", style: .default) { _ in
            tradingEvent.shared.startBuy(asset: asset.symbol, source: TradingActionSource.tokenDetail)
            self.openCreateOrder(action: CreateOrderAction.Buy, asset: asset)
        }
        alert.addAction(buyButton)
        
        //we can't actually sell NEO but rather use NEO to buy other asset
        if asset.symbol != "NEO" {
            let sellButton = UIAlertAction(title: "Sell", style: .default) { _ in
                tradingEvent.shared.startSell(asset: asset.symbol, source: TradingActionSource.tokenDetail)
                self.openCreateOrder(action: CreateOrderAction.Sell, asset: asset)
            }
            alert.addAction(sellButton)
        }
        
        
        let cancel = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { _ in
            
        }
        alert.addAction(cancel)
        alert.popoverPresentationController?.sourceView = sender as? UIView
        present(alert, animated: true, completion: nil)
    }
}

extension DAppBrowserViewController: WKScriptMessageHandler {
    
    func currentAccount() -> [String: Any] {
        return ["address": Authenticated.wallet!.address,
                "publicKey": Authenticated.wallet!.publicKeyString]
    }

    func parseAndAnalyzeTransaction(unsignedHex: String) {
        var unsignedHexVar = unsignedHex
        if unsignedHexVar.hasSuffix("0000") {
            unsignedHexVar.removeLast(4)
            let jsonStart = unsignedHexVar.index(of: "7b")
            if jsonStart != nil && (jsonStart?.encodedOffset)! % 2 == 0  {
                let unsignedJson = unsignedHexVar.substring(from: jsonStart!)
                let unsignedJsonData = unsignedJson.dataWithHexString()
                do {
                    //统计功能注释
//                    let dict = try JSONSerialization.jsonObject(with: unsignedJsonData, options: []) as? [String: Any]
//                    Amplitude.instance().logEvent("Switcheo_Signed_JSON", withEventProperties: dict)
                } catch {
                    return
                }
            }
        } else {
            //统计功能注释
//            Amplitude.instance().logEvent("Switcheo_Signed_Raw_TX")
        }
    }

    func requestToSign(unsignedRawTransaction: String) {
        print(unsignedRawTransaction)
        if unsignedRawTransaction.count < 2 {
            self.callback(command: "requestToSign", data: nil, errorMessage: "invalid unsigned raw transaction", withSession: true)
            return
        }
        //showing confirmation dialog saying that the app requests users to sign a transaction
        let message = String(format: "Sign a transaction from %@?", self.currentURL!.host!)
        OzoneAlert.confirmDialog("", message: message, cancelTitle: "Deny", confirmTitle: "Confirm", didCancel: {
            self.callback(command: "requestToSign", data: nil, errorMessage: "User denied to sign a transaction", withSession: true)
            return
        }) {
            let data = unsignedRawTransaction.dataWithHexString()
            var error: NSError?
            let signed = NeoutilsSign(data, Authenticated.wallet!.privateKey.fullHexString, &error)
            if error != nil {
                self.callback(command: "requestToSign", data: nil, errorMessage: error?.localizedDescription, withSession: true)
                return
            }
            let dic = ["signatureData": signed?.fullHexString ?? "", "account": self.currentAccount()] as [String: Any]
            self.parseAndAnalyzeTransaction(unsignedHex: unsignedRawTransaction)
            self.callback(command: "requestToSign", data: dic, errorMessage: nil, withSession: true)
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if (message.name != "sendMessageHandler") {
            return
        }
        #if DEBUG
        print(message.body)
        #endif
        guard let jsonData = message.body as? [String: String] else {
            self.callback(command: "", data: nil, errorMessage: "Invalid data", withSession: false)
            return
        }
        
        let command = jsonData["command"]!
        
        if !availableCommands.contains(command) {
            self.callback(command: command, data: nil, errorMessage: "unsupported command", withSession: false)
            return
        }
        
        if command == "init" {
            self.callback(command: "init", data: [:], errorMessage: nil, withSession: false)
            return
        }
        
        if command == "requestToConnect" {
            //this is a URL
            let dappURL =  jsonData["data"]!
            guard let url = URL(string: dappURL) else {
                return
            }
            self.currentURL = url
            let host = currentURL?.host!
            let message = String(format: "%@ want to connect with your O3 app. Allow?", host!)
            OzoneAlert.confirmDialog(message: message, cancelTitle: "Cancel", confirmTitle: "Allow", didCancel: {
                
            }) {
                let prompt = String(format: "Connect with %@?", host!)
                O3KeychainManager.authenticateWithBiometricOrPass(message: prompt) { result in
                    switch(result) {
                    case .success(let _):
                        DispatchQueue.main.async {
                            self.title = host?.firstUppercased
                            self.sessionID = UUID().uuidString
                            self.loggedIn = true
                            self.callback(command: "requestToConnect", data: self.currentAccount(), errorMessage: nil, withSession: true)
                        }
                    case .failure(let _):
                        return
                    }
                }

            }
            return
        }
        
        if command == "verifySession" {
            let session =  jsonData["data"]!
            //invalid session
            if session != sessionID {
                self.callback(command: "verifySession", data: nil, errorMessage: "Invalid session", withSession: false)
                return
            }
            self.callback(command: "verifySession", data: self.currentAccount(), errorMessage: nil, withSession: true)
            return
        }
        
        //below are the methods that need permission
        if  self.loggedIn == false {
            return
        }
        
        if command == "getPlatform" {
            self.callback(command: "getPlatform", data: ["platform": "ios", "version": Bundle.main.releaseVersionNumber ?? ""], errorMessage: nil, withSession: true)
        } else if command == "getAccounts" {
            let blockchains = ["neo": self.currentAccount()]
            let dic = ["accounts": blockchains]
            self.callback(command: "getAccounts", data: dic, errorMessage: nil, withSession: true)
        } else if command == "isAppAvailable" {
            let dic = ["isAppAvailable": true]
            self.callback(command: "isAppAvailable", data: dic, errorMessage: nil, withSession: true)
        } else if command == "requestToSign" {
            let unsignedRawTransaction =  jsonData["data"]!
            self.requestToSign(unsignedRawTransaction: unsignedRawTransaction)
        } else if command == "getDeviceInfo" {
            //TODO finish this with more info
            let dic = ["device": UIDevice.current.model]
            self.callback(command: "getDeviceInfo", data: dic, errorMessage: nil, withSession: true)
        } else if command == "getBalances" {
            self.getBalances()
        }
    }
    
    func getBalances() {
        O3APIClient(network: Network.main).getAccountState(address: Authenticated.wallet!.address) { result in
            DispatchQueue.main.async {
                switch result {
                case .failure:
                    return
                case .success(let accountState):
                    DispatchQueue.main.async {
                        var balances: [String: Any] = [:]
                        for asset in accountState.assets {
                            balances[asset.symbol] = ["name": asset.name,
                                                      "symbol": asset.symbol,
                                                      "decimals": asset.decimals,
                                                      "value": asset.value,
                                                      "id": asset.id]
                        }
                        for asset in accountState.nep5Tokens {
                            balances[asset.symbol] = ["name": asset.name,
                                                      "symbol": asset.symbol,
                                                      "decimals": asset.decimals,
                                                      "value": asset.value,
                                                      "id": asset.id]
                        }
                        let dic = ["balances": balances, "account": self.currentAccount()]
                        self.callback(command: "getBalances", data: dic, errorMessage: nil, withSession: true)
                    }
                }
            }
        }
        
    }
    
}

extension DAppBrowserViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url,
            let host = url.host, host.hasPrefix("switcheo.exchange") {
            let button = UIButton(type: .custom)
            button.setImage(#imageLiteral(resourceName: "ic_verified_badge"), for: .normal)
            button.setTitle(host.firstUppercased, for: .normal)
            button.theme_setTitleColor(O3Theme.textFieldTextColorPicker, forState: .normal)
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
            button.titleLabel?.font = UIFont(name: "Avenir-Medium", size: 16)
            button.frame.size.width = 200
            self.navigationItem.titleView = button

        } else {
            self.title = webView.title
        }
        self.navigationItem.rightBarButtonItem = nil
    }
    
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url,
                let host = url.host, host.hasPrefix("o3.network"),
                UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                print(url)
                print("Redirected to browser. No need to open it locally")
                decisionHandler(.cancel)
            } else if let url = navigationAction.request.url,
                let host = url.host, host.hasPrefix("switcheo.exchange") {
                DispatchQueue.main.async {
                    let redirectURL = URL(string: String(format: "https://analytics.o3.network/redirect/?url=%@", url.absoluteString))
                    Controller().openDappBrowser(url: redirectURL!, modal: true)
                }
                decisionHandler(.cancel)
            } else {
                print("Open it locally")
                decisionHandler(.allow)
            }
        } else {
            decisionHandler(.allow)
        }
    }
    
}
