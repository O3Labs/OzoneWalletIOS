//
//  O3Client.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/17/17.
//  Copyright © 2017 drei. All rights reserved.
//

import UIKit

typealias JSONDictionary = [String: Any]

public enum O3ClientError: Error {
    case  invalidBodyRequest, invalidData, invalidRequest, noInternet

    var localizedDescription: String {
        switch self {
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

public enum O3ClientResult<T> {
    case success(T)
    case failure(O3ClientError)
}

public class O3Client {

    enum O3Endpoints: String {
        case getPriceHistory = "/v1/price/"
        case getPortfolioValue = "/v1/historical"
        case getAccountValue = "/v1/value"
        case getNewsFeed = "/v1/feed/"
        case getTokenSales = "https://platform.o3.network/api/v1/neo/tokensales"
        case getDapps = "/v1/dapps"
        case getExploreAssets = "/v1/assets"
    }

    enum HTTPMethod: String {
        case GET
        case POST
    }

    var baseURL = "https://api.o3.network"

    public static let shared = O3Client()

    func sendRequest(_ endpointURL: String, method: HTTPMethod, data: [String: Any?]?,
                     noBaseURL: Bool = false, completion: @escaping (O3ClientResult<JSONDictionary>) -> Void) {
        var urlString = ""
        if noBaseURL {
            urlString = endpointURL
        } else {
            urlString = baseURL + endpointURL
        }
        let url = URL(string: urlString)
        let request = NSMutableURLRequest(url: url!)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        if data != nil {
            guard let body = try? JSONSerialization.data(withJSONObject: data!, options: []) else {
                completion(.failure(.invalidBodyRequest))
                return
            }
            request.httpBody = body
        }

        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, _, err) in
            if err != nil {
                completion(.failure(.invalidRequest))
                return
            }

            guard let dataUnwrapped = data,
                let json = (try? JSONSerialization.jsonObject(with: dataUnwrapped, options: [])) as? JSONDictionary else {
                    completion(.failure(.invalidData))
                    return
            }

            if let code = json["code"] as? Int {
                if code != 200 {
                    completion(.failure(.invalidData))
                    return
                }
            }

            let result = O3ClientResult.success(json)
            completion(result)
        }
        task.resume()
    }

    func getPriceHistory(_ symbol: String, interval: String, completion: @escaping (O3ClientResult<History>) -> Void) {
        var endpoint = O3Endpoints.getPriceHistory.rawValue + symbol + String(format: "?i=%@", interval)
        endpoint += String(format: "&currency=%@", UserDefaultsManager.referenceFiatCurrency.rawValue)

        sendRequest(endpoint, method: .GET, data: nil) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                guard let result = response["result"] as? JSONDictionary,
                    let data = result["data"] as? JSONDictionary,
                    let responseData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted),
                    let block = try? decoder.decode(History.self, from: responseData) else {
                        completion(.failure(.invalidData))
                        return
                }

                let clientResult = O3ClientResult.success(block)
                completion(clientResult)
            }
        }
    }

    func getPortfolioValue(_ assets: [PortfolioAsset], interval: String, completion: @escaping (O3ClientResult<PortfolioValue>) -> Void) {

        var queryString = String(format: "?i=%@", interval)
        for asset in assets {
            queryString += String(format: "&%@=%@", asset.symbol, asset.value.description)
        }
        queryString += String(format: "&currency=%@", UserDefaultsManager.referenceFiatCurrency.rawValue)

        let endpoint = O3Endpoints.getPortfolioValue.rawValue + queryString
        print (endpoint)
        sendRequest(endpoint, method: .GET, data: nil) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                guard let result = response["result"] as? JSONDictionary,
                    let data = result["data"] as? JSONDictionary,
                    let responseData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted),
                    let block = try? decoder.decode(PortfolioValue.self, from: responseData) else {
                        completion(.failure(.invalidData))
                        return
                }

                let clientResult = O3ClientResult.success(block)
                completion(clientResult)
            }
        }
    }

    func getNewsFeed(completion: @escaping(O3ClientResult<FeedData>) -> Void) {
        let endpoint = O3Endpoints.getNewsFeed.rawValue
        sendRequest(endpoint, method: .GET, data: nil) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                guard let result = response["result"] as? JSONDictionary,
                    let data = result["data"] as? JSONDictionary,
                    let responseData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted),
                    let feedData = try? decoder.decode(FeedData.self, from: responseData) else {
                        completion(.failure(.invalidData))
                        return
                }

                let clientResult = O3ClientResult.success(feedData)
                completion(clientResult)
            }
        }
    }

    func getFeatures(completion: @escaping(O3ClientResult<FeatureFeed>) -> Void) {
        var endpoint = "https://platform.o3.network/api/v1/neo/news/featured"
        #if TESTNET
        endpoint = "https://platform.o3.network/api/v1/neo/news/featured?network=test"
        #endif
        #if PRIVATENET
        endpoint = "https://platform.o3.network/api/v1/neo/news/featured?network=private"
        #endif
        sendRequest(endpoint, method: .GET, data: nil, noBaseURL: true) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                let result = response["result"] as? JSONDictionary
                let responseData = result!["data"] as? JSONDictionary
                guard let data = try? JSONSerialization.data(withJSONObject: responseData!, options: .prettyPrinted),
                    let featureFeed = try? decoder.decode(FeatureFeed.self, from: data) else {
                        return
                }
                completion(.success(featureFeed))
            }
        }
    }

    func getAssetsForMarketPlace(completion: @escaping(O3ClientResult<[Asset]>) -> Void) {
        var endpoint = "https://api.o3.network/v1/marketplace"
        #if TESTNET
        endpoint = "https://api.o3.network/v1/marketplace?network=test"
        #endif
        #if PRIVATENET
        endpoint = "https://api.o3.network/v1/marketplace?network=private"
        #endif

        sendRequest(endpoint, method: .GET, data: nil, noBaseURL: true) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                let result = response["result"] as? JSONDictionary
                let responseData = result!["data"] as? JSONDictionary
                guard let data = try? JSONSerialization.data(withJSONObject: responseData!["assets"]!, options: .prettyPrinted),
                    let assetList = try? decoder.decode([Asset].self, from: data) else {
                        return
                }
                guard let nep5data = try? JSONSerialization.data(withJSONObject: responseData!["nep5"]!, options: .prettyPrinted),
                    let nep5list = try? decoder.decode([Asset].self, from: nep5data) else {
                        return
                }
                var combinedList: [Asset] = []
                for item in assetList {
                    combinedList.append(item)
                }
                for item in nep5list {
                    combinedList.append(item)
                }
                completion(.success(combinedList))
            }
        }
    }

    func getTokens(completion: @escaping(O3ClientResult<[NEP5Token]>) -> Void) {
        var endpoint = "https://platform.o3.network/api/v1/neo/nep5"
        #if TESTNET
        endpoint = "https://platform.o3.network/api/v1/neo/nep5?network=test"
        #endif
        #if PRIVATENET
        endpoint = "https://platform.o3.network/api/v1/neo/nep5?network=private"
        #endif

        sendRequest(endpoint, method: .GET, data: nil, noBaseURL: true) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                let result = response["result"] as? JSONDictionary
                let responseData = result!["data"] as? JSONDictionary
                guard let data = try? JSONSerialization.data(withJSONObject: responseData!["nep5tokens"]!, options: .prettyPrinted),
                    let list = try? decoder.decode([NEP5Token].self, from: data) else {
                        return
                }
                completion(.success(list))
            }
        }
    }

    func getTokenSales(address: String, completion: @escaping(O3ClientResult<TokenSales>) -> Void) {
        var endpoint = "https://platform.o3.network/api/v1/neo/" + address + "/tokensales"
        #if TESTNET
        endpoint = "https://platform.o3.network/api/v1/neo/" + address + "/tokensales?network=test"
        #endif
        #if PRIVATENET
        endpoint = "https://platform.o3.network/api/v1/neo/" + address + "/tokensales?network=private"
        #endif
        sendRequest(endpoint, method: .GET, data: nil, noBaseURL: true) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                guard let data = try? JSONSerialization.data(withJSONObject: response, options: .prettyPrinted),
                    let liveSales = try? decoder.decode(TokenSales.self, from: data) else {
                        return
                }
                completion(.success(liveSales))
            }
        }
    }

    func getUnboundOng(address: String, completion: @escaping(O3ClientResult<UnboundOng>) -> Void) {
        var endpoint = "https://platform.o3.network/api/v1/ont/" + address + "/unboundong"
        #if TESTNET
        endpoint = "https://platform.o3.network/api/v1/ont/" + address + "/unboundong?network=test"
        #endif
        #if PRIVATENET
        endpoint = "https://platform.o3.network/api/v1/ont/" + address + "/unboundong?network=private"
        #endif
        sendRequest(endpoint, method: .GET, data: nil, noBaseURL: true) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                let result = response["result"] as? JSONDictionary
                let responseData = result!["data"] as? JSONDictionary
                guard let data = try? JSONSerialization.data(withJSONObject: responseData!, options: .prettyPrinted),
                    let unboundong = try? decoder.decode(UnboundOng.self, from: data) else {
                        return
                }
                completion(.success(unboundong))
            }
        }
    }
    
    func getAccountValue(_ assets: [PortfolioAsset], completion: @escaping (O3ClientResult<AccountValue>) -> Void) {
        
        var queryString = String(format: "?currency=%@", UserDefaultsManager.referenceFiatCurrency.rawValue)
        for asset in assets {
            queryString += String(format: "&%@=%@", asset.symbol, asset.value.description)
        }
        
        let endpoint = O3Endpoints.getAccountValue.rawValue + queryString
        print (endpoint)
        sendRequest(endpoint, method: .GET, data: nil) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                guard let result = response["result"] as? JSONDictionary,
                    let data = result["data"] as? JSONDictionary,
                    let responseData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted),
                    let obj = try? decoder.decode(AccountValue.self, from: responseData) else {
                        completion(.failure(.invalidData))
                        return
                }
                
                let clientResult = O3ClientResult.success(obj)
                completion(clientResult)
            }
        }
    }
    
    func getDapps(completion: @escaping (O3ClientResult<[Dapps]>) -> Void){
        let endpoint = O3Endpoints.getDapps.rawValue
        sendRequest(endpoint, method: .GET, data: nil) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                let result = response["result"] as? JSONDictionary
                guard let data = try? JSONSerialization.data(withJSONObject: result!["data"]!, options: .prettyPrinted),
   
                    let dappsList = try? decoder.decode([Dapps].self, from: data) else {
                        completion(.failure(.invalidData))
                        return
                }

                let clientResult = O3ClientResult.success(dappsList)
                completion(clientResult)
            }
        }
    }
    
    func getExploreAssets(completion: @escaping (O3ClientResult<[ExploreAssets]>) -> Void){
         let endpoint = O3Endpoints.getExploreAssets.rawValue
         sendRequest(endpoint, method: .GET, data: nil) { result in
             switch result {
             case .failure(let error):
                 completion(.failure(error))
             case .success(let response):
                 let decoder = JSONDecoder()
                 let result = response["result"] as? JSONDictionary
                 let responseData = result!["data"] as? JSONDictionary
                 guard let data = try? JSONSerialization.data(withJSONObject: responseData!["assets"]!, options: .prettyPrinted),
                     let assetList = try? decoder.decode([ExploreAssets].self, from: data) else {
                         return
                 }

                 let clientResult = O3ClientResult.success(assetList)
                 completion(clientResult)
             }
         }
     }
    
}
