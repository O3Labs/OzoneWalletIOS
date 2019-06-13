//
//  CoinbaseDapiHandlers.swift
//  O3
//
//  Created by Andrei Terentiev on 6/13/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation

extension dAppBrowserViewModel {
    func handleCoinbaseConnect(message: dAppMessage) {
        CoinbaseClient.shared.getToken(code: message.data["token"] as! String) { result in
            switch result {
            case .failure(let e):
                self.delegate?.error(message: message, error: e.localizedDescription)
            case .success(let token):
                let expiryTime = Int(Date().timeIntervalSince1970) + token.expires_in   
                ExternalAccounts.setCoinbaseTokenForSession(token: token.access_token, expiryTime: expiryTime)
                CoinbaseClient.shared.getUser { result in
                    switch result {
                    case .failure(let e):
                        self.delegate?.error(message: message, error: e.localizedDescription)
                    case .success(let userData):
                        ExternalAccounts.getFromFileSystem().setAccount(platform: ExternalAccounts.Platforms.COINBASE, unencryptedToken: token.refresh_token,
                                                                        scope: token.scope, accountMetaData: nil)
                        self.delegate?.didFinishMessage(message: message, response: true)
                    }
                }
            }
        }
    }
}
