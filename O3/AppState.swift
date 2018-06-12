//
//  AppState.swift
//  O3
//
//  Created by Apisit Toompakdee on 5/23/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

class AppState: NSObject {

    static var network: Network {
        #if TESTNET
        return .test
        #endif
        #if PRIVATENET
        return .privateNet
        #endif

        return .main
    }

    static var bestSeedNodeURL: String = ""
    
    enum ClaimingState: String {
        case Fresh = ""
        case WaitingForClaimableData = "0"
        case ReadyToClaim = "1"
    }
    
    static func claimingState(address: String) -> ClaimingState {
        if UserDefaults.standard.value(forKey: address + "_claimingState") == nil {
            return ClaimingState.Fresh
        }
        return  AppState.ClaimingState(rawValue: UserDefaults.standard.value(forKey: address + "_claimingState") as! String)!
    }
    
    static func setClaimingState(address: String, claimingState: ClaimingState){
        UserDefaults.standard.setValue(claimingState.rawValue, forKey: address + "_claimingState")
        UserDefaults.standard.synchronize()
    }
}
