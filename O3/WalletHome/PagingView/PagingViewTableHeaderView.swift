//
//  PagingViewTableHeaderView.swift
//  O3
//
//  Created by jcc on 2020/6/18.
//  Copyright © 2020 O3 Labs Inc. All rights reserved.
//

import UIKit
import Lottie
import Crashlytics
import Neoutils
import StoreKit

protocol PagingViewTableHeaderViewDelegate: AnyObject {
    func setIsClaimingNeo(_ isClaiming: Bool)
    func setIsClaimingOnt(_ isClaiming: Bool)
}

class PagingViewTableHeaderView: UIView {
    var headerViewFrame: CGRect = CGRect.zero
    
    weak var delegate: PagingViewTableHeaderViewDelegate?

    var neoClaimSuccessAnimation: LOTAnimationView = LOTAnimationView(name: "claim_success")
    var ontClaimSuccessAnimation: LOTAnimationView = LOTAnimationView(name: "claim_success")

    var ongBalance = 0.0

    @IBOutlet weak var shadowBackground: UIView!
    //Neo Claiming Views
    @IBOutlet weak var neoClaimLoadingContainer: UIView!
    @IBOutlet weak var neoClaimSuccessContainer: UIView!
    @IBOutlet weak var neoSyncNowButton: UIButton!
    @IBOutlet var neoClaimNowButton: UIButton!
    @IBOutlet var claimableGasAmountLabel: UILabel!
    @IBOutlet var neoGasClaimingStateLabel: UILabel?
    @IBOutlet var confirmedClaimableGASTitle: UILabel?
    
    //Ont Claiming Views
    @IBOutlet weak var ontSyncButton: UIButton!
    @IBOutlet weak var ontClaimButton: UIButton!
    @IBOutlet weak var claimableOntAmountLabel: UILabel!
    @IBOutlet weak var ontClaimingStateTitle: UILabel!
    @IBOutlet weak var ongTitle: UILabel!
    @IBOutlet weak var ontClaimingSuccessContainer: UIView!
    @IBOutlet weak var ontClaimingLoadingContainer: UIView!
    
    let estimatedString = AccountStrings.estimatedClaimableGasTitle
    let confirmedString = AccountStrings.confirmedClaimableGasTitle
    let claimSucceededString = AccountStrings.successClaimTitle
    let loadingString = AccountStrings.claimingInProgressTitle
    
    func setupLocalizedStrings() {
        neoGasClaimingStateLabel?.text = AccountStrings.confirmedClaimableGasTitle
        ontClaimingStateTitle?.text = AccountStrings.confirmedClaimableGasTitle
        neoClaimNowButton?.setTitle(AccountStrings.claimNowButton, for: .normal)
        neoSyncNowButton?.setTitle(AccountStrings.updateNowButton, for: UIControl.State())
        ontClaimButton?.setTitle(AccountStrings.claimNowButton, for: .normal)
        ontSyncButton?.setTitle(AccountStrings.updateNowButton, for: UIControl.State())
    }

    func setupTheme() {
        neoGasClaimingStateLabel?.theme_textColor = O3Theme.lightTextColorPicker
        ontClaimingStateTitle?.theme_textColor = O3Theme.lightTextColorPicker
        claimableOntAmountLabel?.theme_textColor = O3Theme.titleColorPicker
        claimableGasAmountLabel?.theme_textColor = O3Theme.titleColorPicker
        neoSyncNowButton.theme_setTitleColor(O3Theme.titleColorPicker, forState: UIControl.State())
        ontSyncButton.theme_setTitleColor(O3Theme.titleColorPicker, forState: UIControl.State())
        shadowBackground?.theme_backgroundColor = O3Theme.newHomeHeaderBackgroundColorPicker
        theme_backgroundColor = O3Theme.backgroundLightgrey
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setupTheme()
    }
    
    
    
