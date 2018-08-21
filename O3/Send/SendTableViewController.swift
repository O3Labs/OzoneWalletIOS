//
//  SendViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 9/11/17.
//  Copyright © 2017 drei. All rights reserved.
//

import Foundation
import UIKit
import KeychainAccess
import SwiftTheme
import Crashlytics
import Neoutils

class SendTableViewController: UITableViewController, AddressSelectDelegate, QRScanDelegate {
    // swiftlint:disable weak_delegate
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    // swiftlint:enable weak_delegate
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var toAddressField: UITextField!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var assetLabel: UILabel!
    @IBOutlet weak var selectedAssetLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var pasteButton: UIButton!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var addressButton: UIButton!
    
    @IBOutlet weak var verifiedAddressDisplayNameLabel: UILabel!
    @IBOutlet weak var verifiedAddressBadge: UIImageView!
    
    @IBOutlet weak var recipientCell: UITableViewCell!
    @IBOutlet weak var sendAmountCell: UITableViewCell!
    @IBOutlet weak var selectedAssetIcon: UIImageView!
    @IBOutlet weak var selectedAssetBalance: UILabel!
    @IBOutlet weak var networkFeeLabel: UILabel!
    
    @IBOutlet weak var mempoolHeightLabel: UILabel!
    @IBOutlet weak var checkboxPriority: UIButton!
    @IBOutlet weak var priorityLabel: UILabel!
    
    var gasBalance: Double = 0.0
    var transactionCompleted: Bool!
    var selectedAsset: TransferableAsset?
    var preselectedAddress = ""
    var incomingQRData: String?
    
    func addThemedElements() {
        let themedTitleLabels = [toLabel, assetLabel, amountLabel]
        for label in themedTitleLabels {
            label?.theme_textColor = O3Theme.titleColorPicker
        }
        selectedAssetLabel.theme_textColor = O3Theme.titleColorPicker
        recipientCell.contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
        sendAmountCell.contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        tableView.theme_separatorColor = O3Theme.tableSeparatorColorPicker
        let themedTextFields = [toAddressField, amountField]
        let placeHolderColor = UserDefaultsManager.theme.textFieldPlaceHolderColor
        for field in themedTextFields {
            field!.attributedPlaceholder = NSAttributedString(
                string: field!.placeholder ?? "",
                attributes: [NSAttributedStringKey.foregroundColor: placeHolderColor])
            field?.theme_keyboardAppearance = O3Theme.keyboardPicker
            field?.theme_backgroundColor = O3Theme.clearTextFieldBackgroundColorPicker
            field?.theme_textColor = O3Theme.textFieldTextColorPicker
        }
    }
    
    func getMempool() {
        NeoClient(seed: AppState.bestSeedNodeURL).getMempoolHeight { result in
            switch(result) {
            case .failure(let error):
                return
            case .success(let count):
                DispatchQueue.main.async {
                    self.mempoolHeightLabel.isHidden = false
                    self.mempoolHeightLabel.text = String(format: SendStrings.mempoolHeight, count.description)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        addThemedElements()
        applyNavBarTheme()
        setLocalizedStrings()
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "times"), style: .plain, target: self, action: #selector(self.tappedLeftBarButtonItem(_:)))
        
        //select best node
        DispatchQueue.global().async {
            if let bestNode = NEONetworkMonitor.autoSelectBestNode(network: AppState.network) {
                AppState.bestSeedNodeURL = bestNode
            }
        }
        getMempool()
        
        tableView.tableFooterView = UIView(frame: .zero)
        self.navigationController?.navigationItem.largeTitleDisplayMode = .automatic
        self.enableSendButton()
        self.toAddressField.text = preselectedAddress.trim()
        if incomingQRData != nil {
            qrScanned(data: incomingQRData!)
        }
        
        //default to NEO
        self.selectedAsset = O3Cache.neo()
        self.assetSelected(selected: O3Cache.neo(), gasBalance: O3Cache.gas().value)
    }
    
    @IBAction func tappedLeftBarButtonItem(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 2 {
            amountField.becomeFirstResponder()
        }
    }
    
    func sendOntology(assetSymbol: String, amount: Double, toAddress: String) {
        let wif = Authenticated.account?.wif
        var error: NSError?
        let endpoint = ONTNetworkMonitor.autoSelectBestNode(network: AppState.network)
        OntologyClient().getGasPrice { result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self.transactionCompleted = false
                    self.performSegue(withIdentifier: "segueToTransactionComplete", sender: nil)
                }
            case .success(let gasPrice):
                let txid = NeoutilsOntologyTransfer(endpoint, gasPrice, 20000, wif, assetSymbol, toAddress, amount, &error)
                DispatchQueue.main.async {
                    if txid != "" {
                        self.savePendingTransaction(blockchain: "ontology", txID: txid!, from: (Authenticated.account?.address)!, to: toAddress, asset: self.selectedAsset!, amount: amount.string(self.selectedAsset!.decimals, removeTrailing: true))
                        self.transactionCompleted = true
                        self.performSegue(withIdentifier: "segueToTransactionComplete", sender: nil)
                    } else {
                        self.transactionCompleted = false
                        self.performSegue(withIdentifier: "segueToTransactionComplete", sender: nil)
                    }
                }
            }
        }
    }
    
