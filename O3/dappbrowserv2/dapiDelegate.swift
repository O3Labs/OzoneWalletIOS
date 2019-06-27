//
//  dapiDelegate.swift
//  O3
//
//  Created by Andrei Terentiev on 4/9/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import PKHUD

extension dAppBrowserV2ViewController: dAppBrowserDelegate {
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
            print(jsonString)
            self.callback(jsonString: jsonString)
        }
    }
    
    func error(message: dAppMessage, error: String) {
        var dic = message.dictionary
        dic["error"] = error
        let jsonData = try? JSONSerialization.data(withJSONObject: dic, options: [])
        let jsonString = String(data: jsonData!, encoding: String.Encoding.utf8)!
        self.callback(jsonString: jsonString)
    }
    
    //events
    func onWalletChanged(newWallet: Wallet) {
        let response = dAppProtocol.GetAccountResponse(address: newWallet.address, publicKey: newWallet.publicKeyString)
        self.event(eventName: "ACCOUNT_CHANGED", data: response.dictionary)
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

    func onInvokeRequest(message: dAppMessage, request: dAppProtocol.InvokeRequest, didCancel: @escaping (_ message: dAppMessage, _ request: dAppProtocol.InvokeRequest) -> Void, onCompleted: @escaping (_ response: dAppProtocol.InvokeResponse?, _ error: dAppProtocol.errorResponse?) -> Void) {
        
        
        let nav = UIStoryboard(name: "dAppBrowser", bundle: nil).instantiateViewController(withIdentifier: "InvokeRequestTableViewControllerNav")
        self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: nav)
        nav.modalPresentationStyle = .custom
        nav.transitioningDelegate = self.halfModalTransitioningDelegate
        if let vc = nav.children.first as? InvokeRequestTableViewController {
            vc.url = self.viewModel.url
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
    
    func onSendRequest(message: dAppMessage, request: dAppProtocol.SendRequest, didCancel: @escaping (_ message: dAppMessage, _ request: dAppProtocol.SendRequest) -> Void, onCompleted: @escaping (_ response: dAppProtocol.SendResponse?, _ error: dAppProtocol.errorResponse?) -> Void) {
        
        
        let nav = UIStoryboard(name: "dAppBrowser", bundle: nil).instantiateViewController(withIdentifier: "SendRequestTableViewControllerNav")
        self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: nav)
        nav.modalPresentationStyle = .custom
        nav.transitioningDelegate = self.halfModalTransitioningDelegate
        if let vc = nav.children.first as? SendRequestTableViewController {
            vc.url = self.viewModel.url
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
    
    func onCoinbaseSendRequest(message: dAppMessage, request: dAppProtocol.CoinbaseSendRequest, didCancel: @escaping (dAppMessage, dAppProtocol.CoinbaseSendRequest) -> Void, onCompleted: @escaping (dAppProtocol.CoinbaseSendResponse?, dAppProtocol.errorResponse?) -> Void) {
        let nav = UIStoryboard(name: "dAppBrowser", bundle: nil).instantiateViewController(withIdentifier: "CoinbaseSendRequestTableViewControllerNav")
        self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: nav)
        nav.modalPresentationStyle = .custom
        nav.transitioningDelegate = self.halfModalTransitioningDelegate
        if let vc = nav.children.first as? CoinbaseSendRequestTableViewController {
            vc.url = self.viewModel.url
            vc.dappMetadata = self.viewModel.dappMetadata
            vc.request = request
            vc.message = message
            
            vc.onCompleted = { response, err in
                onCompleted(response,err)
            }
            
            vc.onCancel = { m, r in
                didCancel(m,r)
            }
        }
        self.present(nav, animated: true, completion: nil)
    }

}

