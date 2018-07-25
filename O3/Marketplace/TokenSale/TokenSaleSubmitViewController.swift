//
//  TokenSaleSubmitViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 4/17/18.
//  Copyright © 2018 drei. All rights reserved.
//

import UIKit
import Neoutils
class TokenSaleSubmitViewController: UIViewController {

    var transactionInfo: TokenSaleTableViewController.TokenSaleTransactionInfo!
    @IBOutlet weak var sendingProgressLabel: UILabel!

    func setThemedElements() {
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
    }

    func performContractBasedTransaction() {
        let fee = transactionInfo.priorityIncluded == true ? Float64(0.0011) : Float64(0)
        let remark = String(format: "O3X%@", transactionInfo.saleInfo.companyID)
        Authenticated.account?.participateTokenSales(network: AppState.network, seedURL: AppState.bestSeedNodeURL, scriptHash: transactionInfo.tokenSaleContractHash, assetID: transactionInfo.assetIDUsedToPurchase, amount: transactionInfo.assetAmount, remark: remark, networkFee: fee) { success, txID, _ in

            //make delay to 5 seconds in production
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if success == true {
                    self.transactionInfo.txID = txID
                    self.performSegue(withIdentifier: "success", sender: self.transactionInfo)
                    return
                }
                self.performSegue(withIdentifier: "error", sender: nil)
            }
        }
    }

    func submitRealTimePricingData(txid: String) {
        let acceptedAssetRate = transactionInfo.saleInfo.acceptingAssets.filter({ $0.asset.uppercased() == transactionInfo.assetNameUsedToPurchase.uppercased() }).first!
        let unsignedData = TokenSaleUnsignedData(amount: transactionInfo.assetAmount, asset: acceptedAssetRate, txid: txid)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let jsonData = try? encoder.encode(unsignedData)
        var error: NSError?
        let signature = NeoutilsSign(jsonData, Authenticated.account!.privateKeyString, &error)?.fullHexString

        let tokenSaleLog = TokenSaleLog(data: unsignedData, signature: signature!, publicKey: Authenticated.account!.publicKeyString)
        O3APIClient(network: AppState.network).postTokenSaleLog(address: (Authenticated.account?.address)!, companyID: transactionInfo.saleInfo.companyID, tokenSaleLog: tokenSaleLog) { result in
            switch result {
            case .failure:
                return
            case .success:
                return
            }
        }
    }

    func performAddressBasedTransaction() {
        //self.submitRealTimePricingData(hellllo)
        let remark = String(format: "O3X%@", transactionInfo.saleInfo.companyID)
        Authenticated.account?.sendAssetTransaction(network: AppState.network, seedURL: AppState.bestSeedNodeURL, asset: AssetId(rawValue: transactionInfo.assetIDUsedToPurchase)!, amount: transactionInfo.assetAmount, toAddress: transactionInfo.saleInfo.address, attributes: [TransactionAttritbute(remark: remark)]) { txid, _ in
            //make delay to 5 seconds in production
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if txid != nil {
                    self.transactionInfo.txID = txid!
                    self.submitRealTimePricingData(txid: txid!)
                    self.performSegue(withIdentifier: "success", sender: self.transactionInfo)
                    return
                }
                self.performSegue(withIdentifier: "error", sender: nil)
            }
        }
    }

    func submitTransaction() {
        if transactionInfo.saleInfo.address == "" {
            performContractBasedTransaction()
        } else {
            performAddressBasedTransaction()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        self.navigationItem.hidesBackButton = true
        self.navigationController?.isNavigationBarHidden = true
        setThemedElements()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let bestNode = NEONetworkMonitor.autoSelectBestNode(network: AppState.network) {
            AppState.bestSeedNodeURL = bestNode
        }
        submitTransaction()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "success" {
            guard let vc = segue.destination as? TokenSaleSuccessViewController,
                let info = sender as? TokenSaleTableViewController.TokenSaleTransactionInfo? else {
                return
            }
            vc.transactionInfo = info
        }
    }

    func setLocalizedStrings() {
        sendingProgressLabel.text = TokenSaleStrings.sendingInProgress
    }
}
