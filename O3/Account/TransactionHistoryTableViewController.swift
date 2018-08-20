//
//  TransactionHistoryTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 1/21/18.
//  Copyright © 2018 drei. All rights reserved.
//

import UIKit

class TransactionHistoryTableViewController: UITableViewController, TransactionHistoryDelegate {

    var transactionHistory = [TransactionHistoryItem]()

    //paging (neoscan starts at page 1)
    var isDataLoading = false
    var pageNo = 1
    var limit = 15
    var offset = 0 // (pageNO * limit) - 15
    var endReached = false

    var contacts = [Contact]()
    var watchAddresses = [WatchAddress]()

    func loadContacts() {
        do {
            contacts = try UIApplication.appDelegate.persistentContainer.viewContext.fetch(Contact.fetchRequest())
        } catch {
            return
        }
    }

    func loadWatchAddresses() {
        do {
            watchAddresses = try UIApplication.appDelegate.persistentContainer.viewContext.fetch(WatchAddress.fetchRequest())
        } catch {
            return
        }
    }

    func initialLoad() {
        O3Client().getTokens { result in
            switch result {
            case .failure:
                return
            case .success(let tokens):
                self.loadTransactionHistory(appendPage: false, pageNo: 1)
            }
        }
    }

    func loadTransactionHistory(appendPage: Bool, pageNo: Int) {
        O3APIClient(network: AppState.network).getTxHistory(address: Authenticated.account!.address, pageIndex: pageNo) { result in
            switch result {
            case .failure:
                DispatchQueue.main.async {
                    self.tableView.refreshControl?.endRefreshing()
                }
                return
            case .success(let txHistory):
                if txHistory.totalPage == pageNo {
                    self.endReached = true
                }
                
                if appendPage {
                    self.transactionHistory += txHistory.list
                } else {
                    self.transactionHistory = txHistory.list
                }
                DispatchQueue.main.async {
                    self.tableView.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadWatchAddresses()
        loadContacts()
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        tableView.theme_separatorColor = O3Theme.tableSeparatorColorPicker
        self.initialLoad()
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(reloadData), for: .valueChanged)
    }

    @objc func reloadData() {
        isDataLoading = false
        pageNo = 1
        limit = 15
        offset = 0
        endReached = false
        self.loadTransactionHistory(appendPage: false, pageNo: 1)
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let transactionEntry = transactionHistory[indexPath.row]
        var transactionData: TransactionCell.TransactionData?

        transactionData = TransactionCell.TransactionData(type: TransactionCell.TransactionType.send,
                                                        date: UInt64(transactionEntry.time),
                                                        asset: transactionEntry.asset, toAddress: transactionEntry.to,
                                                        fromAddress: transactionEntry.from,
                                                        amount: transactionEntry.amount, precision: transactionEntry.asset.decimal!)

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "transactionCell") as? TransactionCell else {
            fatalError("Undefined table view behavior")
        }
        cell.selectionStyle = .none
        cell.delegate = self
        cell.data = transactionData

        return cell

    }

    func showActionSheet(tx: TransactionHistoryItem) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let viewDetail = UIAlertAction(title: "View detail", style: .default) { _ in
            let selectedTransactionID  = tx.txid
            self.performSegue(withIdentifier: "segueToWebview", sender: selectedTransactionID)
        }
        alert.addAction(viewDetail)
        
        let addressToCheck: String?
        if tx.to == Authenticated.account!.address {
            addressToCheck = tx.from
        } else {
           addressToCheck = tx.to
        }
        
        let exists = getContacts().contains(where: {$0.address == addressToCheck})
        
        //only show this when the address is not in contacts
        if !exists {
            let saveAddress = UIAlertAction(title: "Add to contacts", style: .default) { _ in
                //open add to contacts dialog
                if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddressEntryTableViewController") as? AddressEntryTableViewController {
                    vc.delegate = self
                    self.present(vc, animated: true, completion: {
                        vc.addressTextView.text = addressToCheck
                        vc.nicknameField.becomeFirstResponder()
                    })
                }
            }
            alert.addAction(saveAddress)
        } 
        
        let cancel = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { _ in
            
        }
        alert.addAction(cancel)
        alert.popoverPresentationController?.sourceView = self.tableView
        present(alert, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //offer action sheet
        let transaction = transactionHistory[indexPath.row]
        showActionSheet(tx: transaction)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactionHistory.count
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToWebview" {
            guard let dest = segue.destination as? TransactionWebViewController else {
                fatalError("Undefined Segue behavior")
            }
            if  let selectedTransactionID = sender as? String {
                dest.transactionID = selectedTransactionID
            }
        }
    }

    func getContacts() -> [Contact] {
        return contacts
    }

    func getWatchAddresses() -> [WatchAddress] {
        return watchAddresses
    }

    //Pagination
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isDataLoading = false
    }

    //Pagination
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (tableView.contentOffset.y + tableView.frame.size.height) >= tableView.contentSize.height {
            if !isDataLoading && !endReached {
                isDataLoading = true
                self.pageNo += 1
                self.limit += 15
                self.offset = (self.limit * self.pageNo) - 15
                loadTransactionHistory(appendPage: true, pageNo: pageNo)
            }
        }
    }
}

extension TransactionHistoryTableViewController: AddressAddDelegate {
    func addressAdded(_ address: String, nickName: String) {
        let context = UIApplication.appDelegate.persistentContainer.viewContext
        let contact = Contact(context: context)
        contact.address = address
        contact.nickName = nickName
        UIApplication.appDelegate.saveContext()
        self.loadContacts()
        self.tableView.reloadData()
    }
}