    func sendNEP5Token(tokenHash: String, decimals: Int, assetName: String, amount: Double, toAddress: String) {
        
        DispatchQueue.main.async {
            OzoneAlert.confirmDialog(message: String(format: SendStrings.sendConfirmationPrompt, amount, assetName, toAddress),
                                     cancelTitle: OzoneAlert.cancelNegativeConfirmString,
                                     confirmTitle: OzoneAlert.confirmPositiveConfirmString, didCancel: {}) {
                                        let keychain = Keychain(service: "network.o3.neo.wallet")
                                        do {
                                            _ = try keychain
                                                .authenticationPrompt(SendStrings.authenticateToSendPrompt)
                                                .get("ozonePrivateKey")
                                            O3HUD.start()
                                            if let bestNode = NEONetworkMonitor.autoSelectBestNode(network: AppState.network) {
                                                AppState.bestSeedNodeURL = bestNode
                                            }
                                            var fee = 0.0
                                            if self.checkboxPriority.isSelected {
                                                fee = 0.0011
                                            }
                                            Authenticated.account?.sendNep5Token(network: AppState.network, seedURL: AppState.bestSeedNodeURL, tokenContractHash: tokenHash, decimals: self.selectedAsset!.decimals, amount: amount, toAddress: toAddress, fee: fee, completion: { (completed, _ , txID) in
                                                
                                                O3HUD.stop {
                                                    self.transactionCompleted = completed ?? false
                                                    Answers.logCustomEvent(withName: "Token Asset Sent",
                                                                           customAttributes: [
                                                                            "Asset Name": assetName,
                                                                            "Amount": amount])
                                                    self.performSegue(withIdentifier: "segueToTransactionComplete", sender: nil)
                                                    if self.transactionCompleted == true {
                                                        self.savePendingTransaction(blockchain: "neo", txID: txID!, from: (Authenticated.account?.address)!, to: toAddress, asset: self.selectedAsset!, amount: amount.string(self.selectedAsset!.decimals, removeTrailing: true))
                                                    }
                                                }
                                                
                                            })
                                            
                                        } catch _ {
                                        }
            }
        }
    }
    
