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

class ClaimableGASTableViewCell: UITableViewCell {
    
    @IBOutlet var loaderView: UIView?
    @IBOutlet var estimatedClaimableGASContainer: UIView?
    @IBOutlet var confirmedClaimableGASContainer: UIView?
    @IBOutlet var successContainer: UIView?
    @IBOutlet var animationView: LOTAnimationView?
    @IBOutlet var progressBar: UIProgressView?
    @IBOutlet var progressBarBackToEstimated: UIProgressView?
    
    @IBOutlet var syncNowButton: UIButton?
    @IBOutlet var claimNowButton: UIButton?
    @IBOutlet var estimatedClaimableGASLabel: UILabel?
    @IBOutlet var confirmedClaimableGASLabel: UILabel?
    @IBOutlet var successClaimableGASLabel: UILabel?
    @IBOutlet var claimingActivityIndicator: UIActivityIndicatorView?
    
    @IBOutlet var estimatedTitle: UILabel?
    @IBOutlet var confirmedTitle: UILabel?
    @IBOutlet var estimatedClaimableGASTitle: UILabel?
    @IBOutlet var confirmedClaimableGASTitle: UILabel?
    @IBOutlet var loadingTitle: UILabel?
    @IBOutlet var gasClaimedSuccessTitle: UILabel?
    @IBOutlet var gasClaimedSuccessSubTitle: UILabel?
    
    func setupLocalizedStrings() {
        estimatedTitle?.text = AccountStrings.estimatedClaimableGasTitle
        estimatedClaimableGASTitle?.text = AccountStrings.claimableGasTitle
        syncNowButton?.setTitle(AccountStrings.updateNowButton, for: .normal)
        
        loadingTitle?.text = AccountStrings.checkingForClaimableDataLoadingTitle
        
        confirmedTitle?.text = AccountStrings.confirmedClaimableGasTitle
        confirmedClaimableGASTitle?.text = AccountStrings.claimableGasTitle
        claimNowButton?.setTitle(AccountStrings.claimNowButton, for: .normal)
        
        gasClaimedSuccessTitle?.text = AccountStrings.successClaimTitle
        gasClaimedSuccessSubTitle?.text = AccountStrings.successClaimSubTitle
        
    }
    
    func setupTheme() {
        estimatedClaimableGASLabel?.theme_textColor = O3Theme.titleColorPicker
        confirmedClaimableGASLabel?.theme_textColor = O3Theme.titleColorPicker
        successClaimableGASLabel?.theme_textColor = O3Theme.titleColorPicker
        
        loaderView?.theme_backgroundColor = O3Theme.backgroundColorPicker
        estimatedClaimableGASContainer?.theme_backgroundColor = O3Theme.backgroundColorPicker
        confirmedClaimableGASContainer?.theme_backgroundColor = O3Theme.backgroundColorPicker
        successContainer?.theme_backgroundColor = O3Theme.backgroundColorPicker
        contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.setupTheme()
    }
    
