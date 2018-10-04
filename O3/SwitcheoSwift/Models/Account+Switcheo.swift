//
//  Account.swift
//  NeoSwift
//
//  Created by Rataphon Chitnorm on 8/25/17.
//  Copyright © 2017 drei. All rights reserved.
//

import Foundation
import Neoutils
import Security


public class SwitcheoAccount{
    
    var switcheo: Switcheo!
    var account: Account!
    
    init(network: Switcheo.Net, account: Account) {
        self.switcheo = Switcheo(net: network)
        self.account = account
    }
    
    private func addAuthenticationData(data: Switcheo.JSONDictionary, completion: @escaping (Switcheo.JSONDictionary) -> Void){
        self.switcheo.exchangeTimestamp { (result) in
            switch result {
            case .failure( _):
                completion(data)
                return
            case .success(let response):
                var authenticatedData = data
                authenticatedData["timestamp"] = response["timestamp"]
                let serializedTransaction = authenticatedData.SWTHEncodingMessage(sort: true)
                var error: NSError?
                let signature = NeoutilsSign(serializedTransaction.hexadecimal()!,
                                             self.account.privateKey.fullHexString,
                                             &error)?.fullHexString
                
                if error != nil {
                    print(error as Any)
                    completion(data)
                    return
                }
                
                authenticatedData["address"] = NeoutilsReverseBytes(self.account.hashedSignature).fullHexString
                authenticatedData["signature"] = signature
                completion(authenticatedData)
            }
        }
        
    }
    
    public func createDeposit(requestTransaction: RequestTransaction,
                              completion: @escaping (Switcheo.SWTHResult<Switcheo.JSONDictionary>) -> Void){
        self.switcheo.exchangeTokens { (r) in
            switch r {
            case .failure(let error ):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                let responseData = try? JSONSerialization.data(withJSONObject: response[requestTransaction.assetID.uppercased()] as Any, options: .prettyPrinted)
                let detail = try? decoder.decode(TokenDetail.self, from: responseData!)
                if (detail == nil) {
                    completion(.failure(self.switcheo.log("decode error")))
                    return
                }
                self.addAuthenticationData(data: requestTransaction.toDictionary(tokenDetail: detail!)) { (result) in
                    self.switcheo.sendRequest(ofType:Switcheo.JSONDictionary.self, "deposits", method: .POST, data: result, completion: completion)
                }
            }
        }
        
    }
    
    public func exececuteDeposit(createdResponse:Switcheo.JSONDictionary,
                                 completion: @escaping (Switcheo.SWTHResult<Switcheo.JSONDictionary>) -> Void){
        let transaction = createdResponse["transaction"] as! Switcheo.JSONDictionary
        //        print(transaction.toString())
        let id = createdResponse["id"] as! String
        let data = ["signature":self.signTxn(transaction)] as Switcheo.JSONDictionary
        self.switcheo.sendRequest(ofType:Switcheo.JSONDictionary.self, "deposits/"+id+"/broadcast", method:.POST   , data: data, completion: completion)
    }
    
    public func createWithdrawal(requestTransaction: RequestTransaction,
                                 completion: @escaping (Switcheo.SWTHResult<Switcheo.JSONDictionary>) -> Void){
        self.switcheo.exchangeTokens { (r) in
            switch r {
            case .failure(let error ):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                let responseData = try? JSONSerialization.data(withJSONObject: response[requestTransaction.assetID.uppercased()] as Any, options: .prettyPrinted)
                let detail = try? decoder.decode(TokenDetail.self, from: responseData!)
                if (detail == nil) {
                    completion(.failure(self.switcheo.log("decode error")))
                    return
                }
                self.addAuthenticationData(data: requestTransaction.toDictionary(tokenDetail: detail!)) { (result) in
                    self.switcheo.sendRequest(ofType:Switcheo.JSONDictionary.self, "withdrawals", method: .POST, data: result, completion: completion)
                    
                }
            }
        }
    }
    
