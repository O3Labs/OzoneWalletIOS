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

public class SwitcheoAccount: Account {
    
    private var switcheo: Switcheo!
    
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
                                             self.privateKey.fullHexString,
                                             &error)?.fullHexString
                
                if error != nil {
                    print(error as Any)
                    completion(data)
                    return
                }
                
                authenticatedData["address"] = NeoutilsReverseBytes(self.hashedSignature).fullHexString
                authenticatedData["signature"] = signature
                completion(authenticatedData)
            }
        }
        
    }
    
    public func createDeposit(requestTransaction: RequestTransaction,
                              completion: @escaping (Switcheo.SWTHResult<Switcheo.JSONDictionary>) -> Void){
        self.addAuthenticationData(data: requestTransaction.dictionary) { (result) in
            self.switcheo.sendRequest(ofType:Switcheo.JSONDictionary.self, "deposits", method: .POST, data: result, completion: completion)
        }
    }
    
    public func exececuteDeposit(createdResponse:Switcheo.JSONDictionary,
                                 completion: @escaping (Switcheo.SWTHResult<Switcheo.JSONDictionary>) -> Void){
        let transaction = createdResponse["transaction"] as! Switcheo.JSONDictionary
        let id = createdResponse["id"] as! String
        let data = ["signature":self.signTxn(transaction)] as Switcheo.JSONDictionary
        self.switcheo.sendRequest(ofType:Switcheo.JSONDictionary.self, "deposits/"+id+"/broadcast", method:.POST   , data: data, completion: completion)
    }
    
    public func createWithdrawal(requestTransaction: RequestTransaction,
                                 completion: @escaping (Switcheo.SWTHResult<Switcheo.JSONDictionary>) -> Void){
        self.addAuthenticationData(data: requestTransaction.dictionary) { (result) in
            self.switcheo.sendRequest(ofType:Switcheo.JSONDictionary.self, "withdrawals", method: .POST, data: result, completion: completion)
        }
    }
    
    public func exececuteWithdrawal(createdResponse:Switcheo.JSONDictionary,
                                    completion: @escaping (Switcheo.SWTHResult<Switcheo.JSONDictionary>) -> Void){
        
        self.switcheo.exchangeTimestamp { (result) in
            switch result {
            case .failure( _):
                completion(.failure(.invalidData))
                return
            case .success(let response):
                
                let id = createdResponse["id"] as! String
                var authenticatedData = ["id":id] as [String:  Any]
                authenticatedData["timestamp"] = response["timestamp"]
                let serializedTransaction = authenticatedData.SWTHEncodingMessage(sort: true)
                var error: NSError?
                let signature = NeoutilsSign(serializedTransaction.hexadecimal()!,
                                             self.privateKey.fullHexString,
                                             &error)?.fullHexString
                
                if error != nil {
                    completion(.failure(.invalidData))
                    return
                }
                
                authenticatedData["signature"] = signature
                self.switcheo.sendRequest(ofType:Switcheo.JSONDictionary.self, "withdrawals/"+id+"/broadcast", method: .POST, data: authenticatedData, completion: completion)
            }
        }
    }
    
    public func orders(contractHash: String, completion: @escaping (Switcheo.SWTHResult<[Order]>) -> Void){
        let data = ["address":NeoutilsReverseBytes(self.hashedSignature).fullHexString,"contract_hash":contractHash]
        self.switcheo.sendRequest(ofType:[Switcheo.JSONDictionary].self, "orders", method: .GET, data: data, completion: { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                let responseData = try? JSONSerialization.data(withJSONObject: response, options: .prettyPrinted)
                let result = try? decoder.decode([Order].self, from: responseData!)
                if (result == nil) {
                    completion(.failure(.invalidData))
                    return
                }
                let w = Switcheo.SWTHResult.success(result!)
                completion(w)
            }
        })
    }
    
    public func createOrder(requestOrder: RequestOrder, completion: @escaping (Switcheo.SWTHResult<Switcheo.JSONDictionary>) -> Void){
        self.addAuthenticationData(data: requestOrder.dictionary) { (result) in
            self.switcheo.sendRequest(ofType:Switcheo.JSONDictionary.self, "orders", method: .POST, data: result, completion: completion)
        }
    }
    
    private func signTxn(_ txn: Switcheo.JSONDictionary) -> String{
        let jsonData = try! JSONSerialization.data(withJSONObject: txn, options: [])
        let decoded = String(data: jsonData, encoding: .utf8)!
        var error: NSError?
        let signature: String = (NeoutilsSign(NeoutilsSerializeTX(decoded),
                                              self.privateKey.fullHexString,
                                              &error)?.fullHexString)!
        if error != nil {
            return ""
        }
        
        return signature
    }
    
    public func executeOrder(createdResponse:Switcheo.JSONDictionary,
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
        
        for make in makes {
            let mid = make["id"] as! String
            let txn = make["txn"] as! Switcheo.JSONDictionary
            authMakes[mid] = self.signTxn(txn)
        }
        print("_______",id)
        
        let data = ["signatures":["fills": authFills, "makes": authMakes]] as Switcheo.JSONDictionary
        self.switcheo.sendRequest(ofType:Switcheo.JSONDictionary.self, "orders/"+id+"/broadcast", method: .POST, data: data, completion: completion)
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
    
}
