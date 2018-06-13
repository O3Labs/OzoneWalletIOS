//
//  URL.swift
//  O3
//
//  Created by Apisit Toompakdee on 6/12/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

extension URL {
    func valueOf(_ queryParamaterName: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == queryParamaterName })?.value
    }
}
