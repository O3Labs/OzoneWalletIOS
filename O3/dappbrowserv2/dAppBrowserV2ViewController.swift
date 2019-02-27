//
//  dAppBrowserV2ViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 11/19/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import WebKit
import Cache
import OpenGraph
import PKHUD
import DeckTransition

protocol dAppBrowserDelegate {
    func onConnectRequest(url: URL, message: dAppMessage, didCancel: @escaping (_ message: dAppMessage) -> Void, didConfirm:@escaping (_ message: dAppMessage, _ wallet: Wallet, _ acount: NEP6.Account?) -> Void)
   
    func onSendRequest(message: dAppMessage, request: dAppProtocol.SendRequest, didCancel: @escaping (_ message: dAppMessage, _ request: dAppProtocol.SendRequest) -> Void, onCompleted:@escaping (_ response: dAppProtocol.SendResponse?, _ error: dAppProtocol.errorResponse?) -> Void)
    
    func onInvokeRequest(message: dAppMessage, request: dAppProtocol.InvokeRequest, didCancel: @escaping (_ message: dAppMessage, _ request: dAppProtocol.InvokeRequest) -> Void, onCompleted:@escaping (_ response: dAppProtocol.InvokeResponse?, _ error: dAppProtocol.errorResponse?) -> Void)
    
    func error(message: dAppMessage, error: String)
    func didFinishMessage(message: dAppMessage, response: Any)
    func didFireEvent(name: String)
    func onWalletChanged(newWallet: Wallet)
    
    func beginLoading()
}


