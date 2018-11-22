//
//  SendRequestTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 11/22/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit


protocol SendRequestDelegate {
    func didCancelSend(message: dAppMessage, request: dAppProtocol.SendRequest)
    func didConfirmSend(message: dAppMessage, request: dAppProtocol.SendRequest)
}

class SendRequestTableViewController: UITableViewController {
    
    var request: dAppProtocol.SendRequest!
    var message: dAppMessage!
    var dappMetadata: dAppMetadata?
    
    @IBOutlet var iconImageView: UIImageView?
    @IBOutlet var nameLabel: UILabel?
    @IBOutlet var permissionLabel: UILabel?
    
    func setupView() {
        self.title = "Send request"
        self.nameLabel?.text = dappMetadata?.title
        self.iconImageView?.kf.setImage(with: URL(string: dappMetadata?.iconURL ?? "https://cdn.o3.network/img/neo/NEO.png"))
        self.permissionLabel?.text = String(format: "%@ is requesting you to send", dappMetadata?.title ?? "App")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
    }

}
