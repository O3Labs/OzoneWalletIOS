//
//  ExploreAssets.swift
//  O3
//
//  Created by jcc on 2020/6/19.
//  Copyright © 2020 O3 Labs Inc. All rights reserved.
//

import UIKit

struct ExploreAssets: Codable {
    let logoURL: String
    let webURL: String
    let name: String
    let blockchain: String
    let tokenHash: String
    let symbol: String
    
    enum CodingKeys: String, CodingKey {
        case logoURL = "logoURL"
        case webURL = "webURL"
        case name = "name"
        case blockchain = "blockchain"
        case tokenHash = "tokenHash"
        case symbol = "symbol"
    }
}
