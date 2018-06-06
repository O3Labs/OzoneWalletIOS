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

    //Tutorial Screen
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
}
