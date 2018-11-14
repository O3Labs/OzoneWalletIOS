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

    static let address = NSLocalizedString("MULTIWALLET_Address", comment: "address title label" )
    static let backupWallet = NSLocalizedString("MULTIWALLET_backup_wallet", comment: "title to backup a saved wallet again")
    static let showRawKey = NSLocalizedString("MULTIWALLET_show_raw_key", comment: "title to show the raw private key of a wallet")
    static let removeWallet = NSLocalizedString("MULTIWALLET_remove_wallet", comment: "title to remove wallet")
    static let addKey = NSLocalizedString("MULTIWALLET_add_key", comment: "title to add key to a watch only address")
    static let Wallets = NSLocalizedString("MULTIWALLET_wallets", comment: "title for manage wallets bottom sehet")
    
    static let deleteEncryptedConfirm = NSLocalizedString("MULTIWALLET_delete_encrypted_confirm", comment: "message to display warning deleting encrypted cannot be undone")
    
    static let cannotDeletePrimary = NSLocalizedString("MULTIWALLET_cannot_delete_primary", comment: "message stating that you cant delete primary key")
    
    static let deleteWatchAddress = NSLocalizedString("MULTIWALLET_delete_watch_addr", comment: "conforim title for when you want to delete your watch address")
    
    static let encryptedKey = NSLocalizedString("MULTIWALLET_encrypted_key", comment: "encrypted key title")
    static let addKeyDescription = NSLocalizedString("MULTIWALLET_add_key_description", comment: "description for adding key to a watch address")
    
    static let editName = NSLocalizedString("MUTLIWALLET_edit_name", comment: "Title to edit name in multiwallet")
    static let enterNewName = NSLocalizedString("MULTIWALLET_enter_new_name", comment: "Description when entering a new name")
    static let myWalletPlaceholder = NSLocalizedString("MULTIWALLET_my_wallet_placeholder", comment: "placeholder for when entering a new name for wallet")
    
    static let newWallet = NSLocalizedString("MULTIWALLET_new_wallet", comment: "button title to create a new wallet")
    
    static let encryptionFinishedDescription = NSLocalizedString("MULTIWALLET_encryption_finished_decription", comment: "Description for when you have finished encrypting a private key and storing it in NEP5")
    
    static let cannotAddDuplicate = NSLocalizedString("MULTIWALLET_cannot_add_duplicate", comment: "You cannot add the same wallet twice.")
}
