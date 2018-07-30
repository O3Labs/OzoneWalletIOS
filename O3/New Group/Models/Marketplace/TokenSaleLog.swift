//
//  TokenSaleLog.swift
//  O3
//
//  Created by Andrei Terentiev on 7/24/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation

public struct TokenSaleUnsignedData: Encodable {
    var amount: String
    var asset: AcceptingAsset
    var txid: String

    enum CodingKeys: String, CodingKey {
        case amount
        case asset
        case txid
    }

    public init(amount: Double, asset: TokenSales.SaleInfo.AcceptingAsset, txid: String) {
        let amountFormatter = NumberFormatter()
        amountFormatter.minimumFractionDigits = 0
        amountFormatter.groupingSeparator = ""
        amountFormatter.locale = Locale(identifier: "en_US")
        amountFormatter.maximumFractionDigits = 8
        self.amount = amountFormatter.string(for: amount)!
        self.asset = AcceptingAsset(asset: asset)
        self.txid = txid
    }

    public struct AcceptingAsset: Encodable {
        var asset: String
        var basicRate: String
        var max: String
        var min: String
        var price: RealTimePricing?

        enum CodingKeys: String, CodingKey {
            case asset
            case basicRate
            case max
            case min
            case price
        }

        public init(asset: TokenSales.SaleInfo.AcceptingAsset) {
            let amountFormatter = NumberFormatter()
            amountFormatter.minimumFractionDigits = 0
            amountFormatter.groupingSeparator = ""
            amountFormatter.locale = Locale(identifier: "en_US")
            amountFormatter.maximumFractionDigits = 8
            self.asset = asset.asset
            self.basicRate = amountFormatter.string(for: asset.basicRate)!
            self.max = amountFormatter.string(for: asset.max)!
            self.min = amountFormatter.string(for: asset.min)!
            self.price = RealTimePricing(price: asset.price!)

        }

        public struct RealTimePricing: Encodable {
            var currency: String
            var lastUpdate: String
            var price: String
            var symbol: String

            enum CodingKeys: String, CodingKey {
                case currency
                case lastUpdate
                case price
                case symbol
            }

            public init(price: TokenSales.SaleInfo.AcceptingAsset.RealTimePricing) {
                let amountFormatter = NumberFormatter()
                amountFormatter.minimumFractionDigits = 0
                amountFormatter.locale = Locale(identifier: "en_US")
                amountFormatter.maximumFractionDigits = 8
                self.currency = price.currency
                self.symbol = price.symbol
                self.lastUpdate = amountFormatter.string(for: price.lastUpdate)!
                self.price = amountFormatter.string(for: price.price)!
            }
        }
    }
}

public struct TokenSaleLog: Encodable {
    var data: TokenSaleUnsignedData
    var publicKey: String
    var signature: String

    enum CodingKeys: String, CodingKey {
        case data
        case publicKey
        case signature
    }

    public init(data: TokenSaleUnsignedData, signature: String, publicKey: String) {
        self.data = data
        self.publicKey = publicKey
        self.signature = signature
    }
}
