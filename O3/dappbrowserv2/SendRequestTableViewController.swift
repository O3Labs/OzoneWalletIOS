//
//  SendRequestTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 11/22/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit


class SendRequestTableViewCell: UITableViewCell {
    @IBOutlet var keyLabel: UILabel!
    @IBOutlet var valueLabel: UILabel!
}

class SendRequestTableViewController: UITableViewController {
    
    var request: dAppProtocol.SendRequest!
    var message: dAppMessage!
    var dappMetadata: dAppMetadata?
    
    var onConfirm: ((_ message: dAppMessage, _ request: dAppProtocol.SendRequest)->())?
    var onCancel: ((_ message: dAppMessage, _ request: dAppProtocol.SendRequest)->())?
    
    struct info {
        var key: String
        var title: String {
            if key == "fee" {
                return "Network fee"
            }
            return key
        }
        var value: String
    }
    
    var data: [info]! = []
    
    enum dataKey: String{
        case asset = "asset"
        case from = "from"
        case to = "to"
        case remark = "remark"
        case fee = "fee"
    }
    
    func setupView() {
        self.title = "Send request"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: self.request.network, style: .plain, target: self, action: nil)
         self.navigationItem.leftBarButtonItem?.isEnabled = false
        self.buildData()
    }
    
    func buildData() {
        data.append(info(key: dataKey.asset.rawValue, value: String(format: "%@ %@", request.amount, request.asset.uppercased())))
        data.append(info(key: dataKey.from.rawValue, value: String(format: "%@", request.fromAddress!)))
        data.append(info(key: dataKey.to.rawValue, value: String(format: "%@", request.toAddress)))
        
        
        if request.remark != nil {
            data.append(info(key: dataKey.remark.rawValue, value: String(format: "%@", request.remark!)))
        }
        if request.fee != nil {
            data.append(info(key: dataKey.fee.rawValue, value: String(format: "%@ GAS", request.fee!)))
        }
        
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
    }
    
    @IBAction func didTapClose(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 1
        }
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            return 179.0
        }
        return 40.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 && indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "dapp-metadata-cell") as! dAppMetaDataTableViewCell
            cell.dappMetadata = self.dappMetadata
            cell.permissionLabel?.text = String(format: "%@ is requesting you to send", dappMetadata?.title ?? "App")
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "info-cell") as! SendRequestTableViewCell
        
        let info = data[indexPath.row]
        cell.keyLabel.text = String(format:"%@", info.title.uppercased())
        cell.valueLabel.text = String(format:"%@", info.value)
        return cell
    }
    
    //mark: -
    @IBAction func didTapCancel(_ sender: Any) {
        onCancel?(message, request)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapConfirm(_ sender: Any) {
        onConfirm?(message, request)
        self.dismiss(animated: true, completion: nil)
    }
}


