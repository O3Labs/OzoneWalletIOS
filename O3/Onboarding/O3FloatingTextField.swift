//
//  O3FloatingTextField.swift
//  O3
//
//  Created by Andrei Terentiev on 1/8/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import SkyFloatingLabelTextField
import UIKit

class O3FloatingTextField: SkyFloatingLabelTextField {
    override init(frame rect: CGRect) {
        super.init(frame: rect)
        //title label attributes
        titleFormatter = { $0 }
        titleLabel.theme_backgroundColor = O3Theme.backgroundColorPicker
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont(name: "Avenir", size: 12)
        errorColor = Theme.light.errorColor
        lineErrorColor = .clear
        
        //ui field attributes
        borderStyle = UITextField.BorderStyle.roundedRect
        tintColor = Theme.light.accentColor
        
        theme_textColor = O3Theme.titleColorPicker
        selectedTitleColor = Theme.light.accentColor
        selectedLineHeight = CGFloat(0)
        borderWidth = 0
        cornerRadius = 8
        selectedLineColor = .clear
        layer.masksToBounds = false
        lineColor = .clear
        lineErrorColor = .clear
        self.font = UIFont(name:"Avenir", size: 14)
        theme_backgroundColor = O3Theme.cardColorPicker
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        //title label attributes
        titleFormatter = { $0 }
        titleLabel.theme_backgroundColor = O3Theme.backgroundColorPicker
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont(name: "Avenir", size: 12)
        errorColor = Theme.light.errorColor
    
        //ui field attributes
        borderStyle = UITextField.BorderStyle.roundedRect
        tintColor = Theme.light.accentColor
        theme_textColor = O3Theme.titleColorPicker
        selectedTitleColor = Theme.light.accentColor
        selectedLineHeight = CGFloat(0)
        borderWidth = 0
        cornerRadius = 8
        selectedLineColor = .clear
        layer.masksToBounds = false
        lineColor = .clear
        lineErrorColor = .clear
        self.font = UIFont(name:"Avenir", size: 14)
        theme_backgroundColor = O3Theme.cardColorPicker
    }
    
    override func titleLabelRectForBounds(_ bounds: CGRect, editing: Bool) -> CGRect {
        let superRect = super.titleLabelRectForBounds(bounds, editing: editing)
        let size = titleLabel.text?.size(withAttributes: [.font: titleLabel.font]) ?? .zero
        if editing {
            let newRect = CGRect(x: superRect.minX + 6, y: superRect.minY - 10, width: size.width.rounded() + 4, height: superRect.height.rounded())
            return newRect
        } else {
            let newRect = CGRect(x: superRect.minX + 6, y: superRect.minY - 10, width: size.width.rounded() + 4, height: superRect.height.rounded())
            return newRect
        }
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        let superRect = super.placeholderRect(forBounds: bounds)
        let newRect = CGRect(x: superRect.minX + 10, y: superRect.minY - 8, width: superRect.width - 8, height: superRect.height)
        return newRect
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let superRect = super.textRect(forBounds: bounds)
        let placeholderRect = self.placeholderRect(forBounds: bounds)
        let newRect = CGRect(x: superRect.minX, y: placeholderRect.minY + 2, width: superRect.width - 8, height: superRect.height)
        return newRect
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let superRect = super.textRect(forBounds: bounds)
        let placeholderRect = self.placeholderRect(forBounds: bounds)
        let newRect = CGRect(x: superRect.minX, y: placeholderRect.minY + 2, width: superRect.width - 8, height: superRect.height)
        return newRect
    }
}
