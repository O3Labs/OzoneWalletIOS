//
//  CoinbaseClient.swift
//  O3
//
//  Created by Andrei Terentiev on 6/12/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation

public enum CoinbaseClientResult<T> {
    case success(T)
    case failure(CoinbaseClientError)
}
struct CoinbaseTokenResponse {
    var access_token: String
    var token_type: String
    var expires_in: String
    var refresh_token: String
    var scope: String
    var created_at: String
}

public enum CoinbaseClientError: Error {
    case invalidBodyRequest, invalidData, invalidRequest
    
    var localizedDescription: String {
        switch self {
        case .invalidBodyRequest:
            return "Invalid body Request"
        case .invalidData:
            return "Invalid response data"
        case .invalidRequest:
            return "Invalid server request"
        }
    }
}


class CoinbaseClient {
    static let shared: CoinbaseClient! = CoinbaseClient()
    static let CB_VERSION = "2019-04-23"
    
    enum HTTPMethod: String {
        case GET
        case POST
    }
    
    func sendRequest(_ endpointURL: String, method: HTTPMethod, data: [String: Any?]?,
                      completion: @escaping (CoinbaseClientResult<JSONDictionary>) -> Void) {
        
        let url = URL(string: endpointURL)
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
            
            let result = CoinbaseClientResult.success(json)
            completion(result)
        }
        task.resume()
    }

    func getToken(code: String, completion: @escaping (CoinbaseClientResult<CoinbaseTokenResponse>) -> Void) {
        let grant_type = "authorization_code"
        let queryString = "?grant_type=\(grant_type)&data=\(code)"
        let url = "https://coinbase-oauth.o3.app/\(queryString)"

        sendRequest(url, method: .GET, data: [:]) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
            }
        }
    }
        
    func refreshToken(completion: @escaping (CoinbaseClientResult<CoinbaseTokenResponse>) -> Void) {
        let grant_type = "refresh_token"
        let token = ExternalAccounts.getFromFileSystem()!!.getCoinbaseToken()
        let queryString = "?grant_type=\(grant_type)&data=\(token)"
        let url = "https://coinbase-oauth.o3.app/\(queryString)"
        
        sendRequest(url, method: .GET, data: [:]) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
            }
        }
    }
    
    private func getUserWithToken() {}
    func getUser() {}
}
