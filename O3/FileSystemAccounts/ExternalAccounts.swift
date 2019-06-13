//
//  ExternalAccounts.swift
//  O3
//
//  Created by Andrei Terentiev on 6/12/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import Security

public class ExternalAccounts: Codable {
    static var file_on_disk_name = "O3_connected_accounts"
    static var coinbaseTokenForSession: String? = nil
    static var coinbaseTokenExpiryTime: Int? = nil
    
    var name: String
    private var accounts: [Account]
    
    public enum Platforms: String {
        case COINBASE
    }
    
    public enum CodingKeys: String, CodingKey {
        case name
        case accounts
    }
    
    public init(name: String, accounts: [Account]) {
        self.name = name
        self.accounts = accounts
    }
    
    required public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name: String = try container.decode(String.self, forKey: .name)
        let accounts: [Account] = try container.decode([Account].self, forKey: .accounts)
        self.init(name: name, accounts: accounts)
    }
    
    public class Account: Codable, Hashable {
        var platform: String
        var algorithm: String
        var iv: IV
        var token: String
        var accountMetaData: AnyCodable? = nil
        
        public var hashValue: Int {
            return platform.hashValue
        }
        
        static public func ==(lhs: Account, rhs: Account) -> Bool {
            return lhs.platform == rhs.platform && lhs.algorithm == rhs.algorithm
                && lhs.token == rhs.token
        }
        
        public enum CodingKeys: String, CodingKey {
            case platform
            case algorithm
            case iv
            case token
            case accountMetaData
        }
        
        init(platform: String, algorithm: String, token: String, accountMetaData: AnyCodable?, iv: IV) {
            self.platform = platform
            self.algorithm = algorithm
            self.token = token
            self.accountMetaData = accountMetaData
            self.iv = iv
        }
        
        required public convenience init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let platform: String = try container.decode(String.self, forKey: .platform)
            let algorithm: String = try container.decode(String.self, forKey: .algorithm)
            let token: String = try container.decode(String.self, forKey: .token)
            let iv: IV = try container.decode(IV.self, forKey: .iv)
            let accountMetaData: AnyCodable? = try container.decode(AnyCodable?.self, forKey: .accountMetaData)
            self.init(platform: platform, algorithm: algorithm, token: token, accountMetaData: accountMetaData, iv: iv)
        }
        
        struct IV: Codable {
            var type: String
            var data: String
        }
    }
    
    func getCoinbaseTokenFromDisk() -> String? {
        let index = accounts.firstIndex { $0.platform.lowercased() == Platforms.COINBASE.rawValue }
        if index == nil {
            return nil
        }
        let pass = O3KeychainManager.getCoinbaseEncryptionPass()
        let account = accounts[index!]
        let decryptedTokenHexData = AES.decrypt(bytes: account.token.dataWithHexString().bytes,
                                            key: pass.dataWithHexString().bytes, keySize: .keySize256, pkcs7Padding: false, iv: account.iv.data.hexadecimal()!.bytes).fullHexString.dataWithHexString()
        let decryptedRawToken = String(decoding: decryptedTokenHexData, as: UTF8.self)
        return decryptedRawToken
    }
    
    func setAccount(platform: ExternalAccounts.Platforms, unencryptedToken: String, scope: String, accountMetaData: AnyCodable?) {
        let dataToEncrypt = Data(unencryptedToken.utf8)
        
        let pass = O3KeychainManager.getCoinbaseEncryptionPass()
        
        var iv: [UInt8] = Array(repeatElement(0, count: 32))
        _ = SecRandomCopyBytes(kSecRandomDefault, 32, &iv)
        
        let encryptedToken = AES.encrypt(bytes: dataToEncrypt.bytes, key: pass.dataWithHexString().bytes, keySize: .keySize256, pkcs7Padding: false, iv: iv).fullHexString
        let account = Account(platform: platform.rawValue, algorithm: "AES256", token: encryptedToken,
                              accountMetaData: accountMetaData, iv: Account.IV(type: "byteArray", data: iv.fullHexString))
    
        let index = accounts.firstIndex { $0.platform == platform.rawValue }
        if index == nil {
            accounts.append(account)
        } else {
            accounts[index!] = account
        }
        writeToFileSystem()
    }
    
    func getAccounts() -> [Account] {
        return accounts
    }
    
    func removeAccount(platform: ExternalAccounts.Platforms) {
        let index = accounts.firstIndex { $0.platform == Platforms.COINBASE.rawValue }
        if index != nil {
            accounts.remove(at: index!)
        }
    }
    
    public func writeToFileSystem() {
        let nep6Data = try! JSONEncoder().encode(self)
        let fileName = "O3_connected_accounts"
        let DocumentDirURL = CloudDataManager.DocumentsDirectory.localDocumentsURL
        let fileManager = FileManager.default
        var isDir : ObjCBool = false
        if fileManager.fileExists(atPath: DocumentDirURL.path, isDirectory: &isDir) {
            
        } else {
            try! fileManager.createDirectory(at: DocumentDirURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        let fileURL = DocumentDirURL.appendingPathComponent(fileName).appendingPathExtension("json")
        try! nep6Data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }
    
    
    static func getCoinbaseTokenFromMemory() -> String? {
        if Int(Date().timeIntervalSince1970) > coinbaseTokenExpiryTime ?? 0 {
            coinbaseTokenForSession = nil
            coinbaseTokenExpiryTime = nil
            return nil
        }
    
        return coinbaseTokenForSession
    }
    
    static func setCoinbaseTokenForSession(token: String, expiryTime: Int) {
        coinbaseTokenForSession = token
        coinbaseTokenExpiryTime = expiryTime
    }
    
    static func getFromFileSystem() -> ExternalAccounts {
        let DocumentDirURL = CloudDataManager.DocumentsDirectory.localDocumentsURL
        let fileURL = DocumentDirURL.appendingPathComponent(file_on_disk_name).appendingPathExtension("json")
        let jsonExternalAccounts = try? Data(contentsOf: fileURL)
        if jsonExternalAccounts == nil {
            ExternalAccounts(name: "O3 Connected Accounts", accounts: []).writeToFileSystem()
            return getFromFileSystem()
        } else {
            let externalAccounts = try? JSONDecoder().decode(ExternalAccounts.self, from: jsonExternalAccounts!)
            return externalAccounts!
        }
        
    }
}
