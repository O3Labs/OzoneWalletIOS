//
//  DAppBrowserViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 6/20/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import WebKit

class DAppBrowserViewController: UIViewController {

    @IBOutlet var containerView: UIView? = nil
    var webView: WKWebView?

    override func loadView() {
        super.loadView()
        
        let contentController = WKUserContentController()
        contentController.add(self, name: "callbackHandler")
        contentController.add(self, name: "o3Address")
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        self.webView = WKWebView( frame: self.containerView!.bounds, configuration: config)
        self.view = self.webView
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = URL(string: "http://localhost:8000/")
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
    
    func getLoggedInAddress(){
        let dict = [
            "address": Authenticated.account?.address
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: [])
        let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)!
        
        // Send the location update to the page
        self.webView?.evaluateJavaScript("o3(\(jsonString))") { result, error in
            guard error == nil else {
                print(error)
                return
            }
        }
    }

}

extension DAppBrowserViewController: WKScriptMessageHandler {
    
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if (message.name == "callbackHandler"){
            print("\(message.body)")
            let messageString = message.body
            DispatchQueue.main.async {
                OzoneAlert.alertDialog(message: messageString as! String, dismissTitle: "OK", didDismiss: {})
            }
        } else if (message.name == "o3Address"){
            DispatchQueue.main.async {
                self.getLoggedInAddress()
            }
        }
    }
    
}

extension DAppBrowserViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.getLoggedInAddress()
    }
}