    func setupView() {
        estimatedClaimableGASContainer?.isHidden = false
        loaderView?.isHidden = true
        confirmedClaimableGASContainer?.isHidden = true
        successContainer?.isHidden = true
        syncNowButton?.addTarget(self, action: #selector(syncNowTapped(_:)), for: .touchUpInside)
        claimNowButton?.addTarget(self, action: #selector(claimNowTapped(_:)), for: .touchUpInside)
    }
    
    func resetState() {
        self.claimingActivityIndicator?.stopAnimating()
        self.claimNowButton?.isHidden = false
        self.progressBar?.progress = 0
        self.progressBarBackToEstimated?.progress = 0
        self.estimatedClaimableGASContainer?.isHidden = true
        self.loaderView?.isHidden = true
        self.confirmedClaimableGASContainer?.isHidden = true
        self.successContainer?.isHidden = true
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupLocalizedStrings()
        self.setupView()
    }
    
    
    func loadClaimableGAS() {
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
                    self.displayClaimableState(claimable: claims)
                }
            }
        }
    }
    
    func displayClaimableState(claimable: Claimable) {
        self.resetState()
      
//        //if user already sent NEO to the address and waiting for the claimable data then we show the loading
//        if AppState.claimingState(address: Authenticated.account!.address) == .WaitingForClaimableData {
//            self.startLoading()
//            return
//        }
        
        
        let gasDouble = NSDecimalNumber(decimal: claimable.gas).doubleValue
        if claimable.claims.count == 0 {
            //if claim array is empty then we show estimated
            let gas = gasDouble.string(8, removeTrailing: true)
            self.showEstimatedClaimableGASState(value: gas)
            if gasDouble.isZero {
                self.syncNowButton?.isEnabled = false
            } else {
                self.syncNowButton?.isEnabled = true
            }
            return
        }
        
        //if claim array is not empty then we show the confirmed claimable and let user claims
        let gas = gasDouble.string(8, removeTrailing: true)
        self.showConfirmedClaimableGASState(value: gas)
    }
    
    func showEstimatedClaimableGASState(value: String) {
        self.resetState()
        self.estimatedClaimableGASContainer?.isHidden = false
        self.estimatedClaimableGASLabel?.text = value
    }
    
    func showConfirmedClaimableGASState(value: String) {
        self.resetState()
        self.confirmedClaimableGASContainer?.isHidden = false
        self.confirmedClaimableGASLabel?.text = value
        self.successClaimableGASLabel?.text = value
        
    }
    
    func sendAllNEOToTheAddress() {
        
        //show loading screen first
        DispatchQueue.main.async {
            self.startLoading()
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
        
        Authenticated.account?.sendAssetTransaction(network: AppState.network, seedURL: AppState.bestSeedNodeURL, asset: AssetId.neoAssetId, amount: O3Cache.neo().value, toAddress: (Authenticated.account?.address)!, attributes: customAttributes) { completed, _ in
            if completed == false {
                //if sending failed then show error message and load the claimable gas again to reset the state
                OzoneAlert.alertDialog(message: "Error while trying to send", dismissTitle: "OK", didDismiss: {
                    
                })
                self.loadClaimableGAS()
                return
            }
        }
    }
    
    
    func claimConfirmedClaimableGAS() {
        self.claimNowButton?.isHidden = true
        self.claimingActivityIndicator?.startAnimating()
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
                    self.claimingActivityIndicator?.stopAnimating()
                    self.claimNowButton?.isHidden = false
                    //TODO show error dialog
                    OzoneAlert.alertDialog(message: "Error while trying to claim", dismissTitle: "OK", didDismiss: {
                        
                    })
                    return
                }
                
                if success == true {
                    
                    self.claimedSuccess()
                    
                    Answers.logCustomEvent(withName: "Gas Claimed",
                                           customAttributes: ["Amount": self.confirmedClaimableGASLabel?.text ?? ""])
                } else {
                    //TODO figure out when success == false
                    OzoneAlert.alertDialog(message: "Error while trying to claim. Please try again later", dismissTitle: "OK", didDismiss: {
                        
                    })
                    return
                }
            }
        }
    }
    
    @objc @IBAction func syncNowTapped(_ sender: Any) {
        self.sendAllNEOToTheAddress()
    }
    
    @objc @IBAction func claimNowTapped(_ sender: Any) {
        self.claimConfirmedClaimableGAS()
    }
    
    func claimedSuccess() {
        AppState.setClaimingState(address: Authenticated.account!.address, claimingState: .Fresh)
        self.confirmedClaimableGASContainer?.isHidden = true
        self.successContainer?.isHidden = false
        startCountdownBackToEstimated()
    }
    
    func startCountdownBackToEstimated() {
        let targetSec = 60
        var sec = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            DispatchQueue.main.async {
                sec += 1
                let percent = ((Float(sec) * 100.0) / Float(targetSec)) / 100.0
                self.progressBarBackToEstimated?.setProgress(percent, animated: true)
                if sec == targetSec {
                    timer.invalidate()
                    self.loadClaimableGAS()
                }
            }
        }
        timer.fire()
    }
    
    func startLoading(){
        self.loaderView?.isHidden = false
        self.estimatedClaimableGASContainer?.isHidden = true
        
        animationView?.layer.transform = CATransform3DScale(CATransform3DMakeRotation(0, 0, 0, 0), -1, 1, 1)
        animationView?.loopAnimation = true
        animationView?.play()
        
        let targetSec = 60
        var sec = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            DispatchQueue.main.async {
                sec += 1
                let percent = ((Float(sec) * 100.0) / Float(targetSec)) / 100.0
                self.progressBar?.setProgress(percent, animated: true)
                if sec == targetSec {
                    timer.invalidate()
                    //load claimable api again to check the claim array
                    self.loadClaimableGAS()
                }
            }
        }
        timer.fire()
    }
    
}
