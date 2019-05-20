//
//  InboxTableViewCell.swift
//  O3
//
//  Created by Andrei Terentiev on 4/22/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher

class InboxTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    var data: Message! {
        didSet {
            titleLabel.text = data.sender.name
            subtitleLabel.text = data.data.text
            
            let dateformatter = DateFormatter()
            dateformatter.dateStyle = .short
            dateformatter.timeStyle = .short
            dateLabel.text = dateformatter.string(from: Date(timeIntervalSince1970: Double(data.timestamp)))
            
            logoImageView.kf.setImage(with: URL(string: "https://cdn-images-1.medium.com/max/284/1*_1U2EsLEnLNQZnc-UjNd6g@2x.png")!)
            
            if data.action == nil {
                actionButton.isHidden = true
                actionButton.heightAnchor.constraint(equalToConstant: 0).isActive = true
                actionButton.setNeedsLayout()
            } else {
                actionButton.isHidden = false
                actionButton.setTitle(data.action!.title, for: UIControl.State())
                actionButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
                actionButton.setNeedsLayout()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setThemedElements()
    }
    
    func setThemedElements() {
        theme_backgroundColor = O3Theme.backgroundColorPicker
        titleLabel.theme_textColor = O3Theme.titleColorPicker
        subtitleLabel.theme_textColor = O3Theme.titleColorPicker
        dateLabel.theme_textColor = O3Theme.lightTextColorPicker
    }
}
