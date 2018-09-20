//
//  Float64+Util.swift
//  SwitcheoSwift
//
//  Created by Rataphon Chitnorm on 8/21/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
let ASSET_DECIMALS = [
    // NEO
    "NEO": 8,
    "GAS": 8,
    "SWTH": 8,
    "ACAT": 8,
    "APH": 8,
    "AVA": 8,
    "COUP": 8,
    "CPX": 8,
    "DBC": 8,
    "EFX": 8,
    "LRN": 8,
    "MCT": 8,
    "NKN": 8,
    "NRVE": 8,
    "OBT": 8,
    "ONT": 8,
    "PKC": 8,
    "QLC": 8,
    "RHT": 0,
    "RPX": 8,
    "SDT": 8,
    "SDS": 8,
    "SOUL": 8,
    "TKY": 8,
    "TNC": 8,
    "TOLL": 8,
    "ZPT": 8,
    "SWH": 8,
    "MCTP": 8,
    "NRVEP": 8,
    "RHTC": 0,
    // ETH
    "ETH": 18,
    "ONC": 18,
]

extension Float64 {
    func toAssetAmount(_ asset: String,tokenDetail: TokenDetail) -> String {
        //        let decimal:Float64 = Float64(ASSET_DECIMALS[asset] ?? 8)
        let fullAmount = self * (pow(10,tokenDetail.decimals))
        let format = NumberFormatter()
        format.maximumFractionDigits = 0
        format.minimumFractionDigits = 0
        let amountText = format.string(from: NSNumber(value: fullAmount))
        return amountText!
    }
    
    func toFixed(_ decimal:Int) -> String {
        let amountText = String(format: "%."+String(format:"%d",decimal)+"f", self)
        return amountText
    }
}

