//
//  TransactionWebViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 10/1/17.
//  Copyright © 2017 drei. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class TransactionWebViewController: UIViewController, WKUIDelegate {
    
    var webView: WKWebView!
    var transaction: TransactionHistoryItem!

    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        self.view = self.webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        var urlString = ""
        if transaction.blockchain == "neo" {
            if AppState.network == .test {
                urlString = "https://testnet-explorer.o3.network/transactions/" + transaction.txid
            } else {
                urlString = "https://explorer.o3.network/transactions/" + transaction.txid
            }
        } else if transaction.blockchain == "ontology" {
            if AppState.network == .test {
                 urlString = "https://explorer.ont.io/transaction/" + transaction.txid + "/testnet"
            } else {
                urlString = "https://explorer.ont.io/transaction/" + transaction.txid
            }
        }

        let myURL = URL(string: urlString)
        let myRequest = URLRequest(url: myURL!)
        self.webView.load(myRequest)
    }
}
