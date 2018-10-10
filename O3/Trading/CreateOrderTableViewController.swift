//
//  CreateOrderTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/19/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import PKHUD
import DeckTransition

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
    
    func onPriceReceived(pairPrice: AssetPrice, fiatPrice: AssetPrice)
    
    func onStateChange(readyToSubmit: Bool)
    
    func onBeginSubmitOrder()
    func onErrorSubmitOrder(message: String)
    func onSuccessSubmitOrder(filledPercent: Double)
    
    func didLoadOpenOrders(numberOfOpenOrder: Int)
    
    func onPairPriceChanged(pairPrice: AssetPrice)
    
    func didLoadOffers(offers: [Offer])
}

extension TradableAsset {
    var imageURL: URL {
        return URL(string: String(format: "https://cdn.o3.network/img/neo/%@.png", self.symbol.uppercased()))!
    }
}

class CreateOrderViewModel {
    
    var delegate: CreateOrderDelegate?
    var selectedAction: CreateOrderAction!
    var pairPrice: AssetPrice! {
        didSet {
            self.delegate?.onStateChange(readyToSubmit: self.readyToSubmit)
        }
    }
    
    var firstFetchedPairPrice: AssetPrice!
    var topOrderPrice: Double!
    
    var fiatPairPrice: AssetPrice! // e.g. neo|gas/usd
    var offerAsset: TradableAsset!
    var wantAsset: TradableAsset!
    var tradingAccount: TradingAccount?
    var openOrders: TradingOrders?
    
    var readyToSubmit: Bool {
        if self.wantAmount == nil {
            return false
        }
        if self.offerAmount == nil {
            return false
        }
        
        if self.selectedAction == .Buy {
            if offerAsset.amountInDouble().isLess(than: self.offerAmount!)  {
                return false
            }
        }
        
        if self.selectedAction == .Sell {
            if wantAsset.amountInDouble().isLess(than: self.wantAmount!)  {
                return false
            }
        }
        
        
        return self.wantAmount! > 0 && self.offerAmount! > 0 //will have to check minimum order of switcheo here
    }
    
    func setWantAmount(value: Double) {
        wantAmount = value
        offerAmount = Double(value * pairPrice.price)
    }
    
    func setOfferAmount(value: Double) {
        offerAmount = value
        wantAmount = Double(value / pairPrice.price)
    }
    
    var wantAmount: Double? = 0 {
        didSet {
            if wantAmount == nil {
                return
            }
            if wantAmount!.isNaN {
                wantAmount = 0
            }
            let total = Fiat(amount: Float(wantAmount! * pairPrice.price * fiatPairPrice.price))
            self.delegate?.onWantAmountChange(value: wantAmount!, pairPrice: pairPrice, totalInFiat: total)
            self.delegate?.onStateChange(readyToSubmit: self.readyToSubmit)
        }
    }
    
    var offerAmount: Double? = 0 {
        didSet {
            if offerAmount == nil {
                return
            }
            if offerAmount!.isNaN {
                offerAmount = 0
            }
            
            let total = Fiat(amount: Float((offerAmount! / pairPrice.price) * pairPrice.price * fiatPairPrice.price))
            self.delegate?.onOfferAmountChange(value: offerAmount!, pairPrice: pairPrice, totalInFiat: total)
            self.delegate?.onStateChange(readyToSubmit: self.readyToSubmit)
        }
    }
    
