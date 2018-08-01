//
//  ClaimableGASTableViewCell.swift
//  O3
//
//  Created by Apisit Toompakdee on 6/11/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import Lottie
import Crashlytics

protocol ClaimingGasCellDelegate: class {
    func setIsClaiming(_ isClaiming: Bool)
}

class ClaimableGASTableViewCell: UITableViewCell {
    weak var delegate: ClaimingGasCellDelegate?
    var claimSuccessAnimation: LOTAnimationView = LOTAnimationView(name: "claim_success")

    @IBOutlet var confirmedClaimableGASContainer: UIView!
    @IBOutlet weak var claimContainerTitleLabel: UILabel!

    @IBOutlet weak var neoClaimLoadingContainer: UIView!
    @IBOutlet weak var neoClaimSuccessContainer: UIView!
    @IBOutlet weak var neoSyncNowButton: UIButton!
    @IBOutlet var neoClaimNowButton: UIButton!
    @IBOutlet var confirmedClaimableNeoGASLabel: UILabel!

    @IBOutlet var neoGasClaimingStateLabel: UILabel?
    @IBOutlet var confirmedClaimableGASTitle: UILabel?

    func setupLocalizedStrings() {
        neoGasClaimingStateLabel?.text = AccountStrings.confirmedClaimableGasTitle
        confirmedClaimableGASTitle?.text = "GAS"
        neoClaimNowButton?.setTitle(AccountStrings.claimNowButton, for: .normal)
        claimContainerTitleLabel.text = AccountStrings.claimNowButton
    }

    func setupTheme() {
        neoGasClaimingStateLabel?.theme_textColor = O3Theme.lightTextColorPicker
        confirmedClaimableNeoGASLabel?.theme_textColor = O3Theme.titleColorPicker
        neoSyncNowButton.theme_setTitleColor(O3Theme.titleColorPicker, forState: UIControlState())
        claimContainerTitleLabel.theme_textColor = O3Theme.titleColorPicker
        confirmedClaimableGASContainer?.theme_backgroundColor = O3Theme.backgroundColorPicker
        contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.setupTheme()
    }

