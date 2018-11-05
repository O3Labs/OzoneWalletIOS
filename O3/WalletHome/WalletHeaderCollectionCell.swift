//
//  WalletHeaderCollectionCell.swift
//  O3
//
//  Created by Andrei Terentiev on 9/24/17.
//  Copyright © 2017 drei. All rights reserved.
//

import Foundation
import UIKit
import Neoutils

protocol WalletHeaderCellDelegate: class {
    func didTapLeft()
    func didTapRight()
}

class WalletHeaderCollectionCell: UICollectionViewCell {
    struct Data {
        var type: HeaderType
        var account: NEP6.Account?
        var numWatchAddresses: Int
        var latestPrice: PriceData
        var previousPrice: PriceData
        var referenceCurrency: Currency
        var selectedInterval: PriceInterval
    }
    enum HeaderType {
        case activeWallet
        case lockedWallet
        case combined
    }
    
    
    @IBOutlet weak var walletHeaderLabel: UILabel!
    @IBOutlet weak var portfolioValueLabel: UILabel!
    @IBOutlet weak var percentChangeLabel: UILabel!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var walletMajorIcon: UIImageView!
    @IBOutlet weak var walletMinorIcon: UIImageView!
    
    @IBOutlet weak var walletUnlockHeaderArea: UIView!
    
    weak var delegate: WalletHeaderCellDelegate?
    
    func setupActiveWallet() {
        if data?.account != nil {
            walletHeaderLabel.text = data?.account!.label
        } else {
            walletHeaderLabel.text = "MY O3 Wallet"
        }
        
        leftButton.isHidden = true
        rightButton.isHidden = false
        percentChangeLabel.isHidden = false
        walletMajorIcon.image = UIImage(named: "ic_wallet")
        walletMinorIcon.image = UIImage(named: "ic_unlocked")
        walletMinorIcon.isHidden = false
    }

    func setupCombined() {
        walletHeaderLabel.text = PortfolioStrings.portfolioHeaderCombinedHeader
        rightButton.isHidden = true
        leftButton.isHidden = false
        percentChangeLabel.isHidden = false
        walletMajorIcon.image = UIImage(named: "ic_all_wallet")
        walletMinorIcon.isHidden = true
    }
    
    func setupLockedWallet() {
        walletHeaderLabel.text = data?.account!.label
        rightButton.isHidden = false
        leftButton.isHidden = false
        percentChangeLabel.isHidden = false
        if data?.account!.key == nil {
            walletMajorIcon.image = UIImage(named: "ic_watch")
            walletMinorIcon.isHidden = true
        } else {
            walletMajorIcon.image = UIImage(named: "ic_wallet")
            walletMinorIcon.image = UIImage(named: "ic_locked")
            walletMinorIcon.isHidden = false
        }
    }
    
    
    var data: WalletHeaderCollectionCell.Data? {
        didSet {
            guard let type = data?.type,
                let numWatchAddresses = data?.numWatchAddresses,
                let latestPrice = data?.latestPrice,
                let previousPrice = data?.previousPrice,
                let referenceCurrency = data?.referenceCurrency,
                let selectedInterval = data?.selectedInterval else {
                    fatalError("Cell is missing type")
            }
            switch type {
            case .activeWallet:
                setupActiveWallet()
            case .lockedWallet:
                setupLockedWallet()
            case .combined:
                setupCombined()
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
            walletUnlockHeaderArea.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(unlockTapped)))
        }
    }
    
    
    @objc func unlockTapped() {
        if let key = data?.account?.key {
            if data?.account?.isDefault == true {
                return
            }

            let alertController = UIAlertController(title: "Enter the password", message: "It will replace default ", preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: OzoneAlert.okPositiveConfirmString, style: .default) { (_) in
                let inputPass = alertController.textFields?[0].text!
                var error: NSError?
                let _ = NeoutilsNEP2Decrypt(key, inputPass, &error)
                if error == nil {
                    NEP6.makeNewDefault(key: key, pass: inputPass!)
                } else {
                    OzoneAlert.alertDialog(message: "Error", dismissTitle: "Ok") {}
                }
            }
            
            let cancelAction = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { (_) in }
            
            alertController.addTextField { (textField) in
                textField.placeholder = "Password"
                textField.isSecureTextEntry = true
            }
            
            alertController.addAction(confirmAction)
            alertController.addAction(cancelAction)
            
            UIApplication.shared.keyWindow?.rootViewController?.presentFromEmbedded(alertController, animated: true, completion: nil)
        }
    }
    
    

    @IBAction func didTapRight(_ sender: Any) {
        delegate?.didTapRight()
    }

    @IBAction func didTapLeft(_ sender: Any) {
        delegate?.didTapLeft()
    }
}
