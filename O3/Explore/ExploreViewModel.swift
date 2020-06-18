//
//  ExploreViewModel.swift
//  O3
//
//  Created by jcc on 2020/6/18.
//  Copyright © 2020 O3 Labs Inc. All rights reserved.
//

import UIKit
import Foundation

protocol ExploreViewModelDelegate: class {
    func showLoadingIndicator()
    func hideLoadingIndicator()
}

class ExploreViewModel {
    weak var delegate: HomeViewModelDelegate?

}
