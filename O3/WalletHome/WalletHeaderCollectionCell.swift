//
//  WalletHeaderCollectionCell.swift
//  O3
//
//  Created by Andrei Terentiev on 9/24/17.
//  Copyright © 2017 drei. All rights reserved.
//

import Foundation
import UIKit

protocol WalletHeaderCellDelegate: class {
    func didTapLeft(index: Int)
    func didTapRight(index: Int)
}

class WalletHeaderCollectionCell: UICollectionViewCell {
    struct Data {
        var index: Int
        var numWatchAddresses: Int
        var latestPrice: PriceData
        var previousPrice: PriceData
        var referenceCurrency: Currency
        var selectedInterval: PriceInterval
    }
    @IBOutlet weak var walletHeaderLabel: UILabel!
    @IBOutlet weak var portfolioValueLabel: UILabel!
    @IBOutlet weak var percentChangeLabel: UILabel!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var walletMajorIcon: UIImageView!
    @IBOutlet weak var walletMinorIcon: UIImageView!
    
    weak var delegate: WalletHeaderCellDelegate?
    var data: WalletHeaderCollectionCell.Data? {
        didSet {
            guard let index = data?.index,
                let numWatchAddresses = data?.numWatchAddresses,
                let latestPrice = data?.latestPrice,
                let previousPrice = data?.previousPrice,
                let referenceCurrency = data?.referenceCurrency,
                let selectedInterval = data?.selectedInterval else {
                    fatalError("Cell is missing type")
            }
            if index == 0 {
                walletHeaderLabel.text = PortfolioStrings.portfolioHeaderO3Wallet
                leftButton.isHidden = true
                rightButton.isHidden = false
                percentChangeLabel.isHidden = false
                walletMajorIcon.image = UIImage(named: "ic_wallet")
                walletMinorIcon.image = UIImage(named: "ic_unlocked")
                walletMinorIcon.isHidden = false
            } else if numWatchAddresses == 0 {
                walletHeaderLabel.text = PortfolioStrings.watchAddress
                rightButton.isHidden = true
                leftButton.isHidden = false
                percentChangeLabel.isHidden = true
                walletMajorIcon.image = UIImage(named: "ic_watch")
                walletMinorIcon.image = UIImage(named: "ic_locked")
                walletMinorIcon.isHidden = false
            } else if index == numWatchAddresses + 1 {
                walletHeaderLabel.text = PortfolioStrings.portfolioHeaderCombinedHeader
                rightButton.isHidden = true
                leftButton.isHidden = false
                percentChangeLabel.isHidden = false
                walletMajorIcon.image = UIImage(named: "ic_all_wallet")
                walletMinorIcon.isHidden = true
            } else {
                walletHeaderLabel.text = (delegate as! HomeViewController).watchAddresses[index - 1].label
                rightButton.isHidden = false
                leftButton.isHidden = false
                percentChangeLabel.isHidden = false
                walletMajorIcon.image = UIImage(named: "ic_watch")
                walletMinorIcon.image = UIImage(named: "ic_locked")
                walletMinorIcon.isHidden = false
            }
            
            
            
            switch referenceCurrency {
            case .btc:
                portfolioValueLabel.text = "₿"+latestPrice.averageBTC.string(Precision.btc, removeTrailing: true)
                percentChangeLabel.theme_textColor = latestPrice.averageBTC >= previousPrice.averageBTC ? O3Theme.positiveGainColorPicker : O3Theme.negativeLossColorPicker
            default:
                portfolioValueLabel.text = latestPrice.averageFiatMoney().formattedString()
                percentChangeLabel.theme_textColor = latestPrice.average >= previousPrice.average ? O3Theme.positiveGainColorPicker : O3Theme.negativeLossColorPicker
            }
            percentChangeLabel.text = String.percentChangeString(latestPrice: latestPrice, previousPrice: previousPrice,
                                                                 with: selectedInterval, referenceCurrency: referenceCurrency)
            walletHeaderLabel.theme_textColor = O3Theme.lightTextColorPicker
        }
    }

    @IBAction func didTapRight(_ sender: Any) {
        guard let index = data?.index else {
            fatalError("undefined collection view cell behavior")
        }
        delegate?.didTapRight(index: index)
    }

    @IBAction func didTapLeft(_ sender: Any) {
        guard let index = data?.index else {
            fatalError("undefined collection view cell behavior")
        }
        delegate?.didTapLeft(index: index)
    }
}
