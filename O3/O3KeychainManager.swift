//
//  O3KeychainManager.swift
//  O3
//
//  Created by Andrei Terentiev on 4/11/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import PKHUD
import KeychainAccess

class O3KeychainManager {
    public enum O3KeychainResult<T> {
        case success(T)
        case failure(String) //could be error type
    }
    
    private static let keychainService = "network.o3.neo.wallet"
    private static let signingKeyPasswordKey = "ozoneActiveNep6Password"
    
    //legacy not used any more, maintain for backwards compatibility
    private static let wifKey = "ozonePrivateKey"
    
    static func getSigningKeyPassword(completion: @escaping(O3KeychainResult<String>) -> ()) {
        DispatchQueue.global(qos: .userInitiated).async {
            let keychain = Keychain(service: self.keychainService)
            let authString = String(format: OnboardingStrings.nep6AuthenticationPrompt, (NEP6.getFromFileSystem()?.accounts[0].label)!)
            do {
                let signingKeyPass = try keychain
                        .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                        .authenticationPrompt(authString)
                        .get(self.signingKeyPasswordKey)
            
                guard signingKeyPass != nil else {
                    completion(.failure("The Key does not exist"))
                    return
                }
                completion(.success(signingKeyPass!))
            } catch let error {
                completion(.failure(error.localizedDescription))
            }
        }
    }
    
    static func getWifKey(completion: @escaping(O3KeychainResult<String>) -> ()) {
        DispatchQueue.global(qos: .userInitiated).async {
            let keychain = Keychain(service: self.keychainService)
            let authString = String(format: OnboardingStrings.nep6AuthenticationPrompt, (NEP6.getFromFileSystem()?.accounts[0].label)!)
            do {
                let wif = try keychain
                    .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                    .authenticationPrompt(authString)
                    .get(self.wifKey)
                
                guard wif != nil else {
                    completion(.failure("The Key does not exist"))
                    return
                }
                completion(.success(wif!))
            } catch let error {
                completion(.failure(error.localizedDescription))
            }
        }
    }
    
    static func getNep6DecryptionPassword(for address: String, completion: @escaping(O3KeychainResult<String>) -> ()) throws {
        DispatchQueue.global(qos: .userInitiated).async {
            let keychain = Keychain(service: self.keychainService)
            let hashed = (address.data(using: .utf8)?.sha256.sha256.fullHexString)!
            let keychainKey = "NEP6." + hashed
            let accountLabel = (NEP6.getFromFileSystem()?.accounts.first{ $0.address == address}!.label)!
            let authString = String(format: OnboardingStrings.nep6AuthenticationPrompt, accountLabel)
            do {
                let keyPass = try keychain
                    .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                    .authenticationPrompt(authString)
                    .get(keychainKey)
                
                guard keyPass != nil else {
                    completion(.failure("The Key does not exist"))
                    return
                }
                completion(.success(keyPass!))
            } catch let error {
                completion(.failure(error.localizedDescription))
            }
        }
    }
    
    static func setNep6DecryptionPassword(for address: String) {
        
    }
}
