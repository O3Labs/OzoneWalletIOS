//
//  FixedDecimalTextField.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/24/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

class FixedDecimalTextField: UITextField, UITextFieldDelegate {

    @IBInspectable var decimals: Int = 8

    override func awakeFromNib() {
           self.delegate = self
        super.awakeFromNib()
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if decimals == 0 && (string == "." || string == "," ) {
            return false
        }
        
        let existingTextHasDecimalSeperator = textField.text?.range(of: ".")
        let replacementTextHasDecimalSeperator = string.range(of: ".")
        var validTextFieldInput = NSCharacterSet.decimalDigits
        validTextFieldInput.insert(".")        
        let replacementTextIsOnlyNumbers = string.rangeOfCharacter(from: validTextFieldInput)
        if string == "" {
            return true
        } else {
            if (textField.text?.components(separatedBy: ".").count)! > 1 {
                let decimalPart = textField.text?.components(separatedBy: ".")[1]
                if (decimalPart?.count)! >= decimals {
                    return false
                }
            }
            
            if replacementTextIsOnlyNumbers != nil {
                if existingTextHasDecimalSeperator != nil,
                    replacementTextHasDecimalSeperator != nil {
                    return false
                }
                return true
            }
            return false
        }
    }
}
