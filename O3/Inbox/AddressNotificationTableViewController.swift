//
//  AddressNotificationTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 5/28/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

protocol AddressNotificationDelegate: class {
    func reloadActiveAddresses()
}

class AddressNotificationTableViewController: UITableViewController {
    var accounts = NEP6.getFromFileSystem()?.accounts ?? []
    weak var delegate: AddressNotificationDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "close-x"), style: .plain, target: self, action: #selector(dismissTapped))
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        tableView.theme_separatorColor = O3Theme.tableSeparatorColorPicker
        navigationItem.title = "Addresses"
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addressNotificationCell") as! UITableViewCell
        let nicknameLabel = cell.viewWithTag(1) as! UILabel
        let addressLabel = cell.viewWithTag(2) as! UILabel
        let notificationSwitch = cell.viewWithTag(3) as! UISwitch
        
        nicknameLabel.theme_textColor = O3Theme.titleColorPicker
        addressLabel.theme_textColor = O3Theme.lightTextColorPicker
        notificationSwitch.theme_backgroundColor = O3Theme.backgroundColorPicker
        cell.theme_backgroundColor = O3Theme.backgroundColorPicker
        
        nicknameLabel.text = accounts[indexPath.row].label
        addressLabel.text = accounts[indexPath.row].address
        
        notificationSwitch.isOn = UserDefaultsManager.subscribedServices.contains(accounts[indexPath.row].address)
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68.0
    }
    
    func subscribeAddress(address: String, notificationSwitch: UISwitch) {
        notificationSwitch.setOn(true, animated: true)
        var temp = UserDefaultsManager.subscribedServices
        temp.append(address)
        UserDefaultsManager.subscribedServices = temp
        O3APIClient(network: AppState.network).subscribeToTopic(topic: address) { result in
            switch result {
            case .failure(_):
                return
            case .success(_):
                return
            }
        }
    }
    
    func unsubscribeAddress(address: String, notificationSwitch: UISwitch) {
        notificationSwitch.setOn(false, animated: true)
        var temp = UserDefaultsManager.subscribedServices
        temp.remove(at: temp.firstIndex(of: address)!)
        UserDefaultsManager.subscribedServices = temp
        O3APIClient(network: AppState.network).unsubscribeToTopic(topic: address) { result in
            switch result {
            case .failure(_):
                return
            case .success(_):
                return
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var address = accounts[indexPath.row].address
        var notificationSwitch = tableView.cellForRow(at: indexPath)?.viewWithTag(3) as! UISwitch
        if UserDefaultsManager.subscribedServices.contains(accounts[indexPath.row].address) {
            unsubscribeAddress(address: address, notificationSwitch: notificationSwitch)
        } else {
            subscribeAddress(address: address, notificationSwitch: notificationSwitch)
        }
        delegate?.reloadActiveAddresses()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
}
