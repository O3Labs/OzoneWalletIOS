//
//  TintedTextField.swift
//  O3
//
//  Created by Andrei Terentiev on 10/19/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import SwiftTheme
import UIKit

class TintedTextField: UITextField {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        for view in subviews {
            if let button = view as? UIButton {
                button.setImage(button.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
                if UserDefaultsManager.theme == Theme.dark {
                        button.tintColor = .white
                }
            }
        }
    }
}
