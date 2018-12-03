//
//  dAppProtocol.swift
//  O3
//
//  Created by Apisit Toompakdee on 11/20/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

extension Encodable {
    subscript(key: String) -> Any? {
        return dictionary[key]
    }
    
    var dictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
    }
}

class dAppProtocol: NSObject {
    
    static let availableCommands: [String] = ["getProvider",
                                              "getNetworks",
                                              "getAccount",
                                              "getBalance",
                                              "getStorage",
                                              "invokeRead",
                                              "invoke",
                                              "send"]
    
    static let needAuthorizationCommands: [String] = ["getAccount", "getAddress", "invoke", "send"]
    
    struct RequestData<T: Codable>: Codable {
        let network: String
        let params: T?
    }
    
    struct GetProviderResponse: Codable {
        let compatibility: [String]
        let name: String
        let version: String
        let website: String
        
        enum CodingKeys: String, CodingKey {
            case compatibility = "platform"
            case name = "name"
            case version = "version"
            case website = "website"
        }
        
        init(name: String, version: String, website: String, compatibility: [String]) {
            self.name = name
            self.version = version
            self.website = website
            self.compatibility = compatibility
        }
    }
    
//    typealias GetNetworksResponse = [String]
    struct GetNetworksResponse: Codable {
        let networks: [String]
        enum CodingKeys: String, CodingKey {
            case networks = "networks"
        }
        
        init(networks: [String]) {
            self.networks = networks
        }
    }
    
    struct GetAccountResponse: Codable {
        let address: String
        let publicKey: String
        
        enum CodingKeys: String, CodingKey {
            case address = "address"
            case publicKey = "publicKey"
        }
        
        init(address: String, publicKey: String) {
            self.address = address
            self.publicKey = publicKey
        }
    }
    
    struct GetBalanceRequest: Codable {
        let address: String
        let assets: [String]?
        let fetchUTXO: Bool? = false
        
        enum CodingKeys: String, CodingKey {
            case address = "address"
            case assets = "assets"
            case fetchUTXO = "fetchUTXO"
        }
    }
    
    typealias GetBalanceResponse = [String: [GetBalanceResponseElement]]
   
    struct GetBalanceResponseElement: Codable {
        let amount, scriptHash, symbol: String
        let unspent: [Unspent]?
        
        init(amount: String, scriptHash: String, symbol: String, unspent: [Unspent]?) {
            self.amount = amount
            self.scriptHash = scriptHash
            self.symbol = symbol
            self.unspent = unspent
        }
    }
    
    struct Unspent: Codable {
        let n: Int
        let txid, value: String
        
        init(n: Int, txid: String, value: String) {
            self.n = n
            self.txid = txid
            self.value = value
        }
    }
    
    
    struct GetStorageRequest: Codable {
        let scriptHash: String
        let key: String
        let network: String?
        
    }
    
    struct GetStorageResponse: Codable {
        let result: String
        enum CodingKeys: String, CodingKey {
            case result = "result"
        }
    }
    
    struct InvokeReadRequest: Codable {
        let operation, scriptHash: String
        let args: [Arg]
        let network: String
    }
    
    struct Arg: Codable {
        let type, value: String
    }
    
    typealias InvokeReadResponse = JSONDictionary

    
    struct InvokeRequest: Codable {
        let operation, scriptHash: String
        let assetIntentOverrides: AssetIntentOverrides?
        let attachedAssets: AttachedAssets?
        let triggerContractVerification: Bool
        let fee: String
        let args: [Arg]?
        let network: String
        
        enum CodingKeys: String, CodingKey {
            case operation = "operation"
            case scriptHash = "scriptHash"
            case assetIntentOverrides = "assetIntentOverrides"
            case attachedAssets = "attachedAssets"
            case triggerContractVerification = "triggerContractVerification"
            case fee = "fee"
            case args = "args"
            case network = "network"
        }
        
        init(operation: String, scriptHash: String, assetIntentOverrides: AssetIntentOverrides?, attachedAssets: AttachedAssets?, triggerContractVerification: Bool, fee: String, args: [Arg]?, network: String) {
            self.operation = operation
            self.scriptHash = scriptHash
            self.assetIntentOverrides = assetIntentOverrides
            self.attachedAssets = attachedAssets
            self.triggerContractVerification = triggerContractVerification
            self.fee = fee
            self.args = args
            self.network = network
        }
        //this is here to validate type. sometime developers could send in a wrong type. e.g. args:"" and Swift won't parse it properly and throw an error
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let operation: String = try container.decode(String.self, forKey: .operation)
            let scriptHash: String = try container.decode(String.self, forKey: .scriptHash)
            let assetIntentOverrides: AssetIntentOverrides? = try? container.decode(AssetIntentOverrides.self, forKey: .assetIntentOverrides)
            let attachedAssets: AttachedAssets? = try? container.decode(AttachedAssets.self, forKey: .attachedAssets)
            let triggerContractVerification: Bool = try container.decode(Bool.self, forKey: .triggerContractVerification)
            let fee: String = try container.decode(String.self, forKey: .fee)
            let args: [Arg]? = try? container.decode([Arg].self, forKey: .args)
            let network: String = try container.decode(String.self, forKey: .network)
            
