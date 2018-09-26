//
//  RequestTrade.swift
//  SwitcheoSwift
//
//  Created by Rataphon Chitnorm on 8/27/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

// To parse the JSON, add this file to your project and do:
//
//   let requestTrade = try? newJSONDecoder().decode(RequestTrade.self, from: jsonData)

import Foundation

public struct RequestTrade: Codable {
    public var blockchain, pair: String
    public var limit, from, to: Int?
    public var contractHash: String
    
    enum CodingKeys: String, CodingKey {
        case blockchain, pair, limit, from, to
        case contractHash = "contract_hash"
    }
    
    public init?(blockchain: String,pair: String, limit: Int?, from: Int?, to: Int?,contractHash: String){
        self.blockchain = blockchain
        self.pair = pair
        self.limit = limit
        self.from = from
        self.to = to
        self.contractHash = contractHash
    }
    
    var dictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
    }
}

