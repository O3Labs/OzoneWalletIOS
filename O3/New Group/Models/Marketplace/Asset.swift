//
//  Asset.swift
//  O3
//
//  Created by Apisit Toompakdee on 8/7/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

public struct Asset: Codable {

    var name: String
    var symbol: String
    var logoURL: String
    var logoURLDark: String
    var url: String

    enum CodingKeys: String, CodingKey {
        case name
        case symbol
        case logoURL
        case logoURLDark
        case url
    }

}
