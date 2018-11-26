//
//  SendWhatTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 10/17/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class SendWhatTableViewController: UITableViewController {
    @IBOutlet weak var mempoolHeightLabel: UILabel!
    @IBOutlet weak var priorityLabel: UILabel!
    @IBOutlet weak var checkboxPriority: UIButton!
    @IBOutlet weak var selectedAssetLabel: UILabel!
    @IBOutlet weak var selectedAssetBalance: UILabel!
    @IBOutlet weak var selectedAssetIcon: UIImageView!
    @IBOutlet weak var networkFeeLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var selectAssetContainer: UIView!
    @IBOutlet weak var amountField: UITextField!
    
    @IBOutlet weak var sendWhereLabel: UILabel!
    @IBOutlet weak var sendWhatLabel: UILabel!
    @IBOutlet weak var sendReviewLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    
    var selectedAddress = ""
    var gasBalance: Double = 0.0
    var selectedAsset: TransferableAsset?
    var selectedAmount: NSNumber = 0.0
    var toSendAlias = ""
    var toSendAliasImage: UIImage?
    
    var feeEnabled = false
    
    // swiftlint:disable weak_delegate
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    // swiftlint:enable weak_delegate
    
    func setMempoolHeight() {
        NeoClient(seed: AppState.bestSeedNodeURL).getMempoolHeight() { (result) in
            switch result {
            case .failure(let error):
                return
            case .success(let pending):
                DispatchQueue.main.async {
                    self.mempoolHeightLabel.text = String(format:SendStrings.mempoolHeight, pending.description)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectAssetTapped(_:)))
        selectAssetContainer.addGestureRecognizer(tap)
        setMempoolHeight()
        continueButton.addTarget(self, action: #selector(continueTapped(_:)), for: .touchUpInside)
        checkboxPriority.addTarget(self, action: #selector(priorityTapped(_:)), for: .touchUpInside)
        
        //default to NEO
        if selectedAsset == nil {
            self.selectedAsset = O3Cache.neo()
            self.assetSelected(selected: O3Cache.neo(), gasBalance: O3Cache.gas().value)
        } else {
            self.assetSelected(selected: selectedAsset!, gasBalance: O3Cache.gas().value)
        }
        
        if selectedAmount != 0 {
            amountField.text = selectedAmount.doubleValue.formattedStringWithoutSeparator(8, removeTrailing: true)
            continueButton.isEnabled = true
        }
        
        setLocalizedStrings()
        addThemedElements()
    }

    func showNetworkFeeLabel() {
        _ = ONTNetworkMonitor.autoSelectBestNode(network: AppState.network)
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
    
    
    @IBAction func amountFieldChanged(_ sender: Any) {
        if amountField.text ?? "" != "" {
            continueButton.isEnabled = true
        } else {
            continueButton.isEnabled = false
        }
    }
    
    func validateEnteredAmount() -> Bool {
        selectedAmount = 0
        if self.selectedAsset == nil {
            return false
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
            return false
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
            return false
        }
        selectedAmount = amount!
        return true
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
    
    @objc func continueTapped(_ sender: Any) {
        if validateEnteredAmount() {
            self.performSegue(withIdentifier: "segueToSendReview", sender: nil)
        }
        
    }
    
    @objc func priorityTapped(_ sender: Any) {
        checkboxPriority!.isSelected = !checkboxPriority!.isSelected
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToSendReview" {
            guard let dest = segue.destination as? SendReviewTableViewController else {
                fatalError("Undefined segue behavior")
            }
            dest.selectedAsset = selectedAsset
            dest.sendToAddress = selectedAddress
            dest.addressAlias = toSendAlias
            dest.addressAliasImage = toSendAliasImage
            dest.selectedAmount = selectedAmount.doubleValue
            dest.feeEnabled = checkboxPriority.isSelected
        }
    }
    
    func setLocalizedStrings() {
        selectedAssetLabel.text = SendStrings.selectedAssetLabel
        continueButton.setTitle(SendStrings.send, for: UIControl.State())
        
        sendWhatLabel.text = SendStrings.sendWhat
        sendWhereLabel.text = SendStrings.sendWhere
        sendReviewLabel.text = SendStrings.sendReview
    }
    
    func addThemedElements() {
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
        contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
        amountField.theme_keyboardAppearance = O3Theme.keyboardPicker
        selectedAssetLabel.theme_textColor = O3Theme.titleColorPicker
        
        amountField.theme_backgroundColor = O3Theme.textFieldBackgroundColorPicker
        amountField.theme_textColor = O3Theme.textFieldTextColorPicker
        amountField.theme_placeholderAttributes = O3Theme.placeholderAttributesPicker
        amountField.theme_keyboardAppearance = O3Theme.keyboardPicker
    }
}


extension SendWhatTableViewController: AssetSelectorDelegate {
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
        }
    }
}
