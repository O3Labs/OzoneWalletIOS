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
    @IBOutlet weak var dustLabel: UILabel!
    @IBOutlet weak var dustSwitch: UISwitch!
    
    @IBOutlet weak var privacyLabel: UILabel!
    @IBOutlet weak var privacySwitch: UISwitch!
    
    
    @IBOutlet weak var manageCell: UITableViewCell!
    @IBOutlet weak var currencyCell: UITableViewCell!
    @IBOutlet weak var themeCell: UITableViewCell!
    @IBOutlet weak var hideDustCell: UITableViewCell!
    @IBOutlet weak var privacyCell: UITableViewCell!
    
    
    @IBOutlet weak var exportCell: UITableViewCell!
    @IBOutlet weak var exportCellLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        setThemedElements()
        setSwitchValues()
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        activeCurrencyLabel.text = UserDefaultsManager.referenceFiatCurrency.rawValue.uppercased()
    }
    
    func setSwitchValues() {
        if  UserDefaultsManager.themeIndex == 1 {
            themeSwitch.isOn = true
        } else {
            themeSwitch.isOn = false
        }
        
        dustSwitch.isOn = UserDefaultsManager.isDustHidden
        privacySwitch.isOn = UserDefaultsManager.privacyModeEnabled
    }
    
    func setLocalizedStrings() {
        manageAddressBookLabel.text = "Manage Address Book"
        currencyLabel.text = "Currency"
        themeLabel.text = "Night Mode"
        title = "General"
        dustLabel.text = "Hide Dust"
        privacyLabel.text = "Enable Privacy Mode"
        exportCellLabel.text = "Export NEP6 File"
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    func exportBackupData() {
        let vc = UIActivityViewController(activityItems: [NEP6.getFromFileSystemAsURL()], applicationActivities: [])
        present(vc, animated: true, completion: nil)
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
        } else if indexPath.row == 3 {
            dustSwitch.setOn(!dustSwitch.isOn, animated: true)
            UserDefaultsManager.isDustHidden = dustSwitch.isOn
            NotificationCenter.default.post(name: Notification.Name("NEP6Updated"), object: nil)
        } else if indexPath.row == 4 {
            privacySwitch.setOn(!privacySwitch.isOn, animated: true)
            UserDefaultsManager.privacyModeEnabled = privacySwitch.isOn
            NotificationCenter.default.post(name: Notification.Name("NEP6Updated"), object: nil)
        } else if indexPath.row == 5 {
            exportBackupData()
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
        privacyCell.theme_backgroundColor = O3Theme.backgroundColorPicker
        hideDustCell.theme_backgroundColor = O3Theme.backgroundColorPicker
        exportCell.theme_backgroundColor = O3Theme.backgroundColorPicker
        activeCurrencyLabel.theme_textColor = O3Theme.lightTextColorPicker
    }
}