    public func exececuteWithdrawal(createdResponse:Switcheo.JSONDictionary,
                                    completion: @escaping (Switcheo.SWTHResult<Switcheo.JSONDictionary>) -> Void){
        
        self.switcheo.exchangeTimestamp { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
                return
            case .success(let response):
                
                let id = createdResponse["id"] as! String
                var authenticatedData = ["id":id] as [String:  Any]
                authenticatedData["timestamp"] = response["timestamp"]
                let serializedTransaction = authenticatedData.SWTHEncodingMessage(sort: true)
                var error: NSError?
                let signature = NeoutilsSign(serializedTransaction.hexadecimal()!,
                                             self.account.privateKey.fullHexString,
                                             &error)?.fullHexString
                
                if error != nil {
                    completion(.failure(self.switcheo.log(error.debugDescription)))
                    return
                }
                
                authenticatedData["signature"] = signature
                self.switcheo.sendRequest(ofType:Switcheo.JSONDictionary.self, "withdrawals/"+id+"/broadcast", method: .POST, data: authenticatedData, completion: completion)
            }
        }
    }
    
    public func orders(contractHash: String, completion: @escaping (Switcheo.SWTHResult<[Order]>) -> Void){
        let data = ["address":NeoutilsReverseBytes(self.account.hashedSignature).fullHexString,"contract_hash":contractHash]
        self.switcheo.sendRequest(ofType:[Switcheo.JSONDictionary].self, "orders", method: .GET, data: data, completion: { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                let responseData = try? JSONSerialization.data(withJSONObject: response, options: .prettyPrinted)
                let result = try? decoder.decode([Order].self, from: responseData!)
                if (result == nil) {
                    completion(.failure(self.switcheo.log("decode error")))
                    return
                }
                let w = Switcheo.SWTHResult.success(result!)
                completion(w)
            }
        })
    }
    
    public func createOrder(requestOrder: RequestOrder, completion: @escaping (Switcheo.SWTHResult<Switcheo.JSONDictionary>) -> Void){
        self.switcheo.exchangeTokens { (r) in
            switch r {
            case .failure(let error ):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                let pairs = requestOrder.pair.components(separatedBy: "_")
                let asset = pairs[0].uppercased()
                let responseData = try? JSONSerialization.data(withJSONObject: response[asset] as Any, options: .prettyPrinted)
                let detail = try? decoder.decode(TokenDetail.self, from: responseData!)
                if (detail == nil) {
                    completion(.failure(self.switcheo.log("decode error")))
                    return
                }
                self.addAuthenticationData(data: requestOrder.toDictionary(asset: asset,tokenDetail: detail!)) { (result) in
                    self.switcheo.sendRequest(ofType:Switcheo.JSONDictionary.self, "orders", method: .POST, data: result, completion: completion)
                }
            }}
    }
    
    private func signTxn(_ txn: Switcheo.JSONDictionary) -> String{
        let jsonData = try! JSONSerialization.data(withJSONObject: txn, options: [])
        let decoded = String(data: jsonData, encoding: .utf8)!
        var error: NSError?
        let signature: String = (NeoutilsSign(NeoutilsSerializeTX(decoded),
                                              self.account.privateKey.fullHexString,
                                              &error)?.fullHexString)!
        if error != nil {
            return ""
        }
        
        return signature
    }
    
    public func exececuteOrder(createdResponse:Switcheo.JSONDictionary,
                               completion: @escaping (Switcheo.SWTHResult<Switcheo.JSONDictionary>) -> Void){
        let id = createdResponse["id"] as! String
        let fills = createdResponse["fills"] as! [Switcheo.JSONDictionary]
        let makes = createdResponse["makes"] as! [Switcheo.JSONDictionary]
        var authFills: Switcheo.JSONDictionary = [:]
        var authMakes: Switcheo.JSONDictionary = [:]
        
        for fill in fills {
            let fid = fill["id"] as! String
            let txn = fill["txn"] as! Switcheo.JSONDictionary
            authFills[fid] = self.signTxn(txn)
        }
        
        //Parse json to
        for make in makes {
            let mid = make["id"] as! String
            let txn = make["txn"] as! Switcheo.JSONDictionary
            authMakes[mid] = self.signTxn(txn)
        }
        let data = ["signatures":["fills": authFills, "makes": authMakes]] as Switcheo.JSONDictionary
        
        var result: (Switcheo.SWTHResult<Switcheo.JSONDictionary>) -> Void
        result = completion
        
        self.switcheo.sendRequest(ofType:Switcheo.JSONDictionary.self, "orders/"+id+"/broadcast", method: .POST, data: data, completion: result)
    }
    
    public func createCancellation(orderID: String,
                                   completion: @escaping (Switcheo.SWTHResult<Switcheo.JSONDictionary>) -> Void){
        let data = ["order_id":orderID] as Switcheo.JSONDictionary
        self.addAuthenticationData(data: data) { (result) in
            self.switcheo.sendRequest(ofType:Switcheo.JSONDictionary.self, "cancellations", method: .POST, data: result, completion: completion)
        }
    }
    
    public func exececuteCancellation(createdResponse:Switcheo.JSONDictionary,
                                      completion: @escaping (Switcheo.SWTHResult<Switcheo.JSONDictionary>) -> Void){
        
        let transaction = createdResponse["transaction"] as! Switcheo.JSONDictionary
        let id = createdResponse["id"] as! String
        let data = ["signature":self.signTxn(transaction)] as Switcheo.JSONDictionary
        self.switcheo.sendRequest(ofType:Switcheo.JSONDictionary.self, "cancellations/"+id+"/broadcast", method: .POST, data: data, completion: completion)
    }
    
    public func deposit(requestTransaction: RequestTransaction,
                        completion: @escaping (Switcheo.SWTHResult<Switcheo.JSONDictionary>) -> Void){
        self.createDeposit(requestTransaction: requestTransaction, completion: { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                self.exececuteDeposit(createdResponse: response, completion: { (r) in
                    switch r {
                    case .failure(let e):
                        completion(.failure(e))
                    case .success(let rsp):
                        let w = Switcheo.SWTHResult.success(rsp)
                        completion(w)
                    }
                })
            }
        })
    }
    
    public func withdrawal(requestTransaction: RequestTransaction,
                           completion: @escaping (Switcheo.SWTHResult<Switcheo.JSONDictionary>) -> Void){
        self.createWithdrawal(requestTransaction: requestTransaction, completion: { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                self.exececuteWithdrawal(createdResponse: response, completion: { (r) in
                    switch r {
                    case .failure(let e):
                        completion(.failure(e))
                    case .success(let rsp):
                        let w = Switcheo.SWTHResult.success(rsp)
                        completion(w)
                    }
                })
            }
        })
    }
    
    public func order(requestOrder: RequestOrder, completion: @escaping (Switcheo.SWTHResult<Switcheo.JSONDictionary>) -> Void){
        self.createOrder(requestOrder: requestOrder) { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                self.exececuteOrder(createdResponse: response, completion: { (r) in
                    switch r {
                    case .failure(let e):
                        completion(.failure(e))
                    case .success(let rsp):
                        let w = Switcheo.SWTHResult.success(rsp)
                        completion(w)
                    }
                })
            }
        }
    }
    
    public func cancellation(orderID: String,
                             completion: @escaping (Switcheo.SWTHResult<Switcheo.JSONDictionary>) -> Void){
        self.createCancellation(orderID: orderID) { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                self.exececuteCancellation(createdResponse: response, completion: { (r) in
                    switch r {
                    case .failure(let e):
                        completion(.failure(e))
                    case .success(let rsp):
                        let w = Switcheo.SWTHResult.success(rsp)
                        completion(w)
                    }
                })
            }
        }
    }
    
}