    func sendNativeAsset(assetId: AssetId, assetName: String, amount: Double, toAddress: String) {
        DispatchQueue.main.async {
            OzoneAlert.confirmDialog(message: String(format: SendStrings.sendConfirmationPrompt, amount, assetName, toAddress),
                                     cancelTitle: OzoneAlert.cancelNegativeConfirmString,
                                     confirmTitle: OzoneAlert.okPositiveConfirmString, didCancel: {}) {
                                        let keychain = Keychain(service: "network.o3.neo.wallet")
                                        do {
                                            _ = try keychain
                                                .authenticationPrompt(SendStrings.authenticateToSendPrompt)
                                                .get("ozonePrivateKey")
                                            O3HUD.start()
                                            if let bestNode = NEONetworkMonitor.autoSelectBestNode(network: AppState.network) {
                                                AppState.bestSeedNodeURL = bestNode
                                            }
                                            var customAttributes: [TransactionAttritbute] = []
                                            let remark = String(format: "O3XSEND")
                                            customAttributes.append(TransactionAttritbute(remark: remark))
                                            var fee = 0.0
                                            if self.checkboxPriority.isSelected {
                                                fee = 0.0011
                                            }
                                            
                                            Authenticated.account?.sendAssetTransaction(network: AppState.network, seedURL: AppState.bestSeedNodeURL, asset: assetId, amount: amount, toAddress: toAddress, attributes: customAttributes, fee: fee) { txid, _ in
                                                O3HUD.stop {
                                                    if txid != nil {
                                                        self.transactionCompleted = true
                                                        Answers.logCustomEvent(withName: "Native Asset Sent",
                                                                               customAttributes: [
                                                                                "Asset Name": assetName,
                                                                                "Amount": amount])
                                                    } else {
                                                        self.transactionCompleted = false
                                                    }
                                                    
                                                    //save to pending tx if it's completed
                                                    if self.transactionCompleted == true {
                                                        self.savePendingTransaction(blockchain: "neo", txID: txid!, from: (Authenticated.account?.address)!, to: toAddress, asset: self.selectedAsset!, amount: amount.string(self.selectedAsset!.decimals, removeTrailing: true))
                                                    }
                                                    
                                                    self.performSegue(withIdentifier: "segueToTransactionComplete", sender: nil)
                                                }
                                            }
                                        } catch _ {
                                        }
            }
        }
    }
    
    @IBAction func sendButtonTapped() {
        
        if self.selectedAsset == nil {
            return
        }
        
        var assetId: String! = self.selectedAsset!.id
        let assetName: String! = self.selectedAsset!.name
        let assetSymbol: String! = self.selectedAsset!.symbol
        let amountFormatter = NumberFormatter()
        amountFormatter.minimumFractionDigits = 0
        amountFormatter.maximumFractionDigits = self.selectedAsset!.decimals
        amountFormatter.numberStyle = .decimal
        
        let amount = amountFormatter.number(from: (self.amountField.text?.trim())!)
        
        if amount == nil {
            OzoneAlert.alertDialog(message: SendStrings.invalidAmountError, dismissTitle: OzoneAlert.okPositiveConfirmString, didDismiss: {
                self.amountField.becomeFirstResponder()
            })
            return
        }
        
        //validate amount
        if amount!.doubleValue > self.selectedAsset!.value {
            let balanceDecimal = self.selectedAsset!.value
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = self.selectedAsset!.decimals
            formatter.numberStyle = .decimal
            let balanceString = formatter.string(for: balanceDecimal)
            
            let message = String(format: SendStrings.notEnoughBalanceError, assetName, balanceString!)
            OzoneAlert.alertDialog(message: message, dismissTitle: OzoneAlert.okPositiveConfirmString, didDismiss: {
                self.amountField.becomeFirstResponder()
            })
            return
        } else if selectedAsset?.name.lowercased() == "gas" && self.selectedAsset!.value - amount!.doubleValue <= 0.00000001 {
            OzoneAlert.alertDialog(message: SendStrings.roundingGasError, dismissTitle: OzoneAlert.okPositiveConfirmString, didDismiss: {
                self.amountField.becomeFirstResponder()
            })
            return
        }
        let toAddress = toAddressField.text?.trim() ?? ""
        
        //validate address first
        if NEOValidator.validateNEOAddress(toAddress) == false {
            DispatchQueue.main.async {
                OzoneAlert.alertDialog(message: SendStrings.invalidAddressError, dismissTitle: OzoneAlert.okPositiveConfirmString, didDismiss: {
                    self.toAddressField.becomeFirstResponder()
                })
                return
            }
        }
        
        if self.selectedAsset?.assetType == .neoAsset {
            if assetId.hasPrefix("0x") {
                assetId = String(assetId.dropFirst(2))
            }
            self.sendNativeAsset(assetId: AssetId(rawValue: assetId)!, assetName: assetName, amount: amount!.doubleValue, toAddress: toAddress)
        } else if self.selectedAsset?.assetType == .nep5Token {
            self.sendNEP5Token(tokenHash: assetId, decimals: self.selectedAsset!.decimals, assetName: assetName, amount: amount!.doubleValue, toAddress: toAddress)
        } else if self.selectedAsset?.assetType == .ontologyAsset {
            self.sendOntology(assetSymbol: assetSymbol, amount: amount!.doubleValue, toAddress: toAddress)
        }
    }
    
