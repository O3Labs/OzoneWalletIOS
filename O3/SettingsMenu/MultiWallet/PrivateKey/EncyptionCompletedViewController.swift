//
//  EncyptionCompletedViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 11/5/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class EncryptionCompletedViewController: UIViewController {
    var encryptedKey = ""
    
    @IBOutlet weak var qrView: UIImageView!
    @IBOutlet weak var encryptedKeyLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var finishButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        setThemedElements()
        
        qrView.image = UIImage(qrData: encryptedKey, width: qrView.frame.width, height: qrView.frame.height, qrLogoName: "ic_QRencryptedKey")
        encryptedKeyLabel.text = encryptedKey
    }
    
    @IBAction func finishButtonTapped(_ sender: Any) {
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    
    
    func setThemedElements() {
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
        encryptedKeyLabel.theme_textColor = O3Theme.titleColorPicker
        descriptionLabel.theme_textColor = O3Theme.titleColorPicker
    }
    
    func setLocalizedStrings() {
        finishButton.setTitle(MultiWalletStrings.multiWalletFinished, for: UIControl.State())
        descriptionLabel.text = MultiWalletStrings.encryptionFinishedDescription
        title = "Encryption Complete"
        
    }
}
