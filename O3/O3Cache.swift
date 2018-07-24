//
//  O3Cache.swift
//  O3
//
//  Created by Andrei Terentiev on 4/16/18.
//  Copyright © 2018 drei. All rights reserved.
//

import Foundation
import Cache

class O3Cache {
    
    static let storageName: String = "O3Cache"
    
    enum keys: String {
        case gas
        case neo
        case tokens
        case ontology
        case readOnlyGas
        case readOnlyNeo
        case readOnlyTokens
        case readOnlyOntologyAssets
    }

    static func clear() {
        if let storage = try? Storage(diskConfig: DiskConfig(name: storageName)) {
            try? storage.removeAll()
        }
    }

    // MARK: Cache Setters for Writable Balances
    static func setNEOForSession(neoBalance: Int) {
        if let storage = try? Storage(diskConfig: DiskConfig(name: storageName)) {
            let neoAsset = TransferableAsset(id: AssetId.neoAssetId.rawValue, name: "NEO", symbol: "NEO",
                                             decimals: 8, value: Double(neoBalance), assetType: .neoAsset)
            try? storage.setObject(neoAsset, forKey: keys.neo.rawValue)
        }
    }

    static func setGASForSession(gasBalance: Double) {
        if let storage = try? Storage(diskConfig: DiskConfig(name: storageName)) {
            let gasAsset = TransferableAsset(id: AssetId.gasAssetId.rawValue, name: "GAS", symbol: "GAS",
                                             decimals: 8, value: gasBalance, assetType: .neoAsset)
            try? storage.setObject(gasAsset, forKey: keys.gas.rawValue)
        }
    }

    static func setTokenAssetsForSession(tokens: [TransferableAsset]) {
        if let storage = try? Storage(diskConfig: DiskConfig(name: storageName)) {
            try? storage.setObject(tokens, forKey: keys.tokens.rawValue)
        }
    }
    
    static func setOntologyAssetsForSession(tokens: [TransferableAsset]) {
        if let storage = try? Storage(diskConfig: DiskConfig(name: storageName)) {
            try? storage.setObject(tokens, forKey: keys.ontology.rawValue)
        }
    }
    
    // MARK: Cache Setters for Read Only Balances
    static func setReadOnlyNEOForSession(neoBalance: Int) {
        if let storage = try? Storage(diskConfig: DiskConfig(name: storageName)) {
            let neoAsset = TransferableAsset(id: AssetId.neoAssetId.rawValue, name: "NEO", symbol: "NEO",
                                             decimals: 8, value: Double(neoBalance), assetType: .neoAsset)
            try? storage.setObject(neoAsset, forKey: keys.readOnlyNeo.rawValue)
        }
    }

    static func setReadOnlyGasForSession(gasBalance: Double) {
        if let storage = try? Storage(diskConfig: DiskConfig(name: storageName)) {
            let gasAsset = TransferableAsset(id: AssetId.gasAssetId.rawValue, name: "GAS", symbol: "GAS",
                                                     decimals: 8, value: gasBalance, assetType: .neoAsset)
            try? storage.setObject(gasAsset, forKey: keys.readOnlyGas.rawValue)
        }
    }

    static func setReadOnlyTokensForSession(tokens: [TransferableAsset]) {
        if let storage = try? Storage(diskConfig: DiskConfig(name: storageName)) {
            try? storage.setObject(tokens, forKey: keys.readOnlyTokens.rawValue)
        }
    }
    
    static func setReadOnlyOntologyAssetsForSession(tokens: [TransferableAsset]) {
        if let storage = try? Storage(diskConfig: DiskConfig(name: storageName)) {
            try? storage.setObject(tokens, forKey: keys.readOnlyOntologyAssets.rawValue)
        }
    }

    // MARK: Cache Getters for Writable Balances
    static func gas() -> TransferableAsset {
        var cachedGASBalance = TransferableAsset(id: AssetId.gasAssetId.rawValue, name: "GAS", symbol: "GAS",
                                                 decimals: 8, value: 0, assetType: .neoAsset)
        if let storage =  try? Storage(diskConfig: DiskConfig(name: storageName)) {
            do {
                cachedGASBalance = try storage.object(ofType: TransferableAsset.self, forKey: keys.gas.rawValue)
            } catch {

            }
        }
        return cachedGASBalance
    }

    static func neo() -> TransferableAsset {
        var cachedNEOBalance = TransferableAsset(id: AssetId.neoAssetId.rawValue, name: "NEO", symbol: "NEO",
                                                 decimals: 0, value: 0, assetType: .neoAsset)
        if let storage =  try? Storage(diskConfig: DiskConfig(name: storageName)) {
            cachedNEOBalance = (try? storage.object(ofType: TransferableAsset.self, forKey: keys.neo.rawValue)) ?? cachedNEOBalance
        }
        return cachedNEOBalance
    }

    static func tokenAssets() -> [TransferableAsset] {
        var cachedTokens = [TransferableAsset]()
        if let storage =  try? Storage(diskConfig: DiskConfig(name: storageName)) {
            cachedTokens = (try? storage.object(ofType: [TransferableAsset].self, forKey: keys.tokens.rawValue)) ?? []
        }
        return cachedTokens
    }
    
    static func ontologyAssets() -> [TransferableAsset] {
        var cachedTokens = [TransferableAsset]()
        if let storage =  try? Storage(diskConfig: DiskConfig(name: storageName)) {
            cachedTokens = (try? storage.object(ofType: [TransferableAsset].self, forKey: keys.ontology.rawValue)) ?? []
        }
        return cachedTokens
    }

    // MARK: Cache Getters For Read Only Balances
    static func readOnlyGas() -> TransferableAsset {
        var cachedGASBalance = TransferableAsset(id: AssetId.gasAssetId.rawValue, name: "GAS", symbol: "GAS",
                                                                   decimals: 8, value: 0, assetType: .neoAsset )
        if let storage =  try? Storage(diskConfig: DiskConfig(name: storageName)) {
            cachedGASBalance = (try? storage.object(ofType: TransferableAsset.self, forKey: keys.readOnlyGas.rawValue)) ?? cachedGASBalance
        }
        return cachedGASBalance
    }

    static func readOnlyNeo() -> TransferableAsset {
        var cachedNEOBalance = TransferableAsset(id: AssetId.neoAssetId.rawValue, name: "NEO", symbol: "NEO",
                                                 decimals: 8, value: 0, assetType: .neoAsset)
        if let storage =  try? Storage(diskConfig: DiskConfig(name: storageName)) {
            cachedNEOBalance = (try? storage.object(ofType: TransferableAsset.self, forKey: keys.readOnlyNeo.rawValue)) ?? cachedNEOBalance
        }
        return cachedNEOBalance
    }

    static func readOnlyTokens() -> [TransferableAsset] {
        var cachedTokens = [TransferableAsset]()
        if let storage =  try? Storage(diskConfig: DiskConfig(name: storageName)) {
            cachedTokens = (try? storage.object(ofType: [TransferableAsset].self, forKey: keys.readOnlyTokens.rawValue)) ?? []
        }
        return cachedTokens
    }

    static func readOnlyOntologyAssets() -> [TransferableAsset] {
        var cachedTokens = [TransferableAsset]()
        if let storage =  try? Storage(diskConfig: DiskConfig(name: storageName)) {
            cachedTokens = (try? storage.object(ofType: [TransferableAsset].self, forKey: keys.readOnlyOntologyAssets.rawValue)) ?? []
        }
        return cachedTokens
    }
}
