//
//  SWTHOrder.swift
//  SwitcheoSwift
//
//  Created by Rataphon Chitnorm on 8/29/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

// To parse the JSON, add this file to your project and do:
//
//   let order = try? newJSONDecoder().decode(Order.self, from: jsonData)

import Foundation

public struct Order: Codable {
    public var id, blockchain, contractHash, address: String
    public var side, offerAssetID, wantAssetID, offerAmount: String
    public var wantAmount, transferAmount, priorityGasAmount: String
    public var useNativeToken: Bool
    public var nativeFeeTransferAmount: Int
    public var depositTxn: JSONNull?
    public var createdAt, status: String
    
    enum CodingKeys: String, CodingKey {
        case id, blockchain
        case contractHash = "contract_hash"
        case address, side
        case offerAssetID = "offer_asset_id"
        case wantAssetID = "want_asset_id"
        case offerAmount = "offer_amount"
        case wantAmount = "want_amount"
        case transferAmount = "transfer_amount"
        case priorityGasAmount = "priority_gas_amount"
        case useNativeToken = "use_native_token"
        case nativeFeeTransferAmount = "native_fee_transfer_amount"
        case depositTxn = "deposit_txn"
        case createdAt = "created_at"
        case status
    }
}

// MARK: Encode/decode helpers

public class JSONNull: Codable {
    public init() {}
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

