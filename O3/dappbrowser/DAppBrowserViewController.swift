//
//  DAppBrowserViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 6/20/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import WebKit

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
    let availableMethods = ["isAvailableHandler", "platformHandler", "getAccountsHandler", "getPublicKeyHandler", "initHandler", "connectHandler", "sendMessageHandler"]
    
    override func loadView() {
        super.loadView()
        
        //This is a list of available methods that web page can call O3 app
        let contentController = WKUserContentController()
        for method in availableMethods {
            contentController.add(self, name: method)
        }
    
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        self.webView = WKWebView( frame: self.containerView!.bounds, configuration: config)
        self.view = self.webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = URL(string: "http://localhost:8000/example/")
        let req = URLRequest(url: url!)
        self.webView!.load(req)
        self.webView?.navigationDelegate = self
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refresh(_:)))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func refresh(_ sender: Any) {
        self.webView?.reload()
    }
    
    func callback(event: String, dictionary: [String: Any]) {
        let dic: [String: Any] = [
        "event":event,
        "data":dictionary
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: dic, options: [])
        let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)!
        // Send the location update to the page
        self.webView?.evaluateJavaScript("o3.callback(\(jsonString))") { result, error in
            guard error == nil else {
                return
            }
        }
    }

}

extension DAppBrowserViewController: WKScriptMessageHandler {
    
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
//        if !availableMethods.contains(message.name) {
//            return
//        }
        if (message.name == "sendMessageHandler"){
            let jsonData = message.body as! [String: String]
//            let data = messageString.data(using: .utf8)
//
//            let jsonData = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: String]
            
            if jsonData["command"] == "init" {
                self.callback(event: "init", dictionary: [:])
            } else if jsonData["command"] == "platform" {
                self.callback(event: "platform", dictionary: ["platform": "ios", "version": Bundle.main.releaseVersionNumber])
            }
            
           
        }
        if (message.name == "initHandler"){
            self.callbackMethodName = message.body as! String
        }else  if (message.name == "connectHandler"){
            let appName = message.body as! String
            let message = String(format:"%@ want to connect to your O3 app. Allow?", appName)
            OzoneAlert.confirmDialog(message: message, cancelTitle: "Cancel", confirmTitle: "Allow", didCancel: {
                
            }) {
                self.callback(event: "connect", dictionary: ["address": Authenticated.account!.address])
            }
        } else if (message.name == "platformHandler"){
            self.callback(event: "platform", dictionary: ["platform": "ios", "version": Bundle.main.releaseVersionNumber])
        } else if (message.name == "getAccountsHandler"){
            let account = ["address": Authenticated.account!.address]
            let dic = ["accounts": [account]]
            self.callback(event: "accounts", dictionary: dic)
        } else if (message.name == "isAvailableHandler"){
            let dic = ["available": true]
            self.callback(event: "is_o3_available", dictionary: dic)
        }
        
    }
    
}

extension DAppBrowserViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
     
    }
}
