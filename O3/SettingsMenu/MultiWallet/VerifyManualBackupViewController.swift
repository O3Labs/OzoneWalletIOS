//
//  VerifyManualBackupViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 1/10/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import M13Checkbox

class VerifyManualBackupViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var screenshotLabel: UILabel!
    @IBOutlet weak var byHandLabel: UILabel!
    @IBOutlet weak var otherLabel: UILabel!
    
    
    @IBOutlet weak var screenshotCheckbox: M13Checkbox!
    @IBOutlet weak var byHandCheckbox: M13Checkbox!
    @IBOutlet weak var otherCheckbox: M13Checkbox!
    
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    var address: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        screenshotCheckbox.addTarget(self, action: #selector(checkboxValueChanged(_:)), for: .valueChanged)
        byHandCheckbox.addTarget(self, action: #selector(checkboxValueChanged(_:)), for: .valueChanged)
        otherCheckbox.addTarget(self, action: #selector(checkboxValueChanged(_:)), for: .valueChanged)
        
        switch AppState.getManualVerifyType(address: address) {
        case .screenshot: screenshotCheckbox.setCheckState(.checked, animated: true)
        case .byHand: byHandCheckbox.setCheckState(.checked, animated: true)
        case .other: otherCheckbox.setCheckState(.checked, animated: true)
        default: break
        }
        
        setThemedElements()
        setLocalizedStrings()

    }
    
    @objc func checkboxValueChanged(_ sender: M13Checkbox) {
        if sender.checkState == .checked {
            for checkbox in [screenshotCheckbox, byHandCheckbox, otherCheckbox] {
                if sender != checkbox {
                    DispatchQueue.main.async {
                            checkbox?.setCheckState(.unchecked, animated: true)
                    }

                }
            }
        }
        
        if screenshotCheckbox.checkState == .checked || byHandCheckbox.checkState == .checked || otherCheckbox.checkState == .checked {
            verifyButton.isEnabled = true
        } else {
            verifyButton.isEnabled = false
        }
    }
    
    @IBAction func verifyTapped(_ sender: Any) {
        AppState.setDismissBackupNotification(dismiss: true)
        if screenshotCheckbox.checkState == .checked {
            AppState.setManualVerifyType(address: address, type: .screenshot)
        } else if byHandCheckbox.checkState == .checked {
            AppState.setManualVerifyType(address: address, type: .byHand)
        } else if otherCheckbox.checkState == .checked {
            AppState.setManualVerifyType(address: address, type: .other)
        }
        
        self.dismiss(animated: true)
    }
    
    func setLocalizedStrings() {
        screenshotLabel.text = "I took a screenshot"
        byHandLabel.text = "I copied it by hand"
        otherLabel.text = "I saved it another way"
        
        cancelButton.setTitle("Cancel", for: UIControl.State())
        verifyButton.setTitle("Verify Backup", for: UIControl.State())
        
        titleLabel.text = "A manual backup can be performed by saving your key, in another secure place. Please verify that you've saved the key using one of the options below. If you lose your private key it cannot be recovered"
    }
    
    func setThemedElements() {
        applyBottomSheetNavBarTheme(title: "Verify Backup")
    }
}
