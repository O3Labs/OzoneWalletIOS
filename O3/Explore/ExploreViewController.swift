//
//  ExploreViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 7/2/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class ExploreViewController: UIViewController, WKNavigationDelegate{
    @IBOutlet weak var webView: WKWebView!
    var urlString = "https://staging.o3.app"
    let currtime = Date().timeIntervalSince1970
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.load(URLRequest(url: URL(string: urlString)!))
        webView.navigationDelegate = self
    }
    
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == WKNavigationType.linkActivated {
            Controller().openDappBrowserV2(url: navigationAction.request.url!)
            decisionHandler(WKNavigationActionPolicy.cancel)
            return
        }
        decisionHandler(WKNavigationActionPolicy.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print(Date().timeIntervalSince1970 - currtime)
    }
}
