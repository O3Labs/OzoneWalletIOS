//
//  FixedDecimalTextField.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/24/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

class FixedDecimalTextField: NoActionUITextField, UITextFieldDelegate {

    @IBInspectable var decimals: Int = 8

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.delegate = self
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if decimals == 0 && (string == "." || string == "," ) {
            return false
        }
        
        let existingTextHasDecimalSeperator = textField.text?.range(of: ".")
        let replacementTextHasDecimalSeperator = string.range(of: ".")
        
        var validTextFieldInput = NSCharacterSet.decimalDigits // Create range with only decimal digits
        validTextFieldInput.insert(".") // Add the decimal character (in case using Keyboard?)
        
        // Create test variable for replacement text against valid input range
        let replacementTextIsOnlyNumbers = string.rangeOfCharacter(from: validTextFieldInput)
        
        if string == "" { // If valid number or backspace ("")
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