    @IBAction func pasteTapped(_ sender: Any) {
        toAddressField.text = UIPasteboard.general.string
        enableSendButton()
    }
    
    @IBAction func scanTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "segueToQR", sender: nil)
    }
    
    func selectedAddress(_ address: String) {
        toAddressField.text = address
        enableSendButton()
    }
    
    func qrScanned(data: String) {
        
        if data.range(of: "neo:") == nil {
            toAddressField.text = data
        } else {
            let nep9Data = NEP9.parse(data)
            let address = nep9Data?.to()
            let asset = nep9Data?.asset()
            let amount = nep9Data?.amount()
            
            toAddressField.text = address
            
            if asset != "" {
                var selected: TransferableAsset?
                
                if asset?.lowercased() == "neo" || asset == AssetId.neoAssetId.rawValue {
                    selected = O3Cache.neo()
                } else if asset?.lowercased() == "gas" || asset == AssetId.gasAssetId.rawValue {
                    selected = O3Cache.gas()
                } else {
                    let tokenAssets = O3Cache.tokenAssets()
                    let assetIndex = tokenAssets.index(where: { (item) -> Bool in
                        item.id.range(of: asset!) != nil
                    })
                    if assetIndex != nil {
                        selected = tokenAssets[assetIndex!]
                    }
                }
                
                if selected != nil {
                    self.selectedAsset = selected
                    self.selectedAssetLabel.text = selected!.symbol
                }
            }
            
            if amount != nil {
                self.amountField.text = String(format: "%f", amount!)
            }
        }
        
        enableSendButton()
    }
    
    @IBAction func selectAssetTapped(_ sender: Any) {
        guard let nav = UIStoryboard(name: "Send", bundle: nil).instantiateViewController(withIdentifier: "AssetSelectorNavigationController") as? UINavigationController else {
            return
        }
        
        guard let modal = nav.viewControllers.first as? AssetSelectorTableViewController else {
            return
        }
        modal.delegate = self
        self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: nav)
        nav.modalPresentationStyle = .custom
        nav.transitioningDelegate = self.halfModalTransitioningDelegate
        self.present(nav, animated: true, completion: nil)
    }
    
    func showVerifiedAddress(verifiedAddress: VerifiedAddress?) {
        if verifiedAddress == nil {
            verifiedAddressDisplayNameLabel.text = ""
            verifiedAddressBadge.isHidden = true
            return
        }
        verifiedAddressDisplayNameLabel.text = verifiedAddress!.displayName
        verifiedAddressBadge.isHidden = false
    }
    
    @IBAction func enableSendButton() {
        self.showVerifiedAddress(verifiedAddress: nil)
        if toAddressField.text?.isEmpty == true {
            sendButton.isEnabled = false
            return
        }
        let validAddress = NeoutilsValidateNEOAddress(toAddressField.text?.trim())
        if validAddress == false {
            sendButton.isEnabled = false
            return
        }
        //check verified address here
        O3APIClient(network: AppState.network).checkVerifiedAddress(address: toAddressField.text!) { result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self.showVerifiedAddress(verifiedAddress: nil)
                }
                return
            case .success(let verifiedAddress):
                DispatchQueue.main.async {
                    //show green verified badge
                    self.showVerifiedAddress(verifiedAddress: verifiedAddress)
                }
            }
        }
        
        sendButton.isEnabled = validAddress == true && amountField.text?.isEmpty == false && selectedAsset != nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToAddressSelect" {
            self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: segue.destination)
            segue.destination.modalPresentationStyle = .custom
            segue.destination.transitioningDelegate = self.halfModalTransitioningDelegate
            guard let dest = segue.destination as? UINavigationController,
                let addressSelectVC = dest.childViewControllers[0] as? AddressSelectTableViewController else {
                    fatalError("Undefined Table view behavior")
            }
            addressSelectVC.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "times"), style: .plain, target: self, action: #selector(tappedCloseAddressSeletor(_:)))
            addressSelectVC.delegate = self
        } else if segue.identifier == "segueToQR" {
            guard let dest = segue.destination as? QRScannerController else {
                fatalError("Undefined segue behavior")
            }
            dest.delegate = self
        } else if segue.identifier == "segueToTransactionComplete" {
            guard let dest = segue.destination as? SendCompleteViewController else {
                fatalError("Undefined segue behavior")
            }
            dest.transactionSucceeded = transactionCompleted
        }
    }
    
    @IBAction func addressTapped(_ sender: Any) {
        performSegue(withIdentifier: "segueToAddressSelect", sender: nil)
    }
    
    @IBAction func priorityTapped(_ sender: Any) {
        checkboxPriority!.isSelected = !checkboxPriority!.isSelected
    }
    
    @IBAction func tappedCloseAddressSeletor(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    func showNetworkFeeLabel() {
        ONTNetworkMonitor.autoSelectBestNode(network: AppState.network)
        OntologyClient().getGasPrice { result in
            switch result {
            case (.failure):
                DispatchQueue.main.async {
                    self.networkFeeLabel.text = String(format: SendStrings.ontologySendRequiresGas, (0.01))
                }
            case(.success(let price)):
                DispatchQueue.main.async {
                    self.networkFeeLabel.isHidden = false
                    self.networkFeeLabel.text = String(format: SendStrings.ontologySendRequiresGas, (Double(price) * 20000.0) / 1000000000.0)
                }
            }
        }
    }
    
    func setLocalizedStrings() {
        toLabel.text = SendStrings.toLabel
        assetLabel.text = SendStrings.assetLabel
        amountLabel.text = SendStrings.amountLabel
        pasteButton.setTitle(SendStrings.paste, for: UIControlState())
        scanButton.setTitle(SendStrings.scan, for: UIControlState())
        addressButton.setTitle(SendStrings.addressBook, for: UIControlState())
        selectedAssetLabel.text = SendStrings.selectedAssetLabel
        sendButton.setTitle(SendStrings.send, for: UIControlState())
        self.title = SendStrings.send
        toAddressField.placeholder = SendStrings.toAddressPlaceholder
    }
}

