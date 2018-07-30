//
//  GasPrice.swift
//  O3
//
//  Created by Andrei Terentiev on 7/30/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
struct GasPrice: Codable {
    let gasprice: Int
    let height: Int

    enum CodingKeys: String, CodingKey {
        case gasprice
        case height
    }
}
