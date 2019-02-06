//
//  dAppMetaDataTableViewCell.swift
//  O3
//
//  Created by Apisit Toompakdee on 11/26/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

class dAppMetaDataTableViewCell: UITableViewCell {

    @IBOutlet var iconImageView: UIImageView?
    @IBOutlet var nameLabel: UILabel?
    @IBOutlet var permissionLabel: UILabel?
    
    var dappMetadata: dAppMetadata? {
        didSet{
            if dappMetadata != nil {
                self.setupView()
            }
        }
    }
    
    
    func setupView() {
        DispatchQueue.main.async {
            self.nameLabel?.text = self.dappMetadata?.title ?? self.dappMetadata?.url.host
            if self.dappMetadata?.iconURL != nil {
                self.iconImageView?.kf.setImage(with: URL(string: self.dappMetadata!.iconURL!))
            } else {
                self.iconImageView?.image = UIImage(named: "unknown_app")
            }
        }
    }
}
