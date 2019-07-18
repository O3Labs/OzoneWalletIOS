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
    case failure(Error)
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

var supportedCurrencies = ["BTC": "Bitcoin", "BCH": "Bitcoin-Cash", "BSV": "Bitcoin-SV",
                           "ETH": "Ethereum", "LTC": "Litecoin", "XLM": "Stellar",
                           "XRP": "Ripple", "EOS": "EOS", "ETC": "Etherum-Classic",
                           "ZEC": "Zcash", "BAT": "basic-attention-token", "USDC": "USDC",
                           "ZRX": "0x", "REP": "Augur", "DAI": "Dai"]

struct CurrencyAccount: Codable {
    var id: String
    var name: String
    var primary: Bool
    var type: String
    var balance: Balance
    var created_at: String?
    var updated_at: String?
    var resource: String
    var resource_path: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case primary
        case type
        case balance
        case created_at
        case updated_at
        case resource
        case resource_path
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        primary = try container.decode(Bool.self, forKey: .primary)
        type = try container.decode(String.self, forKey: .type)
        balance = try container.decode(Balance.self, forKey: .balance)
        created_at = try? container.decode(String.self, forKey: .created_at)
        updated_at = try? container.decode(String.self, forKey: .updated_at)
        resource = try container.decode(String.self, forKey: .resource)
        resource_path = try container.decode(String.self, forKey: .resource_path)
    }
    
    struct Balance: Codable {
        var amount: String
        var currency: String
        
        enum CodingKeys: String, CodingKey {
            case amount
            case currency
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            amount = try container.decode(String.self, forKey: .amount)
            currency = try container.decode(String.self, forKey: .currency)
        }
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
            return "Invalid server request"        }
    }
}

public struct CoinbaseSpecificError: Error {
    var id: String
    var message: String
}


class CoinbaseClient {
    static let shared: CoinbaseClient! = CoinbaseClient()
    static let CB_VERSION = "2019-04-23"
    
    enum HTTPMethod: String {
        case GET
        case POST
    }
    
