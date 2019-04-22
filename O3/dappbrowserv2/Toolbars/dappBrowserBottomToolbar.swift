//
//  dappBrowserBottomToolbar.swift
//  O3
//
//  Created by Andrei Terentiev on 4/9/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
extension dAppBrowserV2ViewController {
    func checkBackForwardButton() {
        DispatchQueue.main.async {
            self.backButton.isEnabled = self.webView.canGoBack
            self.forwardButton.isEnabled = self.webView.canGoForward
        }
    }
    
    func didTapBack(_ sender: Any) {
        if self.webView.canGoBack {
            self.webView.goBack()
        } else {
            return
        }
    }
    
    func didTapForward(_ sender: Any) {
        if self.webView.canGoForward {
            self.webView.goForward()
        } else {
            return
        }
    }
}
