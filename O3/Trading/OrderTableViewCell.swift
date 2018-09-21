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
        return String(format:"%@ %@/%@", price.string(offerAsset.decimals, removeTrailing: true), offerAsset.symbol.uppercased(), wantAsset.symbol.uppercased())
    }
    
}

class OrderTableViewCell: UITableViewCell {
    
    @IBOutlet var wantAssetImageView: UIImageView!
    @IBOutlet var offerAssetImageView: UIImageView!
    @IBOutlet var wantAssetSymbolLabel: UILabel!
    @IBOutlet var offerAssetSymbolLabel: UILabel!
    @IBOutlet var wantAmountLabel: UILabel!
    @IBOutlet var offerAmountLabel: UILabel!
    @IBOutlet var priceLabel: UILabel!
    @IBOutlet var actionLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var cancelButton: UIButton!
    var delegate: OrderViewModelDelegate?
    
    private var v: OrderViewModel!
    
    func configure(viewModel: OrderViewModel) {
        v = viewModel
        wantAssetImageView.kf.setImage(with: viewModel.wantAsset.imageURL)
        offerAssetImageView.kf.setImage(with: viewModel.offerAsset.imageURL)
        wantAssetSymbolLabel.text = viewModel.wantAsset.symbol.uppercased()
        offerAssetSymbolLabel.text = viewModel.offerAsset.symbol.uppercased()
        
        wantAmountLabel.text = viewModel.formatAmount(amount: viewModel.wantAmount, decimals: viewModel.wantAsset.decimals)
        offerAmountLabel.text = viewModel.formatAmount(amount: viewModel.offerAmount, decimals: viewModel.offerAsset.decimals)
        priceLabel.text = viewModel.formattedPriceString()
        timeLabel.text = viewModel.formattedDateTime()
        actionLabel.text = viewModel.action.rawValue.uppercased()
        actionLabel.theme_textColor = viewModel.action == OrderViewModel.Action.Buy ? O3Theme.positiveGainColorPicker : O3Theme.negativeLossColorPicker
        self.cancelButton.isHidden = v.orderStatus == SwitcheoOrderStatus.completed || v.orderStatus == SwitcheoOrderStatus.cancelled
    }
    
    @IBAction func didTapCancel(_ sender: Any) {
        self.delegate?.cancelTapped(v: self.v)
    }
}
