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
        if Authenticated.wallet == nil {
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
        O3APIClient(network: AppState.network).getAccountState(address: Authenticated.wallet!.address) { result in
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
                    O3Cache.setOntologyAssetsForSession(tokens: accountState.ontology)

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
    
    static func parseO3NetworkScheme(url: URL) {
        switch url.host {
        case "portfolio":
            Controller().focusOnTab(tabIndex: 0)
        case "wallet":
            Controller().focusOnTab(tabIndex: 1)
        case "marketplace":
            Controller().focusOnTab(tabIndex: 2)
        case "news":
            Controller().focusOnTab(tabIndex: 3)
        case "settings":
            Controller().focusOnTab(tabIndex: 4)
        default:
            Controller().focusOnTab(tabIndex: 0)
        }
    }
    
    static func parseO3BrowserScheme(url: URL) {
        switch url.host {
        case "dapp":
            var dappurl = URLComponents(string: url.absoluteString)?.queryItems?.filter({$0.name == "url"}).first?.value!
            Controller().openDappBrowserV2(url: URL(string: dappurl ?? "www.o3.network")!)
        default:
            return
        }
    }
}
