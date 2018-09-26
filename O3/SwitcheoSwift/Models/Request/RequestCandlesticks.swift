//
//  RequestCandlesticks.swift
//  SwitcheoSwift
//
//  Created by Rataphon Chitnorm on 8/24/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//
// To parse the JSON, add this file to your project and do:
//
//   let requestCandlesticks = try? newJSONDecoder().decode(RequestCandlesticks.self, from: jsonData)

import Foundation

public struct RequestCandlesticks: Codable {
    public var pair: String
    public var interval, startTime, endTime: Int
    
    enum CodingKeys: String, CodingKey {
        case pair, interval
        case startTime = "start_time"
        case endTime = "end_time"
    }
    
    public init?(pair: String, interval: Int, startTime: Int, endTime: Int){
        self.pair = pair
        self.interval = interval
        self.startTime = startTime
        self.endTime = endTime
    }
    
    var dictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
    }
}

