//
//  Dapps.swift
//  O3
//
//  Created by jcc on 2020/6/19.
//  Copyright © 2020 O3 Labs Inc. All rights reserved.
//

import UIKit

struct Dapps: Codable {
    let name: String
    let iconURL: String
    let blockchain: String
    let url: String
    let slug: String
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case iconURL = "iconURL"
        case blockchain = "blockchain"
        case url = "url"
        case slug = "slug"
        case description = "description"
    }
}

