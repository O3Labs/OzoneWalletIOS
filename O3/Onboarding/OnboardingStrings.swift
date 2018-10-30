//
//  OnboardingStrings.swift
//  O3
//
//  Created by Andrei Terentiev on 4/27/18.
//  Copyright © 2018 drei. All rights reserved.
//

import Foundation

struct OnboardingStrings {
    //Landing Screen
    static let landingTitleOne = NSLocalizedString("ONBOARDING_Landing_Title_One", comment: "The first title in the landing pages")
    static let landingTitleTwo = NSLocalizedString("ONBOARDING_Landing_Title_Two", comment: "The second title in the landing pages")
    static let landingTitleThree = NSLocalizedString("ONBOARDING_Landing_Title_Three", comment: "The third title in the landing pages")
    static let landingTitleFour = NSLocalizedString("ONBOARDING_Landing_Title_Four", comment: "The foruth title in the landing pages")
    static let landingTitleFive = NSLocalizedString("ONBOARDING_Landing_Title_Five", comment: "The fifth title in the landing pages")

    static let landingSubtitleOne = NSLocalizedString("ONBOARDING_Landing_Subtitle_One", comment: "The first subtitle in the landing pages")
    static let landingSubtitleTwo = NSLocalizedString("ONBOARDING_Landing_Subtitle_Two", comment: "The second subtitle in the landing pages")
    static let landingSubtitleThree = NSLocalizedString("ONBOARDING_Landing_Subtitle_Three", comment: "The third subtitle in the landing pages")
    static let landingSubtitleFour = NSLocalizedString("ONBOARDING_Landing_Subtitle_Four", comment: "The fourth subtitle in the landing pages")
    static let landingSubtitleFive = NSLocalizedString("ONBOARDING_Landing_Subtitle_Five", comment: "The fifth subtitle in the landing pages")

    static let loginTitle = NSLocalizedString("ONBOARDING_Login_Title", comment: "Title for all login items in the onboarding flow")
    static let createNewWalletTitle = NSLocalizedString("ONBOARDING_Create_New _Wallet", comment: "Title For Creating a New Wallet in the onboarding flow")

    static let stylizedOr = NSLocalizedString("ONBOARDING_OR", comment: "Seperator for login and create new wallet")

    //Login Screen
    static let encryptedKeyDetected = NSLocalizedString("ONBOARDING_encrypted_key_detected", comment: "Title for when user tries to login with encrypted key")
    static let pleaseEnterNEP2Password = NSLocalizedString("ONBOARDING_please_enter_nep2_password", comment: "Subtitle for when unlocking the nep2 key")
    static let submit = NSLocalizedString("ONBOARDING_submit", comment: "Title for button to decrypt private key and continue itno app")
    static let privateKey = NSLocalizedString("ONBOARDING_private_key", comment: "A label for entering the private key field, can be NEP2 or WIF")
    static let invalidKey = NSLocalizedString("ONBOARDING_invalid_key", comment: "An alert message for when an invalid key is detected")

    //Tutorial Screen
    static let walletGenerated = NSLocalizedString("ONBOARDING_Wallet_Generated", comment: "Title for wallet generated popup")
    static let pleaseTakeAMoment = NSLocalizedString("ONBOARDING_Please_Take_A_Moment", comment: "Please take a moment to make a backup of your private key")
    static let gotIt = NSLocalizedString("ONBOARDING_got_it", comment: "Ok got it")

    static let titleAnimationHeader = NSLocalizedString("ONBOARDING_Title_Animation_Header", comment: "Title for the animation header when learning more")
    static let subtitleAnimationHeader = NSLocalizedString("ONBOARDING_Subtitle_Animation_Header", comment: "Subtitle for the animation header when learning more")
    static let learnMore = NSLocalizedString("ONBOARDING_Learn_More", comment: "Title for learn more buttong")
    static let backupAndContinue = NSLocalizedString("ONBOARDING_backup_and_continue", comment: "Tutle for backing private key and moving to end")

    static let tutorialTitleOne = NSLocalizedString("ONBOARDING_Tutorial_Title_One", comment: "Title for the first tutorial card when creating new wallet")
    static let tutorialTitleTwo = NSLocalizedString("ONBOARDING_Tutorial_Title_Two", comment: "Title for the second tutorial card when creating new wallet")
    static let tutorialTitleThree = NSLocalizedString("ONBOARDING_Tutorial_Title_Three", comment: "Title for the third tutorial card when creating new wallet")
    static let tutorialTitleFour = NSLocalizedString("ONBOARDING_Tutorial_Title_Four", comment: "Title for the fourth tutorial card when creating new wallet")
    static let tutorialTitleFive = NSLocalizedString("ONBOARDING_Tutorial_Title_Five", comment: "Title for the fifth tutorial card when creating new wallet")

