//
//  LoginV2TableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 6/8/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Neoutils
import SwiftTheme
import KeychainAccess
import Channel
import PKHUD

class LoginV2TableViewController: UITableViewController, AVCaptureMetadataOutputObjectsDelegate, Nep2PasswordDelegate, UITextViewDelegate {
    @IBOutlet weak var pkeyLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var keyTextView: O3TextView!

    var alreadyScanned = false
    var qrView: UIView!
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    let supportedCodeTypes = [
        AVMetadataObject.ObjectType.qr]

    func presentNEP2Detected() {
        guard let nep2DetectedVC = UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "nep2DetectedViewController") as? NEP2DetectedViewController else {
            return
        }
        nep2DetectedVC.modalPresentationStyle = .overCurrentContext
        nep2DetectedVC.modalTransitionStyle = .crossDissolve
        nep2DetectedVC.delegate = self
        nep2DetectedVC.nep2EncryptedKey = keyTextView.text.trim()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.presentFromEmbedded(nep2DetectedVC, animated: true, completion: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        keyTextView.delegate = self
        loginButton.isEnabled = false
        self.navigationController?.hideHairline()
        let qrView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height * 0.5))
        tableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height * 0.5)
        tableView.tableHeaderView?.embed(qrView)
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        if captureDevice == nil {
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)

            captureSession = AVCaptureSession()
            captureSession.addInput(input)

            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes

            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer.frame = qrView.layer.bounds
            qrView.layer.insertSublayer(videoPreviewLayer!, at: 0)

            captureSession!.startRunning()
        } catch {
            return
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        if textView.text.trim() == "" {
            loginButton.isEnabled = false
            loginButton.backgroundColor = Theme.light.disabledColor
        } else {
            loginButton.isEnabled = true
            loginButton.backgroundColor = Theme.light.accentColor
        }
    }

    func instantiateMainAsNewRoot() {
        DispatchQueue.main.async {
            UIApplication.shared.keyWindow?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        }
    }

    func passwordEntered(account: Account?) {
        self.alreadyScanned = false
        if account != nil {
            loginToApp(account: account!)
        }
    }

    func loginToApp(account: Account) {
        dismissKeyboard()

        let keychain = Keychain(service: "network.o3.neo.wallet")
        Authenticated.account = account
        Channel.pushNotificationEnabled(true)
        DispatchQueue.main.async {
            HUD.show(.labeledProgress(title: nil, subtitle: OnboardingStrings.selectingBestNodeTitle))
        }

        DispatchQueue.global(qos: .background).async {
            if let bestNode = NEONetworkMonitor.autoSelectBestNode(network: AppState.network) {
                AppState.bestSeedNodeURL = bestNode
            }
            DispatchQueue.main.async {
                HUD.hide()
                do {
                    //save pirivate key to keychain
                    try keychain
                        .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                        .set(account.wif, key: AppState.protectedKeyValue)
                    SwiftTheme.ThemeManager.setTheme(index: UserDefaultsManager.themeIndex)
                    self.instantiateMainAsNewRoot()
                } catch _ {
                    return
                }
            }
        }
    }

    @IBAction func cancelTapped(_ sender: Any) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }

    func invalidKeyDetected() {
        DispatchQueue.main.async {
            OzoneAlert.alertDialog(message: OnboardingStrings.invalidKey, dismissTitle: OzoneAlert.okPositiveConfirmString) {
                self.alreadyScanned = false
            }
        }
    }

    func attemptLoginWithKey(key: String) {
        if key.count == 58 && key.hasPrefix("6P") {
            DispatchQueue.main.async {
                self.presentNEP2Detected()
            }
        } else if let account = Account(wif: key) {
            loginToApp(account: account)
        } else {
            invalidKeyDetected()
        }
    }

    @IBAction func loginTapped(_ sender: Any) {
        attemptLoginWithKey(key: keyTextView.text.trim())
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count == 0 {
            return
        }

        guard let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject else {
            return
        }

        if supportedCodeTypes.contains(metadataObj.type) {
            if !alreadyScanned {
                if let dataString = metadataObj.stringValue {
                    keyTextView.text = dataString.trim()
                    alreadyScanned = true
                    attemptLoginWithKey(key: dataString)
                }
            }
        }
    }

    func setLocalizedStrings() {
        title = OnboardingStrings.loginTitle
        pkeyLabel.text = OnboardingStrings.privateKeyTitle
        loginButton.setTitle(OnboardingStrings.loginTitle, for: UIControl.State())
    }
}
