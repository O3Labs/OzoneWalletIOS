//
//  ExternalAccounts.swift
//  O3
//
//  Created by Andrei Terentiev on 6/12/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation

public class ExternalAccounts: Codable {
    static var file_on_disk_name = "O3_connected_accounts"
    static var coinbaseTokenForSession: String? = nil
    static var coinbaseTokenExpiryTime: Int? = nil
    
    var name: String
    private var accounts: [Account]
    
    
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
       // var iv: IV
        var token: String
        var accountMetaData: Data? = nil
        
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
            //case iv
            case token
            case accountMetaData
        }
        
        public init(platform: String, algorithm: String, token: String, accountMetaData: Data?) {
            self.platform = platform
            self.algorithm = algorithm
            self.token = token
            self.accountMetaData = accountMetaData
        }
        
        required public convenience init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let platform: String = try container.decode(String.self, forKey: .platform)
            let algorithm: String = try container.decode(String.self, forKey: .algorithm)
            let token: String = try container.decode(String.self, forKey: .token)
            let accountMetaData: Data? = nil //try container.decode(Any?.self, forKey: .accountMetaData)
            self.init(platform: platform, algorithm: algorithm, token: token, accountMetaData: accountMetaData)
        }
    }
    
    func getCoinbaseToken() -> String { return "" }
    
    func setAccount(platform: String, unencryptedToken: String, scope: String, accountMetaData: Data?) {}
    
    func removeAccount(platform: String) {}
    
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
    
    
    static func getCoinbaseTokenFromMemory() -> String? { return nil }
    static func setCoinbaseTokenForSession(token: String, expiryTime: Int) {}
    static func getFromFileSystem() -> ExternalAccounts? {
        let DocumentDirURL = CloudDataManager.DocumentsDirectory.localDocumentsURL
        let fileURL = DocumentDirURL.appendingPathComponent(file_on_disk_name).appendingPathExtension("json")
        let jsonExternalAccounts = try? Data(contentsOf: fileURL)
        if jsonExternalAccounts == nil {
            return nil
        }
        let externalAccounts = try? JSONDecoder().decode(ExternalAccounts.self, from: jsonExternalAccounts!)
        return externalAccounts
    }
}
