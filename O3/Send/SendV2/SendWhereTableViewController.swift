//
//  SendWhereTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 10/16/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Neoutils
import Lottie

class SendWhereTableViewController: UITableViewController, QRScanDelegate, AddressSelectDelegate {
    // swiftlint:disable weak_delegate
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    // swiftlint:enable weak_delegate
    
    
    @IBOutlet weak var whereLabel: UILabel!
    @IBOutlet weak var whatLabel: UILabel!
    @IBOutlet weak var reviewLabel: UILabel!
    
    @IBOutlet weak var addressInfoLabel: UILabel!
    @IBOutlet weak var addressBadgeImageView: UIImageView!
    @IBOutlet weak var resolvingLoadingContainer: UIView!
    
    
    @IBOutlet weak var contactsButton: UIButton!
    @IBOutlet weak var pasteButton: UIButton!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var addressTextField: UITextField!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var continueButton: UIButton!
    var addressToSend = ""
    var addressAlias = ""
    var addressAliasImage: UIImage?
    var selectedAsset: TransferableAsset?
    var selectedAmount: Double?


    let loadingView = LOTAnimationView(name: "loader_portfolio")
    var incomingQRData: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.hideHairline()
        setLocalizedStrings()
        applyNavBarTheme()
        addThemedElements()
        addressTextField.addTarget(self, action: #selector(addressTextFieldChanged(_:)), for: .editingChanged)
        continueButton.addTarget(self, action: #selector(continueButtonTapped(_:)), for: .touchUpInside)
        loadingView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        loadingView.play()
        resolvingLoadingContainer.embed(loadingView)
        addressTextField.text = addressToSend
        if incomingQRData != nil {
            qrScanned(data: incomingQRData!)
        }
        
        enableContinueButton()
    }
    
    @IBAction func addressTapped(_ sender: Any) {
        performSegue(withIdentifier: "segueToAddressSelect", sender: nil)
    }
    
    @IBAction func pasteTapped(_ sender: Any) {
        addressTextField.text = UIPasteboard.general.string
        enableContinueButton()
    }
    
    @IBAction func scanTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "segueToQR", sender: nil)
    }
    
    func hideAddressInfo() {
        DispatchQueue.main.async {
            self.addressInfoLabel.text = ""
            self.addressAlias = ""
            self.addressAliasImage = nil
            self.addressBadgeImageView.isHidden = true
            self.resolvingLoadingContainer.isHidden = true
        }
    }
    
    func showAddressInfo(addressInfo: String, badge: UIImage? = nil) {
        addressInfoLabel.isHidden = false
        addressInfoLabel.text = addressInfo
        if NeoutilsValidateNEOAddress(addressInfoLabel.text) {
            addressAlias = addressTextField.text!.trim()
        } else {
            addressAlias = addressInfoLabel.text!
        }
        
        addressAliasImage = badge
        if (badge != nil) {
            addressBadgeImageView.isHidden = false
            addressBadgeImageView.image = badge
        }
    }
    
    @objc func addressTextFieldChanged(_ sender: Any) {
        //if it's ending in .neo then try to fetch the address by domain
        //if length if 34 then try to validate neo address
        let text = addressTextField.text?.trim() ?? ""
        if text.hasSuffix(".neo") {
            resolvingLoadingContainer.isHidden = false
            O3APIClient(network: AppState.network).domainLookup(domain: text) { result in
                DispatchQueue.main.async {
                    self.resolvingLoadingContainer.isHidden = true
                    switch result {
                    case .failure(let _):
                        self.showAddressInfo(addressInfo: SendStrings.invalidNNSName)
                        self.addressInfoLabel.textColor = UIColor(named: "lightThemeRed")
                    case .success(let address):
                        self.showAddressInfo(addressInfo: address, badge: UIImage(named: "nns"))
                        self.addressInfoLabel.textColor = UIColor(named: "lightThemeGreen")
                        self.addressToSend = address
                        self.enableContinueButton()
                    }
                }
            }
        } else {
            hideAddressInfo()
            enableContinueButton()
        }
    }

    func enableContinueButton() {
        if NeoutilsValidateNEOAddress(addressInfoLabel.text) {
            continueButton.isEnabled = true
            return
        }
        
        let address = addressTextField.text?.trim() ?? ""
        if !NeoutilsValidateNEOAddress(address) {
            continueButton.isEnabled = false
            return
        }
        addressToSend = address
        continueButton.isEnabled = true
        hideAddressInfo()
        O3APIClient(network: AppState.network).checkVerifiedAddress(address: address) { result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    return
                case .success(let verifiedAddress):
                    self.showAddressInfo(addressInfo: verifiedAddress.displayName, badge: UIImage(named: "shield-check"))
                    self.addressInfoLabel.textColor = UIColor(named: "lightThemeGreen")

                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToAddressSelect" {
            self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: segue.destination)
            segue.destination.modalPresentationStyle = .custom
            segue.destination.transitioningDelegate = self.halfModalTransitioningDelegate
            guard let dest = segue.destination as? UINavigationController,
                let addressSelectVC = dest.children[0] as? AddressSelectTableViewController else {
                    fatalError("Undefined Table view behavior")
            }
            addressSelectVC.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "times"), style: .plain, target: self, action: #selector(tappedCloseAddressSelector(_:)))
            addressSelectVC.delegate = self
        } else if segue.identifier == "segueToQR" {
            guard let dest = segue.destination as? QRScannerController else {
                fatalError("Undefined segue behavior")
            }
            dest.delegate = self
        } else if segue.identifier == "segueToSendWhat" {
            guard let dest = segue.destination as? SendWhatTableViewController else {
                fatalError("Undefined segue behabior")
            }
            dest.selectedAddress = addressToSend
            dest.toSendAlias = addressAlias
            dest.toSendAliasImage = addressAliasImage
            dest.selectedAmount = NSNumber(value: selectedAmount ?? 0)
            dest.selectedAsset = selectedAsset
        }
    }
    
    func selectedAddress(_ address: String) {
        addressTextField.text = address
        enableContinueButton()
    }
    
    func qrScanned(data: String) {
        if data.range(of: "neo:") == nil {
            addressTextField.text = data
        } else {
            let nep9Data = NEP9.parse(data)
            let address = nep9Data?.to()
            let asset = nep9Data?.asset()
            let amount = nep9Data?.amount()
            
            addressTextField.text = address
            
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
                }
                
                if amount != nil {
                    self.selectedAmount = amount
                }
                
            }
        }
    }
    
    @IBAction func tappedCloseAddressSelector(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func continueButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "segueToSendWhat", sender: nil)
    }
    
    
    func addThemedElements() {
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
        contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
        addressTextField.theme_backgroundColor = O3Theme.textFieldBackgroundColorPicker
        addressTextField.theme_textColor = O3Theme.textFieldTextColorPicker
        addressTextField.theme_placeholderAttributes = O3Theme.placeholderAttributesPicker
        addressTextField.theme_keyboardAppearance = O3Theme.keyboardPicker
    }
    
    func setLocalizedStrings() {
        pasteButton.setTitle(SendStrings.paste, for: UIControl.State())
        scanButton.setTitle(SendStrings.scan, for: UIControl.State())
        contactsButton.setTitle(SendStrings.addressBook, for: UIControl.State())
        self.title = SendStrings.send
        
        whereLabel.text = SendStrings.sendWhere
        whatLabel.text = SendStrings.sendWhat
        reviewLabel.text = SendStrings.sendReview
        addressTextField.placeholder = SendStrings.toAddressPlaceholder
        continueButton.setTitle(SendStrings.continueButton, for: UIControl.State())
    }
}
