//
//  SWTHTrade.swift
//  SwitcheoSwift
//
//  Created by Rataphon Chitnorm on 8/27/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

// To parse the JSON, add this file to your project and do:
//
//   let sWTHTrade = try? newJSONDecoder().decode(SWTHTrade.self, from: jsonData)

public struct Trade: Codable {
    public var id: String
    public var fillAmount, takeAmount: Float
    public var eventTime: String
    public var isBuy: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case fillAmount = "fill_amount"
        case takeAmount = "take_amount"
        case eventTime = "event_time"
        case isBuy = "is_buy"
    }
}
