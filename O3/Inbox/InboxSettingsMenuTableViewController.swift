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
            if services[indexPath.row] == UserDefaultsManager.Subscriptions.o3.rawValue {
                unsubscribeToO3()
            } else {
                unsubscribeToNeoEconomy()
            }
        } else {
            var temp = UserDefaultsManager.subscribedServices
            temp.append(services[indexPath.row])
            UserDefaultsManager.subscribedServices = temp
            if services[indexPath.row] == UserDefaultsManager.Subscriptions.o3.rawValue {
                subscribeToO3()
            } else {
                subscribeToNeoEconomy()
            }
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
    
    func unsubscribeToO3() {
        DispatchQueue.global().async {
            O3APIClient(network: AppState.network).unsubscribeToTopic(topic: UserDefaultsManager.Subscriptions.o3.rawValue) { result in
                switch result {
                case .failure(_):
                    return
                case .success(_):
                    return
                }
            }
        }
        
        for account in NEP6.getFromFileSystem()?.accounts ?? [] {
            DispatchQueue.global().async {
                O3APIClient(network: AppState.network).unsubscribeToTopic(topic: account.address) { result in
                    switch result {
                    case .failure(_):
                        return
                    case .success(_):
                        return
                    }
                }
            }
        }
    }
    
    func subscribeToO3() {
        DispatchQueue.global().async {
            O3APIClient(network: AppState.network).subscribeToTopic(topic: UserDefaultsManager.Subscriptions.o3.rawValue) { result in
                switch result {
                case .failure(_):
                    return
                case .success(_):
                    return
                }
            }
        }
        for account in NEP6.getFromFileSystem()?.accounts ?? [] {
            DispatchQueue.global().async {
                O3APIClient(network: AppState.network).subscribeToTopic(topic: account.address) { result in
                    switch result {
                    case .failure(_):
                        return
                    case .success(_):
                        return
                    }
                }
            }
        }
    }
    
    func unsubscribeToNeoEconomy() {
        DispatchQueue.global().async {
            O3APIClient(network: AppState.network).unsubscribeToTopic(topic: UserDefaultsManager.Subscriptions.neoeconomy.rawValue) { result in
                switch result {
                case .failure(_):
                    return
                case .success(_):
                    return
                }
            }
        }
    }
    
    func subscribeToNeoEconomy() {
        DispatchQueue.global().async {
            O3APIClient(network: AppState.network).subscribeToTopic(topic: UserDefaultsManager.Subscriptions.neoeconomy.rawValue) { result in
                switch result {
                case .failure(_):
                    return
                case .success(_):
                    return
                }
            }
        }
    }
    
    func unsubscribeFromAllServices() {
        unsubscribeToNeoEconomy()
        unsubscribeToO3()
    }
    
    
    @objc func footerSelected() {
        if allNotificationsSwitch.isOn == false {
            allNotificationsSwitch.setOn(true, animated: true)
            UserDefaultsManager.subscribedServices = []
            tableView.reloadData()
            unsubscribeFromAllServices()
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
        
        allNotificationsSwitch.theme_backgroundColor = O3Theme.backgroundColorPicker
        
    }
}
