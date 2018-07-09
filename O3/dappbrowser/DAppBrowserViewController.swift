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

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}

class DAppBrowserViewController: UIViewController {
    
    @IBOutlet var containerView: UIView? = nil
    var webView: WKWebView?
    var callbackMethodName: String = "callback"
    let availableCommands = ["init", "requestToConnect", "getPlatform", "getAccounts", "isAppAvailable", "requestToSign", "getDeviceInfo", "verifySession"]
    
    var loggedIn = false
    //create new session ID everytime user open this page
    var sessionID: String?
    
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
       // let url = URL(string: "https://s3-ap-northeast-1.amazonaws.com/network.o3.cdn/____dapp/example/index.html")
        let url = URL(string: "http://localhost:8000/example/app.html")
        let req = URLRequest(url: url!)
        self.webView!.load(req)
        self.webView?.navigationDelegate = self
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refresh(_:)))
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout(_:)))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func refresh(_ sender: Any) {
        self.webView?.reload()
    }
    
    @objc func logout(_ sender: Any) {
        //notify the connected app that user has loggedout
        self.loggedIn = false
        sessionRevoked()
    }
    
    func sessionRevoked() {
        sessionID = nil
        self.callback(command:"revokedSession", data: [:], errorMessage: nil, withSession: true)
    }

    func callback(command: String, data: [String: Any]?, errorMessage: String?, withSession: Bool) {
        var dic: [String: Any] = [
            "command": command,
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
        
        let jsonData = try! JSONSerialization.data(withJSONObject: dic, options: [])
        let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)!
        self.webView?.evaluateJavaScript("o3.callback(\(jsonString))") { result, error in
            guard error == nil else {
                return
            }
        }
    }
    
}

extension DAppBrowserViewController: WKScriptMessageHandler {
    
    func requestToSign(unsignedRawTransaction: String) {
        if unsignedRawTransaction.count < 2 {
            self.callback(command:"requestToSign", data: nil, errorMessage: "invalid unsigned raw transaction", withSession: true)
            return
        }
        let data = unsignedRawTransaction.dataWithHexString()
        var error: NSError?
        let signed = NeoutilsSign(data, Authenticated.account!.privateKey.fullHexString, &error)
        if error != nil {
            self.callback(command:"requestToSign", data: nil, errorMessage: error?.localizedDescription, withSession: true)
            return
        }
        let dic = ["signatureData": signed?.fullHexString]
        self.callback(command:"requestToSign", data: dic,errorMessage: nil, withSession: true)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if (message.name != "sendMessageHandler")
        {
            return
        }
        print(message.body)
        guard let jsonData = message.body as? [String: String] else {
            self.callback(command: "", data:nil, errorMessage: "Invalid data", withSession: false)
            return
        }
        
        let command = jsonData["command"]!
        
        if !availableCommands.contains(command) {
            self.callback(command:command, data: nil,errorMessage: "unsupported command", withSession: false)
            return
        }
        
        if command == "init" {
            self.callback(command:"init", data: [:], errorMessage: nil, withSession: false)
            return
        }
        
        if command == "requestToConnect" {
            let appName =  jsonData["data"]!
            let message = String(format:"%@ want to connect to your O3 app. Allow?", appName)
            OzoneAlert.confirmDialog(message: message, cancelTitle: "Cancel", confirmTitle: "Allow", didCancel: {
                
            }) {
                self.sessionID = UUID().uuidString
                self.loggedIn = true
                self.callback(command:"requestToConnect", data: ["address": Authenticated.account!.address], errorMessage: nil, withSession: true)
            }
            return
        }
        
         if command == "verifySession" {
            let session =  jsonData["data"]!
            //invalid session
            if session != sessionID {
                self.callback(command:"verifySession", data: nil, errorMessage: "Invalid session", withSession: false)
                return
            }
            let dic = ["address": Authenticated.account!.address]
            self.callback(command:"verifySession", data: dic, errorMessage: nil, withSession: true)
            return
        }
        
        if  self.loggedIn == false {
            return
        }
        
        if command == "getPlatform" {
            self.callback(command:"getPlatform", data: ["platform": "ios", "version": Bundle.main.releaseVersionNumber ?? ""], errorMessage: nil, withSession: true)
        }  else if command == "getAccounts" {
            let neoAccount = ["address": Authenticated.account!.address,
                              "publicKey":Authenticated.account!.publicKeyString]
            let blockchains = ["neo": neoAccount]
            let dic = ["accounts": blockchains]
            self.callback(command:"getAccounts", data: dic,errorMessage: nil, withSession: true)
        } else if command == "isAppAvailable" {
            let dic = ["isAppAvailable": true]
            self.callback(command:"isAppAvailable", data: dic,errorMessage: nil, withSession: true)
        }  else if command == "requestToSign" {
            let unsignedRawTransaction =  jsonData["data"]!
            self.requestToSign(unsignedRawTransaction: unsignedRawTransaction)
        } else if command == "getDeviceInfo" {
            //TODO finish this with more info
            let dic = ["device": UIDevice.current.model]
            self.callback(command:"getDeviceInfo", data: dic, errorMessage: nil, withSession: true)
        }
    }
    
}

extension DAppBrowserViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
    }
}
