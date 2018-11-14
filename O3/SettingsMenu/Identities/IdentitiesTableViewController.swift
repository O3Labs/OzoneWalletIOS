//
//  IdentitiesTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 11/2/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import WebBrowser

class IdentitiesTableViewController: UITableViewController, WebBrowserDelegate {
    
    var nnsNames = [String]()
    func loadNNSNames() {
        O3APIClient(network: AppState.network).reverseDomainLookup(address: (Authenticated.wallet?.address)!) { result in
            switch result {
            case .failure (let error):
                print(error)
            case .success(let domains):
                DispatchQueue.main.async {
                    self.nnsNames = []
                    for domain in domains {
                        self.nnsNames.append(domain.domain)
                    }
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    @objc func dismissTapped() {
        self.dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-x"), style: .plain, target: self, action: #selector(dismissTapped))
        setLocalizedStrings()
        setThemedElements()
        applyNavBarTheme()
        loadNNSNames()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if nnsNames.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "nnsEmptyTableViewCell")!
            (cell.viewWithTag(1) as! UILabel).theme_textColor = O3Theme.titleColorPicker
            (cell.viewWithTag(1) as! UILabel).text = SettingsStrings.nnsEmpty
            cell.contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
            return cell
        }
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "nnsNameTableViewCell")!
        (cell.viewWithTag(1) as! UILabel).theme_textColor = O3Theme.titleColorPicker
        (cell.viewWithTag(1) as! UILabel).text = nnsNames[indexPath.row]
        cell.contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Controller().openDappBrowser(url: URL(string: "https://o3.app/" + nnsNames[indexPath.row])!, modal: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if nnsNames.count > 0 {
            return nnsNames.count
        }
        return 1
    }
    
    func setLocalizedStrings() {
        
    }
    
    func setThemedElements() {
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
}