    static let tutorialInfoOneOne = NSLocalizedString("ONBOARDING_Tutorial_Info_One_One", comment: "Text for the first info paragraph on the first tutorial card")
    static let tutorialInfoOneTwo = NSLocalizedString("ONBOARDING_Tutorial_Info_One_Two", comment: "Text for the first info paragraph on the second tutorial card")
    static let tutorialInfoOneThree = NSLocalizedString("ONBOARDING_Tutorial_Info_One_Three", comment: "Text for the first info paragraph on the third tutorial card")
    static let tutorialInfoOneFour = NSLocalizedString("ONBOARDING_Tutorial_Info_One_Four", comment: "Text for the first info paragraph on the fourth tutorial card")
    static let tutorialInfoOneFive = NSLocalizedString("ONBOARDING_Tutorial_Info_One_Five", comment: "Text for the first info paragraph on the fifth tutorial card")

    static let tutorialInfoTwoOne = NSLocalizedString("ONBOARDING_Tutorial_Info_Two_One", comment: "Text for the second info paragraph on the first tutorial card")
    static let tutorialInfoTwoTwo = NSLocalizedString("ONBOARDING_Tutorial_Info_Two_Two", comment: "Text for the second info paragraph on the second tutorial card")
    static let tutorialInfoTwoThree = NSLocalizedString("ONBOARDING_Tutorial_Info_Two_Three", comment: "Text for the second info paragraph on the third tutorial card")
    static let tutorialInfoTwoFive = NSLocalizedString("ONBOARDING_Tutorial_Info_Two_Five", comment: "Text for the second info paragraph on the fifth tutorial card")

    static let emphasisThree = NSLocalizedString("ONBOARDING_Tutorial_Emphasis_Three", comment: "Emphasis text for the third info paragraph on the third tutorial card")
    static let emphasisFive = NSLocalizedString("ONBOARDING_Tutorial_Emphasis_Fuve", comment: "Emphasis text for the third info paragraph on the fifth tutorial card")

    static let finish = NSLocalizedString("ONBOARDING_finish", comment: "Button title to finish the tutorial")
    static let back = NSLocalizedString("ONBOARDING_back", comment: "Button title to go back in the tutorial page")

    //backup
    static let backup = NSLocalizedString("ONBOARDING_Backup", comment: "Title menu to backup private key")
    static let reccommended = NSLocalizedString("ONBOARDING_Reccommended", comment: "Text showing reccommended backup option")

    static let copiedToClipboardAlertTitle = NSLocalizedString("ONBOARDING_Copied_Title", comment: "Title for when copied to clipboard")
    static let copiedToClipboardAlertDescription = NSLocalizedString("ONBOARDING_Copied_Description", comment: "Description for when the key has been copied to your clipboard")
    static let screenShotTakenAlertTitle = NSLocalizedString("ONBOARDING_Screenshot_Alert_Title", comment: "Title for when a screenshot was taken")
    static let screenShotTakenAlertDescription = NSLocalizedString("ONBOARDING_Screenshot_Alert_Description", comment: "Description for when the screenshot was taken")

    static let backupOptionCopy = NSLocalizedString("ONBOARDING_Backup_Copy_Title", comment: "Title for option to backup the key by copying to clipboard")
    static let backupOptionEmail = NSLocalizedString("ONBOARDING_Backup_Email_Title", comment: "Title for option to backup the key by emailing an encrypted NEP2")
    static let backupOptionPaper = NSLocalizedString("ONBOARDING_Backup_Paper_Title", comment: "Title for option to backup private key using paperr")
    static let backupOptionScreenshot = NSLocalizedString("ONBOARDING_Backup_Screenshot_Title", comment: "Title for option to backup private key using screenshot")
    static let backupGoBackOption = NSLocalizedString("ONBOARDING_Backup_Go_Back", comment: "Title for option to go back and view private key")

    static let createPassword = NSLocalizedString("ONBOARDING_Create_Password_title", comment: "Title for when creating a password for encrypting your private key")
    static let reenterPassword = NSLocalizedString("ONBOARDING_Reenter_Password_title", comment: "Title for when when confirming password for NEP-2 Encryption")
    static let createPasswordDescription = NSLocalizedString("ONBOARDING_Create_Password_Description", comment: "Description for when creating a password for NEP-2 Encryption")
    static let reenterPasswordDescription = NSLocalizedString("ONBOARDING_Reenter_Password_Description", comment: "Description for when reentering password with NEP-2 Description")
    static let createPasswordHint = NSLocalizedString("ONBOARDING_Create_Password_Hint", comment: "Hint for text field when creating a password")
    static let reenterPasswordHint = NSLocalizedString("ONBOARDING_Reenter_Password_Hint", comment: "Hint for text field when reentering a password")
    static let continueButton = NSLocalizedString("ONBOARDING_Continue_Button", comment: "Continue button when creating a password")