extension SendTableViewController: AssetSelectorDelegate {
    func assetSelected(selected: TransferableAsset, gasBalance: Double) {
        DispatchQueue.main.async {
            if selected.id.contains("0000000") {
                self.showNetworkFeeLabel()
                self.mempoolHeightLabel.isHidden = true
                self.checkboxPriority.isHidden = true
                self.priorityLabel.isHidden = true
            } else {
                self.networkFeeLabel.isHidden = true
                self.checkboxPriority.isHidden = false
                self.priorityLabel.isHidden = false
                self.mempoolHeightLabel.isHidden = false
            }
            self.gasBalance = gasBalance
            self.selectedAsset = selected
            self.selectedAssetLabel.text = selected.symbol
            self.selectedAssetBalance.text = selected.value.string(selected.decimals, removeTrailing: true)
            let imageURL = String(format: "https://cdn.o3.network/img/neo/%@.png", selected.symbol.uppercased())
            self.selectedAssetIcon?.kf.setImage(with: URL(string: imageURL))
            self.enableSendButton()
        }
    }
}

extension SendTableViewController {
    
    func savePendingTransaction(blockchain: String,txID: String, from: String, to: String, asset: TransferableAsset, amount: String) {
        let context = UIApplication.appDelegate.accountPersistentContainer.viewContext
        let pending = PendingTransaction(context: context)
        pending.blockchain = blockchain
        pending.txID = txID
        pending.from = from
        pending.to = to
        pending.amount = amount
        pending.timestamp = Int64(Date().timeIntervalSince1970)
        pending.asset = asset.symbol
        UIApplication.appDelegate.saveAccountContext()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "pendingTransactionAdded"), object: nil)
    }
    
}
