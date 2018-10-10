//
//  SWTHCandlestick.swift
//  SwitcheoSwift
//
//  Created by Rataphon Chitnorm on 8/24/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

// To parse the JSON, add this file to your project and do:
//
//   let sWTHCandlestick = try? newJSONDecoder().decode(SWTHCandlestick.self, from: jsonData)

import Foundation

public struct Candlestick: Codable {
    public var time, swthCandlestickOpen, close, high: String
    public var low, volume, quoteVolume: String
    
    enum CodingKeys: String, CodingKey {
        case time
        case swthCandlestickOpen = "open"
        case close, high, low, volume
        case quoteVolume = "quote_volume"
    }
}

