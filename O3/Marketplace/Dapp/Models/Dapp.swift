//
//  Dapp.swift
//  O3
//
//  Created by Apisit Toompakdee on 10/2/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

struct Dapp: Codable {
    let name: String
    let description: String
    let iconURL: String
    let blockchain: String
    let legacy: Bool
    let isDapp: Bool
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case description = "description"
        case iconURL = "iconURL"
        case blockchain = "blockchain"
        case url = "url"
        case legacy = "legacy"
        case isDapp = "isDapp"
    }
}
