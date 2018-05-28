//
//  O3APIClient.swift
//  O3
//
//  Created by Apisit Toompakdee on 5/23/18.
//  Copyright © 2018 drei. All rights reserved.
//

import UIKit

public enum O3APIClientError: Error {
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
    }

    func sendRESTAPIRequest(_ resourceEndpoint: String, params: [Any]?, completion :@escaping (O3APIClientResult<JSONDictionary>) -> Void) {

        var fullURL = apiBaseEndpoint + resourceEndpoint
        if network == .test {
            fullURL += "?network=test"
        } else if network == .privateNet {
            fullURL += "?network=private"
        }

        let request = NSMutableURLRequest(url: URL(string: fullURL)!)
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

            let resultJson = O3APIClientResult.success(json!)
            completion(resultJson)
        }
        task.resume()
    }

    public func getUTXO(for address: String, params: [Any]?, completion: @escaping(O3APIClientResult<Assets>) -> Void) {
        let url = "/v1/neo/" + address + "/" + o3APIResource.getUTXO.rawValue
        sendRESTAPIRequest(url, params: params) { result in
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
        sendRESTAPIRequest(url, params: nil) { result in
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
        sendRESTAPIRequest(url, params: nil) { result in
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

}
