//
//  AssetIconsTableViewCell.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/14/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import Kingfisher
class AssetIconsTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
        super.awakeFromNib()
    }
    
    @IBOutlet var horizontalStackView: UIStackView?
    var list: [TransferableAsset]? {
        didSet {
            self.setupView()
        }
    }
    
    func setupView() {
        if list == nil {
            return
        }
        for v in self.horizontalStackView!.subviews {
            v.removeFromSuperview()
        }
        for i in list! {
            let imageURL = String(format: "https://cdn.o3.network/img/neo/%@.png",i.symbol.uppercased())
            KingfisherManager.shared.retrieveImage(with: URL(string: imageURL)!, options: [], progressBlock: nil) { image, _, _, _  in
                let imageView = UIImageView(image: image)
                imageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
                imageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
                imageView.contentMode = .scaleAspectFit
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                self.horizontalStackView?.addArrangedSubview(imageView)
            }
        }
        let spacerView = UIView()
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacerView.translatesAutoresizingMaskIntoConstraints = false
        spacerView.backgroundColor = UIColor.clear
        self.horizontalStackView?.addArrangedSubview(spacerView)
    }
    
 
}
