//
//  OrderTableViewCell.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/21/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

protocol OrderViewModelDelegate {
    func cancelTapped(v: OrderViewModel)
}

struct OrderViewModel {
    
    enum Action: String {
        case Buy = "buy"
        case Sell = "sell"
    }
    
    var orderID: String!
    var orderStatus: SwitcheoOrderStatus!
    var wantAsset: TradableAsset!
    var offerAsset: TradableAsset!
    var price: Double!
    var wantAmount: Double!
    var offerAmount: Double!
    var action: Action!
    var datetime: Date!
    var originalWantAmount: Double!
    var filled: Bool! = false
    var filledAmount: Double!
    
    func formattedDateTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy.MM.dd @ HH:mm"
        let strDate = dateFormatter.string(from: self.datetime)
        return strDate
    }
    
    func formatAmount(amount: Double, decimals: Int) -> String {
        return Double(amount / pow(Double(10), Double(decimals))).string(decimals, removeTrailing: true)
    }
    
    func formattedPriceString() -> String {
        if action == .Sell {
            return String(format:"%@ %@/%@", price.string(offerAsset.decimals, removeTrailing: true), wantAsset.symbol.uppercased(), offerAsset.symbol.uppercased())
        }
        return String(format:"%@ %@/%@", price.string(offerAsset.decimals, removeTrailing: true), offerAsset.symbol.uppercased(), wantAsset.symbol.uppercased())
    }
    
    func progressPercent() -> Double {
        if filled == false {
            return Double(0.0)
        }
        
        if action == .Sell {
            let amount = filledAmount > 0 ? filledAmount : offerAmount
            return (amount! / originalWantAmount)  * Double(100.0)
        }
        let amount = filledAmount > 0 ? filledAmount : offerAmount
        return (amount! / originalWantAmount)  * Double(100.0)
    }
    
}

class OrderTableViewCell: UITableViewCell {
    
    @IBOutlet var wantAssetImageView: UIImageView!
    @IBOutlet var offerAssetImageView: UIImageView!
    @IBOutlet var wantAssetSymbolLabel: UILabel!
    @IBOutlet var offerAssetSymbolLabel: UILabel!
    @IBOutlet var filledAmountLabel: UILabel!
    @IBOutlet var offerAmountLabel: UILabel!
    @IBOutlet var priceLabel: UILabel!
    @IBOutlet var actionLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    
    @IBOutlet var progressLabel: UILabel?
    @IBOutlet var progressBar: UIProgressView?
    @IBOutlet var cancelButton: UIButton?
    var delegate: OrderViewModelDelegate?
    
    private var v: OrderViewModel!
    
    func configure(viewModel: OrderViewModel) {
        v = viewModel
        wantAssetImageView.kf.setImage(with: viewModel.wantAsset.imageURL)
        offerAssetImageView.kf.setImage(with: viewModel.offerAsset.imageURL)
        wantAssetSymbolLabel.text = viewModel.wantAsset.symbol.uppercased()
        offerAssetSymbolLabel.text = viewModel.offerAsset.symbol.uppercased()
        
        filledAmountLabel.text = viewModel.formatAmount(amount: viewModel.wantAmount, decimals: viewModel.wantAsset.decimals)
        offerAmountLabel.text = viewModel.formatAmount(amount: viewModel.offerAmount, decimals: viewModel.offerAsset.decimals)
        priceLabel.text = viewModel.formattedPriceString()
        timeLabel.text = viewModel.datetime.timeAgo(numericDates: true)
        actionLabel.text = viewModel.action.rawValue.uppercased()
        actionLabel.theme_textColor = viewModel.action == OrderViewModel.Action.Buy ? O3Theme.positiveGainColorPicker : O3Theme.negativeLossColorPicker
        
        let completedOrder = v.orderStatus == SwitcheoOrderStatus.completed || v.orderStatus == SwitcheoOrderStatus.cancelled || v.orderStatus == SwitcheoOrderStatus.empty
        self.cancelButton?.isHidden = completedOrder
        self.progressBar?.isHidden = true
        self.progressLabel?.isHidden = true
        
        if completedOrder == false {
            self.progressBar?.isHidden = false
            self.progressLabel?.isHidden = false
            self.progressLabel?.text = String(format: "%@%@ filled", viewModel.progressPercent().string(2, removeTrailing: true), "%")
            self.progressBar?.progress = Float(viewModel.progressPercent() / 100.0)
        }
       
    }
    
    @IBAction func didTapCancel(_ sender: Any) {
        self.delegate?.cancelTapped(v: self.v)
    }
}
