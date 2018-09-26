//
//  Order.swift
//  SwitcheoSwift
//
//  Created by Rataphon Chitnorm on 8/24/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//
// To parse the JSON, add this file to your project and do:
//
//   let order = try? newJSONDecoder().decode(Order.self, from: jsonData)
import Foundation
import Neoutils

public struct RequestOrder: Codable {
    public var pair, blockchain, side: String
    public var price, wantAmount: Float64
    public var useNativeTokens: Bool
    public var orderType: String
    public var contractHash: String
    public var otcAddress: String
    
    enum CodingKeys: String, CodingKey {
        case pair, blockchain, side, price
        case wantAmount = "want_amount"
        case useNativeTokens = "use_native_tokens"
        case orderType = "order_type"
        case contractHash = "contract_hash"
        case otcAddress = "otc_address"
    }
    
    public init?(pair: String, blockchain: String, side: String, price: Float64, wantAmount: Float64, useNativeTokens: Bool, orderType: String, contractHash: String, otcAddress:String){
        self.pair = pair
        self.blockchain = blockchain
        self.side = side
        self.price = price
        self.wantAmount = wantAmount
        self.useNativeTokens = useNativeTokens
        self.orderType = orderType
        self.contractHash = contractHash
        self.otcAddress = otcAddress
    }
    
    public func toDictionary(asset: String, tokenDetail: TokenDetail) -> [String: Any] {
        var dict = (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
        dict["want_amount"] = self.wantAmount.toAssetAmount(asset,tokenDetail: tokenDetail)
        dict["price"] = self.price.toFixed(8)
        if self.otcAddress != "" && self.orderType == "otc" {
            dict["otc_address"] = NeoutilsNEOAddresstoScriptHashBigEndian(self.otcAddress)
        }else{
            dict.removeValue(forKey: "otc_address")
        }
        #if DEBUG
        print(dict.debugDescription)
        #endif
        return dict
    }
}