    func setupView() {
        let loaderView = LOTAnimationView(name: "loader_portfolio")
        loaderView.loopAnimation = true
        loaderView.play()
        neoClaimLoadingContainer.embed(loaderView)
        neoClaimSuccessContainer.embed(claimSuccessAnimation)
        neoSyncNowButton?.addTarget(self, action: #selector(neoSyncNowTapped(_:)), for: .touchUpInside)
        neoClaimNowButton?.addTarget(self, action: #selector(neoClaimNowTapped(_:)), for: .touchUpInside)
    }

    func resetState() {
        DispatchQueue.main.async {
            self.neoGasClaimingStateLabel?.theme_textColor = O3Theme.lightTextColorPicker
            self.neoClaimLoadingContainer.isHidden = true
            self.neoClaimSuccessContainer.isHidden = true
            self.neoClaimNowButton.isHidden = true
            self.neoSyncNowButton.isHidden = true
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupLocalizedStrings()
        self.setupView()
    }

    func loadClaimableGASNeo() {
        O3APIClient(network: AppState.network).getClaims(address: (Authenticated.account?.address)!) { result in
            switch result {
            case .failure(let error):
                self.resetState()
                OzoneAlert.alertDialog(message: error.localizedDescription, dismissTitle: "OK", didDismiss: {})
                return
            case .success(let claims):
                DispatchQueue.main.async {
                    if claims.claims.count > 0 {
                        AppState.setClaimingState(address: Authenticated.account!.address, claimingState: .ReadyToClaim)
                    }
                    self.displayClaimableStateNeo(claimable: claims)
                }
            }
        }
    }

    func displayClaimableStateNeo(claimable: Claimable) {
        self.resetState()

        let gasDouble = NSDecimalNumber(decimal: claimable.gas).doubleValue
        if claimable.claims.count == 0 {
            //if claim array is empty then we show estimated
            let gas = gasDouble.string(8, removeTrailing: true)
            self.showEstimatedClaimableGASStateNeo(value: gas)
            self.neoSyncNowButton?.isEnabled = !gasDouble.isZero
        } else {
            //if claim array is not empty then we show the confirmed claimable and let user claims
            let gas = gasDouble.string(8, removeTrailing: true)
            self.showConfirmedClaimableGASStateNeo(value: gas)
        }
    }

    func showEstimatedClaimableGASStateNeo(value: String) {
        self.resetState()
        DispatchQueue.main.async {
            self.neoSyncNowButton.isHidden = false
            self.confirmedClaimableNeoGASLabel.text = value
        }
    }

    func showConfirmedClaimableGASStateNeo(value: String) {
        self.resetState()
        DispatchQueue.main.async {
            self.confirmedClaimableNeoGASLabel?.text = value
            self.neoClaimNowButton?.isHidden = false
            self.neoClaimLoadingContainer.isHidden = true
        }
    }

    func sendAllNEOToTheAddress() {
        //show loading screen first
        self.delegate?.setIsClaiming(true)
        DispatchQueue.main.async {
            self.neoSyncNowButton.isHidden = true
            self.startLoadingNeoClaims()
        }

        //try to fetch best node
        if let bestNode = NEONetworkMonitor.autoSelectBestNode(network: AppState.network) {
            AppState.bestSeedNodeURL = bestNode
            #if DEBUG
            print(AppState.network)
            print(AppState.bestSeedNodeURL)
            #endif
        }

        //to be able to claim. we need to send the entire NEO to ourself.
        var customAttributes: [TransactionAttritbute] = []
        let remark = String(format: "O3XFORCLAIM")
        customAttributes.append(TransactionAttritbute(remark: remark))

        Authenticated.account?.sendAssetTransaction(network: AppState.network, seedURL: AppState.bestSeedNodeURL, asset: AssetId.neoAssetId, amount: O3Cache.neo().value, toAddress: (Authenticated.account?.address)!, attributes: customAttributes) { txid, _ in
            if txid == nil {
                self.delegate?.setIsClaiming(false)
                //if sending failed then show error message and load the claimable gas again to reset the state
                OzoneAlert.alertDialog(message: "Error while trying to send", dismissTitle: "OK", didDismiss: {

                })
                self.loadClaimableGASNeo()
                return
            }
        }
    }

    func claimConfirmedNeoClaimableGAS() {
        self.delegate?.setIsClaiming(true)
        DispatchQueue.main.async {
            self.neoClaimNowButton?.isHidden = true
            self.neoClaimLoadingContainer.isHidden = false
        }
        //show loading perhaps
        if let bestNode = NEONetworkMonitor.autoSelectBestNode(network: AppState.network) {
            AppState.bestSeedNodeURL = bestNode
            #if DEBUG
            print(AppState.network)
            print(AppState.bestSeedNodeURL)
            #endif
        }

        Authenticated.account?.claimGas(network: AppState.network, seedURL: AppState.bestSeedNodeURL) { success, error in

            DispatchQueue.main.async {

                if error != nil {
                    self.delegate?.setIsClaiming(false)
                    self.neoClaimLoadingContainer.isHidden = true
                    self.neoClaimNowButton?.isHidden = false
                    OzoneAlert.alertDialog(SendStrings.transactionFailedTitle, message: SendStrings.transactionFailedSubtitle, dismissTitle: OzoneAlert.okPositiveConfirmString) {}
                    return
                }

                if success == true {
                    self.neoClaimedSuccess()
                    Answers.logCustomEvent(withName: "Gas Claimed",
                                           customAttributes: ["Amount": self.confirmedClaimableNeoGASLabel?.text ?? ""])
                } else {
                    DispatchQueue.main.async {
                        self.delegate?.setIsClaiming(false)
                        self.neoClaimLoadingContainer.isHidden = true
                        self.neoClaimNowButton?.isHidden = false
                    }
                    OzoneAlert.alertDialog(SendStrings.transactionFailedTitle, message: SendStrings.transactionFailedSubtitle, dismissTitle: OzoneAlert.okPositiveConfirmString) {}
                    return
                }
            }
        }
    }

    @objc @IBAction func neoSyncNowTapped(_ sender: Any) {
        self.sendAllNEOToTheAddress()
    }

    @objc @IBAction func neoClaimNowTapped(_ sender: Any) {
        self.claimConfirmedNeoClaimableGAS()
    }

    func neoClaimedSuccess() {
        AppState.setClaimingState(address: Authenticated.account!.address, claimingState: .Fresh)
        DispatchQueue.main.async {
            self.neoClaimLoadingContainer.isHidden = true
            self.neoClaimSuccessContainer.isHidden = false
            self.claimSuccessAnimation.play()
            self.neoGasClaimingStateLabel?.theme_textColor = O3Theme.positiveGainColorPicker
            self.startCountdownBackToNeoEstimated()
        }
    }

    //CountdownTimers NEO
    func startCountdownBackToNeoEstimated() {
        let targetSec = 60
        var sec = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            DispatchQueue.main.async {
                sec += 1
                if sec == targetSec {
                    timer.invalidate()
                    self.delegate?.setIsClaiming(false)
                    self.loadClaimableGASNeo()
                }
            }
        }
        timer.fire()
    }

    func startLoadingNeoClaims() {
        self.neoClaimLoadingContainer.isHidden = false
        let targetSec = 60
        var sec = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            DispatchQueue.main.async {
                sec += 1
                self.delegate?.setIsClaiming(true)
                if sec == targetSec {
                    timer.invalidate()
                    self.delegate?.setIsClaiming(false)
                    //load claimable api again to check the claim array
                    self.loadClaimableGASNeo()
                }
            }
        }
        timer.fire()
    }
}
