//
//  Notifications.swift
//  O3
//
//  Created by Andrei Terentiev on 4/22/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation

extension O3Client {
    func subscribeToTopic(service: String, topic: String, pubKey: String, completion: @escaping(O3ClientResult<Any>) -> Void) {
        var endpoint = "https://platform.o3.network/api/v1/nc/" + pubKey + "/subscribe"
        #if TESTNET
        endpoint = "https://platform.o3.network/api/v1/nc/" + pubKey + "/subscribe?network=test"
        #endif
        #if PRIVATENET
        endpoint = "https://platform.o3.network/api/v1/nc/" + pubKey + "/subscribe?network=test"
        #endif
        sendRequest(endpoint, method: .POST, data: nil, noBaseURL: true) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                guard let data = try? JSONSerialization.data(withJSONObject: response, options: .prettyPrinted)  else {
                    return
                }
                completion(.success(data))
            }
        }
    }
    
    func unsubscribeToTopic(service: String, topic: String, pubKey: String, completion: @escaping(O3ClientResult<Any>) -> Void) {
        var endpoint = "https://platform.o3.network/api/v1/nc/" + pubKey + "/unsubscribe"
        #if TESTNET
        endpoint = "https://platform.o3.network/api/v1/nc/" + pubKey + "/unsubscribe?network=test"
        #endif
        #if PRIVATENET
        endpoint = "https://platform.o3.network/api/v1/nc/" + pubKey + "/unsubscribe?network=test"
        #endif
        sendRequest(endpoint, method: .POST, data: nil, noBaseURL: true) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                guard let data = try? JSONSerialization.data(withJSONObject: response, options: .prettyPrinted)  else {
                    return
                }
                completion(.success(data))
            }
        }
    }
}