class dAppBrowserV2ViewController: UIViewController {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var walletSwitcherButton: UIBarButtonItem!
    @IBOutlet weak var toolbar: UIView!
    @IBOutlet weak var openOrderButton: BadgeUIButton!
    var webView: WKWebView!
    var progressView: UIProgressView!
    var textFieldURL: UITextField!
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    
    var viewModel: dAppBrowserViewModel!
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(loadOpenOrders), name: NSNotification.Name(rawValue: "needsReloadOpenOrders"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(viewOpenOrders(_:)), name: NSNotification.Name(rawValue: "viewTradingOrders"), object: nil)
    }
    
    deinit {
        self.webView.removeObserver(self, forKeyPath: "estimatedProgress", context: nil)
        self.webView.removeObserver(self, forKeyPath: "loading", context: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "needsReloadOpenOrders"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "viewTradingOrders"), object: nil)
    }
    
    
    func setupView() {
        self.view.theme_backgroundColor = O3Theme.backgroundColorPicker
        self.webView.theme_backgroundColor = O3Theme.backgroundColorPicker
        self.webView.scrollView.theme_backgroundColor = O3Theme.backgroundColorPicker
        self.webView.isOpaque = false
        self.containerView.theme_backgroundColor = O3Theme.backgroundColorPicker
        self.hidesBottomBarWhenPushed = true
        self.navigationController?.hideHairline()
        self.progressView = UIProgressView(frame: CGRect(x: 0.0, y: (self.navigationController?.navigationBar.frame.size.height)! - 3.0, width: self.view.frame.size.width, height: 3.0))
        self.progressView.progressViewStyle = .bar
        self.navigationController?.navigationBar.addSubview(self.progressView)
        
        self.webView?.frame = self.containerView!.bounds
        self.webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        self.webView.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
        self.webView.allowsBackForwardNavigationGestures = true
        self.toolbar.isHidden = true
        toolbar?.theme_backgroundColor = O3Theme.backgroundColorPicker
        
        
        if viewModel.assetSymbol != nil {
            addObservers()
            loadTradableAssets { list in
                let tradableAsset = list.first(where: { t -> Bool in
                    return t.symbol.uppercased() == self.viewModel.assetSymbol!.uppercased()
                })
                DispatchQueue.main.async {
                    if tradableAsset != nil {
                        self.viewModel.tradableAsset = tradableAsset
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
    
    @IBAction func tradeTapped(_ sender: Any) {
        if (viewModel.assetSymbol?.lowercased() != "neo") {
            self.showActionSheetAssetInTradingAccount(asset: self.viewModel.tradableAsset!)
        } else {
            showBuyOptionsNEO()
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if (keyPath == "estimatedProgress") {
            self.progressView.setProgress(Float(self.webView.estimatedProgress), animated: true)
        } else if (keyPath == "loading") {
            UIApplication.shared.isNetworkActivityIndicatorVisible = self.webView.isLoading
            if (self.webView.isLoading) {
                self.progressView.setProgress(0.1, animated: true)
            }else{
                self.progressView.setProgress(0.0, animated: false)
            }
        }
    }
    
    func showURLHost(url: URL) {
        let secureInfo = UIButton(frame: CGRect(x: 0, y: 0, width: 24, height: 16))
        if url.scheme == "http"{
            secureInfo.frame = CGRect(x: 0, y: 0, width: 24, height: 16)
            secureInfo.tintColor = UIColor.lightGray
            secureInfo.setImage(UIImage(named: "info-circle.png"), for: .normal)
        } else {
            secureInfo.frame = CGRect(x: 0, y: 0, width: 18, height: 12)
            secureInfo.theme_tintColor = O3Theme.positiveGainColorPicker
            secureInfo.setImage(UIImage(named: "lock-solid.png"), for: .normal)
        }
        secureInfo.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        textFieldURL.leftView = secureInfo
        textFieldURL.leftViewMode = .always
    }
    
    @IBAction func didTapWallet(_ sender: UIBarButtonItem) {
        
        if self.viewModel.unlockedWallet == nil {
            return
        }
        
        let vc = UIStoryboard(name: "dAppBrowser", bundle: nil).instantiateViewController(withIdentifier: "ConnectWalletSelectorTableViewController") as! ConnectWalletSelectorTableViewController
        
        let accounts = NEP6.getFromFileSystem()?.accounts.filter({ n -> Bool in
            return n.key != nil
        })
        
        //calculate the height by how many accounts are there
        var height = CGFloat(accounts!.count * 60)
        height = min(height, (CGFloat)(UIScreen.main.bounds.height * 0.5))
         vc.preferredContentSize = CGSize(width: UIScreen.main.bounds.width * 0.7, height: height)
        vc.modalPresentationStyle = .popover
        vc.selectedAccount = self.viewModel.selectedAccount
        
        let presentationController = vc.presentationController as! UIPopoverPresentationController
        presentationController.barButtonItem = sender
        presentationController.theme_backgroundColor = O3Theme.backgroundColorPicker
        presentationController.delegate = self
        presentationController.sourceRect = CGRect(x: 0, y: 0, width: 25, height: 25)
        presentationController.permittedArrowDirections = [.any]
        self.present(vc, animated: true, completion: nil)
    }

    
    @IBAction func didTapBack(_ sender: Any) {
        if self.webView.canGoBack {
            print("Can go back")
            self.webView.goBack()
        } else {
            print("Can't go back")
        }
    }
    
    func checkBackButton() {
        DispatchQueue.main.async {
            self.backButton.isEnabled = self.webView.canGoBack
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        
        var req = URLRequest(url: self.viewModel.url)
        if (viewModel.url?.absoluteString.hasPrefix("https://public.o3.network")) == true {
            let queryItems = [NSURLQueryItem(name: "theme", value: UserDefaultsManager.themeIndex == 0 ? "light" : "dark")]
            let urlComps = NSURLComponents(url: viewModel.url!, resolvingAgainstBaseURL: false)!
            urlComps.queryItems = queryItems as [URLQueryItem]
            req = URLRequest(url: urlComps.url!)
        }
        
        openOrderButton.addTarget(self, action: #selector(viewOpenOrders(_:)), for: UIControl.Event.touchUpInside)
        
        self.viewModel.loadMetadata()
        self.webView.load(req)
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        
        self.viewModel.delegate = self
        
        textFieldURL = UITextField(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - (44 * 2), height: 30))
        textFieldURL.borderStyle  = .roundedRect
        textFieldURL.font = UIFont(name: "Avenir-Medium", size: 14)
        textFieldURL.theme_backgroundColor = O3Theme.backgroundLightgrey
        textFieldURL.theme_textColor = O3Theme.textFieldTextColorPicker
        textFieldURL.isEnabled = false
        textFieldURL.delegate = self
        showURLHost(url: self.viewModel.url)
        self.navigationItem.titleView = textFieldURL
        
        checkBackButton()
    }
    
    @IBAction func didTapMore(_ sender: UIBarButtonItem) {
        
        let vc = UIStoryboard(name: "dAppBrowser", bundle: nil).instantiateViewController(withIdentifier: "dAppBrowserMenuTableViewController") as! dAppBrowserMenuTableViewController
        //number of menus x cell height
        let height = CGFloat(4 * 44.0)
        vc.preferredContentSize = CGSize(width: UIScreen.main.bounds.width * 0.8, height: height)
        vc.modalPresentationStyle = .popover
        vc.onClose = {
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        }
        vc.onRefresh = {
            DispatchQueue.main.async {
                self.webView.reload()
            }
        }
        
        vc.onShare = {
            DispatchQueue.main.async {
                let vc = UIActivityViewController(activityItems: [self.viewModel.url.absoluteString], applicationActivities: [])
                self.present(vc, animated: true, completion: nil)
            }
        }
        
        vc.onDisconnect = {
            DispatchQueue.main.async {
                self.viewModel.unlockedWallet = nil
                self.viewModel.selectedAccount = nil
                self.viewModel.isConnected = false
                self.walletSwitcherButton.tintColor = UIColor.gray
            }
        }
        
        let presentationController = vc.presentationController as! UIPopoverPresentationController
        presentationController.theme_backgroundColor = O3Theme.backgroundColorPicker
        presentationController.barButtonItem = sender
        presentationController.delegate = self
        presentationController.sourceRect = CGRect(x: 0, y: 0, width: 25, height: 25)
        presentationController.permittedArrowDirections = [.any]
        self.present(vc, animated: true, completion: nil)
    }

}
extension dAppBrowserV2ViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textFieldURL.textAlignment = .left
        textFieldURL.text = self.viewModel.url.absoluteString
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        showURLHost(url: self.viewModel.url)
    }
}

extension dAppBrowserV2ViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        
        return nil
    }
}

extension dAppBrowserV2ViewController: WKScriptMessageHandler{
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if (message.name != "sendMessageHandler") {
            return
        }
        #if DEBUG
        print(message.body)
        #endif
        
        let jsonDataTemp = try? JSONSerialization.data(withJSONObject:  message.body as! JSONDictionary, options: [])
        let jsonString = String(data: jsonDataTemp!, encoding: String.Encoding.utf8)!
        print(jsonString)
        let decoder = JSONDecoder()
        guard let dictionary =  message.body as? JSONDictionary,
            let data = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted),
            let message = try? decoder.decode(dAppMessage.self, from: data) else {
                return
        }
        
        //command not supported
        if dAppProtocol.availableCommands.contains(message.command) == false {
            self.viewModel.responseWithError(message: message, error: "Command not supported")
            return
        }
        
        if dAppProtocol.needAuthorizationCommands.contains(message.command) && self.viewModel.isConnected == false {
            self.viewModel.requestToConnect(message: message, didCancel: { m in
                //cancel
                self.viewModel.responseWithError(message: message, error: "CONNECTION_DENIED")
            }) { m, wallet, account in
                //confirm
                DispatchQueue.main.async {
                    self.viewModel.proceedMessage(message: message)
                }
            }
            return
        }
        
        //proceed message that doesn't need authentication
        self.viewModel.proceedMessage(message: message)
    }
}

