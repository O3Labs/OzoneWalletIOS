//
//  NeoScan.swift
//  NeoSwift
//
//  Created by Apisit Toompakdee on 4/2/18.
//  Copyright © 2018 drei. All rights reserved.
//

import UIKit

public class NeoScan: NSObject {

    public let baseEndpoint = "https://neoscan.io/api/main_net"

    public enum NeoScanResult<T> {
        case success(T)
        case failure(NeoClientError)
    }

    public enum NeoScanError: Error {
        case invalidData

        var localizedDescription: String {
            switch self {
            case .invalidData:
                return "Invalid response data"
            }
        }
    }

    enum APIEndpoints: String {
        case getHistory = "/v1/get_address_abstracts/" //with address
    }

    func sendFullNodeRequest(_ url: String, params: [Any]?, completion :@escaping (NeoScanResult<JSONDictionary>) -> Void) {
        let request = NSMutableURLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, _, err) in
            if err != nil {
                completion(.failure(.invalidRequest))
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

            let resultJson = NeoScanResult.success(json!)
            completion(resultJson)
        }
        task.resume()
    }

    public func getTransactionHistory(address: String, page: Int, completion: @escaping(NeoScanResult<NEOScanTransactionHistory>) -> Void) {
        let url = baseEndpoint + APIEndpoints.getHistory.rawValue + address + "/" + String(page)
        sendFullNodeRequest(url, params: nil) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                guard let data = try? JSONSerialization.data(withJSONObject: response, options: .prettyPrinted),
                    let jsonResult = try? decoder.decode(NEOScanTransactionHistory.self, from: data) else {
                        completion(.failure(.invalidData))
                        return
                }
                let result = NeoScanResult.success(jsonResult)
                completion(result)
            }
        }
    }
}
