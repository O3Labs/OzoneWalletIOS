//
//  CreateOrderTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/19/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit


enum CreateOrderAction: Int {
    case Buy = 0
    case Sell
}

protocol CreateOrderDelegate {
    func onpairPriceChange(price: AssetPrice)
    func onWantAssetChange(asset: TradableAsset, action: CreateOrderAction)
    func onOfferAssetChange(asset: TradableAsset, action: CreateOrderAction)
    func onActionChange(action: CreateOrderAction)
    
    func onWantAmountChange(value: Double, pairPrice: AssetPrice)
    func onOfferAmountChange(value: Double, pairPrice: AssetPrice)
}


extension TradableAsset {
    var imageURL: URL {
        return URL(string: String(format: "https://cdn.o3.network/img/neo/%@.png", self.symbol.uppercased()))!
    }
}
class CreateOrderViewModel {
    
    var delegate: CreateOrderDelegate!
    var selectedAction: CreateOrderAction!
    
    var pairPrice: AssetPrice! {
        didSet {
            self.delegate.onpairPriceChange(price: pairPrice)
        }
    }
    var offerAsset: TradableAsset!
    var wantAsset: TradableAsset!
    
    var wantAmount: Double? {
        didSet {
            if wantAmount == nil {
                return
            }
            self.delegate.onWantAmountChange(value: wantAmount!, pairPrice: pairPrice)
        }
    }
    
    var offerAmount: Double? {
        didSet {
            if offerAmount == nil {
                return
            }
            self.delegate.onOfferAmountChange(value: offerAmount!, pairPrice: pairPrice)
        }
    }
    
    var title: String {
        return String(format: "%@ %@", selectedAction == CreateOrderAction.Sell ? "SELL" : "BUY"
            , wantAsset.symbol)
    }
    
    func setupView() {
        self.delegate.onOfferAssetChange(asset: offerAsset, action: selectedAction)
        self.delegate.onWantAssetChange(asset: wantAsset, action: selectedAction)
        self.delegate.onActionChange(action: selectedAction)
    }
    
    func loadPrice() {
        let symbol = wantAsset.symbol
        let currency = offerAsset.symbol
        O3APIClient(network: AppState.network).loadPricing(symbol: symbol, currency: currency) { result in
            switch result {
            case .failure(_):
                //TODO show error
                return
            case .success(let response):
                self.pairPrice = response
            }
        }
    }
}

class CreateOrderTableViewController: UITableViewController {
    
    var viewModel: CreateOrderViewModel!
    
    @IBOutlet var targetPriceLabel: UILabel!
    @IBOutlet var targetAssetLabel: UILabel!
    
    @IBOutlet var wantAssetLabel: UITextField!
    @IBOutlet var offerAssetLabel: UITextField!
    
    @IBOutlet var offerAmountTextField: UITextField!
    @IBOutlet var wantAmountTextField: UITextField!
    
    @IBOutlet var leftAssetImageView: UIImageView!
    @IBOutlet var rightAssetImageView: UIImageView!
    
    @IBOutlet var offerAssetSelector: UIImageView!
    @IBOutlet var wantAssetSelector: UIImageView!
    
    var inputToolbar = AssetInputToolbar()
    
