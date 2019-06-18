//
//  CoinbaseSendRequestTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 6/14/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class CoinbaseSendRequestTableViewController: UITableViewController {
    var dappMetadata: dAppMetadata!
    var url: URL!
    var request: dAppProtocol.CoinbaseSendRequest!
    var message: dAppMessage!

    
    var onCancel: ((_ message: dAppMessage, _ request: dAppProtocol.CoinbaseSendRequest)->())?
    var onCompleted: ((_ response: dAppProtocol.CoinbaseSendResponse?, _ error: dAppProtocol.errorResponse?)->())?
    
    var sendResultState: CoinbaseTwoFactorTableViewController.TwoFactorState?
    var sendResultError: String?
    
    struct info {
        var key: String
        var title: String {
            return key.capitalized
        }
        var value: String
        var data: Any?
    }
    
    var data: [info]! = []
    
    enum dataKey: String {
        case total = "total"
        case from = "from"
        case to = "to"
        case remark = "memo"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buildData()
        tableView.reloadData()
    }
    
    func buildData() {
        data.append(info(key: dataKey.from.rawValue, value: String(format: "%@", "Coinbase"), data: nil))
        data.append(info(key: dataKey.to.rawValue, value: String(format: "%@", request.to), data: nil))
        data.append(info(key: dataKey.remark.rawValue, value: String(format: "%@", request.description ?? ""), data: nil))
        data.append(info(key: dataKey.total.rawValue,
                         value: String(format: "%@ %@", request.amount, request.asset.symbol.uppercased()),
                         data: request))
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return 4
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 && indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "dapp-metadata-cell") as! dAppMetaDataTableViewCell
            cell.dappMetadata = self.dappMetadata
            cell.permissionLabel?.text = String(format: "is requesting to send %@", self.request.asset.symbol)
            return cell
        } else {
            let info = data[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "info-cell") as! SendRequestTableViewCell
            cell.keyLabel.text = String(format:"%@", info.title)
            cell.valueLabel.text = String(format:"%@", info.value)
            return cell
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        onCancel?(message, request)
        self.dismiss(animated: true)
    }
    
    @IBAction func sendTapped(_ sender: Any) {
        CoinbaseClient.shared.send(amount: request.amount, to: request.to, currency: request.asset.symbol) { result in
            switch result {
            case .failure(let e):
                if let specificError = e as? CoinbaseSpecificError  {
                    if specificError.id == "two_factor_required" {
                        DispatchQueue.main.async {
                            self.sendResultState = .NEED2FA
                            self.performSegue(withIdentifier: "segueToTwoFactor", sender: nil)
                        }
                    } else {
                        self.sendResultState = .FAIL
                        self.sendResultError = specificError.message
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "segueToTwoFactor", sender: nil)
                        }
                    }
                } else {
                    self.sendResultState = .FAIL
                    self.sendResultError = e.localizedDescription
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "segueToTwoFactor", sender: nil)
                    }
                }
            case .success(let response):
                self.sendResultState = .SUCCESS
                let dapiResult = dAppProtocol.CoinbaseSendResponse(result: response, txid: nil)
                self.onCompleted?(dapiResult, nil)
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "segueToTwoFactor", sender: nil)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToTwoFactor" {
            guard let dest = segue.destination as? CoinbaseTwoFactorTableViewController else {
                fatalError("Something Went Terribly Wrong")
            }
            dest.state = sendResultState!
            dest.errorMessage = sendResultError
            dest.request = request
            dest.message = message
            dest.onCompleted = onCompleted
            dest.onCancel = onCancel
        }
    }
}
