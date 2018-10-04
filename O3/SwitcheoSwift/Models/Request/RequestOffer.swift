//
//  RequestOffer.swift
//  SwitcheoSwift
//
//  Created by Rataphon Chitnorm on 8/27/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

// To parse the JSON, add this file to your project and do:
//
//   let requestOffer = try? newJSONDecoder().decode(RequestOffer.self, from: jsonData)

import Foundation

public struct RequestOffer: Codable {
    public var blockchain, pair, contractHash: String
    
    enum CodingKeys: String, CodingKey {
        case blockchain, pair
        case contractHash = "contract_hash"
    }
    
    public init?(blockchain: String,pair: String, contractHash: String){
        self.blockchain = blockchain
        self.pair = pair
        self.contractHash = contractHash
    }
    
    var dictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
    }
}

