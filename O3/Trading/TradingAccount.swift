//
//  TradingAccount.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/10/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation


struct TradingAccount: Codable {
    let switcheo: SwitcheoBalance
    
    enum CodingKeys: String, CodingKey {
        case switcheo = "switcheo"
    }
}

struct SwitcheoBalance: Codable {
    let confirming: [Confirming]
    let confirmed: [TradableAsset]
    let locked: [TradableAsset]
    
    enum CodingKeys: String, CodingKey {
        case confirming = "confirming"
        case confirmed = "confirmed"
        case locked = "locked"
    }
}

struct TradableAsset: Codable {
    let id: String
    let name: String
    let symbol: String
    let decimals: Int
    let value: String
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case symbol = "symbol"
        case decimals = "decimals"
        case value = "value"
    }
}

extension TradableAsset {
    func amountInDouble() -> Double{
        let valueDecimal = NSDecimalNumber(string: self.value)
        let dividedBalance = (valueDecimal.doubleValue / pow(10, Double(self.decimals)))
        let value = Double(truncating: (dividedBalance as NSNumber?)!)
        return value
    }
    
    func formattedAmountInString() -> String {
        let amountFormatter = NumberFormatter()
        amountFormatter.minimumFractionDigits = 0
        amountFormatter.maximumFractionDigits = self.decimals
        amountFormatter.numberStyle = .decimal
        amountFormatter.locale = Locale.current
        amountFormatter.usesGroupingSeparator = true
        
        return String(format: "%@", amountFormatter.string(from: NSNumber(value: self.amountInDouble()))!)
    }
    
    func toTransferableAsset() -> TransferableAsset {
        var assetType = TransferableAsset.AssetType.neoAsset
        
        if self.symbol.uppercased() != TransferableAsset.NEO().symbol.uppercased() || self.symbol.uppercased() != TransferableAsset.GAS().symbol.uppercased() {
            assetType = TransferableAsset.AssetType.nep5Token
        }
        
       return TransferableAsset(id: self.id, name: self.name, symbol: self.symbol, decimals: self.decimals, value: self.amountInDouble(), assetType: assetType)
    }
}

extension TransferableAsset {
    func toTradableAsset() -> TradableAsset {
        let valueDouble = round(NSDecimalNumber(decimal: Decimal(self.value * pow(10, Double(self.decimals)))).doubleValue)
        return TradableAsset(id: self.id, name: self.name, symbol: self.symbol, decimals: self.decimals, value: String(format:"%0f",valueDouble))
    }
}

struct Confirming: Codable {
    let symbol: String
    let eventType: String
    let hash: String
    let amount: String
    let decimals: Int
    let txid: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case symbol = "symbol"
        case eventType = "eventType"
        case hash = "hash"
        case amount = "amount"
        case decimals = "decimals"
        case txid = "TXID"
        case createdAt = "createdAt"
    }
}

