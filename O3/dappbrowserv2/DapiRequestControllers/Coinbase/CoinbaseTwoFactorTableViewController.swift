//
//  CoinbaseTwoFactorTableViewControlller.swift
//  O3
//
//  Created by Andrei Terentiev on 6/17/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Lottie

class CoinbaseTwoFactorTableViewController: UITableViewController {
    
    @IBOutlet weak var twoFactorTitleLabel: UILabel!
    @IBOutlet weak var twoFactorEntryTextField: O3FloatingTextField!
    
    @IBOutlet weak var sendResultContainerView: UIView!
    @IBOutlet weak var resultAnimationContainerView: UIView!
    @IBOutlet weak var resultTitleLabel: UILabel!
    @IBOutlet weak var resultSubtitleLabel: UILabel!
    
    @IBOutlet weak var twoFactorErrorLabel: UILabel!
    @IBOutlet weak var headerView: UIView!
    let successAnimation = LOTAnimationView(name: "Transaction_Sent")
    let failureAnimation = LOTAnimationView(name: "coinbase_error" )
    
    var message: dAppMessage!
    var request: dAppProtocol.CoinbaseSendRequest!
    
    var onCancel: ((_ message: dAppMessage, _ request: dAppProtocol.CoinbaseSendRequest)->())?
    var onCompleted: ((_ response: dAppProtocol.CoinbaseSendResponse?, _ error: dAppProtocol.errorResponse?)->())?
    
    enum TwoFactorState {
        case SUCCESS
        case FAIL
        case NEED2FA
    }
    
    var state: TwoFactorState = .NEED2FA
    var errorMessage: String?
    
    let TWO_FACTOR_FAILED_MESSAGE = "Verification code error - That code was invalid. Please try again."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        setThemedElements()
        
        twoFactorErrorLabel.isHidden = true
        
        navigationItem.hidesBackButton = true
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.reloadData()
        
        switch state {
        case .SUCCESS: showSuccessState()
        case .FAIL: showErrorState(errorMessage: errorMessage ?? "")
        case .NEED2FA: return //default state do nothing
        }
    }
    
    @IBAction func resultFinishTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.onCancel?(message, request)
        self.dismiss(animated: true)
    }
    
    func showErrorState(errorMessage: String) {
        DispatchQueue.main.async {
            self.resultAnimationContainerView.embed(self.failureAnimation)
            self.sendResultContainerView.theme_backgroundColor = O3Theme.backgroundColorPicker
            self.sendResultContainerView.isHidden = false
            self.resultTitleLabel.text = "Transaction Failed"
            self.resultSubtitleLabel.text = errorMessage
            self.resultTitleLabel.theme_textColor = O3Theme.negativeLossColorPicker
            self.resultSubtitleLabel.theme_textColor = O3Theme.negativeLossColorPicker
            self.headerView.bringSubviewToFront(self.sendResultContainerView)
            self.failureAnimation.loopAnimation = false
            self.failureAnimation.play()
            self.onCompleted?(nil, dAppProtocol.errorResponse(error: errorMessage))
        }
    }
    
    func showSuccessState() {
        DispatchQueue.main.async {
            self.resultAnimationContainerView.embed(self.successAnimation)
            self.sendResultContainerView.theme_backgroundColor = O3Theme.backgroundColorPicker
            self.sendResultContainerView.isHidden = false
            self.resultTitleLabel.text = "Transaction Succeeded"
            self.resultTitleLabel.theme_textColor = O3Theme.positiveGainColorPicker
            self.headerView.bringSubviewToFront(self.sendResultContainerView)
            self.successAnimation.loopAnimation = true
            self.successAnimation.play()
        }
    }
    
    func showIncorrectTwoFactorState() {
        DispatchQueue.main.async {
            self.twoFactorErrorLabel.isHidden = false
        }
    }

    
    @IBAction func sendButtonTapped(_ sender: Any) {
        DispatchQueue.main.async {
            self.twoFactorErrorLabel.isHidden = true
        }
        
        CoinbaseClient.shared.send(amount: request.amount, to: request.to, currency: request.asset.symbol, twoFactorToken: twoFactorEntryTextField.text!) { result in
            switch result {
            case .failure(let e):
                //need special case if two factor error
                if let id = (e as? CoinbaseSpecificError)?.id {
                    if id == "invalid_request" && (e as! CoinbaseSpecificError).message == self.TWO_FACTOR_FAILED_MESSAGE {
                        self.showIncorrectTwoFactorState()
                    } else {
                        self.showErrorState(errorMessage: (e as! CoinbaseSpecificError).message)
                    }
                } else {
                    self.showErrorState(errorMessage: e.localizedDescription)
                }
                
                print(e)
                return
            case .success(let response):
                print (response)
                let dapiResult = dAppProtocol.CoinbaseSendResponse(result: response, txid: nil)
                self.showSuccessState()
                self.onCompleted?(dapiResult, nil)
                return
            }
        }
    }
    
    func setLocalizedStrings() {
        twoFactorEntryTextField.placeholder = "Two Factor Code"
        twoFactorTitleLabel.text = "Enter your two factor code to complete the transaction"
        twoFactorErrorLabel.text = "Invalid code, please try again"
    }
    
    func setThemedElements() {
        sendResultContainerView.theme_backgroundColor = O3Theme.backgroundColorPicker
        twoFactorTitleLabel.theme_textColor = O3Theme.titleColorPicker
        
    }
}
