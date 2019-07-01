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
import Neoutils
import LocalAuthentication

class O3KeychainManager {
    public enum O3KeychainResult<T> {
        case success(T)
        case failure(String) //could be error type
    }
    
    private static let keychainService = "network.o3.neo.wallet"
    
    //not used anymore maintain for backwards compatibilit if nep6 style key is not in keychain user is prompted to upgrade
    private static let legacySigningKeyPasswordKey = "ozoneActiveNep6Password"
    
    //legacy not used any more, maintain for backwards compatibility, if active in keychain, user will be prompted to upgrade
    private static let wifKey = "ozonePrivateKey"
    
    //O3 Keys for protected auth to o3 services
    private static let o3PrivKey = "o3PrivKey"
    private static let o3PubKey = "o3PubKey"
    
    private static let coinbaseEncryptionPass = "coinbaseEncryptionPass"
    
    static func getSigningKeyPassword(with prompt: String, completion: @escaping(O3KeychainResult<String>) -> ()) {
        DispatchQueue.global(qos: .userInitiated).async {
            let keychain = Keychain(service: self.keychainService)
            do {
                let signingKeyPass = try keychain
                        .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                        .authenticationPrompt(prompt)
                        .get(self.legacySigningKeyPasswordKey)
            
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
    
    static func removeLegacySigningKey(completion: @escaping(O3KeychainResult<String>) -> ()) {
        do {
            let keychain = Keychain(service: self.keychainService)
            try keychain
                .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                .remove(self.legacySigningKeyPasswordKey)
            completion(.success(""))
        } catch let e {
            completion(.failure(e.localizedDescription))
        }
    }
    
    static func checkSigningKeyExists(completion: @escaping(O3KeychainResult<Bool>) -> ()) {
        let keychain = Keychain(service: self.keychainService)
        do {
            //save pirivate key to keychain
            let containsKey = try keychain.contains(legacySigningKeyPasswordKey)
            completion(.success(containsKey))
        } catch let error {
            completion(.failure(error.localizedDescription))
        }
    }
    
    static func getWifKey(completion: @escaping(O3KeychainResult<String>) -> ()) {
        DispatchQueue.global(qos: .userInitiated).async {
            let keychain = Keychain(service: self.keychainService)
            let authString = String(format: OnboardingStrings.nep6AuthenticationPrompt, "My O3 Wallet")
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
    
    static func removeLegacyWifKey(completion: @escaping(O3KeychainResult<String>) -> ()) {
        do {
            let keychain = Keychain(service: self.keychainService)
            try keychain
                .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                .remove(self.wifKey)
        } catch _ {
            return
        }
    }
    
    static func removeSigningKeyPassword(completion: @escaping(O3KeychainResult<String>) -> ()) {
        do {
            let keychain = Keychain(service: self.keychainService)
            try keychain
                .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                .remove(self.legacySigningKeyPasswordKey)
        } catch _ {
            return
        }
    }
    
    static func inputPassword(account: NEP6.Account, completion: @escaping(O3KeychainResult<Wallet>) -> ()) {
        let alertController = UIAlertController(title: String(format: "Login to %@", account.label), message: "Enter the password you used to secure this wallet", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: OzoneAlert.okPositiveConfirmString, style: .default) { (_) in
            let inputPass = alertController.textFields?[0].text
            var error: NSError?
            if let wallet = Wallet(wallet: NeoutilsNEP2DecryptToWallet(account.key!, inputPass, &error)) {
                completion(.success(wallet))
            } else {
                OzoneAlert.alertDialog("Incorrect passphrase", message: "Please check your passphrase and try again", dismissTitle: "Ok") {
                    completion(.failure("Failed Decryption"))
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { (_) in
            completion(.failure("Failed Decryption"))
        }
        
        alertController.addTextField { (textField) in
            textField.isSecureTextEntry = true
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        UIApplication.shared.keyWindow?.rootViewController?.presentFromEmbedded(alertController, animated: true, completion: nil)
    }
    
    
    static func getWalletForNep6(for address: String, completion: @escaping(O3KeychainResult<Wallet>) -> ()) {
        let account = (NEP6.getFromFileSystem()?.getAccounts().first{ $0.address == address})!
       DispatchQueue.global(qos: .userInteractive).async {
            let keychain = Keychain(service: self.keychainService)
            let hashed = (address.data(using: .utf8)?.sha256.sha256.fullHexString)!
            let keychainKey = "NEP6." + hashed
            let accountLabel = account.label
            let authString = String(format: OnboardingStrings.nep6AuthenticationPrompt, accountLabel)
            do {
                let keyPass = try keychain
                    .accessibility(.whenUnlockedThisDeviceOnly, authenticationPolicy: .userPresence)
                    .authenticationPrompt(authString)
                    .get(keychainKey)
                if keyPass != nil {
                    DispatchQueue.main.async { HUD.show(.progress) }
                    var error: NSError? = nil
                    let currtime = Date().timeIntervalSince1970
                    let wif: String? = ""
        
                    if let wallet = Wallet(wallet: NeoutilsNEP2DecryptToWallet(account.key, keyPass, &error)) {
                        guard error == nil else {
                            completion(.failure(error!.localizedDescription))
                            return
                        }
                        DispatchQueue.main.async { HUD.hide() }
                        print(Date().timeIntervalSince1970 - currtime)
                        completion(.success(wallet))
                        return
                    } else {
                        completion(.failure(error!.localizedDescription))
                    }
                }
                
                O3KeychainManager.inputPassword(account: account) { result in
                    completion(result)
                }
            } catch let error {
                if error as! Status == Status.userCanceled {
                    completion(.failure(error.localizedDescription))
                } else {
                    O3KeychainManager.inputPassword(account: account) { result in
                        completion(result)
                    }
                }
            }
        }
    }   
    
    static func setNep6DecryptionPassword(for address: String, pass: String, completion: @escaping(O3KeychainResult<String>) -> ()) {
        let keychain = Keychain(service: self.keychainService)
        let hashed = (address.data(using: .utf8)?.sha256.sha256.fullHexString)!
        let keychainKey = "NEP6." + hashed
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                //save pirivate key to keychain
                try keychain
                    .accessibility(.whenUnlockedThisDeviceOnly, authenticationPolicy: .userPresence)
                    .set(pass, key: keychainKey)
                completion(.success(""))
            } catch let error {
                completion(.failure(error.localizedDescription))
            }
        }
    }
    
    static func removeNep6DecryptionPassword(for address: String, completion: @escaping(O3KeychainResult<Bool>) -> ()) {
        let keychain = Keychain(service: self.keychainService)
        let hashed = (address.data(using: .utf8)?.sha256.sha256.fullHexString)!
        let keychainKey = "NEP6." + hashed
        do {
            try keychain
                .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                .remove(keychainKey)
            completion(.success(true))
        } catch let error {
            completion(.failure(error.localizedDescription))
        }
    }
    
    static func checkNep6PasswordExists(for address: String, completion: @escaping(O3KeychainResult<Bool>) -> ()) {
        let keychain = Keychain(service: self.keychainService)
        let hashed = (address.data(using: .utf8)?.sha256.sha256.fullHexString)!
        let keychainKey = "NEP6." + hashed
        do {
            //save pirivate key to keychain
            let containsKey = try keychain.contains(keychainKey)
            completion(.success(true))
        } catch let error {
            completion(.failure(error.localizedDescription))
        }
    }
    
    static func authenticateWithBiometricOrPass(message: String, completion: @escaping(O3KeychainResult<Bool>) -> ()) {
        let localAuthenticationContext = LAContext()
        localAuthenticationContext.localizedFallbackTitle = "Use Passcode"
        #if targetEnvironment(simulator)
        completion(.success(true))
        return
        #endif
        
        var authError: NSError?
        let reasonString = message
        
        if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) {
            
            localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reasonString) { success, evaluateError in
                if success {
                    completion(.success(true))
                } else {
                    completion(.failure("Did not authenticate"))
                }
            }
        } else {
            completion(.failure("Did not authenticate"))
        }
    }
    
    static public func containsNep6Password(for address: String) -> Bool {
        // We spcify kSecUseAuthenticationUIFail so that the error
        // errSecInteractionNotAllowed will be returned if an item needs
        // to authenticate with UI and the authentication UI will not be presented.
        let hashed = (address.data(using: .utf8)?.sha256.sha256.fullHexString)!
        let keychainKey = "NEP6." + hashed
        
        let keychainQuery: [AnyHashable: Any] = [
            kSecClass as AnyHashable: kSecClassGenericPassword,
            kSecAttrService as AnyHashable: "network.o3.neo.wallet",
            kSecAttrAccount as AnyHashable: keychainKey,
            kSecUseAuthenticationUI as AnyHashable: kSecUseAuthenticationUIFail
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &result)
        
        // If that status is errSecInteractionNotAllowed, then
        // we know that the key is present, but you cannot interact with
        // it without authentication. Otherwise, we assume the key is not present.
        return status == errSecInteractionNotAllowed
    }
    
    static public func containsLegacyNep6() -> Bool {
        // We spcify kSecUseAuthenticationUIFail so that the error
        // errSecInteractionNotAllowed will be returned if an item needs
        // to authenticate with UI and the authentication UI will not be presented.

        let keychainQuery: [AnyHashable: Any] = [
            kSecClass as AnyHashable: kSecClassGenericPassword,
            kSecAttrService as AnyHashable: "network.o3.neo.wallet",
            kSecAttrAccount as AnyHashable: legacySigningKeyPasswordKey,
            kSecUseAuthenticationUI as AnyHashable: kSecUseAuthenticationUIFail
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &result)
        
        // If that status is errSecInteractionNotAllowed, then
        // we know that the key is present, but you cannot interact with
        // it without authentication. Otherwise, we assume the key is not present.
        return status == errSecInteractionNotAllowed
    }
    
    static public func createO3KeyPair() {
        //use neo format for generating pub/priv key
        var error: NSError? = nil
        let wallet = NeoutilsNewWallet(&error)
        let keychain = Keychain(service: self.keychainService)
        keychain[o3PubKey] = wallet!.publicKey()?.fullHexString
        keychain[o3PrivKey] = wallet!.privateKey()?.fullHexString
    }
    
    static public func getO3PubKey() -> String? {
        let keychain = Keychain(service: self.keychainService)
        return keychain[o3PubKey]
    }
    
    static public func getO3PrivKey() -> String? {
        let keychain = Keychain(service: self.keychainService)
        return keychain[o3PrivKey]
    }
    
    static public func setCoinbaseEncryptionPass() {
        var error: NSError? = nil
        let keychain = Keychain(service: self.keychainService)
        let wallet = NeoutilsNewWallet(&error)
        keychain[coinbaseEncryptionPass] = wallet!.privateKey()?.fullHexString
    }
    
    static public func getCoinbaseEncryptionPass() -> String {
        let keychain = Keychain(service: self.keychainService)
        let pass = keychain[coinbaseEncryptionPass]
        if pass == nil {
            setCoinbaseEncryptionPass()
            return keychain[coinbaseEncryptionPass]!
        } else {
            return pass!
        }
    }
}