            self.init(operation: operation, scriptHash: scriptHash, assetIntentOverrides: assetIntentOverrides, attachedAssets: attachedAssets, triggerContractVerification: triggerContractVerification, fee: fee, args: args, network: network)
        }
        
        struct AssetIntentOverrides: Codable {
            let inputs: [Input]
            let outputs: [Output]
        }
        
        struct Input: Codable {
            let txid: String
            let index: Int
        }
        
        struct Output: Codable {
            let asset, address, value: String
        }

        struct AttachedAssets: Codable {
            let gas: Int?
            let neo: Int?
            
            enum CodingKeys: String, CodingKey {
                case gas = "GAS"
                case neo = "NEO"
            }
        }
        
        
    }
    
    struct InvokeResponse: Codable {
        let txid: String
        let nodeUrl: String
        
        init(txid: String, nodeUrl: String) {
            self.txid = txid
            self.nodeUrl = nodeUrl
        }
    }
    
    struct SendRequest: Codable {
        let amount, toAddress: String
        var fromAddress: String?
        let network, asset: String
        let remark: String?
        let fee: String?
    }

    struct SendResponse: Codable {
        let txid: String
        let nodeUrl: String
        
        init(txid: String, nodeUrl: String) {
            self.txid = txid
            self.nodeUrl = nodeUrl
        }
    }
    
    struct errorResponse: Codable {
        let error: String
    }
    
    
}


class O3DappAPI {
    
    func getStorage(request: dAppProtocol.GetStorageRequest) -> dAppProtocol.GetStorageResponse {
        let network = request.network!.lowercased().contains("test") ? Network.test : Network.main
        var node = AppState.bestSeedNodeURL
        if let bestNode = NEONetworkMonitor.autoSelectBestNode(network: network) {
            node = bestNode
        }
        
        var response = ""
        let requestGroup = DispatchGroup()
        requestGroup.enter()
        NeoClient(seed: node).getStorage(scriptHash: request.scriptHash, key: request.key) { result in
            switch result {
            case .failure(_):
                response = ""
                requestGroup.leave()
            case .success(let storageValue):
                response = storageValue
                requestGroup.leave()
            }
        }
        requestGroup.wait()
        return dAppProtocol.GetStorageResponse(result: response)
    }
    
    func invokeRead(request: dAppProtocol.InvokeReadRequest) -> dAppProtocol.InvokeReadResponse? {
        
        let network = request.network.lowercased().contains("test") ? Network.test : Network.main
        var node = AppState.bestSeedNodeURL
        if let bestNode = NEONetworkMonitor.autoSelectBestNode(network: network) {
            node = bestNode
        }
        
        var response: NeoClient.InvokeFunctionResult?

        var args: [[String: String]] = []
        for a in request.args {
            args.append(["type": a.type, "value": a.value])
        }
        let requestGroup = DispatchGroup()
        requestGroup.enter()
        NeoClient(seed: node).invokeFunction(scriptHash: request.scriptHash, operation: request.operation, arguments: args) { result in
            switch result {
            case .failure(_):
                requestGroup.leave()
            case .success(let requestResult):
                response = requestResult
                requestGroup.leave()
            }
        }
        requestGroup.wait()
        return response.dictionary as JSONDictionary
    }
    
    func invoke(request: dAppProtocol.InvokeRequest) -> dAppProtocol.InvokeResponse {
        return dAppProtocol.InvokeResponse(txid: "implement this", nodeUrl: "https://o3.network")
    }
    
