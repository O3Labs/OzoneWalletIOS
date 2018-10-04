//
//  CenterImageButton.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/14/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

class CenterImageButton: UIButton {

    @IBInspectable var verticalSpacing: Float = 6
    
    override func awakeFromNib() {
        self.alignVertical(spacing: CGFloat(verticalSpacing))
    }
}
