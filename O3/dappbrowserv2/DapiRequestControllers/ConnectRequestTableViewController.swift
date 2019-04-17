//
//  ConnectRequestTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 11/20/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import Neoutils
import PKHUD
import KeychainAccess

class ConnectRequestTableViewController: UITableViewController {
    
    var url: URL?
    var message: dAppMessage!
    var dappMetadata: dAppMetadata?
    var selectedAccount: NEP6.Account?
    
    var onConfirm: ((_ message: dAppMessage, _ wallet: Wallet, _ account: NEP6.Account?)->())?
    var onCancel: ((_ message: dAppMessage)->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Connect request"
        //set selected one to the main active one first
        let nep6 = NEP6.getFromFileSystem()
        let defaultAccount =  nep6?.accounts.first(where: { n -> Bool in
            return n.isDefault == true
        })
        selectedAccount = defaultAccount
    }
    
    @IBAction func didTapClose(_ sender: Any) {
        onCancel?(message)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapCancel(_ sender: Any) {
        onCancel?(message)
        self.dismiss(animated: true, completion: nil)
    }
    
    func sendWalletDetails(wallet: Wallet) {
        DispatchQueue.main.async {
            HUD.hide()
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            dapiEvent.shared.accountConnected(url: self.url?.absoluteString ?? "", domain: self.url?.host ?? "")
            self.onConfirm?(self.message, wallet, self.selectedAccount)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func didTapConnect(_ sender: Any) {
        if selectedAccount?.isDefault ?? false{
            //no need to decrypt the default wallet, its already in session
            sendWalletDetails(wallet: Authenticated.wallet!)
        } else {
            O3KeychainManager.getWalletForNep6(for: (self.selectedAccount?.address)!) { result in
                switch result {
                case .success(let wallet):
                    self.sendWalletDetails(wallet: wallet)
                case .failure:
                     return
                }
            }
        }
    }
    
    //mark:-
    
    @IBAction func unwindToConnectRequest(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? ConnectWalletSelectorTableViewController {
            DispatchQueue.main.async {
                self.selectedAccount = sourceViewController.selectedAccount
                self.tableView.reloadData()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectWallet" {
            let vc = segue.destination as! ConnectWalletSelectorTableViewController
            vc.selectedAccount = selectedAccount
        }
    }
    
    //mark: - 
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 1
        }
        if section == 1 {
            return 1
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            return 80.0
        }
        if indexPath.section == 1 {
            return 60.0
        }
        return 0.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 && indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "dapp-metadata-cell") as! dAppMetaDataTableViewCell
            cell.dappMetadata = self.dappMetadata
            cell.permissionLabel?.text = String(format: "is requesting to connect to your wallet")
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "wallet-cell") as! ConnectRequestWalletUITableViewCell
        cell.titleLabel.text = selectedAccount?.label ?? "My O3 Wallet"
        cell.addressLabel.text = selectedAccount?.address ?? Authenticated.wallet?.address
        return cell
    }
}
