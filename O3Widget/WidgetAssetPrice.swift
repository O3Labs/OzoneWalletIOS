//
//  WidgetAssetPrice.swift
//  O3Widget
//
//  Created by Apisit Toompakdee on 3/5/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import UIKit

struct WidgetAssetPrice: Codable {
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