    var title: String {
        return String(format: "Trade %@ for %@", selectedAction == CreateOrderAction.Buy ? offerAsset.symbol : wantAsset.symbol, selectedAction == CreateOrderAction.Buy ? wantAsset.symbol : offerAsset.symbol)
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
                O3APIClient(network: AppState.network, useCache: true).loadPricing(symbol: self.offerAsset.symbol, currency: UserDefaultsManager.referenceFiatCurrency.rawValue) { result in
                    switch result {
                    case .failure(_):
                        //TODO show error
                        self.delegate?.endLoading()
                        return
                    case .success(let fiatResponse):
                        self.delegate?.endLoading()
                        self.pairPrice = pairResponse
                        self.firstFetchedPairPrice = pairResponse //keep the original
                        self.fiatPairPrice = fiatResponse
                        self.delegate?.onPriceReceived(pairPrice: self.pairPrice, fiatPrice: self.fiatPairPrice)
                        completion()
                    }
                }
            }
        }
    }
    
    func selectOfferAsset(asset: TradableAsset) {
        self.offerAsset = asset
        DispatchQueue.global(qos: .background).async {
            self.loadOpenOrders()
        }
        DispatchQueue.global(qos: .background).async {
            self.loadOffers()
        }
        DispatchQueue.global(qos: .background).async {
            self.loadPrice(){
                self.delegate?.onOfferAssetChange(asset: asset, action: self.selectedAction)
            }
        }
    }
    
    func selectWantAsset(asset: TradableAsset) {
        self.wantAsset = asset
        DispatchQueue.global(qos: .background).async {
            self.loadOpenOrders()
        }
        DispatchQueue.global(qos: .background).async {
            self.loadOffers()
        }
        DispatchQueue.global(qos: .background).async {
            self.loadPrice(){
                self.delegate?.onWantAssetChange(asset: asset, action: self.selectedAction)
            }
        }
    }
    
    func loadOpenOrders() {
        let pair = String(format:"%@_%@", wantAsset.symbol.uppercased(), offerAsset.symbol.uppercased())
        O3APIClient(network: AppState.network).loadSwitcheoOrders(address: Authenticated.account!.address, status: SwitcheoOrderStatus.open, pair: pair) { result in
            switch result{
            case .failure(let error):
                print(error)
                self.delegate?.didLoadOpenOrders(numberOfOpenOrder: 0)
            case .success(let response):
                self.openOrders = response
                self.delegate?.didLoadOpenOrders(numberOfOpenOrder: response.switcheo.count)
            }
        }
    }
    
    func loadOffers() {
        let pair = String(format:"%@_%@", wantAsset.symbol.uppercased(), offerAsset.symbol.uppercased())
        let blockchain = "neo"
        let sw = Switcheo(net: AppState.network == Network.main ? Switcheo.Net.Main : Switcheo.Net.Test)
        let switcheoHash =  AppState.network == Network.main ? Switcheo.V2.Main : Switcheo.V2.Test
        let request = RequestOffer(blockchain: blockchain, pair: pair, contractHash: switcheoHash.rawValue)
        sw?.offers(request: request!, completion: { result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let response):
                #if DEBUG
                print(response)
                #endif
                self.delegate?.didLoadOffers(offers: response)
            }
        })
    }
    
    func submitOrder() {
        self.delegate?.onBeginSubmitOrder()
        let blockchain = "neo"
        
        var pair = String(format:"%@_%@", wantAsset.symbol.uppercased(), offerAsset.symbol.uppercased())
        //TODO fix this
        //incase the want asset is NEO meaning selling NEO for something
        if wantAsset.symbol.uppercased() == "NEO" {
            pair = String(format:"%@_%@", offerAsset.symbol.uppercased(), wantAsset.symbol.uppercased())
        }
        
        let side = selectedAction == CreateOrderAction.Buy ? "buy" : "sell"
        let orderType = "limit"
        let switcheoAccount = SwitcheoAccount(network: AppState.network == Network.main ? Switcheo.Net.Main : Switcheo.Net.Test, account: Authenticated.account!)
        let switcheoHash =  AppState.network == Network.main ? Switcheo.V2.Main : Switcheo.V2.Test
        
        let want = selectedAction == CreateOrderAction.Buy ? wantAmount! : offerAmount!
        let order = RequestOrder(pair: pair, blockchain: blockchain, side: side, price: Float64(pairPrice.price), wantAmount: Float64(want), useNativeTokens: false, orderType: orderType, contractHash: switcheoHash.rawValue, otcAddress: "")
        
        switcheoAccount.order(requestOrder: order!) { result in
            switch result {
            case .failure(let error):
                self.delegate?.onErrorSubmitOrder(message: error)
            case .success(let response):
                var filledPercent = Double(0.0)
                let offerAmount = response["offer_amount"] as! String
                let wantAmount = response["want_amount"] as! String
                let orderID = response["id"] as! String
                let createdAt = response["created_at"] as! String
                let side = response["side"] as! String
                let priceSelection = self.pairPrice.price.isEqual(to: self.firstFetchedPairPrice.price) ? "default" : "manual"
                tradingEvent.shared.placedOrder(orderID: orderID, datetime: createdAt, side: side, pair: pair, baseCurrency: self.offerAsset.symbol, quantity: want, priceSelection: priceSelection)
                
                if let fills = response["fills"] as? Array<Switcheo.JSONDictionary> {
                    let formatter = NumberFormatter()
                    var filledAmount = Double(0)
                    
                    if side == "buy" {
                        filledAmount = fills.reduce(0.0, {(result: Double, item: Switcheo.JSONDictionary) -> Double in
                            if let wantAmount = item["want_amount"] as? String {
                                return result + (formatter.number(from: wantAmount)?.doubleValue)!
                            }
                            return result
                        })
                    } else {
                        filledAmount = fills.reduce(0.0, {(result: Double, item: Switcheo.JSONDictionary) -> Double in
                            if let fillAmount = item["fill_amount"] as? String {
                                return result + (formatter.number(from: fillAmount)?.doubleValue)!
                            }
                            return result
                        })
                    }
                    
                   
                    let originalWantAmount = side == "sell" ? (formatter.number(from: offerAmount)?.doubleValue)! : (formatter.number(from: wantAmount)?.doubleValue)!
                    filledPercent = (filledAmount / originalWantAmount)  * Double(100.0)
                    print(fills)
                    print(filledAmount)
                    print(filledPercent)
                }
                
                self.delegate?.onSuccessSubmitOrder(filledPercent: filledPercent)
            }
        }
    }
    
    func setPairPrice(price: Double) {
        self.pairPrice.updatePrice(value: price)
        
        if self.pairPrice.price.isEqual(to: 0.0) {
            self.offerAmount = 0
            return
        }
        
        if self.wantAmount?.isNaN == false && self.wantAmount != nil && !self.wantAmount!.isLessThanOrEqualTo(0.0) {
            let newOfferAmount = (self.wantAmount! * price)
            self.offerAmount = newOfferAmount
        }
        self.delegate?.onPairPriceChanged(pairPrice: pairPrice)
    }
    
    var priceChangeDescription: String {
        if firstFetchedPairPrice.price.isEqual(to: pairPrice.price) {
            
            return String(format: "Updated %@", Date(timeIntervalSince1970: TimeInterval(pairPrice.lastUpdate)).timeAgo(numericDates: true))
        }
        let change: Double = Double(100.0) - Double((firstFetchedPairPrice.price / pairPrice.price) * 100.0 )
        return String(format: "%@%@ %@ median", change.string(2, removeTrailing: true), "%", change < 0 ? "below" : "above")
    }
    
    var priceTitle: String {
        if firstFetchedPairPrice.price.isEqual(to: pairPrice.price) {
            return "PRICE".uppercased()
        }
        return "CUSTOM PRICE".uppercased()
    }
    
}

