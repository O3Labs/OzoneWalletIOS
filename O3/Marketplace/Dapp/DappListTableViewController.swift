//
//  DappListTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 10/2/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

class DappListTableViewController: UITableViewController {

    var list: [Dapp]! = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
    }
    
    func loadData() {
        O3APIClient(network: AppState.network).loadDapps { result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let list):
                DispatchQueue.main.async {
                    self.list = list
                    self.tableView.reloadData()
                }
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! DappTableViewCell
    
        let dapp = list[indexPath.row]
        cell.configure(dapp: dapp)
        return cell
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let dapp = list[indexPath.row]
        Controller().openDappBrowser(url: URL(string: dapp.url)!, modal: true)
    }
}
