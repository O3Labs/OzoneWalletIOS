//
//  CurrencyTableViewCell.swift
//  O3
//
//  Created by jcc on 2020/6/18.
//  Copyright © 2020 O3 Labs Inc. All rights reserved.
//

import UIKit

class CurrencyTableViewCell: UITableViewCell {
    @IBOutlet weak var assetTitleLabel: UILabel!
    @IBOutlet weak var assetAmountLabel: UILabel!
    @IBOutlet weak var assetFiatPriceLabel: UILabel!
    @IBOutlet weak var assetFiatAmountLabel: UILabel!
    @IBOutlet weak var assetPercentChangeLabel: UILabel!
    @IBOutlet weak var assetIcon: UIImageView!
    
    struct Data {
        var asset: PortfolioAsset
        var referenceCurrency: Currency
        var latestPrice: PriceData
        var firstPrice: PriceData
    }

    override func awakeFromNib() {
        let titleLabels = [assetTitleLabel, assetAmountLabel, assetFiatAmountLabel]
        contentView.theme_backgroundColor = O3Theme.cardColorPicker
        theme_backgroundColor = O3Theme.cardColorPicker
        for label in titleLabels {
            label?.theme_textColor = O3Theme.titleColorPicker
        }
        assetFiatPriceLabel.theme_textColor = O3Theme.lightTextColorPicker
        super.awakeFromNib()
    }
    var data: CurrencyTableViewCell.Data? {
        didSet {
            guard let asset = data?.asset,
                let referenceCurrency = data?.referenceCurrency,
                let latestPrice = data?.latestPrice,
                let firstPrice = data?.firstPrice else {
                    fatalError("undefined data set")
            }
            if UserDefaultsManager.privacyModeEnabled {
                assetAmountLabel.isHidden = true
                assetFiatAmountLabel.isHidden = true
            } else {
                assetAmountLabel.isHidden = false
                assetFiatAmountLabel.isHidden = false
            }
            
            assetTitleLabel.text = asset.symbol
            let amountDouble = Double(truncating: asset.value as NSNumber)
            
            
            let precision = referenceCurrency == .btc ? Precision.btc : Precision.usd
            let referencePrice = referenceCurrency == .btc ? latestPrice.averageBTC : latestPrice.average
            let referenceFirstPrice = referenceCurrency == .btc ? firstPrice.averageBTC : firstPrice.average
            assetAmountLabel.text = amountDouble.string(8, removeTrailing: true)
            if referenceCurrency == .btc {
                assetFiatAmountLabel.text = "₿"+latestPrice.averageBTC.string(Precision.btc, removeTrailing: true)
            } else {
                assetFiatAmountLabel.text = Fiat(amount: Float(referencePrice) * Float(amountDouble)).formattedString()
            }

            //format USD properly
            if referenceCurrency == .btc {
                assetFiatPriceLabel.text = "₿"+referencePrice.string(precision, removeTrailing: referenceCurrency == .btc)
            } else {
                assetFiatPriceLabel.text = Fiat(amount: Float(referencePrice)).formattedString()
            }

            assetPercentChangeLabel.text = String.percentChangeStringShort(latestPrice: latestPrice, previousPrice: firstPrice,
                                                                           referenceCurrency: referenceCurrency)
            
            
            DispatchQueue.main.async {
                if latestPrice.average > firstPrice.average {
                    self.assetPercentChangeLabel.theme_textColor = O3Theme.positiveGainColorPicker
                } else if latestPrice.average < firstPrice.average {
                    self.assetPercentChangeLabel.theme_textColor = O3Theme.negativeLossColorPicker
                } else {
                    self.assetPercentChangeLabel.theme_textColor = O3Theme.lightTextColorPicker
                    self.assetPercentChangeLabel.text = "--"
                }
            }

            var logoURL = ""
            if let walletAsset = asset as? O3WalletNativeAsset {
                logoURL = String(format: "https://cdn.o3.network/img/neo/%@.png", asset.symbol.uppercased())
            } else {
                logoURL = String(format: "https://cdn.o3.app/img/assets/%@.png", asset.symbol.uppercased())
            }
            
            assetIcon.kf.setImage(with: URL(string: logoURL))
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
