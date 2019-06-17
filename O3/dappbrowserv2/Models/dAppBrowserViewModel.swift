//
//  DappViewModel.swift
//  O3
//
//  Created by Andrei Terentiev on 1/21/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import OpenGraph

class dAppBrowserViewModel: NSObject {
    
    var isConnected: Bool = false
    var connectedTime: Date?
    var url: URL!
    var delegate: dAppBrowserDelegate?
    var dappMetadata: dAppMetadata? = dAppMetadata()
    var selectedAccount: NEP6.Account?
    var unlockedWallet: Wallet?
    var assetSymbol: String? = nil
    var tradingAccount: TradingAccount? = nil
    var tradableAsset: TradableAsset? = nil
    
    func loadMetadata(){
        OpenGraph.fetch(url: url!) { og, error in
            self.dappMetadata?.url = self.url!
            self.dappMetadata?.title = og?[.title]
            self.dappMetadata?.iconURL = og?[.image]
            self.dappMetadata?.description = og?[.description]
        }
    }
    
    func requestToConnect(message: dAppMessage, didCancel: @escaping (_ message: dAppMessage) -> Void, didConfirm: @escaping (_ message: dAppMessage, _ wallet: Wallet, _ acount: NEP6.Account?) -> Void) {
        
        self.delegate?.onConnectRequest(url: self.url, message: message, didCancel: { m in
            didCancel(m)
        }, didConfirm: { m, wallet, account in
            self.isConnected = true
            self.connectedTime = Date()
            self.unlockedWallet = wallet
            self.selectedAccount = account
            didConfirm(m, wallet, account)
        })
    }
    
    func requestToSend(message: dAppMessage, request: dAppProtocol.SendRequest, didCancel: @escaping (_ message: dAppMessage,_ request: dAppProtocol.SendRequest) -> Void, onCompleted:@escaping (_ response: dAppProtocol.SendResponse?, _ error: dAppProtocol.errorResponse?) -> Void) {
        self.delegate?.onSendRequest(message: message, request: request, didCancel: didCancel, onCompleted: onCompleted)
    }
    
    func requestToInvoke(message: dAppMessage, request: dAppProtocol.InvokeRequest, didCancel: @escaping (_ message: dAppMessage,_ request: dAppProtocol.InvokeRequest) -> Void, onCompleted:@escaping (_ response: dAppProtocol.InvokeResponse?, _ error: dAppProtocol.errorResponse?) -> Void) {
        self.delegate?.onInvokeRequest(message: message, request: request, didCancel: didCancel, onCompleted: onCompleted)
    }
    
    func responseWithError(message: dAppMessage, error: String) {
        self.delegate?.error(message: message, error: error)
    }
    
    func processCoinbaseMessage(message: dAppMessage) {
        if message.command.lowercased() == "connect".lowercased() {
            handleCoinbaseConnect(message: message)
        }
    }
    
    func processPayMessage(message: dAppMessage) {
        if message.command == "send" {
            handleCoinbasePay(message: message)
        }
    }
    
    func processBlockchainMessage(message: dAppMessage) {
        if message.command.lowercased() == "getAccount".lowercased() {
            if unlockedWallet == nil {
                
                return
            }
            let response = dAppProtocol.GetAccountResponse(address: unlockedWallet!.address, publicKey: unlockedWallet!.publicKeyString)
            self.delegate?.didFinishMessage(message: message, response: response.dictionary)
            return
        }
        
        if message.command.lowercased() == "getProvider".lowercased() {
            var theme = "Light Mode"
            if UserDefaultsManager.theme == .dark {
                theme = "Dark Mode"
            }
            let response = dAppProtocol.GetProviderResponse(name: "o3", version: "v2", website: "https://o3.network", compatibility: ["NEP-dapi"], theme: theme)
            self.delegate?.didFinishMessage(message: message, response: response.dictionary)
            return
        }
        
        
        if message.command.lowercased() == "getNetworks".lowercased() {
            let response = dAppProtocol.GetNetworksResponse(networks: ["MainNet", "TestNet", "PrivateNet"])
            self.delegate?.didFinishMessage(message: message, response: response.dictionary)
            return
        }
        
        if message.command.lowercased() == "getBalance".lowercased() {
            //parse input
            let decoder = JSONDecoder()
            guard let dictionary =  message.data?.value as? JSONDictionary,
                let data = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted),
                let request = try? decoder.decode(dAppProtocol.RequestData<[dAppProtocol.GetBalanceRequest]>.self, from: data) else {
                    self.delegate?.error(message: message, error: "Unable to parse the request")
                    return
            }
            DispatchQueue.global().async {
                let response = O3DappAPI().getBalance(request: request)
                //it is very important to make the struct to dictionary otherwise JSONDecoder will throw and error invalid SwiftValue when trying to decode it
                self.delegate?.didFinishMessage(message: message, response: response.dictionary)
                
            }
            return
        }
        
