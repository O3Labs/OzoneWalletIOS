//
//  VerifiedAddress.swift
//  O3
//
//  Created by Apisit Toompakdee on 6/25/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

struct VerifiedAddress: Codable {
    let address: String
    let publicKey: String
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case address = "address"
        case publicKey = "publicKey"
        case displayName = "displayName"
    }
}