extension dAppBrowserV2ViewController: WKNavigationDelegate {
    
    override func loadView() {
        super.loadView()
        
        let contentController = WKUserContentController()
        //only on message handler
        contentController.add(self, name: "sendMessageHandler")
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        self.webView = WKWebView( frame: self.containerView!.bounds, configuration: config)
        self.webView.backgroundColor = UIColor.clear
        self.containerView?.addSubview(self.webView!)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.webView?.frame = self.containerView!.bounds
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            completionHandler()
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        textFieldURL.text = webView.url?.host
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        checkBackButton()
        self.event(eventName: "READY", data: [:])
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
    
}


extension dAppBrowserV2ViewController: dAppBrowserDelegate {
    func onWalletChanged(newWallet: Wallet) {
        let response = dAppProtocol.GetAccountResponse(address: newWallet.address, publicKey: newWallet.publicKeyString)
        self.event(eventName: "ACCOUNT_CHANGED", data: response.dictionary)
    }
    
    
    func beginLoading() {
        DispatchQueue.main.async {
            HUD.show(.progress)
        }
    }
    
    func onSendRequest(message: dAppMessage, request: dAppProtocol.SendRequest, didCancel: @escaping (_ message: dAppMessage, _ request: dAppProtocol.SendRequest) -> Void, onCompleted: @escaping (_ response: dAppProtocol.SendResponse?, _ error: dAppProtocol.errorResponse?) -> Void) {
        
        
        let nav = UIStoryboard(name: "dAppBrowser", bundle: nil).instantiateViewController(withIdentifier: "SendRequestTableViewControllerNav")
        self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: nav)
        nav.modalPresentationStyle = .custom
        nav.transitioningDelegate = self.halfModalTransitioningDelegate
        if let vc = nav.children.first as? SendRequestTableViewController {
            vc.message = message
            vc.selectedWallet = self.viewModel.unlockedWallet

            vc.onCompleted = { response, err in
                onCompleted(response,err)
            }
            
            vc.onCancel = { m, r in
                didCancel(m,r)
            }
            
            vc.dappMetadata = self.viewModel.dappMetadata
            vc.request = request
        }
        self.present(nav, animated: true, completion: nil)
    }
    
