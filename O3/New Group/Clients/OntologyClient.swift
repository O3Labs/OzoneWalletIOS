//
//  OntologyClient.swift
//  O3
//
//  Created by Andrei Terentiev on 7/30/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation

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

public enum OntologyClientError: Error {
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

public enum OntologyClientResult<T> {
    case success(T)
    case failure(OntologyClientError)
}

public class OntologyClient {
    private init() {}

    enum RPCMethod: String {
        case getGasPrice = "getgasprice"
    }

    func sendJSONRPCRequest(_ method: RPCMethod, params: [Any]?, completion: @escaping (OntologyClientResult<JSONDictionary>) -> Void) {
        guard let url = URL(string: AppState.bestOntologyNodeURL) else {
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

            let resultJson = OntologyClientResult.success(json!)
            completion(resultJson)
        }
        task.resume()
    }

 /*   func getGasPrice(completion: @escaping(OntologyClientResult<Int>) -> Void) {
        sendJSONRPCRequest(.getGasPrice, params: nil) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                
            }
        }
    }*/
}
