//
//  Deposit.swift
//  SwitcheoSwift
//
//  Created by Rataphon Chitnorm on 8/20/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation

public struct DepositUnsignedData: Encodable {
    var blockchain: String
    var asset_id: String
    var amount: Float64
    var timestamp: Int
    var contract_hash: String
    public init(
        blockchain: String,
        asset_id: String,
        amount: Float64,
        timestamp: Int,
        contract_hash: String) {
        self.amount = amount
        self.asset_id = asset_id
        self.blockchain = blockchain
        self.contract_hash = contract_hash
        self.timestamp = timestamp
    }
}


