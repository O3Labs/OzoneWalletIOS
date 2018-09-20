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

extension Array where Element == TradableAsset {
    func defaultAcceptedAsset() -> TradableAsset? {
        //find either NEO or GAS as a default one
        for v in self {
            if v.symbol.uppercased() == TransferableAsset.NEO().symbol.uppercased() || v.symbol.uppercased() == TransferableAsset.GAS().symbol.uppercased() {
                return v
            }
        }
        return nil
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

extension SwitcheoBalance {
    
    var basePairs: [TradableAsset]! {
        var bases: [TradableAsset] = [
            TradableAsset(id: "0xc56f33fc6ecfcd0c225c4ab356fee59390af8560be0e930faebe74a6daff7c9b", name: "NEO", symbol: "NEO", decimals: 8, value: "0"),
            TradableAsset(id: "0x602c79718b16e442de58778e148d0b1084e3b2dffd5de6b7b16cee7969282de7", name: "GAS", symbol: "GAS", decimals: 8, value: "0"),
            TradableAsset(id: "ab38352559b8b203bde5fddfa0b07d8b2525e132", name: "Switcheo", symbol: "SWTH", decimals: 8, value: "0"),
        ]
        
        for i in bases.indices {
            let found = self.confirmed.first { t -> Bool in
                return bases[i].id == t.id
            }
            if found != nil {
               bases[i].value = found!.value
            }
        }
      
        return bases
    }

    func loadSupportedTokens(completion: @escaping ([TradableAsset]) -> Void) {
        O3APIClient.shared.loadSupportedTokenSwitcheo { result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let response):
                completion(response)
            }
        }
    }
}

struct TradableAsset: Codable {
    let id: String
    let name: String
    let symbol: String
    let decimals: Int
    var value: String?
    
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
        if self.value == nil {
            return ""
        }
        
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

