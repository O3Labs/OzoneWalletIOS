//
//  SWTHLast24hour.swift
//  SwitcheoSwift
//
//  Created by Rataphon Chitnorm on 8/24/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

// To parse the JSON, add this file to your project and do:
//
//   let sWTHLast24Hour = try? newJSONDecoder().decode(SWTHLast24Hour.self, from: jsonData)

import Foundation

public struct Last24hour: Codable {
    public var pair, swthLast24HourOpen, close, high: String
    public var low, volume, quoteVolume: String
    
    enum CodingKeys: String, CodingKey {
        case pair
        case swthLast24HourOpen = "open"
        case close, high, low, volume
        case quoteVolume = "quote_volume"
    }
}
