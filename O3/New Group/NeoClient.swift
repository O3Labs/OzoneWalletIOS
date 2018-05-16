//
//  NeoClient.swift
//  NeoSwift
//
//  Created by Andrei Terentiev on 8/19/17.
//  Copyright © 2017 drei. All rights reserved.
//

import Foundation
import Neoutils

public enum NeoClientError: Error {
    case invalidSeed, invalidBodyRequest, invalidData, invalidRequest, noInternet

    var localizedDescription: String {
        switch self {
        case .invalidSeed:
            return "Invalid seed"
        case .invalidBodyRequest:
            return "Invalid body Request"
        case .invalidData:
            return "Invalid response data"
        case .invalidRequest:
            return "Invalid server request"
        case .noInternet:
            return "No Internet connection"
        }
    }
}

public enum NeoClientResult<T> {
    case success(T)
    case failure(NeoClientError)
}

public enum Network: String {
    case test
    case main
    case privateNet
}

public class NEONetworkMonitor {
    private init() {
        self.network =  self.load()
    }
    public static let sharedInstance = NEONetworkMonitor()
    public var network: NEONetwork?

    private func load() -> NEONetwork? {
        guard let path = Bundle(for: type(of: self)).path(forResource: "nodes", ofType: "json") else {
            return nil
        }
        guard let fileData = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        let decoder = JSONDecoder()

        guard let json = try? JSONSerialization.jsonObject(with: fileData, options: []) as? JSONDictionary else {
            return nil
        }

        if json == nil {
            return nil
        }

        guard let data = try? JSONSerialization.data(withJSONObject: json!, options: []),
            let result = try? decoder.decode(NEONetwork.self, from: data) else {
                return nil
        }
        return result
    }

    public static func autoSelectBestNode() -> String? {
        let networks = NEONetworkMonitor().load()
        let nodes = networks?.mainNet.nodes.map({$0.URL}).joined(separator: ",")
        guard let bestNode =  NeoutilsSelectBestSeedNode(nodes) else {
            return nil
        }
        return bestNode.url()
    }

}

public class NeoClient {
    public var network: Network = .test
    public var seed = "http://seed3.o3node.org:10332"
    public var fullNodeAPI = "http://testnet-api.wallet.cityofzion.io/v2/"
    public static let sharedTest = NeoClient(network: .test)
    public static let sharedMain = NeoClient(network: .main)
    private init() {}
    private let tokenInfoCache = NSCache<NSString, AnyObject>()

    enum RPCMethod: String {
        case getBestBlockHash = "getbestblockhash"
        case getBlock = "getblock"
        case getBlockCount = "getblockcount"
        case getBlockHash = "getblockhash"
        case getConnectionCount = "getconnectioncount"
        case getTransaction = "getrawtransaction"
        case getTransactionOutput = "gettxout"
        case getUnconfirmedTransactions = "getrawmempool"
        case sendTransaction = "sendrawtransaction"
        case validateAddress = "validateaddress"
        case getAccountState = "getaccountstate"
        case getAssetState = "getassetstate"
        case getPeers = "getpeers"
        case invokeFunction = "invokefunction"
        case invokeContract = "invokescript"
        //The following routes can't be invoked by calling an RPC server
        //We must use the wrapper for the nodes made by COZ
        case getBalance = "getbalance"
    }

    enum NEP5Method: String {
        case balanceOf
        case decimal
        case symbol
    }

    enum apiURL: String {
        case getUTXO = "utxo"
        case getClaims = "claimablegas"
        case getTransactionHistory = "address/history/"
    }

    public init(seed: String) {
        self.seed = seed
    }

    public init(network: Network) {
        self.network = network
        switch self.network {
        case .test:
            fullNodeAPI = "http://testnet-api.wallet.cityofzion.io/v2/"
            seed = "http://test4.cityofzion.io:8880"
        case .main:
            fullNodeAPI = "https://platform.o3.network/api/v1/neo/"
            seed = "http://seed1.neo.org:10332"
        case .privateNet:
            fullNodeAPI = "http://127.0.0.1:5000/"
            seed = "http://localhost:30333"
        }
    }

    public init(network: Network, seedURL: String) {
        self.network = network
        switch self.network {
        case .test:
            fullNodeAPI = "http://testnet-api.wallet.cityofzion.io/v2/"
            seed = seedURL
        case .main:
            fullNodeAPI = "https://platform.o3.network/api/v1/neo/"
            seed = seedURL
        case .privateNet:
            fullNodeAPI = "http://127.0.0.1:5000/"
            seed = seedURL
        }

    }

