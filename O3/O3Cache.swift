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
    
    static var storage: Storage<TransferableAsset>? {
        let diskConfig = DiskConfig(name: storageName)
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
        
        let storage = try? Storage(
            diskConfig: diskConfig,
            memoryConfig: memoryConfig,
            transformer: TransformerFactory.forCodable(ofType: TransferableAsset.self)
        )
        return storage
    }
    
    static var arrayStorage: Storage<[TransferableAsset]>? {
        let diskConfig = DiskConfig(name: storageName)
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
        
        let storage = try? Storage(
            diskConfig: diskConfig,
            memoryConfig: memoryConfig,
            transformer: TransformerFactory.forCodable(ofType: [TransferableAsset].self)
        )
        return storage
    }
    
    static func clear() {
        ((try? storage?.removeAll()) as ()??)
        ((try? arrayStorage?.removeAll()) as ()??)
    }
    
    // MARK: Cache Setters for Writable Balances
    static func setNEOForSession(neoBalance: Int) {
        let neoAsset = TransferableAsset(id: AssetId.neoAssetId.rawValue, name: "NEO", symbol: "NEO",
                                         decimals: 8, value: Double(neoBalance), assetType: .neoAsset)
        ((try? storage?.setObject(neoAsset, forKey: keys.neo.rawValue)) as ()??)
    }
    
    static func setGASForSession(gasBalance: Double) {
        let gasAsset = TransferableAsset(id: AssetId.gasAssetId.rawValue, name: "GAS", symbol: "GAS",
                                         decimals: 8, value: gasBalance, assetType: .neoAsset)
        ((try? storage?.setObject(gasAsset, forKey: keys.gas.rawValue)) as ()??)
        
    }
    
    static func setTokenAssetsForSession(tokens: [TransferableAsset]) {
        ((try? arrayStorage?.setObject(tokens, forKey: keys.tokens.rawValue)) as ()??)
        
    }
    
    static func setOntologyAssetsForSession(tokens: [TransferableAsset]) {
        ((try? arrayStorage?.setObject(tokens, forKey: keys.ontology.rawValue)) as ()??)
    }
    
    // MARK: Cache Setters for Read Only Balances
    static func setReadOnlyNEOForSession(neoBalance: Int, address: String) {
        
        let neoAsset = TransferableAsset(id: AssetId.neoAssetId.rawValue, name: "NEO", symbol: "NEO",
                                         decimals: 8, value: Double(neoBalance), assetType: .neoAsset)
        ((try? storage?.setObject(neoAsset, forKey: address + "_" + keys.readOnlyNeo.rawValue)) as ()??)
        
    }
    
    static func setReadOnlyGasForSession(gasBalance: Double, address: String) {
        let gasAsset = TransferableAsset(id: AssetId.gasAssetId.rawValue, name: "GAS", symbol: "GAS",
                                         decimals: 8, value: gasBalance, assetType: .neoAsset)
        ((try? storage?.setObject(gasAsset, forKey: address + "_" + keys.readOnlyGas.rawValue)) as ()??)
        
    }
    
    static func setReadOnlyTokensForSession(tokens: [TransferableAsset], address: String) {
        ((try? arrayStorage?.setObject(tokens, forKey: address + "_" + keys.readOnlyTokens.rawValue)) as ()??)
    }
    
    static func setReadOnlyOntologyAssetsForSession(tokens: [TransferableAsset], address: String) {
        ((try? arrayStorage?.setObject(tokens, forKey: address + "_" + keys.readOnlyOntologyAssets.rawValue)) as ()??)
    }

    
    // MARK: Cache Getters for Writable Balances
    static func gas() -> TransferableAsset {
        var cachedGASBalance = TransferableAsset(id: AssetId.gasAssetId.rawValue, name: "GAS", symbol: "GAS",
                                                 decimals: 8, value: 0, assetType: .neoAsset)
        
        do {
            cachedGASBalance = try storage?.object(forKey: keys.gas.rawValue) ?? cachedGASBalance
        } catch {
            
        }
        
        return cachedGASBalance
    }
    
    static func neo() -> TransferableAsset {
        var cachedNEOBalance = TransferableAsset(id: AssetId.neoAssetId.rawValue, name: "NEO", symbol: "NEO",
                                                 decimals: 0, value: 0, assetType: .neoAsset)
        
        do {
            cachedNEOBalance = try storage?.object(forKey: keys.neo.rawValue) ?? cachedNEOBalance
        } catch {
            
        }
        
        return cachedNEOBalance
    }
    
    static func tokenAssets() -> [TransferableAsset] {
        var cachedTokens = [TransferableAsset]()
        do {
            cachedTokens = try arrayStorage?.object(forKey: keys.tokens.rawValue) ?? cachedTokens
        } catch {
            
        }
        return cachedTokens
    }
    
    static func ontologyAssets() -> [TransferableAsset] {
        var cachedTokens = [TransferableAsset]()
        do {
            cachedTokens = try arrayStorage?.object(forKey: keys.ontology.rawValue) ?? cachedTokens
        } catch {
            
        }
        return cachedTokens
    }
    
    // MARK: Cache Getters For Read Only Balances
    static func readOnlyGas(address: String) -> TransferableAsset {
        var cachedGASBalance = TransferableAsset(id: AssetId.gasAssetId.rawValue, name: "GAS", symbol: "GAS",
                                                 decimals: 8, value: 0, assetType: .neoAsset )
        do {
           cachedGASBalance = try storage?.object(forKey: address + "_" + keys.readOnlyGas.rawValue) ?? cachedGASBalance
        } catch {
            
        }
        return cachedGASBalance
    }
    
    static func readOnlyNeo(address: String) -> TransferableAsset {
        var cachedNEOBalance = TransferableAsset(id: AssetId.neoAssetId.rawValue, name: "NEO", symbol: "NEO",
                                                 decimals: 8, value: 0, assetType: .neoAsset)
        do {
            cachedNEOBalance = try storage?.object(forKey: address + "_" + keys.readOnlyNeo.rawValue) ?? cachedNEOBalance
        } catch {
            
        }
        return cachedNEOBalance
    }
    
    static func readOnlyTokens(address: String) -> [TransferableAsset] {
        var cachedTokens = [TransferableAsset]()
        do {
           cachedTokens = try arrayStorage?.object(forKey: address + "_" + keys.readOnlyTokens.rawValue) ?? cachedTokens
        } catch {
            
        }
        return cachedTokens
    }
    
    static func readOnlyOntologyAssets(address: String) -> [TransferableAsset] {
        var cachedTokens = [TransferableAsset]()
        do {
            cachedTokens = try arrayStorage?.object(forKey: address + "_" + keys.readOnlyOntologyAssets.rawValue) ?? cachedTokens
        } catch {
            
        }
        return cachedTokens
    }
    
    
    static var memoryCache = NSCache<NSString, AnyObject>()
    
    static var memoryStorage: Storage<[dAppProtocol.GetBalanceResponseElement]>? {
        let expiry = Date().addingTimeInterval(TimeInterval(30))
        //memory only cache
        let memoryConfig = MemoryConfig(
            // Expiry date that will be applied by default for every added object
            // if it's not overridden in the `setObject(forKey:expiry:)` method
            expiry: .date(expiry), //30seconds
            countLimit: 50,
            totalCostLimit: 0
        )
        
        let diskConfig = DiskConfig(
            name: "O3DAPPCACHE",
            expiry: .date(expiry)
        )
        let storage = try? Storage(
            diskConfig: diskConfig,
            memoryConfig: memoryConfig,
            transformer: TransformerFactory.forCodable(ofType: [dAppProtocol.GetBalanceResponseElement].self)
        )
        return storage
    }
    
}
