//
//  Asset.swift
//  O3
//
//  Created by Apisit Toompakdee on 8/7/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

public struct Asset: Codable {

    let name: String
    let symbol: String
    let logoURL: String
    let url: String?
    let logoURLDark: String?
    let logoSVG: String?
    let webURL: String?
    let tokenHash: String?
    let decimal: Int? = 0

    enum CodingKeys: String, CodingKey {
        case name = "name"
        case symbol = "symbol"
        case decimal = "decimal"
        case tokenHash = "tokenHash"
        case logoURL = "logoURL"
        case logoURLDark = "logoURLDark"
        case logoSVG = "logoSVG"
        case webURL = "webURL"
        case url = "url" //this is a url to go to token detail screen
    }
}

public class JSONNull: Codable {
    public init() {}
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}
