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
}
