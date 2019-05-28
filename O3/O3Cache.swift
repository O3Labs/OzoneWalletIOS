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
        case gasForAddress
        case neoForAddress
        case tokensForAddress
        case ontologyForAddress
        case portfolioValue
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
        ((try? portfolioStorage?.removeAll()) as ()??)
    }
    
    // MARK: Cache Setters for Read Only Balances
    static func setNeoBalance(neoBalance: Int, address: String) {
        
        let neoAsset = TransferableAsset(id: AssetId.neoAssetId.rawValue, name: "NEO", symbol: "NEO",
                                         decimals: 8, value: Double(neoBalance), assetType: .neoAsset)
        ((try? storage?.setObject(neoAsset, forKey: address + "_" + keys.neoForAddress.rawValue)) as ()??)
        
    }
    
    static func setGasBalance(gasBalance: Double, address: String) {
        let gasAsset = TransferableAsset(id: AssetId.gasAssetId.rawValue, name: "GAS", symbol: "GAS",
                                         decimals: 8, value: gasBalance, assetType: .neoAsset)
        ((try? storage?.setObject(gasAsset, forKey: address + "_" + keys.gasForAddress.rawValue)) as ()??)
        
    }
    
    static func setTokensBalance(tokens: [TransferableAsset], address: String) {
        ((try? arrayStorage?.setObject(tokens, forKey: address + "_" + keys.tokensForAddress.rawValue)) as ()??)
    }
    
    static func setOntologyBalance(tokens: [TransferableAsset], address: String) {
        ((try? arrayStorage?.setObject(tokens, forKey: address + "_" + keys.ontologyForAddress.rawValue)) as ()??)
    }
    
    // MARK: Cache Getters For Read Only Balances
    static func gasBalance(for address: String) -> TransferableAsset {
        var cachedGASBalance = TransferableAsset(id: AssetId.gasAssetId.rawValue, name: "GAS", symbol: "GAS",
                                                 decimals: 8, value: 0, assetType: .neoAsset )
        do {
           cachedGASBalance = try storage?.object(forKey: address + "_" + keys.gasForAddress.rawValue) ?? cachedGASBalance
        } catch {
            
        }
        return cachedGASBalance
    }
    
    static func neoBalance(for address: String) -> TransferableAsset {
        var cachedNEOBalance = TransferableAsset(id: AssetId.neoAssetId.rawValue, name: "NEO", symbol: "NEO",
                                                 decimals: 8, value: 0, assetType: .neoAsset)
        do {
            cachedNEOBalance = try storage?.object(forKey: address + "_" + keys.neoForAddress.rawValue) ?? cachedNEOBalance
        } catch {
            
        }
        return cachedNEOBalance
    }
    
    static func tokensBalance(for address: String) -> [TransferableAsset] {
        var cachedTokens = [TransferableAsset]()
        do {
           cachedTokens = try arrayStorage?.object(forKey: address + "_" + keys.tokensForAddress.rawValue) ?? cachedTokens
        } catch {
            
        }
        return cachedTokens
    }
    
    static func ontologyBalances(for address: String) -> [TransferableAsset] {
        var cachedTokens = [TransferableAsset]()
        do {
            cachedTokens = try arrayStorage?.object(forKey: address + "_" + keys.ontologyForAddress.rawValue) ?? cachedTokens
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
    
    
    //address to string portfolio value
    static var portfolioStorage: Storage<AccountValue>? {
        let expiry = Date().addingTimeInterval(TimeInterval(3600))
        let diskConfig = DiskConfig(name: "portfolioStorage", expiry: .date(expiry) )
        let memoryConfig = MemoryConfig(expiry: .date(expiry), countLimit: 10, totalCostLimit: 10)
        
        let storage = try? Storage(
            diskConfig: diskConfig,
            memoryConfig: memoryConfig,
            transformer: TransformerFactory.forCodable(ofType: AccountValue.self)
        )
        return storage
    }
    
    static func setCachedPortfolioValue(for address: String, portfolioValue: AccountValue) {
        ((try? O3Cache.portfolioStorage?.setObject(portfolioValue, forKey: address + "_" + keys.portfolioValue.rawValue)) as ()??)
    }
    
    static func getCachedPortfolioValue(for address: String)-> AccountValue? {
        var cachedportfolioValue: AccountValue?
        do {
            try O3Cache.portfolioStorage?.removeExpiredObjects()
            cachedportfolioValue = try O3Cache.portfolioStorage?.object(forKey: address + "_" + keys.portfolioValue.rawValue)
        } catch {
            
        }
        return cachedportfolioValue
    }
}
