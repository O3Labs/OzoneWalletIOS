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

    public static let sharedInstance = NEONetworkMonitor()

    public static func autoSelectBestNode(network: Network) -> String? {

        var bestNode = ""
        //load from https://platform.o3.network/api/v1/nodes instead
        let semaphore = DispatchSemaphore(value: 0)
        O3APIClient(network: network).getNodes { result in
            switch result {
            case .failure(let error):

                #if DEBUG
                print(error)
                #endif
                bestNode = ""
            case .success(let nodes):
                bestNode = nodes.neo.best
            }
            semaphore.signal()
        }
        semaphore.wait()
        return bestNode
    }

}

public class ONTNetworkMonitor {

    public static let sharedInstance = ONTNetworkMonitor()

    public static func autoSelectBestNode(network: Network) -> String? {
        var bestNode = ""
        let semaphore = DispatchSemaphore(value: 0)
        O3APIClient(network: network).getNodes { result in
            switch result {
            case .failure(let error):
                #if DEBUG
                print(error)
                #endif
                bestNode = ""

            case .success(let nodes):
                bestNode = nodes.ontology.best
            }
            semaphore.signal()
        }
        semaphore.wait()
        return bestNode
    }
}

public class NeoClient {

    public var seed = "http://seed3.o3node.org:10332"

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
    }

    enum NEP5Method: String {
        case balanceOf
        case decimal
        case symbol
    }

    public init(seed: String) {
        self.seed = seed
    }

    func sendJSONRPCRequest(_ method: RPCMethod, params: [Any]?, completion: @escaping (NeoClientResult<JSONDictionary>) -> Void) {
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

    public func sendRawTransaction(with data: Data, completion: @escaping(NeoClientResult<Bool>) -> Void) {
        sendJSONRPCRequest(.sendTransaction, params: [data.fullHexString]) { result in
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
        sendJSONRPCRequest(.getBlockCount, params: nil) { result in
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
        sendJSONRPCRequest(.getConnectionCount, params: nil) { result in
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
        sendJSONRPCRequest(.getAccountState, params: [address]) { result in
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
        sendJSONRPCRequest(.invokeContract, params: [script]) { result in
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