    func sendRequest(_ endpointURL: String, method: HTTPMethod, data: [String: Any?]?, headers: [String: String],
                      completion: @escaping (CoinbaseClientResult<JSONDictionary>) -> Void) {
        
        let url = URL(string: endpointURL)
        let request = NSMutableURLRequest(url: url!)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("O3iOS", forHTTPHeaderField: "User-Agent")
        request.setValue(CoinbaseClient.CB_VERSION, forHTTPHeaderField: "CB_VERSION")
        for header in headers {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        if data != nil {
            guard let body = try? JSONSerialization.data(withJSONObject: data!, options: []) else {
                completion(.failure(CoinbaseClientError.invalidBodyRequest))
                return
            }
            request.httpBody = body
        }
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, err) in
            print(response.debugDescription)
            if err != nil {
                completion(.failure(CoinbaseClientError.invalidRequest))
                return
            }
            
            guard let dataUnwrapped = data,
                let json = (try? JSONSerialization.jsonObject(with: dataUnwrapped, options: [])) as? JSONDictionary else {
                    completion(.failure(CoinbaseClientError.invalidData))
                    return
            }
            
            print (json)
            let result = CoinbaseClientResult.success(json)
            completion(result)
        }
        task.resume()
    }

    func getToken(code: String, completion: @escaping (CoinbaseClientResult<CoinbaseTokenResponse>) -> Void) {
        let grant_type = "authorization_code"
        let queryString = "?grant_type=\(grant_type)&data=\(code)"
        let url = "https://coinbase-oauth.o3.app/\(queryString)"

        sendRequest(url, method: .POST, data: [:], headers: [:]) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let result):
                let decoder = JSONDecoder()
                guard let data = try? JSONSerialization.data(withJSONObject: result, options: .prettyPrinted),
                    let tokenResponse = try? decoder.decode(CoinbaseTokenResponse.self, from: data) else {
                        completion(.failure(CoinbaseClientError.invalidData))
                        return
                }
                print (tokenResponse
                )
                completion(.success(tokenResponse))
            }
        }
    }
        
    func refreshToken(completion: @escaping (CoinbaseClientResult<CoinbaseTokenResponse>) -> Void) {
        let grant_type = "refresh_token"
        let token = ExternalAccounts.getCoinbaseTokenFromDisk()!
        let queryString = "?grant_type=\(grant_type)&data=\(token)"
        let url = "https://coinbase-oauth.o3.app/\(queryString)"
        print(queryString)
        sendRequest(url, method: .POST, data: [:], headers: [:]) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                if let data = (response["errors"] as? NSArray)?.firstObject as? JSONDictionary {
                    let coinbaseError = CoinbaseSpecificError(id: data["id"] as! String, message: data["message"] as! String)
                    if data["id"] as! String == "revoked_token" {
                        let externalAccounts = ExternalAccounts.getFromFileSystem()
                        externalAccounts.removeAccount(platform: ExternalAccounts.Platforms.COINBASE)
                        externalAccounts.writeToFileSystem()
                        completion(.failure(coinbaseError))
                        return
                    }
                }
                
                guard let data = try? JSONSerialization.data(withJSONObject: response, options: .prettyPrinted),
                    let tokenResponse = try? decoder.decode(CoinbaseTokenResponse.self, from: data) else {
                        completion(.failure(CoinbaseClientError.invalidData))
                        return
                }
                let account = ExternalAccounts.getFromFileSystem().getAccounts().first {
                    $0.platform == ExternalAccounts.Platforms.COINBASE.rawValue
                }!
                let expiryTime = Int(Date().timeIntervalSince1970) + tokenResponse.expires_in
                ExternalAccounts.setCoinbaseTokenForSession(token: tokenResponse.access_token, expiryTime: expiryTime)
                
                ExternalAccounts.getFromFileSystem().setAccount(platform: ExternalAccounts.Platforms.COINBASE, unencryptedToken: tokenResponse.refresh_token, scope: tokenResponse.scope, accountMetaData: account.accountMetaData)
                completion(.success(tokenResponse))
            }
        }
    }
    
    private func getUserWithToken(completion: @escaping (CoinbaseClientResult<[String: String]>) -> Void) {
        let url = "https://api.coinbase.com/v2/user"
        let headers = ["Authorization" : "Bearer \(ExternalAccounts.getCoinbaseTokenFromMemory()!)"]
        sendRequest(url, method: .GET, data: nil, headers: headers) { result in
            switch result {
                case .failure(let e):
                    completion(.failure(e))
                case .success(let response):
                    if let data = (response["errors"] as? NSArray)?.firstObject as? JSONDictionary {
                        let coinbaseError = CoinbaseSpecificError(id: data["id"] as! String, message: data["message"] as! String)
                        completion(.failure(coinbaseError))
                    } else {
                        let data = response["data"] as! JSONDictionary
                        let email = data["email"] as! String
                        let id = data["id"] as! String
                        completion(.success(["email": email, "id": id]))
                }
            }
        }
    }
    
    func getUser(completion: @escaping (CoinbaseClientResult<[String: String]>) -> Void) {
        if ExternalAccounts.getCoinbaseTokenFromMemory() == nil {
            refreshToken { result in
                switch result {
                case .failure(let e):
                    completion(.failure(e))
                case .success(_):
                    self.getUserWithToken { result in
                        completion(result)
                    }
                }
            }
        } else {
            self.getUserWithToken { result in
                completion(result)
            }
        }
    }
    
    func getWalletAccountWithToken(currency: String, completion: @escaping (CoinbaseClientResult<CurrencyAccount>) -> Void) {
        let url = "https://api.coinbase.com/v2/accounts"
        let headers = ["Authorization" : "Bearer \(ExternalAccounts.getCoinbaseTokenFromMemory()!)"]
        sendRequest(url, method: .GET, data: nil, headers: headers) { result in
            switch result {
            case .failure(let e):
                completion(.failure(e))
            case .success(let response):
                if let data = (response["errors"] as? NSArray)?.firstObject as? JSONDictionary {
                    let coinbaseError = CoinbaseSpecificError(id: data["id"] as! String, message: data["message"] as! String)
                    completion(.failure(coinbaseError))
                } else {
                    let decoder = JSONDecoder()
                    guard let data = try? JSONSerialization.data(withJSONObject: response["data"], options: .prettyPrinted),
                        let currencyAccounts = try? decoder.decode([CurrencyAccount].self, from: data) else {
                            completion(.failure(CoinbaseClientError.invalidData))
                            return
                    }
                    let index = currencyAccounts.firstIndex { $0.balance.currency.lowercased() == currency.lowercased() && $0.type == "wallet" }
                    if index == nil {
                        completion(.failure(CoinbaseSpecificError(id: "wallet_error", message: "User does not have this wallet in their coinbase account")))
                    } else {
                        completion(.success(currencyAccounts[index!]))
                    }
                }
            }
        }
    }
    
    func getWalletAccount(currency: String, completion: @escaping (CoinbaseClientResult<CurrencyAccount>) -> Void) {
        if ExternalAccounts.getCoinbaseTokenFromMemory() == nil {
            refreshToken { result in
                switch result {
                case .failure(let e):
                    completion(.failure(e))
                case .success(_):
                    self.getWalletAccountWithToken(currency: currency) { result in
                        completion(result)
                    }
                }
            }
        } else {
            self.getWalletAccountWithToken(currency: currency) { result in
                completion(result)
            }
        }
    }
    
    func sendWithToken(amount: String, to: String, currency: String, idem: String? = nil, description: String? = nil,
              toInstitution: Bool? = false, institutionWebsite: String? = nil, twoFactorToken: String? = nil,
              completion: @escaping (CoinbaseClientResult<Bool>) -> Void) {
        getWalletAccount(currency: currency) { result in
            switch result {
            case .failure(let e):
                completion(.failure(e))
            case .success(let account):
                let url = "https://api.coinbase.com/v2/accounts/\(account.id)/transactions"
                var parameters: [String: String] = ["type": "send",
                                                    "to": to,
                                                    "amount": amount,
                                                    "currency": currency]
                if idem != nil {
                    parameters["idem"] = idem
                }
                
                if description != nil {
                    parameters["description"] = description
                }
                
                if toInstitution == true {
                    parameters["to_financial_institution"] = "true"
                    parameters["financial_institution_website"] = institutionWebsite
                }
                
                var headers: [String: String] = ["Authorization" : "Bearer \(ExternalAccounts.getCoinbaseTokenFromMemory()!)"]
                if twoFactorToken != nil {
                    headers["CB-2FA-TOKEN"] = twoFactorToken
                }
                
                self.sendRequest(url, method: .POST, data: parameters, headers: headers) { result in
                    switch result {
                    case .failure(let e):
                        completion(.failure(e))
                    case .success(let response):
                        if let data = (response["errors"] as? NSArray)?.firstObject as? JSONDictionary {
                            let coinbaseError = CoinbaseSpecificError(id: data["id"] as! String, message: data["message"] as! String)
                            completion(.failure(coinbaseError))
                        } else {
                            completion(.success(true))
                        }
                    }
                }
            }
        }
    }
    
    func send(amount: String, to: String, currency: String, idem: String? = nil, description: String? = nil,
              toInstitution: Bool? = false, institutionWebsite: String? = nil, twoFactorToken: String? = nil,
              completion: @escaping (CoinbaseClientResult<Bool>) -> Void) {
        
        if ExternalAccounts.getCoinbaseTokenFromMemory() == nil {
            refreshToken { result in
                switch result {
                case .failure(let e):
                    completion(.failure(e))
                case .success(_):
                    self.sendWithToken(amount: amount, to: to, currency: currency,
                                       idem: idem, description: description, toInstitution: toInstitution,
                                       institutionWebsite: institutionWebsite, twoFactorToken: twoFactorToken) { result in
                        completion(result)
                    }
                }
            }
        } else {
            self.sendWithToken(amount: amount, to: to, currency: currency,
                               idem: idem, description: description, toInstitution: toInstitution,
                               institutionWebsite: institutionWebsite, twoFactorToken: twoFactorToken) { result in
                completion(result)
            }
        }
    }
    
    
    struct CoinbasePortfolioAccount: PortfolioAsset {
        var symbol: String
        var name: String
        var value: Double
    }
    
    func converToPortfolioAccounts(accounts: [CurrencyAccount]) -> [CoinbasePortfolioAccount] {
        
        var convertedAccounts = [CoinbasePortfolioAccount]()
        for account in accounts {
            if let walletAccountIndex = convertedAccounts.firstIndex(where: { $0.symbol == account.balance.currency}) {
                var newBalance = convertedAccounts[walletAccountIndex].value + (Double(account.balance.amount) ?? 0.0)
                convertedAccounts[walletAccountIndex].value = newBalance
                
            } else {
                var currencySymbol = account.balance.currency.uppercased()
                if supportedCurrencies.keys.contains(currencySymbol) == false {
                    continue
                }
                
                if Double(account.balance.amount) ?? 0.0 > 0 {
                    convertedAccounts.append(CoinbasePortfolioAccount(symbol: currencySymbol,
                                                                      name: supportedCurrencies[currencySymbol]!,
                                                                      value: Double(account.balance.amount) ?? 0.0))
                }
            }
        }
        
        return convertedAccounts
    }
    
    func getAllPortfolioAssetsWithToken(completion: @escaping (CoinbaseClientResult<[CoinbasePortfolioAccount]>) -> Void) {
        let url = "https://api.coinbase.com/v2/accounts"
        let headers = ["Authorization" : "Bearer \(ExternalAccounts.getCoinbaseTokenFromMemory()!)"]
        sendRequest(url, method: .GET, data: nil, headers: headers) { result in
            switch result {
            case .failure(let e):
                completion(.failure(e))
            case .success(let response):
                if let data = (response["errors"] as? NSArray)?.firstObject as? JSONDictionary {
                    let coinbaseError = CoinbaseSpecificError(id: data["id"] as! String, message: data["message"] as! String)
                    completion(.failure(coinbaseError))
                } else {
                    let decoder = JSONDecoder()
                    guard let data = try? JSONSerialization.data(withJSONObject: response["data"], options: .prettyPrinted),
                        let currencyAccounts = try? decoder.decode([CurrencyAccount].self, from: data) else {
                            completion(.failure(CoinbaseClientError.invalidData))
                            return
                    }
                    let accounts = self.converToPortfolioAccounts(accounts: currencyAccounts)
                    completion(.success(accounts))
                }
            }
        }
    }

    func getAllPortfolioAssets(completion: @escaping (CoinbaseClientResult<[CoinbasePortfolioAccount]>) -> Void) {
        if ExternalAccounts.getCoinbaseTokenFromMemory() == nil {
            refreshToken { result in
                switch result {
                case .failure(let e):
                    completion(.failure(e))
                case .success(_):
                    self.getAllPortfolioAssetsWithToken { result in
                        completion(result)
                    }
                }
            }
        } else {
            getAllPortfolioAssetsWithToken { result in
                completion(result)
            }
        }
    }
    
    func getNewAddressWithToken(currency: String, completion: @escaping (CoinbaseClientResult<[String: String]>) -> Void) {
        getWalletAccountWithToken(currency: currency) { result in
            switch result {
            case .failure(let e):
                completion(.failure(e))
            case .success(let wallet):
                self.createAddressWithToken(accountID: wallet.id) { result in
                    switch result {
                    case .failure(let e):
                        completion(.failure(e))
                    case .success(let success):
                        if success {
                            let url = "https://api.coinbase.com/v2/accounts/\(wallet.id)/addresses"
                            let headers = ["Authorization" : "Bearer \(ExternalAccounts.getCoinbaseTokenFromMemory()!)"]
                            self.sendRequest(url, method: .GET, data: nil, headers: headers) { result in
                                switch result {
                                case .failure(let e):
                                    completion(.failure(e))
                                case .success(let response):
                                    if response.keys.contains("errors") {
                                        completion(.failure(CoinbaseSpecificError(id: "coinbase_error", message: "something went wrong")))
                                    } else {
                                        let data = response["data"] as! [[String: Any]]
                                        let address =  data[0]["address"] as! String
                                        var tag: String? = nil
                                        if data[0].keys.contains("destination_tag") {
                                            tag = data[0]["destination_tag"] as! String
                                        }
                                        var dict = ["address": address]
                                        if tag != nil {
                                            dict["tag"] = tag!
                                        }
                                        
                                        completion(.success(dict))
                                    }
                                }
                            }
                        } else {
                            completion(.failure(CoinbaseSpecificError(id: "coinbase_error", message: "Could not create address")))
                        }
                    }
                }
            }
        }
    }
    
    func getNewAddress(currency: String, completion: @escaping (CoinbaseClientResult<[String: String]>) -> Void) {
        if ExternalAccounts.getCoinbaseTokenFromMemory() == nil {
            refreshToken { result in
                switch result {
                case .failure(let e):
                    completion(.failure(e))
                case .success(_):
                    self.getNewAddressWithToken(currency: currency) { result in
                        completion(result)
                    }
                }
            }
        } else {
            self.getNewAddressWithToken(currency: currency) { result in
                completion(result)
            }
        }
    }
    
    func createAddressWithToken(accountID: String, completion: @escaping (CoinbaseClientResult<Bool>) -> Void) {
        let url = "https://api.coinbase.com/v2/accounts/\(accountID)/addresses"
        let headers = ["Authorization" : "Bearer \(ExternalAccounts.getCoinbaseTokenFromMemory()!)"]
        sendRequest(url, method: .POST, data: nil, headers: headers) { result in
            switch result {
            case .failure(let e):
                completion(.failure(e))
            case .success(let response):
                if let data = (response["errors"] as? NSArray)?.firstObject as? JSONDictionary {
                    let coinbaseError = CoinbaseSpecificError(id: data["id"] as! String, message: data["message"] as! String)
                    completion(.failure(coinbaseError))
                } else {
                    completion(.success(true))
                }
            }
        }
    }
}
