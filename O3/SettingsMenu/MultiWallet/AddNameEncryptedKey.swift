//
//  AddNameEncryptedKey.swift
//  O3
//
//  Created by Andrei Terentiev on 10/26/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class AddNameEncryptedKeyTableViewController: UITableViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nameInputField: UITextField!
    @IBOutlet weak var finishButton: ShadowedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        setThemedElements()
    }
    
    @IBAction func finishButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    func setLocalizedStrings() {
        titleLabel.text = MultiWalletStrings.setWalletNameTitle
        finishButton.setTitle(MultiWalletStrings.multiWalletFinished, for: UIControl.State())
    }
    
    func setThemedElements() {
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        titleLabel.theme_textColor = O3Theme.titleColorPicker
    }
}
