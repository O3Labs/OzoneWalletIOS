//
//  UnboungOng.swift
//  O3
//
//  Created by Andrei Terentiev on 8/1/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
struct UnboundOng: Codable {
    let ong: String
    let calculated: Bool

    enum CodingKeys: String, CodingKey {
        case ong
        case calculated
    }
}

struct newUnboundOng: Codable {
    let asset_name: String
    let balance : String
    
    enum CodingKeys: String, CodingKey {
        case asset_name
        case balance
    }
}