    func onInvokeRequest(message: dAppMessage, request: dAppProtocol.InvokeRequest, didCancel: @escaping (_ message: dAppMessage, _ request: dAppProtocol.InvokeRequest) -> Void, onCompleted: @escaping (_ response: dAppProtocol.InvokeResponse?, _ error: dAppProtocol.errorResponse?) -> Void) {
        
        
        let nav = UIStoryboard(name: "dAppBrowser", bundle: nil).instantiateViewController(withIdentifier: "InvokeRequestTableViewControllerNav")
        self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: nav)
        nav.modalPresentationStyle = .custom
        nav.transitioningDelegate = self.halfModalTransitioningDelegate
        if let vc = nav.children.first as? InvokeRequestTableViewController {
            vc.selectedWallet = self.viewModel.unlockedWallet
            vc.message = message
            vc.onCompleted = { response, err in
                onCompleted(response,err)
            }
            
            vc.onCancel = { m, r in
                didCancel(m, r)
            }
            
            vc.dappMetadata = self.viewModel.dappMetadata
            vc.request = request
        }
        self.present(nav, animated: true, completion: nil)
    }
    
    
    func error(message: dAppMessage, error: String) {
        var dic = message.dictionary
        dic["error"] = error
        let jsonData = try? JSONSerialization.data(withJSONObject: dic, options: [])
        let jsonString = String(data: jsonData!, encoding: String.Encoding.utf8)!
        self.callback(jsonString: jsonString)
    }
    
    func event(eventName: String, data: [String: Any]) {
        var dic:[String: Any] = [:]
        dic["command"] = "event"
        dic["eventName"] = eventName
        dic["data"] = data
        dic["blockchain"] = "NEO"
        dic["platform"] = "o3-dapi"
        dic["version"] = "1"
        
        let jsonData = try? JSONSerialization.data(withJSONObject: dic, options: [])
        let jsonString = String(data: jsonData!, encoding: String.Encoding.utf8)!
        self.callback(jsonString: jsonString)
    }
    
    func callback(jsonString: String) {
        //make sure this is called from Main Thread
        DispatchQueue.main.async {
            self.webView!.evaluateJavaScript("_o3dapi.receiveMessage(\(jsonString))") { _, error in
                guard error == nil else {
                    return
                }
            }
        }
    }
    
    func didFinishMessage(message: dAppMessage, response: Any) {
        DispatchQueue.main.async {
            HUD.hide()
            
            var dic = message.dictionary
            dic["data"] = response
            let jsonData = try? JSONSerialization.data(withJSONObject: dic, options: [])
            let jsonString = String(data: jsonData!, encoding: String.Encoding.utf8)!
            self.callback(jsonString: jsonString)
        }
    }
    
    func didFireEvent(name: String) {
        if name.lowercased() == "disconnect" {
            self.walletSwitcherButton.tintColor = UIColor.gray
        }
        self.event(eventName: name, data: [:])
    }
    
    func onConnectRequest(url: URL, message: dAppMessage, didCancel: @escaping (dAppMessage) -> Void, didConfirm: @escaping (_ message: dAppMessage, _ wallet: Wallet, _ acount: NEP6.Account?) -> Void) {
        let nav = UIStoryboard(name: "dAppBrowser", bundle: nil).instantiateViewController(withIdentifier: "ConnectRequestTableViewControllerNav")
        self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: nav)
        nav.modalPresentationStyle = .custom
        nav.transitioningDelegate = self.halfModalTransitioningDelegate
        if let vc = nav.children.first as? ConnectRequestTableViewController {
            vc.url = url
            vc.message = message
            vc.onConfirm = { m, wallet, account in
                DispatchQueue.main.async {
                    self.walletSwitcherButton.theme_tintColor = O3Theme.positiveGainColorPicker
                }
                didConfirm(m, wallet, account)
            }
            
            vc.onCancel = { m in
                didCancel(m)
            }
            
            vc.dappMetadata = self.viewModel.dappMetadata
        }
        self.present(nav, animated: true, completion: nil)
    }
}

extension dAppBrowserV2ViewController: UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate{
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle{
        return .none
    }
}


extension dAppBrowserV2ViewController {
    @IBAction func unwindToDappBrowser(sender: UIStoryboardSegue) {
        if let source = sender.source as? ConnectWalletSelectorTableViewController {
            DispatchQueue.main.async {
                if source.selectedWallet == nil {
                    return
                }
                 self.viewModel.changeActiveAccount(account: source.selectedAccount, wallet: source.selectedWallet!)
            }
        }
    }
}