    static let paperBackupInfoOne = NSLocalizedString("ONBOARDING_paper_backup_info_one", comment: "First Info text when confirming that writing down on paper was successful")
    static let paperBackupInfoTwo = NSLocalizedString("ONBOARDING_paper_backup_info_two", comment: "Second Info text when confirming that writing down on paper was successful")
    static let notMatchedWif = NSLocalizedString("ONBOARDING_not_matched_wif", comment: "Oh no! Looks like your backup copy doesn't match your private key. Try again, or go back to review your private key")
    static let enterPrivateKey = NSLocalizedString("ONBOARDING_enter_private_key", comment: "Title when reentering backup")

    static let emailSubject = NSLocalizedString("ONBOARDING_email_subject", comment: "Email subject when sending NEP-2 backup")
    static let emailBody = NSLocalizedString("ONBOARDING_email_body", comment: "Email body when sending Nep-2 backup")
    static let mailNotSetupTitle = NSLocalizedString("ONBOARDING_mail_not_setup_title", comment: "Title when error and mail is not yet setup")
    static let mailNotSetupMessage = NSLocalizedString("ONBOARDING_mail_not_setup_message", comment: "Message to display when the email is not setup on the phone")
    static let failedToSendEmailDescription = NSLocalizedString("ONBOARDING_failed_to_send_email", comment: "Message to display when send email could not finish correctly")
    static let invalidPasswordLength = NSLocalizedString("ONBOARDING_invalid_password_length", comment: "Message to display when password is too short")
    static let passwordMismatch = NSLocalizedString("ONBOARDING_password_mismatch", comment: "Message to display when the password is mismatched")

    //Login Screen
    static let loginNoPassCodeError = NSLocalizedString("ONBOARDING_Login_No_Passcode_Error", comment: "Error message that is displayed when the user tries to login without a passcode")
    static let createWalletNoPassCodeError = NSLocalizedString("ONBOARDING_Create_Wallet_No_Passcode_Error", comment: "Error message that is displayed when the user tries to Create a New Wallet without a passcode")
    static let loginInputInfo = NSLocalizedString("ONBOARDING_Login_Input_Info_Title", comment: "Subtitle under the text field of the login controller. Explains what to do in textfield")
    static let selectingBestNodeTitle = NSLocalizedString("ONBOARDING_Selecting_Best_Node", comment: "Displayed when the app is waiting to connect to the network. It is finding the best NEO node to connect to")

    //Welcome Screen
    static let keychainFailureError = NSLocalizedString("ONBOARDING_Keychain_Failure_Error", comment: "Error message to display when the system fails to retrieve the private key from the keychain")
    static let haveSavedPrivateKeyConfirmation =
        NSLocalizedString("ONBARDING_Confirmed_Private_Key_Saved_Prompt", comment: "A prompt asking the user to please confirm that they have indeed backed up their private key in a secure location before continuing")
    static let pleaseBackupWarning = NSLocalizedString("ONBOARDING_Please_Backup Warning", comment: "A warning given to the user to make sure that they have backed up their private key in a secure location. Also states that deletibg the passcode will delete the key from the device")
    static let privateKeyTitle = NSLocalizedString("ONBOARDING_Private_Key_title", comment: "A title presented over the top of the private key, specifies WIF format. e.g. Your Private Key (WIF)")
    static let welcomeTitle = NSLocalizedString("ONBOARDING_Welcome", comment: "Title Welciming the user after successful wallet creation")
    static let startActionTitle = NSLocalizedString("ONBOARDING_Start_Action_Title", comment: "Title to start the app after completing the onboarding")
    static let alreadyHaveWalletWarning = NSLocalizedString("ONBOARDING_Already_Have_Wallet_Explanation", comment: "When the user tries to create a new wallet, but they already have one saved on the devicve, this explanation/warning is given to the user")

    static let loginWithExistingPasscode = NSLocalizedString("ONBOARDING Login_Button_Specifying_PassCode", comment: "On authentication screen, when wallet already exists. Ask them to login using the specific type of authentication they have, e.g Login using Passcode")
    static let loginWithExistingBiometric = NSLocalizedString("ONBOARDING Login_Button_Specifying_Biometric", comment: "On authentication screen, when wallet already exists. Ask them to login using the specific type of authentication they have, e.g Login using TouchID")
    static let authenticationPrompt = NSLocalizedString("ONBOARDING_Existing_Wallet_Authentication_Prompt", comment: "Prompt asking the user to authenticate themselves when they already have a wallet stored on device.")
    
    static let welcomeBackTitle = NSLocalizedString("ONBOARDING_welcome_back_title", comment: "Title for welcome back authentication")
    static let welcomeBackSubtitle = NSLocalizedString("ONBOARDING_welcome_back_subtitle", comment: "Subtitle for welcome back authentication")
    static let walletSelectTitle = NSLocalizedString("ONBOARDING_wallet_select", comment: "Title to select a wall to login with")
}
