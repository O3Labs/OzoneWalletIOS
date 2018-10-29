//
//  MultiWalletStrings.swift
//  O3
//
//  Created by Andrei Terentiev on 10/25/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation

struct MultiWalletStrings {
    static let activateMultiWalletTitle = NSLocalizedString("MULTIWALLET_activate_multiwallet_title", comment: "title for activating multiwallet page")
    static let activateMultiWalletSubtitle = NSLocalizedString("MULTIWALLET_activate_multiwallet_subtitle", comment: "subtitle for activating multiwallet")
    static let passwordInputHint = NSLocalizedString("MULTIWALLET_password_hint", comment: "Input hint for when making password to generate encrypted ket")
    static let verifyPasswordInputHint = NSLocalizedString("MULTIWALLET_password_verify_hint", comment: "Input hint for when verifying password to generate encrypted key")
    static let activateMultiWalletInfo = NSLocalizedString("MULTIWALLET_activate_info", comment: "additional info about what will happen when multiwallet is activated")
    static let generateEncryptedKey = NSLocalizedString("MULTIWALLET_generate_encrypted_key", comment: "Button title to generate an encrypted key when activating multiwallet")
    
    static let backupEncryptedKey = NSLocalizedString("MULTIWALLET_backup_encrypted_key", comment: "Button title to backup up encrypted key and nep6 file")
    static let multiWalletGeneratedDescription = NSLocalizedString("MULTIWALLET_generated_decription", comment: "description text after a multi wallet has been generated")
    static let multiWalletFinished = NSLocalizedString("MULTIWALLET_finished", comment: "button title after finished multiwallet creation")
    
    static let watchAddressAdded = NSLocalizedString("MULTIWALLET_watch_address_added", comment: "A description to display after a watch address has been successfully added")
    
    static let invalidWalletEntry = NSLocalizedString("MULTIWALLET_invalid_wallet_entry", comment: "error text when they enter text that can't be parsed as a key or address")
    static let addWalletDecription = NSLocalizedString("MULTIWALLET_add_wallet_description", comment: "Description text when adding more wallets to your multi wallet")
    static let encryptedKeyDetected = NSLocalizedString("MULTIWALLET_encrypted_key_detected", comment: "Description when an encrypted key is detected in multiwallet add")
    static let encryptedPasswordHint = NSLocalizedString("MULTIWALLET_encrypted_password_hint", comment: "Hint for entering encrypted key password in multiwallet setup")
    static let continueAction = NSLocalizedString("MULTIWALLET_continue", comment: "text for continue action")
    
    static let failedToDecrypt = NSLocalizedString("MULTIWALLET_failed_to_decrypt", comment: "error alert after failing to decrrypt the encrypted key")
    
    static let setWalletNameTitle = NSLocalizedString("MULTIWALLET_set_wallet_title", comment: "description of adding a name to a wallet title")
}
