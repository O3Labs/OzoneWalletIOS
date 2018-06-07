//
//  NEP2PasswordViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 6/6/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class NEP2PasswordViewController: UITableViewController {
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var showButton: UIButton!
    var wif = ""

    lazy var inputToolbar: UIToolbar = {
        var toolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.isTranslucent = true
        toolbar.sizeToFit()
        let flexibleButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        var doneButton = UIBarButtonItem(title: OnboardingStrings.continueButton, style: .plain, target: self, action: #selector(self.continueTapped(_:)))

        toolbar.setItems([flexibleButton, doneButton], animated: false)
        toolbar.isUserInteractionEnabled = true

        return toolbar
    }()

    var passwordIsSecure = true

    var allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.~`!@#$%^&*()+=-/;:\"\'{}[]<>^?,")

    override func viewDidLoad() {
        super.viewDidLoad()
        passwordTextField.inputAccessoryView = inputToolbar
        passwordTextField.becomeFirstResponder()
        setLocalizedStrings()
    }

    @IBAction func continueTapped(_ sender: Any) {
        if validatePassword() {
            self.performSegue(withIdentifier: "segueToConfirmPassword", sender: nil)
        } else {
            OzoneAlert.alertDialog(message: "fdsafdsa", dismissTitle: "fdsafdsa") {

            }
        }
    }

    func validatePassword() -> Bool {
        let passwordText = passwordTextField.text?.trim() ?? ""
        if !(passwordText.count >= 8) {
            return false
        }

        if passwordText.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            return false
        }

        return true
    }

    @IBAction func showButtonTapped(_ sender: Any) {
        passwordIsSecure = !passwordIsSecure
        passwordTextField.isSecureTextEntry = passwordIsSecure
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let dest = segue.destination as? NEP2PasswordConfirmViewController else {
            fatalError("Unknown segue has been triggered")
        }
        dest.previousPassword = passwordTextField.text?.trim()
        dest.wif = wif
    }

    func setLocalizedStrings() {
        title = OnboardingStrings.createPassword
        descriptionLabel.text = OnboardingStrings.createPasswordDescription
        passwordTextField.placeholder = OnboardingStrings.createPasswordHint
    }
}
