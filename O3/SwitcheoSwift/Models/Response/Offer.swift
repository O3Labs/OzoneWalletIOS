//
//  SWTHOffer.swift
//  SwitcheoSwift
//
//  Created by Rataphon Chitnorm on 8/27/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

// To parse the JSON, add this file to your project and do:
//
//   let sWTHOffer = try? newJSONDecoder().decode(SWTHOffer.self, from: jsonData)

import Foundation

public struct Offer: Codable {
    public var id, offerAsset, wantAsset: String
    public var availableAmount, offerAmount, wantAmount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case offerAsset = "offer_asset"
        case wantAsset = "want_asset"
        case availableAmount = "available_amount"
        case offerAmount = "offer_amount"
        case wantAmount = "want_amount"
    }
}

