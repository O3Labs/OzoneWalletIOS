//
//  ContractDetailsTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 2/14/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
class ContractInfoCell: UITableViewCell {
    @IBOutlet weak var keyLabel: UILabel!
    @IBOutlet weak var valueLabel: ThemedUILabel!
}

class ContractDetailsTableViewController: UITableViewController {
    var contract: ContractState?
    var scriptHash: String!
    
    var attachedAssets: [(String, String)] = [("NEO", "0"), ("GAS", "0")]
    
    func loadContractDetails() {
        NeoClient(seed: AppState.bestSeedNodeURL).getContractState(scriptHash: scriptHash) { result in
            switch result {
            case .failure(_):
                return
            case .success(let contractState):
                DispatchQueue.main.async {
                    self.contract = contractState
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadContractDetails()
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
        tableView.theme_separatorColor = O3Theme.tableSeparatorColorPicker
        title = "Transaction Details"
    }
    
    func convertContractToArray() -> [(String, String)] {
        guard let contract = contract else {
            return []
        }
        return [("name", contract.name),
                ("author", contract.author),
                ("email", contract.email),
                ("description", contract.description),
                ("scriptHash", contract.hash),
                ("version", String(describing: contract.version)),
                ("parameters", String(describing: contract.parameters)),
                ("storage", String(describing: contract.properties.storage)),
                ("dynamic_invoke", String(describing: contract.properties.dynamic_invoke))
                 ]
        
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sectionHeader")!
        let titleView = cell.viewWithTag(1) as! UILabel
        if section == 0 {
            titleView.text = "Contract Details"
        } else {
            titleView.text = "Attached Assets"
        }
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard contract != nil else {
              return UITableViewCell()
            }
            var arr = convertContractToArray()
            let cell = tableView.dequeueReusableCell(withIdentifier: "contract-info-cell") as! ContractInfoCell
            
            cell.keyLabel.text = arr[indexPath.row].0
            cell.valueLabel.text = arr[indexPath.row].1
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "contract-info-cell") as! ContractInfoCell
            cell.keyLabel.text = attachedAssets[indexPath.row].0
            cell.valueLabel.text = attachedAssets[indexPath.row].1
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(44.0)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Contract Info"
        } else {
            return "Attached Assets"
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return convertContractToArray().count
        } else {
            return 2
        }
    }
    
    
    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