    func send(wallet: Wallet, request: dAppProtocol.SendRequest) -> (dAppProtocol.SendResponse?, dAppProtocol.errorResponse?) {
        let isNative = request.asset.lowercased() == "neo" || request.asset.lowercased() == "gas"
        let network = request.network.lowercased().contains("test") ? Network.test : Network.main
        var node = AppState.bestSeedNodeURL
        if let bestNode = NEONetworkMonitor.autoSelectBestNode(network: network) {
            node = bestNode
        }
        let requestGroup = DispatchGroup()
        requestGroup.enter()
        
        var response: dAppProtocol.SendResponse?
        var error: dAppProtocol.errorResponse?
        if isNative {
            let assetID = request.asset.lowercased() == "neo" ? AssetId.neoAssetId : AssetId.gasAssetId
            let fm = NumberFormatter()
            let amountNumber = fm.number(from: request.amount)
            let feeNumber = fm.number(from: request.fee ?? "0")
            //TODO validation
            //check balance
            var attributes:[TransactionAttritbute] = []
            if request.remark != nil {
                attributes.append(TransactionAttritbute(remark: request.remark!))
            }
            wallet.sendAssetTransaction(network: network, seedURL: node, asset: assetID, amount: amountNumber!.doubleValue, toAddress: request.toAddress, attributes: attributes, fee: feeNumber!.doubleValue) { txID, err in
                if err != nil {
                    error = dAppProtocol.errorResponse(error: err.debugDescription)
                    requestGroup.leave()
                    return
                }
                response = dAppProtocol.SendResponse(txid: txID!, nodeUrl: node)
                requestGroup.leave()
                return
            }
        }
        
        requestGroup.wait()
        return (response, error)
    }
    
    
    func getBalance(request: dAppProtocol.RequestData<[dAppProtocol.GetBalanceRequest]>) -> dAppProtocol.GetBalanceResponse {
        
        
        var addressList: [String: [String]] = [:]
        for p in request.params! {
            addressList[p.address] = p.assets
        }
        
        var response: dAppProtocol.GetBalanceResponse = [:]
        
        let fetchBalanceGroup = DispatchGroup()
        let fetchUTXOgroup = DispatchGroup()
        
        //prepare utxo first
        var addressUTXO: [String:Assets] = [:]
        for a in addressList{
            fetchUTXOgroup.enter()
            
            //try to get cache object here
            let cacheKey = (a.key + request.network + "utxo") as NSString
            let cachedBalanced = O3Cache.memoryCache.object(forKey:cacheKey)
            if cachedBalanced != nil { //if we found cache then asset to it and leave the group then tell the loop to continue
                addressUTXO[a.key] = cachedBalanced as! Assets
                fetchUTXOgroup.leave()
                continue
            }
            
            let o3client = O3APIClient(network: request.network.lowercased().contains("test") ? Network.test : Network.main)
            DispatchQueue.global().async {
                o3client.getUTXO(for: a.key, completion: { result in
                    switch result {
                    case .failure:
                        fetchUTXOgroup.leave()
                        return
                    case .success(let utxo):
                        addressUTXO[a.key] = utxo
                        fetchUTXOgroup.leave()
                        O3Cache.memoryCache.setObject(addressUTXO[a.key]! as AnyObject, forKey: cacheKey)
                    }
                })
            }
        }
        fetchUTXOgroup.wait()
        
        for a in addressList{
            fetchBalanceGroup.enter()
            //try to get cache object here
            let cacheKey = (a.key + request.network) as NSString
            let cachedBalanced = O3Cache.memoryCache.object(forKey:cacheKey)
            if cachedBalanced != nil {
                //if we found cache then asset to it and leave the group then tell the loop to continue
                response[a.key] = cachedBalanced as! [dAppProtocol.GetBalanceResponseElement]
                fetchBalanceGroup.leave()
                continue
            }
            
            response[a.key] = []
            let o3client = O3APIClient(network: request.network.lowercased().contains("test") ? Network.test : Network.main, useCache: false)
            DispatchQueue.global().async {
                
                o3client.getAccountState(address: a.key) { result in
                    switch result {
                    case .failure:
                        fetchBalanceGroup.leave()
                        return
                    case .success(let accountState):
                        for t in accountState.assets {
                            var unspent: [dAppProtocol.Unspent] = []
                            let utxo = t.symbol.lowercased() == "neo" ? addressUTXO[a.key]?.getSortedNEOUTXOs() : addressUTXO[a.key]?.getSortedGASUTXOs()
                            if utxo != nil {
                                for u in utxo! {
                                    let unspentTx = dAppProtocol.Unspent(n: u.index, txid: u.txid, value: NSDecimalNumber(decimal: u.value).stringValue)
                                    unspent.append(unspentTx)
                                }
                            }
                            let amount = t.value.formattedStringWithoutSeparator(t.decimals, removeTrailing: true)
                            let element = dAppProtocol.GetBalanceResponseElement(amount: amount, scriptHash: t.id, symbol: t.symbol, unspent: unspent)
                            response[a.key]?.append(element)
                        }
                        for t in accountState.nep5Tokens {
                            let amount = t.value.formattedStringWithoutSeparator(t.decimals, removeTrailing: true)
                            let element = dAppProtocol.GetBalanceResponseElement(amount: amount, scriptHash: t.id, symbol: t.symbol, unspent: nil)
                            response[a.key]?.append(element)
                        }
                        O3Cache.memoryCache.setObject(response[a.key]! as AnyObject, forKey: cacheKey)
                        fetchBalanceGroup.leave()
                    }
                }
            }
        }
        
        fetchBalanceGroup.wait()
        return response
    }
}
