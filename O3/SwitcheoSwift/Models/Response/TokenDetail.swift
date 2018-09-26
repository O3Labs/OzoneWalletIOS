//
//  Token.swift
//  SwitcheoSwift
//
//  Created by Rataphon Chitnorm on 9/11/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//
import Foundation

public struct TokenDetail: Codable {
    public var hash: String
    public var decimals: Float64
    
    enum CodingKeys: String, CodingKey {
        case hash
        case decimals
    }
}
