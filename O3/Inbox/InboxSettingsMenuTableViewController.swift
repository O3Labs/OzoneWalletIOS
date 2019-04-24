//
//  InboxSettingsMenuTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 4/23/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class InboxSettingsMenuTableViewController: UITableViewController {
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var allNotificationsSwitch: UISwitch!
    @IBOutlet weak var muteAllLabel: UILabel!
    
    let services = [UserDefaultsManager.Subscriptions.o3.rawValue,
                    UserDefaultsManager.Subscriptions.switcheo.rawValue,
                    UserDefaultsManager.Subscriptions.neoeconomy.rawValue]
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        footerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(footerSelected)))
        setFooterSwitch()
        setThemedElements()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "inboxSettingsMenuTableViewCell") as? InboxSettingsMenuTableViewCell else {
            fatalError("Something went terribly wrong")
        }
        cell.serviceLabel.text = services[indexPath.row]
        cell.serviceSwitch.setOn(UserDefaultsManager.subscribedServices.contains(services[indexPath.row]), animated: true)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if UserDefaultsManager.subscribedServices.contains(services[indexPath.row]) {
            var temp = UserDefaultsManager.subscribedServices
            temp.remove(at: temp.firstIndex(of: services[indexPath.row])!)
            UserDefaultsManager.subscribedServices = temp
        } else {
            var temp = UserDefaultsManager.subscribedServices
            temp.append(services[indexPath.row])
            UserDefaultsManager.subscribedServices = temp
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
        setFooterSwitch()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    
    func setFooterSwitch() {
        allNotificationsSwitch.setOn(UserDefaultsManager.subscribedServices.isEmpty, animated: true)
    }
    
    @objc func footerSelected() {
        if allNotificationsSwitch.isOn {
            allNotificationsSwitch.setOn(true, animated: true)
            UserDefaultsManager.subscribedServices = []
            tableView.reloadData()
        } else {
            allNotificationsSwitch.setOn(false, animated: true)
        }
    }
    
    func setThemedElements() {
        tableView.theme_backgroundColor = O3Theme.cardColorPicker
        view.theme_backgroundColor = O3Theme.cardColorPicker
        tableView.theme_separatorColor = O3Theme.tableSeparatorColorPicker
        muteAllLabel.theme_textColor = O3Theme.titleColorPicker
        muteAllLabel.text = "Mute All"
        
        allNotificationsSwitch.theme_thumbTintColor = O3Theme.backgroundColorPicker
        allNotificationsSwitch.theme_tintColor = O3Theme.backgroundColorPicker
        
        
    }
}
