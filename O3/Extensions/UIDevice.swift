//
//  UIDevice.swift
//  O3
//
//  Created by Andrei Terentiev on 10/16/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIDevice {
    var modelName: String {
        if let modelName = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] { return modelName }
        var info = utsname()
        uname(&info)
        return String(
            Mirror(reflecting: info.machine).children.compactMap { // for Swift versions below 4.1 use flatMap
                guard let value = $0.value as? Int8,
                    case let unicode = UnicodeScalar(UInt8(value)),
                    32...126 ~= unicode.value else { return nil }
                return Character(unicode)
        })
    }
}
