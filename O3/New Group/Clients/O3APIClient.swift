//
//  O3APIClient.swift
//  O3
//
//  Created by Apisit Toompakdee on 5/23/18.
//  Copyright © 2018 drei. All rights reserved.
//

import UIKit
import Neoutils

public enum O3APIClientError: Error {
    case invalidSeed, invalidBodyRequest, invalidData, invalidRequest, noInternet, invalidAddress

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
        case .invalidAddress:
            return "Invalid address"
        }

    }
}

public enum O3APIClientResult<T> {
    case success(T)
    case failure(O3APIClientError)
}

class O3APIClient: NSObject {

    public var apiBaseEndpoint = "https://platform.o3.network/api"
    public var network: Network = .main

    init(network: Network) {
        self.network = network
    }

    enum o3APIResource: String {
        case getBalances = "balances"
        case getUTXO = "utxo"
        case getClaims = "claimablegas"
        case getInbox = "inbox"
        case postTokenSaleLog = "tokensales"
    }

    func sendRESTAPIRequest(_ resourceEndpoint: String, data: Data?, requestType: String = "GET", completion :@escaping (O3APIClientResult<JSONDictionary>) -> Void) {

        var fullURL = apiBaseEndpoint + resourceEndpoint
        if network == .test {
            fullURL += "?network=test"
        } else if network == .privateNet {
            fullURL += "?network=private"
        }

        let request = NSMutableURLRequest(url: URL(string: fullURL)!)
        request.httpMethod = requestType
        request.timeoutInterval = 60
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpBody = data

        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, result, err) in
            print(result)
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

            let resultJson = O3APIClientResult.success(json!)
            completion(resultJson)
        }
        task.resume()
    }

    public func getUTXO(for address: String, completion: @escaping(O3APIClientResult<Assets>) -> Void) {
        let url = "/v1/neo/" + address + "/" + o3APIResource.getUTXO.rawValue
        sendRESTAPIRequest(url, data: nil) { result in
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

                let result = O3APIClientResult.success(assets)
                completion(result)
            }
        }
    }

    public func getClaims(address: String, completion: @escaping(O3APIClientResult<Claimable>) -> Void) {
        let url = "/v1/neo/" + address + "/" + o3APIResource.getClaims.rawValue
        sendRESTAPIRequest(url, data: nil) { result in
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

                let claimsResult = O3APIClientResult.success(claims)
                completion(claimsResult)
            }
        }
    }

    func getAccountState(address: String, completion: @escaping(O3APIClientResult<AccountState>) -> Void) {
        let url = "/v1/neo/" + address + "/" + o3APIResource.getBalances.rawValue
        sendRESTAPIRequest(url, data: nil) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                guard let dictionary = response["result"] as? JSONDictionary,
                    let data = try? JSONSerialization.data(withJSONObject: dictionary["data"] as Any, options: .prettyPrinted),
                    let accountState = try? decoder.decode(AccountState.self, from: data) else {
                        return
                }
                let balancesResult = O3APIClientResult.success(accountState)
                completion(balancesResult)
            }
        }
    }

    func getInbox(address: String, completion: @escaping(O3APIClientResult<Inbox>) -> Void) {
        let url = "/v1/inbox/" + address
        sendRESTAPIRequest(url, data: nil) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                guard let data = try? JSONSerialization.data(withJSONObject: response["result"] as Any, options: .prettyPrinted),
                    let decoded = try? decoder.decode(Inbox.self, from: data) else {
                        completion(.failure(.invalidData))
                        return
                }
                let success = O3APIClientResult.success(decoded)
                completion(success)
            }
        }
    }

    func getNodes(completion: @escaping(O3APIClientResult<Nodes>) -> Void) {
        let url = "/v1/nodes"
        sendRESTAPIRequest(url, data: nil) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                guard let dictionary = response["result"] as? JSONDictionary,
                    let data = try? JSONSerialization.data(withJSONObject: dictionary["data"] as Any, options: .prettyPrinted),
                    let decoded = try? decoder.decode(Nodes.self, from: data) else {
                        return
                }
                let success = O3APIClientResult.success(decoded)
                completion(success)
            }
        }
    }

    func checkVerifiedAddress(address: String, completion: @escaping(O3APIClientResult<VerifiedAddress>) -> Void) {
        let validAddress = NeoutilsValidateNEOAddress(address)
        if validAddress == false {
            completion(.failure(.invalidAddress))
            return
        }
        let url = "/v1/verification/" + address
        sendRESTAPIRequest(url, data: nil) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                guard let dictionary = response["result"] as? JSONDictionary,
                    let data = try? JSONSerialization.data(withJSONObject: dictionary["data"] as Any, options: .prettyPrinted),
                    let decoded = try? decoder.decode(VerifiedAddress.self, from: data) else {
                        return
                }
                let success = O3APIClientResult.success(decoded)
                completion(success)
            }
        }
    }

    func postTokenSaleLog(address: String, companyID: String, tokenSaleLog: TokenSaleLog,
                          completion: @escaping(O3APIClientResult<Bool>) -> Void) {
        let url = "/v1/neo/" + address + "/tokensales/" + companyID
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try? encoder.encode(tokenSaleLog)
        sendRESTAPIRequest(url, data: data!, requestType: "POST") { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                guard let dictionary = response["result"] as? JSONDictionary,
                    let data = try? JSONSerialization.data(withJSONObject: dictionary["data"] as Any, options: .prettyPrinted),
                    let decoded = try? decoder.decode(String.self, from: data) else {
                        return
                }
                let success = O3APIClientResult.success(true)
                completion(success)
            }
        }
    }
    
    func getTxHistory(address: String, pageIndex: Int, completion: @escaping(O3APIClientResult<TransactionHistory>) -> Void) {
        let url = String(format:"/v1/history/%@?p=%d", address, pageIndex)
        sendRESTAPIRequest(url, data: nil) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                guard let dictionary = response["result"] as? JSONDictionary,
                    let data = try? JSONSerialization.data(withJSONObject: dictionary["data"] as Any, options: .prettyPrinted),

                    let decoded = try? decoder.decode(TransactionHistory.self, from: data) else {
                        return
                }
                let success = O3APIClientResult.success(decoded)
                completion(success)
            }
        }
    }
    
    func tradingBalances(address: String, completion: @escaping(O3APIClientResult<TradingAccount>) -> Void) {
        let validAddress = NeoutilsValidateNEOAddress(address)
        if validAddress == false {
            completion(.failure(.invalidAddress))
            return
        }
        let url = "/v1/trading/" + address
        sendRESTAPIRequest(url, data: nil) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                guard let dictionary = response["result"] as? JSONDictionary,
                    let data = try? JSONSerialization.data(withJSONObject: dictionary["data"] as Any, options: .prettyPrinted),
                    let decoded = try? decoder.decode(TradingAccount.self, from: data) else {
                        return
                }
                let success = O3APIClientResult.success(decoded)
                completion(success)
            }
        }
    }
    
    func loadPricing(symbol: String, currency: String, completion: @escaping(O3APIClientResult<AssetPrice>) -> Void) {
        let url = String(format: "/v1/pricing/%@/%@", symbol, currency)
        sendRESTAPIRequest(url, data: nil) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                guard let dictionary = response["result"] as? JSONDictionary,
                    let data = try? JSONSerialization.data(withJSONObject: dictionary["data"] as Any, options: .prettyPrinted),
                    let decoded = try? decoder.decode(AssetPrice.self, from: data) else {
                        return
                }
                let success = O3APIClientResult.success(decoded)
                completion(success)
            }
        }
    }

}
