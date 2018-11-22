//
//  ConvertToWalletTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 10/31/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Neoutils
import SwiftTheme
import KeychainAccess
import Channel

class ConvertToWalletTableViewController: UITableViewController, AVCaptureMetadataOutputObjectsDelegate, Nep2PasswordDelegate, UITextViewDelegate {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var keyTextView: O3TextView!
    @IBOutlet weak var pkeyLabel: UILabel!
    @IBOutlet weak var convertButton: UIButton!
    
    let nep6 = NEP6.getFromFileSystem()!
    var watchAddress = ""
    var encryptedKey = ""
    
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
        encryptedKey = keyTextView.text.trim()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.presentFromEmbedded(nep2DetectedVC, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        setThemedElements()
        keyTextView.delegate = self
        convertButton.isEnabled = false
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
            convertButton.isEnabled = false
            convertButton.backgroundColor = Theme.light.disabledColor
        } else {
            convertButton.isEnabled = true
            convertButton.backgroundColor = Theme.light.accentColor
        }
    }
    
    func passwordEntered(account: Wallet?) {
        if  account?.address ?? "" != watchAddress {
            //error this priate key unlocks a different wallet
            return
        }
        self.nep6.convertWatchAddrToWallet(addr: account!.address, key: encryptedKey)
        self.nep6.writeToFileSystem()
        self.navigationController?.popViewController(animated: true)
    }
    
    func updateNep6(account: Wallet) {
        dismissKeyboard()
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func invalidKeyDetected() {
        DispatchQueue.main.async {
            OzoneAlert.alertDialog(message: OnboardingStrings.invalidKey, dismissTitle: OzoneAlert.okPositiveConfirmString) {
                self.alreadyScanned = false
            }
        }
    }
    
    func inputPassword(wif: String) {
        let alertController = UIAlertController(title: "Make a password", message: "some message", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: OzoneAlert.okPositiveConfirmString, style: .default) { (_) in
            let inputPass = alertController.textFields?[0].text!
            let inputVerifyPass = alertController.textFields?[1].text!
            var error: NSError?
            if inputPass != inputVerifyPass {
                OzoneAlert.alertDialog("Passwords do not match", message: "Please check your passphrase and try again", dismissTitle: "Ok") {}
                return
            }
            
            
            if inputPass == inputVerifyPass && inputPass!.count >= 8 {
                var error: NSError?
                let key = NeoutilsNEP2Encrypt(wif, inputPass, &error)
                self.nep6.convertWatchAddrToWallet(addr: self.watchAddress, key: key!.encryptedKey())
                self.nep6.writeToFileSystem()
                self.navigationController?.popViewController(animated: true)
            } else {
                OzoneAlert.alertDialog("Incorrect passphrase", message: "Please check your passphrase and try again", dismissTitle: "Ok") {}
            }
        }
        
        let cancelAction = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Verify Password"
            textField.isSecureTextEntry = true
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        UIApplication.shared.keyWindow?.rootViewController?.presentFromEmbedded(alertController, animated: true, completion: nil)
    }
    
    func attemptLoginWithKey(key: String) {
        if key.count == 58 && key.hasPrefix("6P") {
            DispatchQueue.main.async {
                self.presentNEP2Detected()
            }
        } else if let account = Wallet(wif: key) {
            if  account.address != watchAddress {
                //error this priate key unlocks a different wallet
            } else {
                inputPassword(wif: key)
            }
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
                    DispatchQueue.main.async {
                        self.keyTextView.text = dataString.trim()
                        self.convertButton.isEnabled = true
                        self.convertButton.backgroundColor = Theme.light.accentColor
                        self.alreadyScanned = true
                        self.attemptLoginWithKey(key: dataString)
                    }
                }
            }
        }
    }
    
    func setThemedElements() {
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        pkeyLabel.theme_textColor = O3Theme.titleColorPicker
        keyTextView.theme_backgroundColor = O3Theme.textFieldBackgroundColorPicker
        keyTextView.theme_textColor = O3Theme.textFieldTextColorPicker
        keyTextView.theme_keyboardAppearance = O3Theme.keyboardPicker
        contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
    
    func setLocalizedStrings() {
        title = OnboardingStrings.loginTitle
        pkeyLabel.text = OnboardingStrings.privateKeyTitle
        convertButton.setTitle(OnboardingStrings.loginTitle, for: UIControl.State())
    }
}
