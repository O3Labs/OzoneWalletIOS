//
//  TokenSales.swift
//  O3
//
//  Created by Andrei Terentiev on 4/12/18.
//  Copyright © 2018 drei. All rights reserved.
//

import Foundation

public struct TokenSales: Codable {
    var live: [SaleInfo]
    var subscribeURL: String

    enum CodingKeys: String, CodingKey {
        case live
        case subscribeURL
    }

    public init(live: [SaleInfo], subscribeURL: String) {
        self.live = live
        self.subscribeURL = subscribeURL
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let live: [SaleInfo] = try container.decode([SaleInfo].self, forKey: .live)
        let subscribeURL: String = try container.decode(String.self, forKey: .subscribeURL)
        self.init(live: live, subscribeURL: subscribeURL)
    }

    public struct SaleInfo: Codable {
        var name: String
        var symbol: String
        var shortDescription: String
        var scriptHash: String
        var webURL: String
        var imageURL: String
        var squareLogoURL: String
        var startTime: Double
        var endTime: Double
        var acceptingAssets: [AcceptingAsset]
        var info: [InfoRow]
        var address: String
        var companyID: String
        var kycStatus: KYCStatus

        enum CodingKeys: String, CodingKey {
            case name
            case symbol
            case shortDescription
            case scriptHash
            case webURL
            case imageURL

            case squareLogoURL
            case startTime
            case endTime
            case acceptingAssets
            case info

            case address
            case companyID
            case kycStatus
        }

        public init(name: String, symbol: String, shortDescription: String, scriptHash: String, webURL: String, imageURL: String, squareLogoURL: String, startTime: Double, endTime: Double,
                    acceptingAssets: [AcceptingAsset], info: [InfoRow], address: String, companyID: String, kycStatus: KYCStatus) {
            self.name = name
            self.symbol = symbol
            self.shortDescription = shortDescription
            self.scriptHash = scriptHash
            self.webURL = webURL
            self.imageURL = imageURL
            self.squareLogoURL = squareLogoURL
            self.startTime = startTime
            self.endTime = endTime
            self.acceptingAssets = acceptingAssets
            self.info = info
            self.address = address
            self.companyID = companyID
            self.kycStatus = kycStatus
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let name: String = try container.decode(String.self, forKey: .name)
            let symbol: String = try container.decode(String.self, forKey: .symbol)
            let shortDescription: String =  try container.decode(String.self, forKey: .shortDescription)
            let scriptHash: String = try container.decode(String.self, forKey: .scriptHash)
            let webURL: String = try container.decode(String.self, forKey: .webURL)
            let imageURL: String = try container.decode(String.self, forKey: .imageURL)
            let squareLogoURL: String = try container.decode(String.self, forKey: .squareLogoURL)
            let startTime: Double = try container.decode(Double.self, forKey: .startTime)
            let endTime: Double = try container.decode(Double.self, forKey: .endTime)
            let acceptingAssets: [AcceptingAsset] = try container.decode([AcceptingAsset].self, forKey: .acceptingAssets)
            let info: [InfoRow] = try container.decode([InfoRow].self, forKey: .info)
            let address: String? = try? container.decode(String.self, forKey: .address)
            let companyID: String = try container.decode(String.self, forKey: .companyID)
            let kycStatus: KYCStatus = try container.decode(KYCStatus.self, forKey: .kycStatus)

            self.init(name: name, symbol: symbol, shortDescription: shortDescription,
                      scriptHash: scriptHash, webURL: webURL, imageURL: imageURL,
                      squareLogoURL: squareLogoURL, startTime: startTime, endTime: endTime,
                      acceptingAssets: acceptingAssets, info: info, address: address ?? "",
                      companyID: companyID, kycStatus: kycStatus)
        }

        public struct KYCStatus: Codable {
            var address: String
            var verified: Bool

            enum CodingKeys: String, CodingKey {
                case address
                case verified
            }

            public init(address: String, verified: Bool) {
                self.address = address
                self.verified = verified
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let address: String = try container.decode(String.self, forKey: .address)
                let verified: Bool = try container.decode(Bool.self, forKey: .verified)
                self.init(address: address, verified: verified)
            }
        }

        public struct AcceptingAsset: Codable {
            var asset: String
            var basicRate: Decimal
            var max: Double
            var min: Double
            var price: RealTimePricing?

            enum CodingKeys: String, CodingKey {
                case asset
                case basicRate
                case max
                case min
                case price
            }

            public init(asset: String, basicRate: Decimal, max: Double, min: Double, price: RealTimePricing?) {
                self.asset = asset
                self.basicRate = basicRate
                self.max = max
                self.min = min
                self.price = price
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let asset: String = try container.decode(String.self, forKey: .asset)
                let basicRate: Decimal = try container.decode(Decimal.self, forKey: .basicRate)
                let max: Double = try container.decode(Double.self, forKey: .max)
                let min: Double = try container.decode(Double.self, forKey: .min)
                let price: RealTimePricing? = try? container.decode(RealTimePricing.self, forKey: .price)
                self.init(asset: asset, basicRate: basicRate, max: max, min: min, price: price)
            }

            public struct RealTimePricing: Codable {
                var currency: String
                var lastUpdate: Int
                var price: Decimal
                var symbol: String

                enum CodingKeys: String, CodingKey {
                    case currency
                    case lastUpdate
                    case price
                    case symbol
                }

                public init(currency: String, lastUpdate: Int, price: Decimal, symbol: String) {
                    self.currency = currency
                    self.lastUpdate = lastUpdate
                    self.price = price
                    self.symbol = symbol
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let currency = try container.decode(String.self, forKey: .currency)
                    let lastUpdate = try container.decode(Int.self, forKey: .lastUpdate)
                    let price = try container.decode(Decimal.self, forKey: .price)
                    let symbol = try container.decode(String.self, forKey: .symbol)
                    self.init(currency: currency, lastUpdate: lastUpdate, price: price, symbol: symbol)
                }
            }
        }

        public struct InfoRow: Codable {
            var label: String
            var value: String
            var link: String?

            enum CodingKeys: String, CodingKey {
                case label
                case value
                case link
            }

            public init(label: String, value: String, link: String?) {
                self.label = label
                self.value = value
                self.link = link
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let label: String = try container.decode(String.self, forKey: .label)
                let value: String = try container.decode(String.self, forKey: .value)
                let link: String? = try container.decodeIfPresent(String.self, forKey: .link)
                self.init(label: label, value: value, link: link)
            }
        }
    }
}
