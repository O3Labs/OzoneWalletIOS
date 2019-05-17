//
//  ReferralLinkViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 5/8/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class ReferralLinkViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var referralDescriptionLabel: UILabel!
    @IBOutlet weak var learnMoreButton: UIButton!
    @IBOutlet weak var referralLinkHeaderLabel: UILabel!
    @IBOutlet weak var referralInputField: UITextField!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var heroImage: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setThemedElements()
        setLocalizedStrings()
        referralInputField.delegate = self
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        let shareURL = URL(string: "https://buy.o3.network/?ref=" + Authenticated.wallet!.address)
        let activityViewController = UIActivityViewController(activityItems: [shareURL as Any], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        self.dismissTapped()
    }
    
    @IBAction func learnMoreTapped(_ sender: Any) {
        Controller().openDappBrowserV2(url: URL(string: "https://www.o3.network")!)
    }
    
    func setThemedElements() {
        
        referralDescriptionLabel.theme_textColor = O3Theme.lightTextColorPicker
        referralLinkHeaderLabel.theme_textColor = O3Theme.titleColorPicker
        
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
        referralInputField.theme_placeholderAttributes = O3Theme.placeholderAttributesPicker
        referralInputField.theme_textColor = O3Theme.textFieldTextColorPicker
        referralInputField.theme_keyboardAppearance = O3Theme.keyboardPicker
        referralInputField.theme_backgroundColor = O3Theme.textFieldBackgroundColorPicker
        
    }
    
    func setLocalizedStrings() {

        referralDescriptionLabel.text = "For every friend that uses your referral code to buy NEO, O3 will give you and your friend a small gas gift"
        learnMoreButton.setTitle("Learn more here", for: UIControl.State())
        referralLinkHeaderLabel.text = "Your referral link"
        shareButton.setTitle("Share", for: UIControl.State())
        referralInputField.text = "https://buy.o3.network/?ref=" + Authenticated.wallet!.address
        referralInputField.inputView = UIView()   //prevents keyboard
        referralInputField.tintColor = .clear
        
    }
}
