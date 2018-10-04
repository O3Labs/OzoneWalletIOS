//
//  Dictionary+SWTHEncoding.swift
//  SwitcheoSwift
//
//  Created by Rataphon Chitnorm on 8/23/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import Neoutils
extension Dictionary {
   
     func SWTHEncodingMessage(sort: Bool)->String{
        guard let jsonData = try? JSONSerialization.data(withJSONObject: self, options:sort ?  JSONSerialization.WritingOptions.sortedKeys:  []) else {
            return ""
        }
        let parameterHexString = jsonData.fullHexString
        let lengthHex = NeoutilsGetVarUInt((Int64(parameterHexString.count / 2))).fullHexString
        let concatenatedString = lengthHex + parameterHexString
        let serializedTransaction = "010001f0" + concatenatedString + "0000"
        return serializedTransaction
    }
    
    func toString() -> String{
        let jsonData = try? JSONSerialization.data(withJSONObject:self as Any, options: .prettyPrinted)
        let jsonString = String(data: jsonData!, encoding: .utf8)
        return jsonString!
    }
}