    func sendRequest(_ method: RPCMethod, params: [Any]?, completion: @escaping (NeoClientResult<JSONDictionary>) -> Void) {
        guard let url = URL(string: seed) else {
            completion(.failure(.invalidSeed))
            return
        }

        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json-rpc", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let requestDictionary: [String: Any?] = [
            "jsonrpc": "2.0",
            "id": 2,
            "method": method.rawValue,
            "params": params ?? []
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: requestDictionary, options: []) else {
            completion(.failure(.invalidBodyRequest))
            return
        }
        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, _, err) in
            if err != nil {
                completion(.failure(.invalidRequest))
                return
            }

            if data == nil {
                completion(.failure(.invalidData))
                return
            }

            guard let json = try? JSONSerialization.jsonObject(with: data!, options: []) as? JSONDictionary else {
                completion(.failure(.invalidData))
                return
            }

            if json == nil {
                completion(.failure(.invalidData))
                return
            }

            let resultJson = NeoClientResult.success(json!)
            completion(resultJson)
        }
        task.resume()
    }

    func sendFullNodeRequest(_ url: String, params: [Any]?, completion :@escaping (NeoClientResult<JSONDictionary>) -> Void) {
        let request = NSMutableURLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        request.timeoutInterval = 60
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, _, err) in
            if err != nil {
                completion(.failure(.invalidRequest))
                return
            }

            if data == nil {
                completion(.failure(.invalidData))
                return
            }

            guard let json = try? JSONSerialization.jsonObject(with: data!, options: []) as? JSONDictionary else {
                completion(.failure(.invalidData))
                return
            }

            if json == nil {
                completion(.failure(.invalidData))
                return
            }

            if let code = json!["code"] as? Int {
                if code != 200 {
                    completion(.failure(.invalidData))
                    return
                }
            }

            let resultJson = NeoClientResult.success(json!)
            completion(resultJson)
        }
        task.resume()
    }

    public func getAssets(for address: String, params: [Any]?, completion: @escaping(NeoClientResult<Assets>) -> Void) {
        let url = fullNodeAPI + address + "/" + apiURL.getUTXO.rawValue
        sendFullNodeRequest(url, params: params) { result in

            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                guard let data = try? JSONSerialization.data(withJSONObject: response["result"] as Any, options: .prettyPrinted),
                    let assets = try? decoder.decode(Assets.self, from: data) else {
                        completion(.failure(.invalidData))
                        return
                }

                let result = NeoClientResult.success(assets)
                completion(result)
            }
        }
    }

    public func getClaims(address: String, completion: @escaping(NeoClientResult<Claimable>) -> Void) {
        let url = fullNodeAPI + address + "/" + apiURL.getClaims.rawValue
        sendFullNodeRequest(url, params: nil) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()

                guard let dictionary = response["result"] as? JSONDictionary,
                    let data = try? JSONSerialization.data(withJSONObject: dictionary["data"] as Any, options: .prettyPrinted),
                    let claims = try? decoder.decode(Claimable.self, from: data) else {
                        completion(.failure(.invalidData))
                        return
                }

                let claimsResult = NeoClientResult.success(claims)
                completion(claimsResult)
            }
        }
    }

    public func sendRawTransaction(with data: Data, completion: @escaping(NeoClientResult<Bool>) -> Void) {
        sendRequest(.sendTransaction, params: [data.fullHexString]) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                guard let success = response["result"] as? Bool else {
                    completion(.failure(.invalidData))
                    return
                }
                let result = NeoClientResult.success(success)
                completion(result)
            }
        }
    }

    public func getBlockCount(completion: @escaping (NeoClientResult<Int64>) -> Void) {
        sendRequest(.getBlockCount, params: nil) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                guard let count = response["result"] as? Int64 else {
                    completion(.failure(.invalidData))
                    return
                }

                let result = NeoClientResult.success(count)
                completion(result)
            }
        }
    }

    public func getConnectionCount(completion: @escaping (NeoClientResult<Int64>) -> Void) {
        sendRequest(.getConnectionCount, params: nil) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                guard let count = response["result"] as? Int64 else {
                    completion(.failure(.invalidData))
                    return
                }

                let result = NeoClientResult.success(count)
                completion(result)
            }
        }
    }

    public func getAccountState(for address: String, completion: @escaping(NeoClientResult<AccountState>) -> Void) {
        sendRequest(.getAccountState, params: [address]) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                guard let data = try? JSONSerialization.data(withJSONObject: (response["result"] as Any), options: .prettyPrinted),
                    let accountState = try? decoder.decode(AccountState.self, from: data) else {
                        completion(.failure(.invalidData))
                        return
                }

                let result = NeoClientResult.success(accountState)
                completion(result)
            }
        }
    }

    public func invokeContract(with script: String, completion: @escaping(NeoClientResult<ContractResult>) -> Void) {
        sendRequest(.invokeContract, params: [script]) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                if response["result"] == nil {
                    completion(.failure(NeoClientError.invalidData))
                    return
                }
                guard let data = try? JSONSerialization.data(withJSONObject: (response["result"] as? JSONDictionary) ?? [:], options: .prettyPrinted),
                    let contractResult = try? decoder.decode(ContractResult.self, from: data) else {
                        completion(.failure(.invalidData))
                        return
                }

                let result = NeoClientResult.success(contractResult)
                completion(result)
            }
        }
    }

    public func getTokenInfo(with scriptHash: String, completion: @escaping(NeoClientResult<NEP5TokenContract>) -> Void) {
        let cacheKey: NSString = scriptHash as NSString
        if let tokenInfo = tokenInfoCache.object(forKey: cacheKey) as? NEP5TokenContract {
            completion(.success(tokenInfo))
            return
        }
        let scriptBuilder = ScriptBuilder()
        scriptBuilder.pushContractInvoke(scriptHash: scriptHash, operation: "name")
        scriptBuilder.pushContractInvoke(scriptHash: scriptHash, operation: "symbol")
        scriptBuilder.pushContractInvoke(scriptHash: scriptHash, operation: "decimals")
        scriptBuilder.pushContractInvoke(scriptHash: scriptHash, operation: "totalSupply")
        invokeContract(with: scriptBuilder.rawHexString) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let contractResult):
                guard let token = NEP5TokenContract(from: contractResult.stack) else {
                    completion(.failure(.invalidData))
                    return
                }
                self.tokenInfoCache.setObject(token as AnyObject, forKey: cacheKey)
                completion(.success(token))
            }
        }
    }

    public func getTokenBalance(_ scriptHash: String, address: String, completion: @escaping(NeoClientResult<Double>) -> Void) {
        let scriptBuilder = ScriptBuilder()
        let cacheKey: NSString = scriptHash as NSString
        guard let tokenInfo = tokenInfoCache.object(forKey: cacheKey) as? NEP5TokenContract else {
            //Token info not in cache then fetch it.
            self.getTokenInfo(with: scriptHash, completion: { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success:
                    self.getTokenBalance(scriptHash, address: address, completion: completion)
                    return
                }
            })
            return
        }

        scriptBuilder.pushContractInvoke(scriptHash: scriptHash, operation: "balanceOf", args: [address.hashFromAddress()])
        self.invokeContract(with: scriptBuilder.rawHexString) { contractResult in
            switch contractResult {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                #if DEBUG
                print(response)
                #endif
                let balanceData = response.stack[0].hexDataValue ?? ""
                if balanceData == "" {
                    completion(.success(0))
                    return
                }

                let balance = Double(balanceData.littleEndianHexToUInt)
                let divider = pow(Double(10), Double(tokenInfo.decimals))
                let amount = balance / divider
                completion(.success(amount))
            }
        }
    }

    public func getTokenBalanceUInt(_ scriptHash: String, address: String, completion: @escaping(NeoClientResult<UInt>) -> Void) {
        let scriptBuilder = ScriptBuilder()

        scriptBuilder.pushContractInvoke(scriptHash: scriptHash, operation: "balanceOf", args: [address.hashFromAddress()])
        self.invokeContract(with: scriptBuilder.rawHexString) { contractResult in
            switch contractResult {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                #if DEBUG
                print(response)
                #endif
                let balanceData = response.stack[0].hexDataValue ?? ""
                if balanceData == "" {
                    completion(.success(0))
                    return
                }
                let balance = balanceData.littleEndianHexToUInt
                completion(.success(balance))
            }
        }
    }

    public func getTokenSaleStatus(for address: String, scriptHash: String, completion: @escaping(NeoClientResult<Bool>) -> Void) {
        let scriptBuilder = ScriptBuilder()
        scriptBuilder.pushContractInvoke(scriptHash: scriptHash, operation: "kycStatus", args: [address.hashFromAddress()])
        self.invokeContract(with: scriptBuilder.rawHexString) { contractResult in
            switch contractResult {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                #if DEBUG
                print(response)
                #endif
                let whitelisted = response.stack[0].hexDataValue
                if whitelisted == "" {
                    completion(.success(false))
                    return
                }
                if whitelisted == "01" {
                    completion(.success(true))
                    return
                }
                completion(.success(false))
            }
        }
    }
}
