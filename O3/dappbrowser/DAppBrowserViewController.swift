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
    var webView: WKWebView?
    var callbackMethodName: String = "callback"
    let availableCommands = ["init", "requestToConnect", "getPlatform", "getAccounts", "getBalances", "isAppAvailable", "requestToSign", "getDeviceInfo", "verifySession"]
    
    var loggedIn = false
    //create new session ID everytime user open this page
    var sessionID: String?
    var currentURL: URL?
    var url: URL?
    
    override func loadView() {
        super.loadView()
        
        let contentController = WKUserContentController()
        //only on message handler
        contentController.add(self, name: "sendMessageHandler")
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        self.webView = WKWebView( frame: self.containerView!.bounds, configuration: config)
        self.view = self.webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        self.title = ""
        self.hidesBottomBarWhenPushed = true
        
        if Authenticated.account == nil {
            return
        }
        if url == nil {
            self.dismiss(animated: false, completion: nil)
            return
        }
        
        let req = URLRequest(url: url!)
        self.webView!.load(req)
        self.webView?.navigationDelegate = self
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "ellipsis-v"), style: .plain, target: self, action: #selector(didTapRight(_:)))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "times"), style: .plain, target: self, action: #selector(didTapLeft(_:)))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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

        let message = String(format: "%@", webView!.title!)
        var dialogTitle: String? = nil
        
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
        self.dismiss(animated: true, completion: nil)
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

extension DAppBrowserViewController: WKScriptMessageHandler {
    
    func currentAccount() -> [String: Any] {
        return ["address": Authenticated.account!.address,
                "publicKey": Authenticated.account!.publicKeyString]
    }
    
    func requestToSign(unsignedRawTransaction: String) {
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
            let signed = NeoutilsSign(data, Authenticated.account!.privateKey.fullHexString, &error)
            if error != nil {
                self.callback(command: "requestToSign", data: nil, errorMessage: error?.localizedDescription, withSession: true)
                return
            }
            let dic = ["signatureData": signed?.fullHexString ?? "", "account": self.currentAccount()] as [String: Any]
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
            guard let url = URL(string: dappURL) else{
                return
            }
            self.currentURL = url
            let host = currentURL?.host!
            let message = String(format: "%@ want to connect with your O3 app. Allow?", host!)
            OzoneAlert.confirmDialog(message: message, cancelTitle: "Cancel", confirmTitle: "Allow", didCancel: {
                
            }) {
                //pop up pincode here
                let keychain = Keychain(service: "network.o3.neo.wallet")
                do {
                    _ = try keychain
                        .authenticationPrompt(String(format: "Connect with %@?", host!))
                        .get("ozonePrivateKey")
                    
                    DispatchQueue.main.async {
                        self.title = host?.firstUppercased
                        //generate session ID
                        //consider saving this to the app state and make it valid as long as user is still active in the app.
                        self.sessionID = UUID().uuidString
                        self.loggedIn = true
                        self.callback(command: "requestToConnect", data: self.currentAccount(), errorMessage: nil, withSession: true)
                    }
                } catch _ {
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
        O3APIClient(network: Network.main).getAccountState(address: Authenticated.account!.address) { result in
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
        self.title = webView.title
        
    }
}
