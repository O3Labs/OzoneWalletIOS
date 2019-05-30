//
//  InboxSettingsMenuTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 4/23/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

protocol NotificationDelegate: class {
    func loadMessages()
}

class InboxSettingsMenuTableViewController: UITableViewController, AddressNotificationDelegate {
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var allNotificationsSwitch: UISwitch!
    @IBOutlet weak var muteAllLabel: UILabel!
    
    weak var delegate: NotificationDelegate?
    
    let services = [UserDefaultsManager.Subscriptions.o3.rawValue,
                    UserDefaultsManager.Subscriptions.neoeconomy.rawValue]
    
    
    
    func reloadActiveAddresses() {
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        footerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(footerSelected)))
        setFooterSwitch()
        setThemedElements()

    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 2 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "inboxSettingsAddressMenuTableViewCell") as? UITableViewCell else {
                fatalError("Unrecoverable error occurred")
            }
            let titleLabel = cell.viewWithTag(1) as! UILabel
            let addressLabel = cell.viewWithTag(2) as! UILabel
            titleLabel.text = "Address Notifications"
            let addresses = NEP6.getFromFileSystem()?.getAccounts().map {$0.address} ?? []
            let subscribedAddress = UserDefaultsManager.subscribedServices.filter(addresses.contains)
            addressLabel.text = "\(subscribedAddress.count) / \(addresses.count) Active"
            titleLabel.theme_textColor = O3Theme.titleColorPicker
            addressLabel.theme_textColor = O3Theme.lightTextColorPicker
            cell.theme_backgroundColor = O3Theme.cardColorPicker
            return cell
            
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "inboxSettingsMenuTableViewCell") as? InboxSettingsMenuTableViewCell else {
                fatalError("Something went terribly wrong")
            }
            cell.serviceLabel.text = services[indexPath.row]
            cell.serviceSwitch.setOn(UserDefaultsManager.subscribedServices.contains(services[indexPath.row]), animated: true)
            return cell
        }

    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 2 {
            self.performSegue(withIdentifier: "segueToAddressManagement", sender: nil)
            return
        }
        
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
        return services.count + 1
    }
    
    func setFooterSwitch() {
        allNotificationsSwitch.setOn(UserDefaultsManager.subscribedServices.isEmpty, animated: true)
    }
    
    func unsubscribeToO3() {
        DispatchQueue.global().async {
            O3APIClient(network: AppState.network).unsubscribeToTopic(topic: UserDefaultsManager.Subscriptions.o3.rawValue) { result in
                self.delegate?.loadMessages()
                switch result {
                case .failure(_):
                    return
                case .success(_):
                    return
                }
            }
        }
    }
    
    func unsubscribeAllAddresses() {
        for account in NEP6.getFromFileSystem()?.getAccounts() ?? [] {
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
        var group = DispatchGroup()
        DispatchQueue.global().async {
            group.enter()
            O3APIClient(network: AppState.network).subscribeToTopic(topic: UserDefaultsManager.Subscriptions.o3.rawValue) { result in
                group.leave()
                switch result {
                case .failure(_):
                    return
                case .success(_):
                    return
                }
            }
        }
        group.wait()
        self.delegate?.loadMessages()
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
                self.delegate?.loadMessages()
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
        unsubscribeAllAddresses()
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToAddressManagement" {
            guard let dest = segue.destination as? UINavigationController,
                let addressController = dest.children.first as? AddressNotificationTableViewController  else {
                    return
                }
            addressController.delegate = self
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
