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
import Lottie

class ExploreViewController: UIViewController, WKNavigationDelegate{
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var animationContainer: UIView!
    
    
    var urlString = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadURL()
        webView.navigationDelegate = self
        setThemedElements()
        let neoLoaderView = LOTAnimationView(name: "loader_portfolio")
        neoLoaderView.loopAnimation = true
        neoLoaderView.play()
        animationContainer.embed(neoLoaderView)
    }
    
    func loadURL() {
        webView.load(URLRequest(url: URL(string: urlString)!))
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == WKNavigationType.linkActivated {
            if navigationAction.request.url?.absoluteString.contains("switcheo.exchange") ?? false || navigationAction.request.url?.absoluteString.contains("nel.group") ?? false {
                Controller().openDappBrowser(url: navigationAction.request.url!, modal: true)
            } else {
                Controller().openDappBrowserV2(url: navigationAction.request.url!)
            }
            
            
            decisionHandler(WKNavigationActionPolicy.cancel)
            return
        }
        decisionHandler(WKNavigationActionPolicy.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        animationContainer.isHidden = true
    }
    
    func setThemedElements() {
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear

    }
}
