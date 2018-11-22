//
//  ConnectRequestTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 11/20/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

protocol ConnectRequestDelegate {
    func didCancel(message: dAppMessage)
    func didConnect(message: dAppMessage)
}

class ConnectRequestTableViewController: UITableViewController {
    
    var url: URL?
    var message: dAppMessage!
    var delegate: ConnectRequestDelegate?
    var dappMetadata: dAppMetadata?
    
    @IBOutlet var iconImageView: UIImageView?
    @IBOutlet var nameLabel: UILabel?
    @IBOutlet var descriptionLabel: UILabel?
    @IBOutlet var permissionLabel: UILabel?
    @IBOutlet var explainationLabel: UILabel?
    
    deinit {
        delegate = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Connect request"

        self.nameLabel?.text = dappMetadata?.title
        self.iconImageView?.kf.setImage(with: URL(string: dappMetadata?.iconURL ?? "https://cdn.o3.network/img/neo/NEO.png"))
        self.permissionLabel?.text = String(format: "%@ will be able to see your public address", dappMetadata?.title ?? "App")
        
    }
    
    @IBAction func didTapClose(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapCancel(_ sender: Any) {
        self.delegate?.didCancel(message: message)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapConnect(_ sender: Any) {
        self.delegate?.didConnect(message: message)
        self.dismiss(animated: true, completion: nil)
    }
    
}