    func setupNavbar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-x"), style: .plain, target: self, action: #selector(dismiss(_: )))
        //setup navbar title here
        self.title = viewModel.title
    }
    
    func setupInputToolbar() {
        inputToolbar.delegate = self
        if viewModel.selectedAction == CreateOrderAction.Sell {
            wantAmountTextField.inputAccessoryView = inputToolbar.loadNib()
            wantAmountTextField.inputAccessoryView?.theme_backgroundColor = O3Theme.backgroundColorPicker
            inputToolbar.asset = viewModel.wantAsset.toTransferableAsset()
        } else {
            offerAmountTextField.inputAccessoryView = inputToolbar.loadNib()
            offerAmountTextField.inputAccessoryView?.theme_backgroundColor = O3Theme.backgroundColorPicker
            inputToolbar.asset = viewModel.offerAsset.toTransferableAsset()
        }
    }
    
    func setupTextFieldDelegate() {
        wantAmountTextField.addTarget(self, action: #selector(wantAmountTextFieldValueChanged(_:)), for: .editingChanged)
        offerAmountTextField.addTarget(self, action: #selector(offerAmountTextFieldValueChanged(_:)), for: .editingChanged)
    }
    
    @objc func wantAmountTextFieldValueChanged(_ sender: UITextField) {
        if sender.text?.count == 0 {
            viewModel.wantAmount = 0
            return
        }
        let formatter = NumberFormatter()
        let number = formatter.number(from: (sender.text?.trim())!)
        viewModel.wantAmount = number?.doubleValue
    }
    
    @objc func offerAmountTextFieldValueChanged(_ sender: UITextField) {
        if sender.text?.count == 0 {
            viewModel.offerAmount = 0
            return
        }
        let formatter = NumberFormatter()
        let number = formatter.number(from: (sender.text?.trim())!)
        viewModel.offerAmount = number?.doubleValue
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        viewModel.loadPrice()
        viewModel.setupView()
        
        setupNavbar()
        setupInputToolbar()
        setupTextFieldDelegate()
    }
    
    @objc func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}


extension CreateOrderTableViewController: CreateOrderDelegate {
    
    func onWantAmountChange(value: Double, pairPrice: AssetPrice) {
        DispatchQueue.main.async {
            self.offerAmountTextField.text = Double(value * pairPrice.price).formattedStringWithoutSeparator(8, removeTrailing: true)
        }
    }
    
    func onOfferAmountChange(value: Double, pairPrice: AssetPrice) {
        DispatchQueue.main.async {
            self.wantAmountTextField.text = Double(value / pairPrice.price).formattedStringWithoutSeparator(8, removeTrailing: true)
        }
    }
    
    func onActionChange(action: CreateOrderAction) {
        DispatchQueue.main.async {
            if action == CreateOrderAction.Sell {
                self.offerAssetSelector.isHidden = false
            } else {
                self.wantAssetSelector.isHidden = false
            }
        }
    }
    
    func onpairPriceChange(price: AssetPrice) {
        DispatchQueue.main.async {
            self.targetPriceLabel.text = price.price.string(8, removeTrailing: true)
        }
    }
    
    func onWantAssetChange(asset: TradableAsset, action: CreateOrderAction) {
        DispatchQueue.main.async {
            if action == CreateOrderAction.Sell {
                self.leftAssetImageView.kf.setImage(with: asset.imageURL)
            } else {
                self.rightAssetImageView.kf.setImage(with: asset.imageURL)
            }
            
            self.wantAssetLabel.text = asset.symbol.uppercased()
        }
    }
    
    func onOfferAssetChange(asset: TradableAsset, action: CreateOrderAction) {
        DispatchQueue.main.async {
            if action == CreateOrderAction.Sell {
                self.rightAssetImageView.kf.setImage(with: asset.imageURL)
            } else {
                self.leftAssetImageView.kf.setImage(with: asset.imageURL)
            }
            
            self.offerAssetLabel.text = asset.symbol.uppercased()
            self.targetAssetLabel.text = asset.symbol.uppercased()
        }
    }
}

extension CreateOrderTableViewController: AssetInputToolbarDelegate{
    func percentAmountTapped(value: Double) {
        if viewModel.selectedAction == CreateOrderAction.Sell {
            viewModel.wantAmount = value
            wantAmountTextField.text = value.formattedStringWithoutSeparator(8, removeTrailing: true)
        } else {
            viewModel.offerAmount = value
            offerAmountTextField.text = value.formattedStringWithoutSeparator(8, removeTrailing: true)
        }
    }
    
    func maxAmountTapped(value: Double) {
        if viewModel.selectedAction == CreateOrderAction.Sell {
            viewModel.wantAmount = value
            wantAmountTextField.text = value.formattedStringWithoutSeparator(8, removeTrailing: true)
        } else {
            viewModel.offerAmount = value
            offerAmountTextField.text = value.formattedStringWithoutSeparator(8, removeTrailing: true)
        }
    }
}
