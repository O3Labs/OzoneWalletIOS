//
//  Deposit.swift
//  SwitcheoSwift
//
//  Created by Rataphon Chitnorm on 8/27/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

// To parse the JSON, add this file to your project and do:
//
//   let deposit = try? newJSONDecoder().decode(Deposit.self, from: jsonData)

import Foundation
import Neoutils

public struct RequestTransaction: Codable {
    public var blockchain, assetID: String
    public var amount: Float64
    public var contractHash: String
    
    enum CodingKeys: String, CodingKey {
        case blockchain
        case assetID = "asset_id"
        case amount
        case contractHash = "contract_hash"
    }
    
    public init?(blockchain: String, assetID: String,amount: Float64,contractHash: String){
        self.blockchain = blockchain
        self.assetID = assetID
        self.amount = amount
        self.contractHash = contractHash
    }
    
    var dictionary: [String: Any] {
        var dict = (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
        dict["amount"] = self.amount.toSWTHAmount()
        return dict
    }
    
}

