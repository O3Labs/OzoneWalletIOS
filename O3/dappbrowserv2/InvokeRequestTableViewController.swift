//
//  InvokeRequestTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 2/12/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class InvokeRequestTableViewCell: UITableViewCell {
    @IBOutlet var keyLabel: UILabel!
    @IBOutlet var valueLabel: UILabel!
    @IBOutlet var actionButton: UIButton?
}

class InvokeRequestTableViewController: UITableViewController {
    
    
    var onCancel: ((_ message: dAppMessage, _ request: dAppProtocol.InvokeRequest)->())?
    var onCompleted: ((_ response: dAppProtocol.InvokeResponse?, _ error: dAppProtocol.errorResponse?)->())?
    
    var usePriority: Bool! = false
    
    var selectedWallet: Wallet! = nil
    var dappMetadata: dAppMetadata! = nil
    var request: dAppProtocol.InvokeRequest! = nil
    
    var data: [info]! = []
    
    struct info {
        var key: String
        var title: String {
            return key.capitalized
        }
        var value: String
        var data: Any?
    }
    
    enum dataKey: String{
        case with = "With"
        case txDetails = "View details"
        case fee = "Priority"
    }
    
    func setupView() {
        self.title = "Authorization Request"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: self.request.network, style: .plain, target: self, action: nil)
        self.navigationItem.leftBarButtonItem?.isEnabled = false
        
        self.buildData()
    }
    
    @IBAction func didTapClose(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func buildData() {
        let account = NEP6.getFromFileSystem()?.accounts.first(where: { n -> Bool in
            return n.address == selectedWallet.address
        })
        data.append(info(key: dataKey.with.rawValue, value: String(format: "%@", account?.label ?? "My O3 Wallet"), data: nil))
        data.append(info(key: dataKey.txDetails.rawValue, value: "", data: nil))
        
        if request.fee != nil {
            let fm = NumberFormatter()
            let feeNumber = fm.number(from: request.fee ?? "0")?.doubleValue
            if feeNumber!.isZero {
                data.append(info(key: dataKey.fee.rawValue, value: "", data: Double(0)))
            } else {
                data.append(info(key: dataKey.fee.rawValue, value: String(format: "%@ GAS", request.fee), data: feeNumber))
            }
            
        } else {
            data.append(info(key: dataKey.fee.rawValue, value: "", data: Double(0)))
        }
        
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 1
        }
        if section == 1 {
            return data.count
        }
        return 1 //empty cell to make it show separator
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            return 80.0
        }
        if indexPath.section == 1 {
            return 44.0
        }
        return 0.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            let info = data[indexPath.row]
            if info.key.lowercased() == dataKey.fee.rawValue.lowercased() {
                if let fee = info.data as? Double {
                    if fee == 0 {
                        usePriority = !usePriority
                        DispatchQueue.main.async {
                            tableView.reloadRows(at: [indexPath], with: .automatic)
                        }
                    }
                }
            } else if info.key.lowercased() == dataKey.txDetails.rawValue.lowercased() {
                self.performSegue(withIdentifier: "segueToContractDetails", sender: nil)
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 && indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "dapp-metadata-cell") as! dAppMetaDataTableViewCell
            cell.dappMetadata = self.dappMetadata
            cell.permissionLabel?.text = String(format: "is requesting to %@", self.request.operation)
            return cell
        }
        
        if indexPath.section == 1 {
            let info = data[indexPath.row]
            if info.key.lowercased() == dataKey.fee.rawValue.lowercased()  {
                //if fee is set by the app and is more than zero we just show the fee here
                if let fee = info.data as? Double {
                    if fee > 0 {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "info-cell") as! SendRequestTableViewCell
                        cell.keyLabel.text = String(format:"%@", info.title)
                        cell.valueLabel.text = String(format:"%@ GAS", fee.string(8, removeTrailing: true))
                        return cell
                    }
                }
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "fee-cell") as! InvokeRequestTableViewCell
                
                cell.actionButton!.isSelected = self.usePriority!
                cell.actionButton!.tintColor = self.usePriority! ? Theme.light.accentColor : Theme.light.lightTextColor
                
                return cell
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "info-cell") as! InvokeRequestTableViewCell
            cell.keyLabel.text = String(format:"%@", info.title)
            cell.valueLabel.text = String(format:"%@", info.value)
            
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        return cell!
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let dest = segue.destination as? UINavigationController,
            let detailsContoller = dest.children[0] as? ContractDetailsTableViewController else {
                fatalError("Invalid Segue Performed")
        }
        detailsContoller.scriptHash = request.scriptHash
        if request.attachedAssets != nil {
            detailsContoller.attachedAssets =
                [("NEO", String(describing: request.attachedAssets?.neo)),
                 ("GAS", String(describing: request.attachedAssets?.gas))
                ]
        }
    }
}
