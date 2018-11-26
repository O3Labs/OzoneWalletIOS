//
//  TransactionHistoryTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 1/21/18.
//  Copyright © 2018 drei. All rights reserved.
//

import UIKit
import CoreData

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
    var pendingTransactions = [PendingTransaction]()
    var allAssets = [Asset]()
    
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
    
    func loadPendingTransaction() {
        do {
            let fetch: NSFetchRequest<PendingTransaction> = PendingTransaction.fetchRequest()
            let sort = NSSortDescriptor(key: #keyPath(PendingTransaction.timestamp), ascending: false)
            fetch.sortDescriptors = [sort]
            pendingTransactions = try UIApplication.appDelegate.accountPersistentContainer.viewContext.fetch(fetch)
        } catch {
            return
        }
    }
    
    func loadAssetsForPendingTransaction() {
        O3Client().getAssetsForMarketPlace { result in
            switch result {
            case .failure:
                return
            case .success(let assets):
                DispatchQueue.main.async {
                    self.allAssets = assets
                    self.loadPendingTransaction()
                }
            }
        }
    }
    
    func initialLoad() {
        O3Client().getTokens { result in
            switch result {
            case .failure:
                return
            case .success(let _):
                self.loadTransactionHistory(appendPage: false, pageNo: 1)
            }
        }
    }
    
    func checkPending() {
        //cross check with the tx history
        for pending in self.pendingTransactions {
            let foundIndex = self.transactionHistory.index{ return $0.txid == pending.txID! }
            if foundIndex != nil {
                UIApplication.appDelegate.accountPersistentContainer.viewContext.delete(pending)
                try? UIApplication.appDelegate.accountPersistentContainer.viewContext.save()
            }
        }
        self.loadPendingTransaction()
    }
    
    
    func loadTransactionHistory(appendPage: Bool, pageNo: Int) {
        O3APIClient(network: AppState.network).getTxHistory(address: Authenticated.wallet!.address, pageIndex: pageNo) { result in
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
                self.checkPending()
                DispatchQueue.main.async {
                    self.tableView.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    @objc func pendingTransactionAdded() {
        self.loadPendingTransaction()
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadWatchAddresses()
        loadContacts()
        loadAssetsForPendingTransaction()
        NotificationCenter.default.addObserver(self, selector: #selector(pendingTransactionAdded), name: Notification.Name(rawValue: "pendingTransactionAdded"), object: nil)
        
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
        return 2
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //pending tx
        if indexPath.section == 0 {
            return 96
        }
        return 96
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "sectionHeader")
            if let label = cell?.viewWithTag(1) as? UILabel {
                label.text = "Pending Transactions"
            }
            cell?.theme_backgroundColor = O3Theme.backgroundLightgrey
            cell?.contentView.theme_backgroundColor = O3Theme.backgroundLightgrey
            return cell?.contentView
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "sectionHeader")
        if let label = cell?.viewWithTag(1) as? UILabel {
            label.text = "History"
        }
        cell?.theme_backgroundColor = O3Theme.backgroundLightgrey
        cell?.contentView.theme_backgroundColor = O3Theme.backgroundLightgrey
        return cell?.contentView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return  pendingTransactions.count == 0 ? 0 : 44
        }
        return  pendingTransactions.count == 0 ? 0 : 44
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //pending trasaction
        if indexPath.section == 0 {
            let pending = pendingTransactions[indexPath.row]
        
            let index = self.allAssets.index { return $0.symbol.uppercased() == pending.asset!.uppercased() }
            let asset = self.allAssets[index!]
            let pendingData = TransactionCell.PendingTransactionData(txID: pending.txID!, time: UInt64(pending.timestamp),
                                                                 asset: asset, toAddress: pending.to!,
                                                                 fromAddress: pending.from!,
                                                                 amount: pending.amount!)
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "transactionCell") as? TransactionCell else {
                fatalError("Undefined table view behavior")
            }
            cell.selectionStyle = .none
            cell.delegate = self
            cell.pending = pendingData
            return cell
        }
        
        let transactionEntry = transactionHistory[indexPath.row]
        var transactionData: TransactionCell.TransactionData?
        
        transactionData = TransactionCell.TransactionData(date: UInt64(transactionEntry.time),
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
    
    func showPendingActionSheet(pendingIndex: IndexPath) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let removePending = UIAlertAction(title: "Remove From History", style: .destructive) { _ in
            UIApplication.appDelegate.accountPersistentContainer.viewContext.delete(self.pendingTransactions[pendingIndex.row])
            try? UIApplication.appDelegate.accountPersistentContainer.viewContext.save()
            self.pendingTransactions.remove(at: pendingIndex.row)
            self.tableView.deleteRows(at: [pendingIndex], with: .fade)
        }
        let cancel = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { _ in}
        
        alert.addAction(cancel)
        alert.addAction(removePending)
        alert.popoverPresentationController?.sourceView = self.tableView
        present(alert, animated: true, completion: nil)
    }
    
    func showActionSheet(tx: TransactionHistoryItem) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let viewDetail = UIAlertAction(title: "View detail", style: .default) { _ in
            self.performSegue(withIdentifier: "segueToWebview", sender: tx)
        }
        alert.addAction(viewDetail)
        
        let addressToCheck: String?
        if tx.to == Authenticated.wallet!.address {
            addressToCheck = tx.from
        } else {
            addressToCheck = tx.to
        }
        
        var exists = getContacts().contains(where: {$0.address == addressToCheck})
        //if sending it to this account we don't offer add to contacts option
        if tx.to == Authenticated.wallet!.address {
            exists = true
        }
        
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
        
        //we don't offer any option on pending transaction
        if indexPath.section == 0{
            showPendingActionSheet(pendingIndex: indexPath)
            return
        }
        //offer action sheet
        let transaction = transactionHistory[indexPath.row]
        showActionSheet(tx: transaction)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return pendingTransactions.count
        }
        return transactionHistory.count
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToWebview" {
            guard let dest = segue.destination as? TransactionWebViewController else {
                fatalError("Undefined Segue behavior")
            }
            if  let tx = sender as? TransactionHistoryItem {
                dest.transaction = tx
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
