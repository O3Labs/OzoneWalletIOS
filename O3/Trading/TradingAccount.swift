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
            if v.symbol.uppercased() == O3WalletNativeAsset.NEO().symbol.uppercased() || v.symbol.uppercased() == O3WalletNativeAsset.GAS().symbol.uppercased() {
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
            TradableAsset(id: "0xc56f33fc6ecfcd0c225c4ab356fee59390af8560be0e930faebe74a6daff7c9b", name: "NEO", symbol: "NEO", decimals: 8, value: "0", precision: 3),
            TradableAsset(id: "7146278a76c33fc6bb870fcaa428e3cdb16809ac", name: "SDUSD", symbol: "SDUSD", decimals: 8, value: "0", precision: 2),
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
    
    func loadTradablePairs(completion: @escaping ([TradablePair]) -> Void) {
        O3APIClient.shared.loadTradablePairsSwitcheo { result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let response):
                completion(response)
            }
        }
    }
    
}

struct TradablePair: Codable {
    let name: String
    var precision: Int
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case precision = "precision"
    }
}

struct TradableAsset: Codable {
    let id: String
    let name: String
    let symbol: String
    let decimals: Int
    var value: String?
    var precision: Int?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case symbol = "symbol"
        case decimals = "decimals"
        case value = "value"
        case precision = "precision"
    }
}

extension TradableAsset {
    func amountInDouble() -> Double{
        if self.value == nil || self.value?.count == 0 {
            return 0.0
        }
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
    
    func toTransferableAsset() -> O3WalletNativeAsset {
        var assetType = O3WalletNativeAsset.AssetType.neoAsset
        
        if self.symbol.uppercased() != O3WalletNativeAsset.NEO().symbol.uppercased() || self.symbol.uppercased() != O3WalletNativeAsset.GAS().symbol.uppercased() {
            assetType = O3WalletNativeAsset.AssetType.nep5Token
        }
        
       return O3WalletNativeAsset(id: self.id, name: self.name, symbol: self.symbol, decimals: self.decimals, value: self.amountInDouble(), assetType: assetType)
    }
}

extension O3WalletNativeAsset {
    func toTradableAsset() -> TradableAsset {
        let valueDouble = round(NSDecimalNumber(decimal: Decimal(self.value * pow(10, Double(self.decimals)))).doubleValue)
        return TradableAsset(id: self.id, name: self.name, symbol: self.symbol, decimals: self.decimals, value: String(format:"%0f",valueDouble), precision: self.decimals)
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