class CreateOrderTableViewController: UITableViewController {
    
    var viewModel: CreateOrderViewModel!
    
    @IBOutlet var targetPriceTextField: UITextField!
    @IBOutlet var targetPriceTitle: UILabel!
    @IBOutlet var targetPriceSubtitle: UILabel!
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
    
    @IBOutlet var selectWantAssetButton: UIButton!
    @IBOutlet var selectOfferAssetButton: UIButton!
    @IBOutlet var reviewAndSubmitSubmitButton: UIButton!
    
    @IBOutlet var labelList: [UILabel]?
    @IBOutlet var textFieldList: [UITextField]?
    
    var inputToolbar = AssetInputToolbar(frame: CGRect.zero)
    var priceInputToolbar = PriceInputToolbar(frame: CGRect.zero)
    var priceInputToggle = PriceInputToggleToolbar(frame: CGRect.zero)
    
    func setupNavbar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-x"), style: .plain, target: self, action: #selector(dismiss(_: )))
        navigationItem.rightBarButtonItem = BadgeBarButtonItem(image: #imageLiteral(resourceName: "receipt"), style: .plain, target: self, action: #selector(openOrderTapped(_:)))
        
        //setup navbar title here
        self.title = viewModel.title
    }
    
    func setupTheme() {
        self.view.theme_backgroundColor = O3Theme.backgroundColorPicker
        self.tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        self.tableView.theme_separatorColor = O3Theme.tableSeparatorColorPicker
        
        for t in labelList! {
            t.theme_textColor = O3Theme.titleColorPicker
        }
        
        for t in textFieldList! {
            t.theme_textColor = O3Theme.titleColorPicker
            t.theme_keyboardAppearance = O3Theme.keyboardPicker
        }
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
    
    func setupPriceInputToolbar() {
        priceInputToolbar.delegate = self
        priceInputToggle.delegate = self
        targetPriceTextField.inputView = priceInputToolbar.loadNib()
        targetPriceTextField.inputAccessoryView = priceInputToggle.loadNib()
    }
    
    func setupTextFieldDelegate() {
        wantAmountTextField.addTarget(self, action: #selector(wantAmountTextFieldValueChanged(_:)), for: .editingChanged)
        offerAmountTextField.addTarget(self, action: #selector(offerAmountTextFieldValueChanged(_:)), for: .editingChanged)
        targetPriceTextField.addTarget(self, action: #selector(priceBeginEditing(_:)), for: .editingDidBegin)
        targetPriceTextField.addTarget(self, action: #selector(priceTextFieldValueChanged(_:)), for: .editingChanged)
    }
    
    @objc func wantAmountTextFieldValueChanged(_ sender: UITextField) {
        if sender.text?.count == 0 {
            viewModel.wantAmount = 0
            return
        }
        if sender.text!.hasSuffix(".") || sender.text!.hasSuffix(",") {
            return
        }
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8
        formatter.numberStyle = .decimal
        let number = formatter.number(from: (sender.text?.trim())!)
        if number == nil {
            return
        }
        viewModel.setWantAmount(value: (number?.doubleValue)!)
    }
    
    @objc func offerAmountTextFieldValueChanged(_ sender: UITextField) {
        if sender.text?.count == 0 {
            viewModel.offerAmount = 0
            return
        }
        if sender.text!.hasSuffix(".") || sender.text!.hasSuffix(",") {
            return
        }
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8
        formatter.numberStyle = .decimal
        let number = formatter.number(from: (sender.text?.trim())!)
        if number == nil {
            return
        }
        viewModel.setOfferAmount(value: (number?.doubleValue)!)
    }
    
    @objc func priceTextFieldValueChanged(_ sender: UITextField) {
        if sender.text?.count == 0 {
            self.viewModel.setPairPrice(price: 0)
            return
        }
        if sender.text!.hasSuffix(".") || sender.text!.hasSuffix(",") {
            return
        }
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8
        formatter.numberStyle = .decimal
        let number = formatter.number(from: (sender.text?.trim())!)
        if number == nil {
            return
        }
        self.viewModel.setPairPrice(price: number!.doubleValue)
        priceInputToolbar.value = viewModel.pairPrice.price
        self.targetPriceTitle.text = self.viewModel.priceTitle
        self.targetPriceSubtitle.text = self.viewModel.priceChangeDescription
    }
    
    @objc func priceBeginEditing(_ sender: UITextField) {
        priceInputToolbar.value = viewModel.pairPrice.price
    }
    
    @objc private func loadOpenOrders() {
        viewModel.loadOpenOrders()
    }
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(loadOpenOrders), name: NSNotification.Name(rawValue: "needsReloadOpenOrders"), object: nil)
    }
    
    deinit {
        viewModel.delegate = nil
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "needsReloadOpenOrders"), object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTheme()
        setupNavbar()
        setupInputToolbar()
        setupPriceInputToolbar()
        setupTextFieldDelegate()
        
        viewModel.delegate = self
        viewModel.setupView()
        
        DispatchQueue.global(qos: .background).async {
            self.viewModel.loadPrice(){}
            self.viewModel.loadOffers()
        }
        
        DispatchQueue.global(qos: .background).async {
            self.viewModel.loadOpenOrders()
        }
        
        if viewModel.selectedAction == CreateOrderAction.Sell {
            selectWantAssetButton.isEnabled = false
            wantAssetSelector.isHidden = true
        }
    }
    
    func viewOpenOrders() {
        guard let nav = UIStoryboard(name: "Trading", bundle: nil).instantiateViewController(withIdentifier: "OrdersTabsViewControllerNav") as? UINavigationController else {
            return
        }
        let transitionDelegate = DeckTransitioningDelegate()
        nav.transitioningDelegate = transitionDelegate
        nav.modalPresentationStyle = .custom
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc func openOrderTapped(_ sender: Any) {
        viewOpenOrders()
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
        modal.excludeSymbols = [self.viewModel.offerAsset.symbol.uppercased(), self.viewModel.wantAsset.symbol.uppercased()]
        self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: nav)
        nav.modalPresentationStyle = .custom
        nav.transitioningDelegate = self.halfModalTransitioningDelegate
        self.present(nav, animated: true, completion: nil)
    }
    
    //MARK: - Review and submit
    @IBAction func submitTapped(_ sender: Any) {
        let title = "Confirm your order"
        let action = viewModel.selectedAction == CreateOrderAction.Buy ? "buy" : "sell"
        let message = String(format: "You are about to place a %@ order of %@ %@ at a price of %@ %@ per %@.", action, viewModel.wantAmount!.string(8, removeTrailing: true), viewModel.wantAsset.symbol.uppercased(), viewModel.pairPrice.price.string(8, removeTrailing: true), viewModel.offerAsset.symbol.uppercased(),viewModel.wantAsset.symbol.uppercased())
        
        OzoneAlert.confirmDialog(title, message: message, cancelTitle: "Cancel", confirmTitle: "Confirm", didCancel: {
            
        }) {
            self.viewModel.submitOrder()
        }
    }
    
    //MARK: - actions for assets
    
    @IBAction func selectOfferAssetTapped(_ sender: Any) {
        //reset
        targetPriceTextField.resignFirstResponder()
        viewModel.wantAmount = 0
        viewModel.offerAmount = 0
        
        if viewModel.selectedAction == CreateOrderAction.Sell {
            
            //if wantAsset is one of the base pairs then we offers everything
            
            let oneOftheBasePairs = viewModel.tradingAccount!.switcheo.basePairs.contains { a -> Bool in
                return a.symbol.uppercased() == viewModel.wantAsset.symbol.uppercased()
            }
            if oneOftheBasePairs == true {
                viewModel.tradingAccount!.switcheo.loadSupportedTokens { list in
                    DispatchQueue.main.async {
                        self.showAssetSelector(list: list, target: self.viewModel.offerAsset)
                    }
                }
                return
            }
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
        targetPriceTextField.resignFirstResponder()
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
    
    func didLoadOffers(offers: [Offer]) {
        DispatchQueue.main.async {
            //if want asset is NEO/GAS meaning it's a sell order
            //want_amount / offer_amount = price per NEO/GAS
            
            //if want asset is SWTH meaning it's a buy order
            // offer_amount / want_amount = price per NEO/GAS
            if self.viewModel.selectedAction == CreateOrderAction.Buy {
                let sellOrders = offers.filter { o -> Bool in
                    return o.offerAsset.uppercased() == self.viewModel.wantAsset.symbol.uppercased()
                }
                if sellOrders.count == 0 {
                    self.viewModel.topOrderPrice = 0
                    self.priceInputToolbar.topOrderPrice = 0
                    return
                }
                let top = sellOrders.first!
                let price = Double(Double(top.wantAmount) / Double(top.offerAmount))
                self.viewModel.topOrderPrice = price
                self.priceInputToolbar.topOrderPrice = price
            } else {
                let buyOrders = offers.filter { o -> Bool in
                    return o.wantAsset.uppercased() == self.viewModel.wantAsset.symbol.uppercased()
                }
                if buyOrders.count == 0 {
                    self.viewModel.topOrderPrice = 0
                    self.priceInputToolbar.topOrderPrice = 0
                    return
                }
                let top = buyOrders.first!
                let price = Double(Double(top.offerAmount) / Double(top.wantAmount))
                self.viewModel.topOrderPrice = price
                self.priceInputToolbar.topOrderPrice = price
            }
        }
    }
    
    
    func onPairPriceChanged(pairPrice: AssetPrice) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
            UIView.animate(withDuration: 0.2, animations: {
                self.targetPriceTitle.text = self.viewModel.priceTitle
                self.targetPriceSubtitle.text = self.viewModel.priceChangeDescription
            })
            if pairPrice.price == 0 {
                self.offerAmountTextField.text = ""
                self.offerTotalFiatPriceLabel.text = ""
                return
            }
            self.targetFiatPriceLabel.text = Fiat(amount: Float(self.viewModel.fiatPairPrice.price * pairPrice.price)).formattedStringWithDecimal(decimals: 8)
            self.targetPriceTextField.text = pairPrice.price.formattedStringWithoutSeparator(8, removeTrailing: true)
        }
    }
    
    func didLoadOpenOrders(numberOfOpenOrder: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
            if let badgeButton = self.navigationItem.rightBarButtonItem! as? BadgeBarButtonItem {
                self.navigationItem.rightBarButtonItem?.isEnabled = numberOfOpenOrder > 0
                badgeButton.badgeNumber = numberOfOpenOrder
            }
        }
    }
    
    func onBeginSubmitOrder() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
            self.reviewAndSubmitSubmitButton.isEnabled = false
            HUD.show(.progress)
        }
    }
    
    func onErrorSubmitOrder(message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
            HUD.hide()
            HUD.flash(HUDContentType.labeledError(title: "Unable to submit order", subtitle: message), delay: 3)
        }
    }
    
    func onSuccessSubmitOrder(filledPercent: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
            HUD.hide()
            //alert
            var title = "Order created!"
            var message = "You can check the progress of the order in the order screen."
            if filledPercent > 0 {
                let filledView = SAConfettiView(frame: self.view.bounds)
                filledView.colors = [Theme.light.primaryColor, Theme.light.accentColor, Theme.light.positiveGainColor, Theme.light.negativeLossColor]
                filledView.type = SAConfettiView.ConfettiType.image(UIImage(named: "confetti")!)
                self.view.addSubview(filledView)
                filledView.startConfetti()
                
                title = String(format: "Your order got filled! 🎉")
                message = String(format: "%@%@ of your order instantly filled. Check the status of remaining order in an order screen.", filledPercent.string(2, removeTrailing: true), "%")
            }
            
            if filledPercent.isEqual(to: 100.0) {
                title = String(format: "Yeahhhhh 🎉")
                message = String(format: "Your order has been instantly filled and deposited into your trading account!")
            }
            
            OzoneAlert.confirmDialog(title, message: message, cancelTitle: "Close", confirmTitle: "View my orders", didCancel: {
                NotificationCenter.default.post(name: NSNotification.Name("needsReloadTradingBalances"), object: nil)
                self.dismiss(animated: true, completion: {})
            }, didConfirm: {
                NotificationCenter.default.post(name: NSNotification.Name("needsReloadTradingBalances"), object: nil)
                self.dismiss(animated: true, completion: {
                    NotificationCenter.default.post(name: NSNotification.Name("viewTradingOrders"), object: nil)
                })
            })
        }
    }
    
    func onStateChange(readyToSubmit: Bool) {
        DispatchQueue.main.async {
            self.title = self.viewModel.title
            self.reviewAndSubmitSubmitButton.isEnabled = readyToSubmit
        }
    }
    
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
    
    func onPriceReceived(pairPrice: AssetPrice, fiatPrice: AssetPrice) {
        DispatchQueue.main.async {
            HUD.hide()
            self.targetPriceSubtitle.text = self.viewModel.priceChangeDescription
            //assign default value to the toolbar
            self.targetFiatPriceLabel.text = Fiat(amount: Float(fiatPrice.price * pairPrice.price)).formattedStringWithDecimal(decimals: 8)
            self.targetPriceTextField.text = pairPrice.price.formattedStringWithoutSeparator(8, removeTrailing: true)
            self.priceInputToolbar.setNewValue(v: pairPrice.price)
            
            if self.viewModel.selectedAction == CreateOrderAction.Sell {
                self.wantAmountTextField.becomeFirstResponder()
            } else {
                self.offerAmountTextField.becomeFirstResponder()
            }
        }
    }
    
    func onWantAmountChange(value: Double, pairPrice: AssetPrice, totalInFiat: Fiat) {
        DispatchQueue.main.async {
            if value.isNaN || value.isZero {
                self.wantAmountTextField.text = ""
                return
            }
            self.wantAmountTextField.text = value.formattedStringWithoutSeparator(8, removeTrailing: true)
            
            self.offerTotalFiatPriceLabel.text = totalInFiat.formattedStringWithDecimal(decimals: 8)
        }
    }
    
    func onOfferAmountChange(value: Double, pairPrice: AssetPrice, totalInFiat: Fiat) {
        DispatchQueue.main.async {
            if value.isNaN || value.isZero {
                self.offerAmountTextField.text = ""
                return
            }
            self.offerAmountTextField.text = value.formattedStringWithoutSeparator(8, removeTrailing: true)
            
            self.offerTotalFiatPriceLabel.text = totalInFiat.formattedStringWithDecimal(decimals: 8)
        }
    }
    
    func onActionChange(action: CreateOrderAction) {
        DispatchQueue.main.async {
            
        }
    }
    
    func onWantAssetChange(asset: TradableAsset, action: CreateOrderAction) {
        DispatchQueue.main.async {
            self.title = self.viewModel.title
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
            viewModel.setWantAmount(value: value)
            wantAmountTextField.text = value.formattedStringWithoutSeparator(8, removeTrailing: true)
        } else {
            viewModel.setOfferAmount(value: value)
            offerAmountTextField.text = value.formattedStringWithoutSeparator(8, removeTrailing: true)
        }
    }
    
    func maxAmountTapped(value: Double) {
        if viewModel.selectedAction == CreateOrderAction.Sell {
            viewModel.setWantAmount(value: value)
            wantAmountTextField.text = value.formattedStringWithoutSeparator(8, removeTrailing: true)
        } else {
            viewModel.setOfferAmount(value: value)
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

extension CreateOrderTableViewController: PriceInputToolbarDelegate {
    func topPriceSelected(value: Double) {
        self.viewModel.setPairPrice(price: value)
    }
    
    func stepper(value: Double, percent: Double) {
        self.viewModel.setPairPrice(price: value)
    }
    
    func originalPriceSelected(value: Double) {
        self.viewModel.setPairPrice(price: value)
    }
    func doneTapped() {
        self.targetPriceTextField.resignFirstResponder()
    }
}
extension CreateOrderTableViewController: PriceInputToggleToolbarDelegate {
    func toggleInput(manually: Bool) {
        DispatchQueue.main.async {
            if manually == true {
                self.targetPriceTextField.inputView = nil
                self.targetPriceTextField.reloadInputViews()
            } else {
                self.priceInputToolbar = PriceInputToolbar(frame: CGRect.zero)
                self.priceInputToolbar.delegate = self
                self.targetPriceTextField.inputView = self.priceInputToolbar.loadNib()
                self.priceInputToolbar.value = self.viewModel.firstFetchedPairPrice.price
                self.priceInputToolbar.topOrderPrice = self.viewModel.topOrderPrice
                self.targetPriceTextField.reloadInputViews()
            }
        }
    }
}
