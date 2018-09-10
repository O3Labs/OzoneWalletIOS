//
//  transactionCell.swift
//  O3
//
//  Created by Andrei Terentiev on 9/13/17.
//  Copyright © 2017 drei. All rights reserved.
//

import Foundation
import UIKit

protocol TransactionHistoryDelegate: class {
    func getWatchAddresses() -> [WatchAddress]
    func getContacts() -> [Contact]
}

class TransactionCell: UITableViewCell {
    weak var delegate: TransactionHistoryDelegate?
    
    struct TransactionData {
        var date: UInt64
        var asset: Asset
        var toAddress: String
        var fromAddress: String
        var amount: String
        var precision: Int = 0
    }
    
    
    struct PendingTransactionData {
        var txID: String
        var time: UInt64
        var asset: Asset
        var toAddress: String
        var fromAddress: String
        var amount: String
    }
    
    @IBOutlet weak var transactionTimeLabel: UILabel?
    @IBOutlet weak var assetLabel: UILabel!
    @IBOutlet weak var assetImageView: UIImageView!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    override func awakeFromNib() {
        assetLabel.theme_textColor = O3Theme.titleColorPicker
        typeLabel.theme_textColor = O3Theme.lightTextColorPicker
        addressLabel.theme_textColor = O3Theme.lightTextColorPicker
        transactionTimeLabel?.theme_textColor = O3Theme.lightTextColorPicker
        contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
        super.awakeFromNib()
    }
    
    func getAddressAlias(address: String) -> String {
        if address == Authenticated.account?.address ?? "" {
            return AccountStrings.o3Wallet
        } else if let contactIndex = delegate?.getContacts().index(where: {$0.address == address}) {
            return delegate?.getContacts()[contactIndex].nickName ?? address
        } else if let watchAddressIndex = delegate?.getWatchAddresses().index(where: {$0.address == address}) {
            return delegate?.getWatchAddresses()[watchAddressIndex].nickName ?? address
        } else if address == "claim" {
            return AccountStrings.claimTransaction
        }
        return address
    }
    
    var data: TransactionData? {
        didSet {
            if data == nil {
                return
            }
            if data!.toAddress == Authenticated.account!.address{
                amountLabel.theme_textColor = O3Theme.positiveGainColorPicker
                typeLabel.text = "Received"
                amountLabel.text = String(format:"+%@", (data?.amount)!)
                addressLabel.text = String(format: "From: %@", getAddressAlias(address: (data?.fromAddress)!))
            } else {
                typeLabel.text = "Sent"
                amountLabel.theme_textColor = O3Theme.negativeLossColorPicker
                amountLabel.text = String(format:"-%@", (data?.amount)!)
                addressLabel.text = String(format: "To: %@", getAddressAlias(address: (data?.toAddress)!))
            }
            
            assetLabel.text = data?.asset.name
            assetImageView.kf.setImage(with: URL(string: data!.asset.logoURL))
            
            let date = Date(timeIntervalSince1970: Double((data?.date)!))
            let dateFormatter = DateFormatter()
            dateFormatter.locale = NSLocale.current
            dateFormatter.dateFormat = "yyyy.MM.dd @ HH:mm"
            let strDate = dateFormatter.string(from: date)
            
            transactionTimeLabel?.text = strDate
            
            amountLabel.theme_textColor = (data?.toAddress ?? "" == Authenticated.account?.address ?? "" ) ? O3Theme.positiveGainColorPicker : O3Theme.negativeLossColorPicker
        }
    }
    
    var pending: PendingTransactionData? {
        didSet {
            if pending == nil {
                return
            }
            //pending will never be received
            typeLabel.text = "Sending"
            amountLabel.theme_textColor = O3Theme.negativeLossColorPicker
            amountLabel.text = String(format:"-%@", (pending?.amount)!)
            addressLabel.text = String(format: "To: %@", getAddressAlias(address: (pending?.toAddress)!))
            
            assetLabel.text = pending?.asset.name
            assetImageView.kf.setImage(with: URL(string: pending!.asset.logoURL))
            
            let date = Date(timeIntervalSince1970: Double((pending?.time)!))
            let dateFormatter = DateFormatter()
            dateFormatter.locale = NSLocale.current
            dateFormatter.dateFormat = "yyyy.MM.dd @ HH:mm"
            let strDate = dateFormatter.string(from: date)
            transactionTimeLabel?.text = strDate
            
            amountLabel.theme_textColor =  O3Theme.negativeLossColorPicker
        }
    }
}
