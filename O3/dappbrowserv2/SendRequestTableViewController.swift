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
    @IBOutlet var iconImageView: UIImageView?
    @IBOutlet var actionButton: UIButton?
}

class SendRequestTableViewController: UITableViewController {
    
    @IBOutlet var containerView: UIView?
    @IBOutlet var actionContainerView: UIView?
    let activityView = dAppActivityView(frame: CGRect.zero)
    
    var request: dAppProtocol.SendRequest!
    var selectedWallet: Wallet!
    var message: dAppMessage!
    var dappMetadata: dAppMetadata?
    var accountState: AccountState?
    var requestedAsset: TransferableAsset?

    var onCancel: ((_ message: dAppMessage, _ request: dAppProtocol.SendRequest)->())?
    var onCompleted: ((_ response: dAppProtocol.SendResponse?, _ error: dAppProtocol.errorResponse?)->())?
    
    var usePriority: Bool! = false
    
    struct info {
        var key: String
        var title: String {
            return key.capitalized
        }
        var value: String
        var data: Any?
    }
    
    var data: [info]! = []
    
    enum dataKey: String{
        case total = "total"
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
    
    func fetchBalance(address: String) {
        let network = request.network.lowercased().contains("test") ? Network.test : Network.main
        O3APIClient(network: network).getAccountState(address: address) { result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let accountstate):
                self.accountState = accountstate
                self.checkBalance(accountState: accountstate)
            }
        }
    }
    
    
    func loadActivityView() {
        UIView.animate(withDuration: 0.25, animations: {
            self.activityView.frame = self.actionContainerView!.bounds
            self.actionContainerView?.alpha = 0
            self.containerView?.addSubview(self.activityView)
            self.activityView.beginLoading()
        }) { completed in
            
        }
        
    }
    
    func checkBalance(accountState: AccountState) {
        //check balance with the request
        let isNative = self.request.asset.lowercased() == "neo" || self.request.asset.lowercased() == "gas"
        
        if isNative {
            self.requestedAsset = accountState.assets.first(where: { t -> Bool in
                return t.name.lowercased() == self.request.asset.lowercased()
            })
        } else {
            //nep5
            self.requestedAsset = accountState.nep5Tokens.first(where: { t -> Bool in
                return t.name.lowercased() == self.request.asset.lowercased() || t.id == self.request.asset
            })
        }
        
        //this should never happen
        if self.requestedAsset == nil {
            return
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func buildData() {
        
        //get wallet label from the address
        //this should never be error
        let account = NEP6.getFromFileSystem()?.accounts.first(where: { n -> Bool in
            return n.address == request.fromAddress
        })
        data.append(info(key: dataKey.from.rawValue, value: String(format: "%@", account!.label), data: nil))
        data.append(info(key: dataKey.to.rawValue, value: String(format: "%@", request.toAddress), data: nil))
        if request.remark != nil {
            data.append(info(key: dataKey.remark.rawValue, value: String(format: "%@", request.remark!), data: nil))
        }
        
        if request.fee != nil {
            let fm = NumberFormatter()
            let feeNumber = fm.number(from: request.fee ?? "0")?.doubleValue
            if feeNumber!.isZero {
                data.append(info(key: dataKey.fee.rawValue, value: "", data: Double(0)))
            } else {
                data.append(info(key: dataKey.fee.rawValue, value: String(format: "%@ GAS", request.fee!), data: feeNumber))
            }
            
        } else {
            data.append(info(key: dataKey.fee.rawValue, value: "", data: Double(0)))
        }
        
        data.append(info(key: dataKey.total.rawValue,
                         value: String(format: "%@ %@", request.amount, request.asset.uppercased()),
                         data: request))
        
        
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
        DispatchQueue.global(qos: .userInitiated).async {
            self.fetchBalance(address: self.request.fromAddress!)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func didTapClose(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 && indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "dapp-metadata-cell") as! dAppMetaDataTableViewCell
            cell.dappMetadata = self.dappMetadata
            cell.permissionLabel?.text = String(format: "is requesting to send %@", self.request.asset.uppercased())
            return cell
        }
        
        if indexPath.section == 1{
            let info = data[indexPath.row]
            if info.key.lowercased() == dataKey.total.rawValue.lowercased()  {
                let cell = tableView.dequeueReusableCell(withIdentifier: "total-cell") as! SendRequestTableViewCell
                cell.keyLabel.text = String(format:"%@", "Total")
                cell.valueLabel.text = String(format:"%@", info.value)
                if let r = info.data as? dAppProtocol.SendRequest {
                    let imageURL = String(format: "https://cdn.o3.network/img/neo/%@.png", r.asset.uppercased())
                    cell.iconImageView?.kf.setImage(with: URL(string: imageURL))
                }
                
              
    
                if self.requestedAsset != nil {
                    let fm = NumberFormatter()
                    let amountNumber = fm.number(from: self.request.amount)
    
                    if self.requestedAsset!.value.isLess(than: amountNumber!.doubleValue) {
                        //insufficient balance
                        if let label = cell.viewWithTag(1) as? UILabel {
                            label.isHidden = false
                            cell.selectionStyle = .default
                        }
                    } else {
                        if let label = cell.viewWithTag(1) as? UILabel {
                            label.isHidden = true
                            cell.selectionStyle = .none
                        }
                    }
                } else {
                    if let label = cell.viewWithTag(1) as? UILabel {
                        label.isHidden = true
                        cell.selectionStyle = .none
                    }
                }
                
                
                return cell
            }
            
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
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "fee-cell") as! SendRequestTableViewCell
                
                cell.actionButton!.isSelected = self.usePriority!
                cell.actionButton!.tintColor = self.usePriority! ? Theme.light.accentColor : Theme.light.lightTextColor
                
                return cell
            }
            
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "info-cell") as! SendRequestTableViewCell
            cell.keyLabel.text = String(format:"%@", info.title)
            cell.valueLabel.text = String(format:"%@", info.value)
            
           
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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
            return
        }
        
        if info.key.lowercased() == dataKey.total.rawValue.lowercased() && self.requestedAsset != nil {
            self.showInsufficientBalancePopup()
            return
        }
    }
    
    //mark: -
    
    func showInsufficientBalancePopup() {
        //show popup saying insufficient balance
        let message = String(format: "Your balance: %@ %@", self.requestedAsset!.value.string(self.requestedAsset!.decimals, removeTrailing: true), self.requestedAsset!.symbol.uppercased())
        OzoneAlert.alertDialog("Insufficient balance", message: message, dismissTitle: "Dismiss") {
            
        }
    }
    
    @IBAction func didTapCancel(_ sender: Any) {
        onCancel?(message, request)
        self.dismiss(animated: true, completion: nil)
    }
    
    func send(wallet: Wallet, request: dAppProtocol.SendRequest) -> (dAppProtocol.SendResponse?, dAppProtocol.errorResponse?) {
        let isNative = request.asset.lowercased() == "neo" || request.asset.lowercased() == "gas"
        let network = request.network.lowercased().contains("test") ? Network.test : Network.main
        var node = AppState.bestSeedNodeURL
        if let bestNode = NEONetworkMonitor.autoSelectBestNode(network: network) {
            node = bestNode
        }
        let requestGroup = DispatchGroup()
        requestGroup.enter()
        
        var response: dAppProtocol.SendResponse?
        var error: dAppProtocol.errorResponse?
        if isNative {
            let assetID = request.asset.lowercased() == "neo" ? AssetId.neoAssetId : AssetId.gasAssetId
            let fm = NumberFormatter()
            let amountNumber = fm.number(from: request.amount)
            let feeNumber = fm.number(from: request.fee ?? "0")
            var attributes:[TransactionAttritbute] = []
            attributes.append(TransactionAttritbute(remark: "O3XDAPI")) //TODO discuss what we should put in
            if request.remark != nil {
                attributes.append(TransactionAttritbute(remark1: request.remark!))
            }
            wallet.sendAssetTransaction(network: network, seedURL: node, asset: assetID, amount: amountNumber!.doubleValue, toAddress: request.toAddress, attributes: attributes, fee: feeNumber!.doubleValue) { txID, err in
                if err != nil {
                    error = dAppProtocol.errorResponse(error: err.debugDescription)
                    requestGroup.leave()
                    return
                }
                response = dAppProtocol.SendResponse(txid: txID!, nodeUrl: node)
                requestGroup.leave()
                return
            }
        }
        
        requestGroup.wait()
        return (response, error)
    }
    
    @IBAction func didTapConfirm(_ sender: Any) {
        
        //check balance here
        if self.requestedAsset != nil {
            let fm = NumberFormatter()
            let amountNumber = fm.number(from: self.request.amount)
            if self.requestedAsset!.value.isLess(than: amountNumber!.doubleValue) {
                //insufficient balance
                self.showInsufficientBalancePopup()
                return
            }
        }
        
        DispatchQueue.main.async {
            self.loadActivityView()
        }
        
        //override it if dapp doesn't set the fee and user checked the priority
        let fm = NumberFormatter()
        if request.fee == nil || fm.number(from: request.fee ?? "0") == 0  {
            request.fee = self.usePriority! ? "0.0011" : "0"
        }
        
        //perform send here
        DispatchQueue.global(qos: .userInitiated).async {
            let (response,err) = self.send(wallet: self.selectedWallet, request: self.request)
            DispatchQueue.main.async {
                //breifly show the success then close the modal after 0.5 second
                self.activityView.success()
                DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.5, execute: {
                    self.onCompleted?(response,err)
                    self.dismiss(animated: true, completion: nil)
                })
            }
        }
        
    }
}


