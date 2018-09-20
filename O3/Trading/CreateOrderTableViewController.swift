//
//  CreateOrderTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/19/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import PKHUD

enum CreateOrderAction: Int {
    case Buy = 0
    case Sell
}

protocol CreateOrderDelegate {
    func beginLoading()
    func endLoading()
    func onWantAssetChange(asset: TradableAsset, action: CreateOrderAction)
    func onOfferAssetChange(asset: TradableAsset, action: CreateOrderAction)
    func onActionChange(action: CreateOrderAction)
    
    func onWantAmountChange(value: Double, pairPrice: AssetPrice, totalInFiat: Fiat)
    func onOfferAmountChange(value: Double, pairPrice: AssetPrice, totalInFiat: Fiat)
    
    func didReceivePrice(pairPrice: AssetPrice, fiatPrice: AssetPrice)
}


extension TradableAsset {
    var imageURL: URL {
        return URL(string: String(format: "https://cdn.o3.network/img/neo/%@.png", self.symbol.uppercased()))!
    }
}
class CreateOrderViewModel {
    
    var delegate: CreateOrderDelegate?
    var selectedAction: CreateOrderAction!
    
    var pairPrice: AssetPrice!
    var fiatPairPrice: AssetPrice! // e.g. neo|gas/usd
    
    var offerAsset: TradableAsset!
    var wantAsset: TradableAsset!
    
    var tradingAccount: TradingAccount?
    
    var wantAmount: Double? {
        didSet {
            if wantAmount == nil {
                return
            }
            let total = Fiat(amount: Float(wantAmount! * pairPrice.price * fiatPairPrice.price))
            self.delegate?.onWantAmountChange(value: wantAmount!, pairPrice: pairPrice, totalInFiat: total)
        }
    }
    
    var offerAmount: Double? {
        didSet {
            if offerAmount == nil {
                return
            }
            let total = Fiat(amount: Float((offerAmount! / pairPrice.price) * pairPrice.price * fiatPairPrice.price))
            self.delegate?.onOfferAmountChange(value: offerAmount!, pairPrice: pairPrice, totalInFiat: total)
        }
    }
    
    var title: String {
        return String(format: "%@ %@", selectedAction == CreateOrderAction.Sell ? "SELL" : "BUY"
            , wantAsset.symbol)
    }
    
    func setupView() {
        self.delegate?.onOfferAssetChange(asset: offerAsset, action: selectedAction)
        self.delegate?.onWantAssetChange(asset: wantAsset, action: selectedAction)
        self.delegate?.onActionChange(action: selectedAction)
    }
    
    func loadPrice(completion: @escaping () -> Void) {
        self.delegate?.beginLoading()
        let symbol = wantAsset.symbol
        let currency = offerAsset.symbol
        O3APIClient(network: AppState.network).loadPricing(symbol: symbol, currency: currency) { result in
            switch result {
            case .failure(_):
                //TODO show error
                self.delegate?.endLoading()
                return
            case .success(let pairResponse):
                //we actually need to get NEO|GAS/USD pair and calculate from the pair price
                //eg. 1 GAS = 5.07182905 USD. 1 SWTH = 0.00138625 GAS so 1 SWTH = 5.07182905 * 0.00138625 = 0.00703082 USD
                O3APIClient(network: AppState.network).loadPricing(symbol: self.offerAsset.symbol, currency: UserDefaultsManager.referenceFiatCurrency.rawValue) { result in
                    switch result {
                    case .failure(_):
                        //TODO show error
                        self.delegate?.endLoading()
                        return
                    case .success(let fiatResponse):
                        self.delegate?.endLoading()
                        self.pairPrice = pairResponse
                        self.fiatPairPrice = fiatResponse
                        self.delegate?.didReceivePrice(pairPrice: self.pairPrice, fiatPrice:  self.fiatPairPrice)
                        completion()
                    }
                }
            }
        }
    }
    
    func selectOfferAsset(asset: TradableAsset) {
        self.offerAsset = asset
        self.loadPrice(){
            self.delegate?.onOfferAssetChange(asset: asset, action: self.selectedAction)
        }
    }
    func selectWantAsset(asset: TradableAsset) {
        self.wantAsset = asset
        self.loadPrice(){
            self.delegate?.onWantAssetChange(asset: asset, action: self.selectedAction)
        }
    }
    
}

class CreateOrderTableViewController: UITableViewController {
    
    var viewModel: CreateOrderViewModel!
    
    @IBOutlet var targetPriceLabel: UILabel!
    @IBOutlet var targetFiatPriceLabel: UILabel!
    @IBOutlet var targetAssetLabel: UILabel!
    
