//
//  Nep6.swift
//  O3
//
//  Created by Andrei Terentiev on 10/24/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import Neoutils

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
        var key: String
        var contract: Any? = nil //contract is not necessary for our use cases at this time but we will inclide field
    
        public enum CodingKeys: String, CodingKey {
            case address
            case label
            case isDefault
            case lock
            case key
        }
        
        public init(address: String, label: String, isDefault: Bool, lock: Bool, key: String) {
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
            let key: String = try container.decode(String.self, forKey: .key)
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
    
    public func makeNewDefault(address: String) {
        let currentDefaultIndex = accounts.firstIndex { $0.isDefault }
        let newDefaultIndex = accounts.firstIndex { $0.address == address }
        if newDefaultIndex == nil || currentDefaultIndex == nil {
            return
        }
        accounts[currentDefaultIndex!].isDefault = false
        accounts[newDefaultIndex!].isDefault = true
    }
    
    public func makeNewDefault(name: String) {
        let currentDefaultIndex = accounts.firstIndex { $0.isDefault }
        let newDefaultIndex = accounts.firstIndex { $0.label == name }
        if newDefaultIndex == nil || currentDefaultIndex == nil {
            return
        }
        accounts[currentDefaultIndex!].isDefault = false
        accounts[newDefaultIndex!].isDefault = true
    }
    
    public func makeNewDefault(key: String) {
        let currentDefaultIndex = accounts.firstIndex { $0.isDefault }
        let newDefaultIndex = accounts.firstIndex { $0.address == key }
        if newDefaultIndex == nil || currentDefaultIndex == nil {
            return
        }
        accounts[currentDefaultIndex!].isDefault = false
        accounts[newDefaultIndex!].isDefault = true
    }
}
