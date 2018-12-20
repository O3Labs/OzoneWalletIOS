//
//  SendCompleteViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 9/20/17.
//  Copyright © 2017 drei. All rights reserved.
//

import Foundation
import UIKit

class SendCompleteViewController: UIViewController, AddressAddDelegate {
    @IBOutlet weak var completeImage: UIImageView!
    @IBOutlet weak var completeTitle: UILabel!
    @IBOutlet weak var completeSubtitle: UILabel!
    @IBOutlet weak var closeButton: UIButton!

    @IBOutlet weak var transactionIdLabel: UILabel!
    @IBOutlet weak var addToContactsCheckbox: UIButton!
    @IBOutlet weak var saveAddressLabel: UILabel!
    
    var contacts = [Contact]()

    var transactionSucceeded: Bool!
    var transactionId: String!
    var toSendAddress: String!
    
    func loadContacts() {
        do {
            contacts = try UIApplication.appDelegate.persistentContainer.viewContext.fetch(Contact.fetchRequest())
        } catch {
            return
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
        loadContacts()
        closeButton.setTitle(SendStrings.close, for: UIControl.State())

        if transactionSucceeded {
            completeImage.image = #imageLiteral(resourceName: "checked")
            completeTitle.text = SendStrings.transactionSucceededTitle
            completeSubtitle.text = SendStrings.transactionSucceededSubtitle
            transactionIdLabel.text = String(format: SendStrings.transactionId, transactionId)
            saveAddressLabel.text = SendStrings.saveToContacts
        } else {
            transactionIdLabel.isHidden = true
            addToContactsCheckbox.isHidden = true
            saveAddressLabel.isHidden = true
            completeImage.image = #imageLiteral(resourceName: "sad")
            completeTitle.text = SendStrings.transactionFailedTitle
            completeSubtitle.text = SendStrings.transactionFailedSubtitle
        }
        if contacts.contains(where: {$0.address == toSendAddress}) {
            addToContactsCheckbox.isHidden = true
            saveAddressLabel.isHidden = true
        }
    }
    @IBAction func checkboxTapped(_ sender: Any) {
        addToContactsCheckbox.isSelected = !addToContactsCheckbox.isSelected
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        if addToContactsCheckbox.isSelected {
            DispatchQueue.main.async {
                if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddressEntryTableViewController") as? AddressEntryTableViewController {
                    vc.delegate = self
                    self.present(vc, animated: true, completion: {
                        vc.addressTextView.text = self.toSendAddress
                        vc.nicknameField.becomeFirstResponder()
                    })
                }
            }
        } else {
            self.view.window!.rootViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func addressAdded(_ address: String, nickName: String) {
        DispatchQueue.main.async {
            let context = UIApplication.appDelegate.persistentContainer.viewContext
            let contact = Contact(context: context)
            contact.address = address
            contact.nickName = nickName
            UIApplication.appDelegate.saveContext()
            UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: false, completion: nil)
        }
    }
}
