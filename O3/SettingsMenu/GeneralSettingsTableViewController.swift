//
//  GeneralSettingsTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 5/9/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import SwiftTheme


class GeneralSettingsTableViewController: UITableViewController {
    
    @IBOutlet weak var manageAddressBookLabel: UILabel!
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var activeCurrencyLabel: UILabel!
    @IBOutlet weak var themeLabel: UILabel!
    @IBOutlet weak var themeSwitch: UISwitch!
    
    @IBOutlet weak var manageCell: UITableViewCell!
    @IBOutlet weak var currencyCell: UITableViewCell!
    @IBOutlet weak var themeCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        setThemedElements()
        setThemeSwitch()
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        activeCurrencyLabel.text = UserDefaultsManager.referenceFiatCurrency.rawValue.uppercased()
    }
    
    func setThemeSwitch() {
        if  UserDefaultsManager.themeIndex == 1 {
            themeSwitch.isOn = true
        } else {
            themeSwitch.isOn = false
        }
    }
    
    func setLocalizedStrings() {
        manageAddressBookLabel.text = "Manage Address Book"
        currencyLabel.text = "Currency"
        themeLabel.text = "Night Mode"
        title = "General"
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "segueToContactsViewController", sender: nil)
            }
        } else if indexPath.row == 1 {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "segueToCurrencySelector", sender: nil)
            }
        } else if indexPath.row == 2 {
            themeSwitch.setOn(!themeSwitch.isOn, animated: true)
            UserDefaultsManager.themeIndex = themeSwitch.isOn ?
                1 : 0
            ThemeManager.setTheme(index: themeSwitch.isOn ?
                1 : 0)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func setThemedElements() {
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        tableView.theme_separatorColor = O3Theme.tableSeparatorColorPicker
        manageCell.theme_backgroundColor = O3Theme.backgroundColorPicker
        themeCell.theme_backgroundColor = O3Theme.backgroundColorPicker
        currencyCell.theme_backgroundColor = O3Theme.backgroundColorPicker
        activeCurrencyLabel.theme_textColor = O3Theme.lightTextColorPicker
    }
}
