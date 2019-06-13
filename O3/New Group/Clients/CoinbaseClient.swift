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
struct CoinbaseTokenResponse: Codable {
    var access_token: String
    var token_type: String
    var expires_in: Int
    var refresh_token: String
    var scope: String
    var created_at: Int
    
    private enum CodingKeys: String, CodingKey {
        case access_token
        case token_type
        case expires_in
        case refresh_token
        case scope
        case created_at
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        access_token = try container.decode(String.self, forKey: .access_token)
        token_type = try container.decode(String.self, forKey: .token_type)
        expires_in = try container.decode(Int.self, forKey: .expires_in)
        refresh_token = try container.decode(String.self, forKey: .refresh_token)
        scope = try container.decode(String.self, forKey: .scope)
        created_at = try container.decode(Int.self, forKey: .created_at)
    }
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
        request.setValue("O3iOS", forHTTPHeaderField: "User-Agent")
        request.setValue(CoinbaseClient.CB_VERSION, forHTTPHeaderField: "CB_VERSION")
        if data != nil {
            guard let body = try? JSONSerialization.data(withJSONObject: data!, options: []) else {
                completion(.failure(.invalidBodyRequest))
                return
            }
            request.httpBody = body
        }
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, err) in
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

        sendRequest(url, method: .POST, data: [:]) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let result):
                let decoder = JSONDecoder()
                guard let data = try? JSONSerialization.data(withJSONObject: result, options: .prettyPrinted),
                    let tokenResponse = try? decoder.decode(CoinbaseTokenResponse.self, from: data) else {
                        completion(.failure(.invalidData))
                        return
                }
                completion(.success(tokenResponse))
            }
        }
    }
        
    func refreshToken(completion: @escaping (CoinbaseClientResult<CoinbaseTokenResponse>) -> Void) {
        let grant_type = "refresh_token"
        let token = ExternalAccounts.getFromFileSystem().getCoinbaseTokenFromDisk()!
        let queryString = "?grant_type=\(grant_type)&data=\(token)"
        let url = "https://coinbase-oauth.o3.app/\(queryString)"
        
        sendRequest(url, method: .POST, data: [:]) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                guard let data = try? JSONSerialization.data(withJSONObject: result, options: .prettyPrinted),
                    let tokenResponse = try? decoder.decode(CoinbaseTokenResponse.self, from: data) else {
                        completion(.failure(.invalidData))
                        return
                }
                let account = ExternalAccounts.getFromFileSystem().getAccounts().first {
                    $0.platform == ExternalAccounts.Platforms.COINBASE.rawValue
                }!
                
                ExternalAccounts.getFromFileSystem().setAccount(platform: ExternalAccounts.Platforms.COINBASE, unencryptedToken: tokenResponse.refresh_token, scope: tokenResponse.scope, accountMetaData: account.accountMetaData)
                let expiryTime = Int(Date().timeIntervalSince1970) + tokenResponse.expires_in
                ExternalAccounts.setCoinbaseTokenForSession(token: tokenResponse.access_token, expiryTime: expiryTime)
            }
        }
    }
    
    private func getUserWithToken() {}
    func getUser(completion: @escaping (CoinbaseClientResult<Bool>) -> Void) {
        if ExternalAccounts.getCoinbaseTokenFromMemory() == nil {
            refreshToken { result in
                switch result {
                case .failure(let e):
                    return
                case .success(let tokenResponse):
                    return
                }
            }
        }
    }
}