    @IBOutlet var wantAssetLabel: UITextField!
    @IBOutlet var offerAssetLabel: UITextField!
    
    
    @IBOutlet var wantAmountTextField: UITextField!
    @IBOutlet var offerAmountTextField: UITextField!
    @IBOutlet var offerTotalFiatPriceLabel: UILabel!
    
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
            
        } else {
            offerAmountTextField.inputAccessoryView = inputToolbar.loadNib()
            offerAmountTextField.inputAccessoryView?.theme_backgroundColor = O3Theme.backgroundColorPicker
            
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
        viewModel.loadPrice(){}
        viewModel.setupView()
        
        setupNavbar()
        setupInputToolbar()
        setupTextFieldDelegate()
    }
    
    deinit {
        viewModel.delegate = nil
    }
    
    @objc func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    
    func showAssetSelector(list: [TradableAsset], target: TradableAsset) {
        guard let nav = UIStoryboard(name: "Trading", bundle: nil).instantiateViewController(withIdentifier: "TradableAssetSelectorTableViewControllerNav") as? UINavigationController else {
            return
        }
        guard let modal = nav.viewControllers.first as? TradableAssetSelectorTableViewController else {
            return
        }
        
        modal.assets = list
        modal.delegate = self
        modal.data = target
        self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: nav)
        nav.modalPresentationStyle = .custom
        nav.transitioningDelegate = self.halfModalTransitioningDelegate
        self.present(nav, animated: true, completion: nil)
    }
    
    
    //MARK: - actions for assets
    
    @IBAction func selectOfferAssetTapped(_ sender: Any) {
        //reset
        viewModel.wantAmount = 0
        viewModel.offerAmount = 0
        
        if viewModel.selectedAction == CreateOrderAction.Sell {
            // when sell and user tapped the right side, we then offer base pairs to sell WANT asset for
            showAssetSelector(list: viewModel.tradingAccount!.switcheo.basePairs, target: viewModel.offerAsset)
        } else if viewModel.selectedAction == CreateOrderAction.Buy {
            //when buy and user tapped the right side, we then offer supported tokens on Switcheo to buy
            viewModel.tradingAccount!.switcheo.loadSupportedTokens { list in
                DispatchQueue.main.async {
                    self.showAssetSelector(list: list, target: self.viewModel.wantAsset)
                }
            }
        }
    }

    @IBAction func selectWantAssetTapped(_ sender: Any) {
        //reset
        viewModel.wantAmount = 0
        viewModel.offerAmount = 0
        
        if viewModel.selectedAction == CreateOrderAction.Buy {
            // when buy and user tapped the left side, we then offer base pairs to buy WANT asset with
            showAssetSelector(list: viewModel.tradingAccount!.switcheo.basePairs, target: viewModel.offerAsset)
        } else if viewModel.selectedAction == CreateOrderAction.Sell {
            //when sell and user tapped the left side, we then offer available tokens in trading account to sell
            showAssetSelector(list: viewModel.tradingAccount!.switcheo.confirmed, target: viewModel.wantAsset)
        }
    }
}

extension CreateOrderTableViewController: CreateOrderDelegate {
    func beginLoading() {
        DispatchQueue.main.async {
            HUD.show(.progress)
        }
    }
    
    func endLoading() {
        DispatchQueue.main.async {
            HUD.hide()
        }
    }
    
    func didReceivePrice(pairPrice: AssetPrice, fiatPrice: AssetPrice) {
        DispatchQueue.main.async {
            HUD.hide()
            self.targetFiatPriceLabel.text = Fiat(amount: Float(fiatPrice.price * pairPrice.price)).formattedStringWithDecimal(decimals: 8)
            self.targetPriceLabel.text = pairPrice.price.string(8, removeTrailing: true)
        }
    }
    
    func onWantAmountChange(value: Double, pairPrice: AssetPrice, totalInFiat: Fiat) {
        DispatchQueue.main.async {
            self.offerAmountTextField.text = value == 0 ? "" : Double(value * pairPrice.price).formattedStringWithoutSeparator(8, removeTrailing: true)
            self.offerTotalFiatPriceLabel.text = totalInFiat.formattedStringWithDecimal(decimals: 8)
        }
    }
    
    func onOfferAmountChange(value: Double, pairPrice: AssetPrice, totalInFiat: Fiat) {
        DispatchQueue.main.async {
            self.wantAmountTextField.text = value == 0 ? "" : Double(value / pairPrice.price).formattedStringWithoutSeparator(8, removeTrailing: true)
            self.offerTotalFiatPriceLabel.text = totalInFiat.formattedStringWithDecimal(decimals: 8)
        }
    }
    
    func onActionChange(action: CreateOrderAction) {
        DispatchQueue.main.async {
            
        }
    }
    
    func onWantAssetChange(asset: TradableAsset, action: CreateOrderAction) {
        DispatchQueue.main.async {
            if action == CreateOrderAction.Sell {
                self.leftAssetImageView.kf.setImage(with: asset.imageURL)
                self.inputToolbar.asset = asset.toTransferableAsset()
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
                self.inputToolbar.asset = asset.toTransferableAsset()
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

extension CreateOrderTableViewController: TradableAssetSelectorTableViewControllerDelegate {
    func assetSelected(selected: TradableAsset, data: Any?) {
        if viewModel.selectedAction == CreateOrderAction.Sell {
            let target = data as! TradableAsset
            if target.symbol == viewModel.offerAsset.symbol {
                viewModel.selectOfferAsset(asset: selected)
            } else {
                viewModel.selectWantAsset(asset: selected)
            }

        } else if viewModel.selectedAction == CreateOrderAction.Buy {
            let target = data as! TradableAsset
            if target.symbol == viewModel.offerAsset.symbol {
                viewModel.selectOfferAsset(asset: selected)
            } else {
                viewModel.selectWantAsset(asset: selected)
            }
        }
    }
}
