//
//  NEP2PasswordConfirmViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 6/6/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class NEP2PasswordConfirmViewController: UITableViewController {
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var fieldTitleLabel: UILabel!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var showButton: UIButton!
    
    var previousPassword: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func validatePassword() -> Bool {
        if previousPassword == passwordField.text?.trim() {
            return true
        }
        return false
    }
    
    @IBAction func continueButtonTapped(_ sender: Any) {
        
    }
}
