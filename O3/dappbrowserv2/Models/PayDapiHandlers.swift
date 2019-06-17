//
//  PayDapiHandlers.swift
//  O3
//
//  Created by Andrei Terentiev on 6/13/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation

extension dAppBrowserViewModel {
    func requestCoinbaseSend(message: dAppMessage, request: dAppProtocol.CoinbaseSendRequest, didCancel: @escaping (_ message: dAppMessage,_ request: dAppProtocol.CoinbaseSendRequest) -> Void, onCompleted:@escaping (_ response: dAppProtocol.CoinbaseSendResponse?, _ error: dAppProtocol.errorResponse?) -> Void) {
        self.delegate?.onCoinbaseSendRequest(message: message, request: request, didCancel: didCancel, onCompleted: onCompleted)
    }
    
    func handleCoinbasePay(message: dAppMessage) {
        let decoder = JSONDecoder()
        guard let dictionary =  message.data?.value as? JSONDictionary,
            let data = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted),
            let request = try? decoder.decode(dAppProtocol.CoinbaseSendRequest.self, from: data) else {
                self.delegate?.error(message: message, error: "Unable to parse the request")
                return
        }
        
        self.requestCoinbaseSend(message: message, request: request, didCancel: { m,r in
            self.delegate?.error(message: message, error: "USER_CANCELLED_SEND")
        }, onCompleted: { response, err in
            DispatchQueue.global().async {
                if err == nil {
                    self.delegate?.didFinishMessage(message: message, response: response!.dictionary)
                } else {
                    self.delegate?.error(message: message, error: err.debugDescription)
                }
            }
        })
        return
    }
}