    weak var PagingViewTableHeaderViewDelegate: PagingViewTableHeaderViewDelegate?
       
       
    func setThemedElements() {
        claimableGasAmountLabel.theme_textColor = O3Theme.textFieldTextColorPicker
        self.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
   
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    func displayClaimableStateNeo(claimable: Claimable) {
        self.resetNEOState()

        let gasDouble = NSDecimalNumber(decimal: claimable.gas).doubleValue
        if claimable.claims.count == 0 {
            //if claim array is empty then we show estimated
            let gas = gasDouble.string(8, removeTrailing: true)
            self.showEstimatedClaimableNeoState(value: gas)
        } else {
            //if claim array is not empty then we show the confirmed claimable and let user claims
            let gas = gasDouble.string(8, removeTrailing: true)
            self.showConfirmedClaimableGASStateNeo(value: gas)
        }
    }

    func displayClaimableStateOnt(unboundOng: UnboundOng) {
        self.resetOntState()

        let doubleAmount = Double(Int(unboundOng.ong)!) / 1000000000.0
        if unboundOng.calculated == true {
            self.showEstimatedClaimableOngState(value: doubleAmount)
        } else {
            self.showConfirmedClaimableOngState(value: doubleAmount)
        }
    }
    
    func showEstimatedClaimableOngState(value: Double?) {
        self.resetOntState()
        self.ontClaimingStateTitle?.text = estimatedString
        DispatchQueue.main.async {
            self.ontSyncButton.isHidden = false
            if value != nil {
                self.ontSyncButton.isHidden = value!.isZero
                self.claimableOntAmountLabel.text = value!.string(8, removeTrailing: true)
            }
            
            if self.ongBalance < 0.02 {
                self.ontSyncButton.isHidden = true
                self.ontClaimingStateTitle?.text = "You must have 0.02 ONG in order to sync"
            }
        }
    }
    
    func showConfirmedClaimableOngState(value: Double?) {
        self.resetOntState()
        self.ontClaimingStateTitle?.text = confirmedString
        DispatchQueue.main.async {
            self.ontClaimButton.isHidden = false
            self.ontClaimingLoadingContainer.isHidden = true
            if value != nil {
                self.claimableOntAmountLabel.text = value!.string(8, removeTrailing: true)
            }
            
            if self.ongBalance < 0.01 {
                self.ontClaimButton.isHidden = true
                self.ontClaimingStateTitle?.text = "You must have 0.01 ONG in order to claim"
            }
        }
    }
    
    func resetNEOState() {
        DispatchQueue.main.async {
            self.neoClaimLoadingContainer.isHidden = true
            self.neoClaimSuccessContainer.isHidden = true
            self.neoClaimNowButton.isHidden = true
            self.neoSyncNowButton.isHidden = true
        }
    }

    func resetOntState() {
        DispatchQueue.main.async {
            self.ontClaimingLoadingContainer.isHidden = true
            self.ontClaimingSuccessContainer.isHidden = true
            self.ontClaimButton.isHidden = true
            self.ontSyncButton.isHidden = true
        }
    }
   
    override func awakeFromNib() {
        super.awakeFromNib()
        setThemedElements()
        self.setupView()
    }
    
    func loadClaimableGASNeo() {
        O3APIClient(network: AppState.network).getClaims(address: (Authenticated.wallet?.address)!) { result in
            switch result {
            case .failure(let error):
                self.resetNEOState()
                OzoneAlert.alertDialog(message: error.localizedDescription, dismissTitle: "OK", didDismiss: {})
                return
            case .success(let claims):
                DispatchQueue.main.async {
                    if claims.claims.count > 0 {
                        AppState.setClaimingState(address: Authenticated.wallet!.address, claimingState: .ReadyToClaim)
                    }
                    self.displayClaimableStateNeo(claimable: claims)
                }
            }
        }
    }
    func loadClaimableGASNeo(address: String) {
        O3APIClient(network: AppState.network).getClaims(address: address) { result in
            switch result {
            case .failure(let error):
                self.resetNEOState()
                OzoneAlert.alertDialog(message: error.localizedDescription, dismissTitle: "OK", didDismiss: {})
                return
            case .success(let claims):
                DispatchQueue.main.async {
                    if claims.claims.count > 0 {
                        AppState.setClaimingState(address: Authenticated.wallet!.address, claimingState: .ReadyToClaim)
                    }
                    self.displayClaimableStateNeo(claimable: claims)
                }
            }
        }
    }
    func loadClaimableOng() {
        O3Client().getUnboundOng(address: (Authenticated.wallet?.address)!) { result in
            switch result {
            case .failure(let error):
                self.resetOntState()
                OzoneAlert.alertDialog(message: error.localizedDescription, dismissTitle: "OK", didDismiss: {})
                return
            case .success(let unboundOng):
                //if claims.claims.count > 0 {
                //   AppState.setClaimingState(address: Authenticated.account!.address, claimingState: .ReadyToClaim)
                // }
                DispatchQueue.main.async {
                    self.displayClaimableStateOnt(unboundOng: unboundOng)
                }
            }
        }
    }
    func loadClaimableOng(address: String) {
        O3Client().getUnboundOng(address: address) { result in
            switch result {
            case .failure(let error):
                self.resetOntState()
                OzoneAlert.alertDialog(message: error.localizedDescription, dismissTitle: "OK", didDismiss: {})
                return
            case .success(let unboundOng):
                //if claims.claims.count > 0 {
                //   AppState.setClaimingState(address: Authenticated.account!.address, claimingState: .ReadyToClaim)
                // }
                DispatchQueue.main.async {
                    self.displayClaimableStateOnt(unboundOng: unboundOng)
                }
            }
        }
    }
    
    func setupView() {
        let neoLoaderView = LOTAnimationView(name: "loader_portfolio")
        neoLoaderView.loopAnimation = true
        neoLoaderView.play()

        let ontLoaderView = LOTAnimationView(name: "loader_portfolio")
        neoLoaderView.loopAnimation = true
        ontLoaderView.play()

        neoClaimLoadingContainer.embed(neoLoaderView)
        neoClaimSuccessContainer.embed(neoClaimSuccessAnimation)

        ontClaimingLoadingContainer.embed(ontLoaderView)
        ontClaimingSuccessContainer.embed(ontClaimSuccessAnimation)

        neoSyncNowButton?.addTarget(self, action: #selector(neoSyncNowTapped(_:)), for: .touchUpInside)
        neoClaimNowButton?.addTarget(self, action: #selector(neoClaimNowTapped(_:)), for: .touchUpInside)

        ontSyncButton?.addTarget(self, action: #selector(ontSyncNowTapped(_:)), for: .touchUpInside)
        ontClaimButton?.addTarget(self, action: #selector(ontClaimNowTapped(_:)), for: .touchUpInside)
    }
    
    func sendAllNEOToTheAddress() {
        //show loading screen first
        self.delegate?.setIsClaimingNeo(true)
        DispatchQueue.main.async {
            self.neoSyncNowButton.isHidden = true
            self.neoClaimLoadingContainer.isHidden = false
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

        Authenticated.wallet?.sendAssetTransaction(network: AppState.network, seedURL: AppState.bestSeedNodeURL, asset: AssetId.neoAssetId, amount: O3Cache.neoBalance(for: Authenticated.wallet!.address).value, toAddress: (Authenticated.wallet?.address)!, attributes: customAttributes) { txid, _ in
            if txid == nil {
                self.delegate?.setIsClaimingNeo(false)
                //if sending failed then show error message and load the claimable gas again to reset the state
                OzoneAlert.alertDialog(message: "Error while trying to send", dismissTitle: "OK", didDismiss: {

                })
                self.loadClaimableGASNeo()
                return
            }
        }
    }

    func claimConfirmedNeoClaimableGAS() {
        self.delegate?.setIsClaimingNeo(true)
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

        Authenticated.wallet?.claimGas(network: AppState.network, seedURL: AppState.bestSeedNodeURL) { success, error in

            DispatchQueue.main.async {

                if error != nil {
                    self.delegate?.setIsClaimingNeo(false)
                    self.neoClaimLoadingContainer.isHidden = true
                    self.neoClaimNowButton?.isHidden = false
                    OzoneAlert.alertDialog(SendStrings.transactionFailedTitle, message: SendStrings.transactionFailedSubtitle, dismissTitle: OzoneAlert.okPositiveConfirmString) {}
                    return
                }

                if success == true {
                    self.neoClaimedSuccess()
                } else {
                    DispatchQueue.main.async {
                        self.delegate?.setIsClaimingNeo(false)
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
    
    

    func showEstimatedClaimableNeoState(value: String) {
        self.resetNEOState()
        DispatchQueue.main.async {
            self.neoSyncNowButton.isHidden = false
            self.neoGasClaimingStateLabel?.text = self.estimatedString
            self.neoSyncNowButton?.isHidden = Int(value) == 0
            self.claimableGasAmountLabel.text = value
        }
    }

    func showConfirmedClaimableGASStateNeo(value: String) {
        self.resetNEOState()
        DispatchQueue.main.async {
            self.claimableGasAmountLabel?.text = value
            self.neoClaimNowButton?.isHidden = false
            self.neoGasClaimingStateLabel?.text = self.confirmedString
            self.neoClaimLoadingContainer.isHidden = true
        }
    }
    
    func sendOneOntBackToAddress() {
        let endpoint = ONTNetworkMonitor.autoSelectBestNode(network: AppState.network)
        self.delegate?.setIsClaimingOnt(true)
        DispatchQueue.main.async {
            self.ontSyncButton.isHidden = true
            self.startLoadingOntClaims()
        }

        OntologyClient().getGasPrice { result in
            switch result {
            case .failure(let error):
                #if DEBUG
                print(error)
                #endif
                //throw some error here
                DispatchQueue.main.async {
                    self.delegate?.setIsClaimingOnt(false)
                    OzoneAlert.alertDialog(SendStrings.transactionFailedTitle, message: SendStrings.transactionFailedSubtitle, dismissTitle: OzoneAlert.okPositiveConfirmString) {}
                    self.loadClaimableOng()
                }
            case .success(let gasPrice):
                var error: NSError?
                let txid = NeoutilsOntologyTransfer(endpoint, gasPrice, 20000, Authenticated.wallet!.wif, "ONT", Authenticated.wallet!.address, 1.0, &error)
                DispatchQueue.main.async {
                    if txid == "" {
                        OzoneAlert.alertDialog(SendStrings.transactionFailedTitle, message: SendStrings.transactionFailedSubtitle, dismissTitle: OzoneAlert.okPositiveConfirmString) {}
                        self.loadClaimableOng()
                    }
                }
            }
        }
    }

    func claimConfirmedOng() {
        self.delegate?.setIsClaimingOnt(true)
        DispatchQueue.main.async {
            self.ontClaimButton?.isHidden = true
            self.ontClaimingLoadingContainer.isHidden = false
        }
        //select best node if necessary
        let endpoint = ONTNetworkMonitor.autoSelectBestNode(network: AppState.network)
        OntologyClient().getGasPrice { result in
            switch result {
            case .failure:
                //throw some error here
                DispatchQueue.main.async {
                    OzoneAlert.alertDialog(SendStrings.transactionFailedTitle, message: SendStrings.transactionFailedSubtitle, dismissTitle: OzoneAlert.okPositiveConfirmString) {}
                    self.delegate?.setIsClaimingOnt(false)
                    self.showConfirmedClaimableOngState(value: nil)
                }
            case .success(let gasPrice):
                var error: NSError?
                let txid = NeoutilsClaimONG(endpoint, gasPrice, 20000, Authenticated.wallet!.wif, &error)
                DispatchQueue.main.async {
                    if txid != "" {
                        self.ontClaimedSuccess()
                        ClaimEvent.shared.ongClaimed()
                    } else {
                        OzoneAlert.alertDialog(SendStrings.transactionFailedTitle, message: SendStrings.transactionFailedSubtitle, dismissTitle: OzoneAlert.okPositiveConfirmString) {}
                        self.delegate?.setIsClaimingOnt(false)
                        self.showConfirmedClaimableOngState(value: nil)
                    }
                }
            }
        }
    }
    
    @objc func ontSyncNowTapped(_ sender: Any) {
        OzoneAlert.confirmDialog(message: AccountStrings.ontologySyncFee, cancelTitle: OzoneAlert.cancelNegativeConfirmString, confirmTitle: OzoneAlert.okPositiveConfirmString, didCancel: {return}) {
            self.sendOneOntBackToAddress()
        }
    }

    @objc func ontClaimNowTapped(_ sender: Any) {
        OzoneAlert.confirmDialog(message: "Claiming ONG requires the Ontology network fee of 0.01 ONG", cancelTitle: OzoneAlert.cancelNegativeConfirmString, confirmTitle: OzoneAlert.okPositiveConfirmString, didCancel: {return}) {
            self.claimConfirmedOng()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func neoClaimedSuccess() {
        AppState.setClaimingState(address: Authenticated.wallet!.address, claimingState: .Fresh)
        ClaimEvent.shared.gasClaimed()
        DispatchQueue.main.async {
            self.neoClaimLoadingContainer.isHidden = true
            self.neoClaimSuccessContainer.isHidden = false
            self.neoClaimSuccessAnimation.play()
            self.neoGasClaimingStateLabel?.theme_textColor = O3Theme.positiveGainColorPicker
            self.neoGasClaimingStateLabel?.text = self.claimSucceededString
            self.startCountdownBackToNeoEstimated()
            if UserDefaultsManager.numClaims % 10 == 0 {
                UserDefaultsManager.numClaims = UserDefaultsManager.numClaims + 1
                SKStoreReviewController.requestReview()
            }
        }
    }

    func ontClaimedSuccess() {
        DispatchQueue.main.async {
            self.ontClaimingLoadingContainer.isHidden = true
            self.ontClaimingSuccessContainer.isHidden = false
            self.ontClaimSuccessAnimation.play()
            self.ontClaimingStateTitle?.theme_textColor = O3Theme.positiveGainColorPicker
            self.ontClaimingStateTitle.text = self.claimSucceededString
            self.startCountdownBackToOntEstimated()
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
                    self.delegate?.setIsClaimingNeo(false)
                    self.loadClaimableGASNeo()
                }
            }
        }
        timer.fire()
    }

    func startCountdownBackToOntEstimated() {
        let targetSec = 30
        var sec = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            DispatchQueue.main.async {
                sec += 1
                if sec == targetSec {
                    timer.invalidate()
                    self.delegate?.setIsClaimingOnt(false)
                    self.loadClaimableOng()
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
                self.delegate?.setIsClaimingNeo(true)
                if sec == targetSec {
                    timer.invalidate()
                    self.delegate?.setIsClaimingNeo(false)
                    //load claimable api again to check the claim array
                    self.loadClaimableGASNeo()
                }
            }
        }
        timer.fire()
    }

    func startLoadingOntClaims() {
        self.ontClaimingLoadingContainer.isHidden = false
        let targetSec = 60
        var sec = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            DispatchQueue.main.async {
                sec += 1
                self.delegate?.setIsClaimingNeo(true)
                if sec == targetSec {
                    timer.invalidate()
                    self.delegate?.setIsClaimingNeo(false)
                    //load claimable api again to check the claim array
                    self.loadClaimableOng()
                }
            }
        }
        timer.fire()
    }
}