        if message.command.lowercased() == "getStorage".lowercased() {
            let decoder = JSONDecoder()
            guard let dictionary =  message.data?.value as? JSONDictionary,
                let data = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted),
                let request = try? decoder.decode(dAppProtocol.GetStorageRequest.self, from: data) else {
                    self.delegate?.error(message: message, error: "Unable to parse the request")
                    return
            }
            let response = O3DappAPI().getStorage(request: request)
            self.delegate?.didFinishMessage(message: message, response: response.dictionary)
            return
        }
        
        if message.command.lowercased() == "invokeRead".lowercased() {
            let decoder = JSONDecoder()
            guard let dictionary =  message.data?.value as? JSONDictionary,
                let data = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted),
                let request = try? decoder.decode(dAppProtocol.InvokeReadRequest.self, from: data) else {
                    self.delegate?.error(message: message, error: "Unable to parse the request")
                    return
            }
            let response = O3DappAPI().invokeRead(request: request)
            self.delegate?.didFinishMessage(message: message, response: response)
            return
        }
        
        if message.command.lowercased() == "invoke".lowercased() {
            let decoder = JSONDecoder()
            guard let dictionary =  message.data?.value as? JSONDictionary,
                let data = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted),
                let request = try? decoder.decode(dAppProtocol.InvokeRequest.self, from: data) else {
                    self.delegate?.error(message: message, error: "Unable to parse the request")
                    return
            }
            self.requestToInvoke(message: message, request: request, didCancel: { m,r in
                self.delegate?.error(message: message, error: "USER_CANCELLED_INVOKE")
            }, onCompleted: { response, err in
                DispatchQueue.global().async {
                    if err == nil {
                        self.delegate?.didFinishMessage(message: message, response: response!.dictionary)
                    } else {
                        self.delegate?.error(message: message, error: err.debugDescription)
                    }
                }
            })
            return
        }
        
        if message.command.lowercased() == "send".lowercased() {
            let decoder = JSONDecoder()
            guard let dictionary =  message.data?.value as? JSONDictionary,
                let data = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted),
                var request = try? decoder.decode(dAppProtocol.SendRequest.self, from: data) else {
                    self.delegate?.error(message: message, error: "Unable to parse the request")
                    return
            }
            request.fromAddress = unlockedWallet!.address
            self.requestToSend(message: message, request: request, didCancel: { m,r in
                self.delegate?.error(message: message, error: "USER_CANCELLED_SEND")
            }, onCompleted: { response, err in
                DispatchQueue.global().async {
                    if err == nil {
                        self.delegate?.didFinishMessage(message: message, response: response!.dictionary)
                    } else {
                        self.delegate?.error(message: message, error: err.debugDescription)
                    }
                }
            })
            
            return
        }
        
        if message.command == "disconnect".lowercased() {
            unlockedWallet = nil
            selectedAccount = nil
            isConnected = false
            DispatchQueue.global().async {
                self.delegate?.didFireEvent(name: "DISCONNECTED")
                self.delegate?.didFinishMessage(message: message, response: JSONDictionary())
            }
        }
    }
    
    func proceedMessage(message: dAppMessage) {
        if message.blockchain == "COINBASE" {
            processCoinbaseMessage(message: message)
        } else if message.blockchain == "PAY" {
            processPayMessage(message: message)
        } else {
            processBlockchainMessage(message: message)
        }
    }
    
    func changeActiveAccount(account: NEP6.Account? ,wallet: Wallet) {
        self.unlockedWallet = wallet
        self.selectedAccount = account
        self.delegate?.onWalletChanged(newWallet: wallet)
    }
}
