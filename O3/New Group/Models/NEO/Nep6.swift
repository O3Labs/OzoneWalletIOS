//
//  Nep6.swift
//  O3
//
//  Created by Andrei Terentiev on 10/24/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import Neoutils
import KeychainAccess

public class NEP6: Codable {
    var name: String
    var version: String
    var scrypt: ScryptParams
    var accounts: [Account]
    var extra: String
    
    enum NEP6Error: Error {
        case invalidAddress
        case invalidName
        case invalidKey
        case duplicateField
    }
    
    public enum CodingKeys: String, CodingKey {
        case name
        case version
        case scrypt
        case accounts
        case extra
    }
    
    public init(name: String, version: String, accounts: [Account], extra: String = "") {
        self.name = name
        self.version = version
        self.accounts = accounts
        self.extra = extra
        self.scrypt = ScryptParams(n: 16384, r: 8, p: 8)
    }
    
    required public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name: String = try container.decode(String.self, forKey: .name)
        let version: String = try container.decode(String.self, forKey: .version)
        let scrypt: ScryptParams = try container.decode(ScryptParams.self, forKey: .scrypt)
        let accounts: [Account] = try container.decode([Account].self, forKey: .accounts)
        self.init(name: name, version: version, accounts: accounts)
    }
    
    public class Account: Codable {
        var address: String
        var label: String
        var isDefault: Bool
        var lock: Bool
        var key: String?
        var contract: Any? = nil //contract is not necessary for our use cases at this time but we will inclide field
    
        public enum CodingKeys: String, CodingKey {
            case address
            case label
            case isDefault
            case lock
            case key
        }
        
        public init(address: String, label: String, isDefault: Bool, lock: Bool, key: String?) {
            self.address = address
            self.label = label
            self.isDefault = isDefault
            self.lock = lock
            self.key = key
        }
        
        required public convenience init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let address: String = try container.decode(String.self, forKey: .address)
            let label: String = try container.decode(String.self, forKey: .label)
            let isDefault: Bool = try container.decode(Bool.self, forKey: .isDefault)
            let lock: Bool = try container.decode(Bool.self, forKey: .lock)
            let key: String? = try? container.decode(String.self, forKey: .key)
            self.init(address: address, label: label, isDefault: isDefault, lock: lock, key: key)
        }
    }
    
    public struct ScryptParams: Codable {
        var n: Int
        var r: Int
        var p: Int
        
        public enum CodingKeys: String, CodingKey {
            case n
            case r
            case p
        }
        
        public init(n: Int, r: Int, p: Int) {
            self.n = n
            self.r = r
            self.p = p
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let n: Int = try container.decode(Int.self, forKey: .n)
            let r: Int = try container.decode(Int.self, forKey: .r)
            let p: Int = try container.decode(Int.self, forKey: .p)
            self.init(n: n, r: r, p: p)
            
        }
    
    }
    
    public func addEncryptedKey(name: String, address: String, key: String) throws {
        if name == "" {
            throw NEP6Error.invalidName
        } else if !NeoutilsValidateNEOAddress(address){
            throw NEP6Error.invalidAddress
        } else if !(key.count == 58 && key.hasPrefix("6P")) {
            throw NEP6Error.invalidKey
        }
        
        for account in accounts {
            if account.label == name {
                throw NEP6Error.duplicateField
            } else if account.address == address {
                throw NEP6Error.duplicateField
            } else if account.key == key {
                throw NEP6Error.duplicateField
            }
        }
        
        let newAccount = NEP6.Account(address: address, label: name, isDefault: false, lock: false, key: key)
        self.accounts.append(newAccount)
    }
    
    func addWatchAddress(address: String, name: String) {
        let newAccount = NEP6.Account(address: address, label: name, isDefault: false, lock: false, key: nil)
        self.accounts.append(newAccount)
    }
    
    func removeEncryptedKey(name: String) {
        let index = accounts.firstIndex { $0.label == name }
        if index != nil {
            accounts.remove(at: index!)
        }
    }
    
    func removeEncryptedKey(address: String) {
        let index = accounts.firstIndex { $0.address == address }
        if index != nil {
            accounts.remove(at: index!)
        }
    }
    
    func removeEncryptedKey(key: String) {
        let index = accounts.firstIndex { $0.key == key }
        if index != nil {
            accounts.remove(at: index!)
        }
    }
    
    public func getWalletAccounts() -> [Account] {
        var walletAccounts = [Account]()
        let defaultIndex = accounts.firstIndex { $0.isDefault == true }
        walletAccounts.append(accounts[defaultIndex!])
        for account in accounts {
            if account.isDefault == false && account.key != nil {
                walletAccounts.append(account)
            }
        }
        return walletAccounts
    }
    
    public func getWatchAccounts() -> [Account] {
        var watchAccounts = [Account]()
        for account in accounts {
            if account.key == nil {
                watchAccounts.append(account)
            }
        }
        return watchAccounts
    }
    
    
    public func convertWatchAddrToWallet(addr: String, key: String) {
        let index = accounts.firstIndex { $0.address == addr }
        accounts[index!].key = key
    }
    
    static func removeFromDevice() {
        let fileName = "O3Wallet"
        let DocumentDirURL = CloudDataManager.DocumentsDirectory.localDocumentsURL
        let fileURL = DocumentDirURL.appendingPathComponent(fileName).appendingPathExtension("json")
        let _ = try? FileManager.default.removeItem(at: fileURL)
    }
    
    static public func makeNewDefault(address: String, pass: String) {
        let nep6 = getFromFileSystem()!
        let currentDefaultIndex = nep6.accounts.firstIndex { $0.isDefault }
        let newDefaultIndex = nep6.accounts.firstIndex { $0.address == address }
        if newDefaultIndex == nil || currentDefaultIndex == nil {
            return
        }
        let keychain = Keychain(service: "network.o3.neo.wallet")
        do {
            //save pirivate key to keychain
            try keychain
                .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                .set(pass, key: "ozoneActiveNep6Password")
            
            nep6.accounts[currentDefaultIndex!].isDefault = false
            nep6.accounts[newDefaultIndex!].isDefault = true
            nep6.accounts.swapAt(newDefaultIndex!, currentDefaultIndex!)

            nep6.writeToFileSystem()
            var error: NSError?
            Authenticated.wallet = Wallet(wif: NeoutilsNEP2Decrypt(nep6.accounts[currentDefaultIndex!].key!, pass, &error))
            NotificationCenter.default.post(name: Notification.Name("NEP6Updated"), object: nil)
        } catch _ {
            return
        }
    }
    
    public func editName(address: String, newName: String) {
        let currentDefaultIndex = accounts.firstIndex { $0.address == address }
        accounts[currentDefaultIndex!].label = newName
    }
    
    static public func makeNewDefault(key: String, pass: String) {
        let nep6 = getFromFileSystem()!
        let currentDefaultIndex = nep6.accounts.firstIndex { $0.isDefault }
        let newDefaultIndex = nep6.accounts.firstIndex { $0.key == key }
        if newDefaultIndex == nil || currentDefaultIndex == nil {
            return
        }
        let keychain = Keychain(service: "network.o3.neo.wallet")
        do {
            //save pirivate key to keychain
            try keychain
                .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                .authenticationPrompt("Confirm this to be the default wallet on your device")
                .set(pass, key: "ozoneActiveNep6Password")
            nep6.accounts[currentDefaultIndex!].isDefault = false
            nep6.accounts[newDefaultIndex!].isDefault = true
            nep6.accounts.swapAt(newDefaultIndex!, currentDefaultIndex!)
            nep6.writeToFileSystem()
            var error: NSError?
            Authenticated.wallet = Wallet(wif: NeoutilsNEP2Decrypt(nep6.accounts[currentDefaultIndex!].key!, pass, &error))
            NotificationCenter.default.post(name: Notification.Name("NEP6Updated"), object: nil)
        } catch _ {
            return
        }
    }
    
    static public func clearAllExceptDefault() {
        let nep6 = getFromFileSystem()
        nep6?.accounts.removeAll { $0.isDefault == false}
        nep6?.writeToFileSystem()
        NotificationCenter.default.post(name: Notification.Name("NEP6Updated"), object: nil)
    }
    
    static public func getFromFileSystem() -> NEP6? {
        let fileName = "O3Wallet"
        let DocumentDirURL = CloudDataManager.DocumentsDirectory.localDocumentsURL
        let fileURL = DocumentDirURL.appendingPathComponent(fileName).appendingPathExtension("json")
        let jsonNep6 = try? Data(contentsOf: fileURL)
        if jsonNep6 == nil {
            return nil
        }
        let nep6 = try? JSONDecoder().decode(NEP6.self, from: jsonNep6!)
        return nep6
    }
    
    static public func getFromFileSystemAsData() -> Data {
        let fileName = "O3Wallet"
        let DocumentDirURL = CloudDataManager.DocumentsDirectory.localDocumentsURL
        let fileURL = DocumentDirURL.appendingPathComponent(fileName).appendingPathExtension("json")
        let jsonNep6 = try! Data(contentsOf: fileURL)
        return jsonNep6
    }
    
    public func writeToFileSystem() {
        let nep6Data = try! JSONEncoder().encode(self)
        let fileName = "O3Wallet"
        let DocumentDirURL = CloudDataManager.DocumentsDirectory.localDocumentsURL
        let fileManager = FileManager.default
        var isDir : ObjCBool = false
        if fileManager.fileExists(atPath: DocumentDirURL.path, isDirectory: &isDir) {
            
        } else {
            try! fileManager.createDirectory(at: DocumentDirURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        let fileURL = DocumentDirURL.appendingPathComponent(fileName).appendingPathExtension("json")
        try! nep6Data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        //CloudDataManager.sharedInstance.copyFileToCloud()
        NotificationCenter.default.post(name: Notification.Name("NEP6Updated"), object: nil)
    }
    
    
}
