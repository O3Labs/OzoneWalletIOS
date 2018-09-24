//
//  AssetPrice.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/19/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

struct AssetPrice: Codable {
    let symbol: String
    let currency: String
    var price: Double
    let lastUpdate: Int
    
    enum CodingKeys: String, CodingKey {
        case symbol = "symbol"
        case currency = "currency"
        case price = "price"
        case lastUpdate = "lastUpdate"
    }
}


extension AssetPrice {
    mutating func updatePrice(value: Double) {
        self.price = value
    }
}
