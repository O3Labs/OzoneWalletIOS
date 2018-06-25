//
//  Router.swift
//  O3
//
//  Created by Apisit Toompakdee on 6/25/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

class Router: NSObject {
    
    static func parseNEP9URL(url: URL) {
        if Authenticated.account == nil {
            return
        }
        var updatedURL: URL = url
        if !url.absoluteString.contains("neo://") {
            let fullURL = updatedURL.absoluteString.replacingOccurrences(of: "neo:", with: "neo://")
            updatedURL = URL(string: fullURL)!
        }
        let address = updatedURL.host?.removingPercentEncoding
        let asset = updatedURL.valueOf("asset")
        let amount = updatedURL.valueOf("amount")
        //Get account state
        O3APIClient(network: AppState.network).getAccountState(address: Authenticated.account!.address) { result in
            DispatchQueue.main.async {
                switch result {
                case .failure:
                    return
                case .success(let accountState):
                    
                    var neoBalance: Int = Int(O3Cache.neo().value)
                    var gasBalance: Double = O3Cache.gas().value
                    
                    for asset in accountState.assets {
                        if asset.id.contains(AssetId.neoAssetId.rawValue) {
                            neoBalance = Int(asset.value)
                        } else {
                            gasBalance = asset.value
                        }
                    }
                    
                    var tokenAssets = O3Cache.tokenAssets()
                    
                    var selectedAsset: TransferableAsset?
                    for token in accountState.nep5Tokens {
                        tokenAssets.append(token)
                        if token.id == asset {
                            selectedAsset = token
                        }
                    }
                    O3Cache.setGASForSession(gasBalance: gasBalance)
                    O3Cache.setNEOForSession(neoBalance: neoBalance)
                    O3Cache.setTokenAssetsForSession(tokens: tokenAssets)
                    O3Cache.setReadOnlyOntologyAssetsForSession(tokens: accountState.ontology)
                    
                    if asset?.lowercased() == "neo" {
                        Controller().openSend(to: address!, selectedAsset: TransferableAsset.NEO(), amount: amount)
                    } else if asset?.lowercased() == "gas" {
                        Controller().openSend(to: address!, selectedAsset: TransferableAsset.GAS(), amount: amount)
                    } else if selectedAsset != nil {
                        Controller().openSend(to: address!, selectedAsset: selectedAsset!, amount: amount)
                    }
                }
            }
        }
    }
    
}
