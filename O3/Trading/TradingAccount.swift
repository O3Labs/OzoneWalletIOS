//
//  TradingAccount.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/10/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation


struct TradingAccount: Codable {
    let switcheo: SwitcheoBalance
    
    enum CodingKeys: String, CodingKey {
        case switcheo = "switcheo"
    }
}

struct SwitcheoBalance: Codable {
    let confirming: [Confirming]
    let confirmed: [TradableAsset]
    let locked: [TradableAsset]
    
    enum CodingKeys: String, CodingKey {
        case confirming = "confirming"
        case confirmed = "confirmed"
        case locked = "locked"
    }
}

struct TradableAsset: Codable {
    let id: String
    let name: String
    let symbol: String
    let decimals: Int
    let value: String
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case symbol = "symbol"
        case decimals = "decimals"
        case value = "value"
    }
}

struct Confirming: Codable {
    let symbol: String
    let eventType: String
    let hash: String
    let amount: String
    let decimals: Int
    let txid: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case symbol = "symbol"
        case eventType = "eventType"
        case hash = "hash"
        case amount = "amount"
        case decimals = "decimals"
        case txid = "TXID"
        case createdAt = "createdAt"
    }
}

