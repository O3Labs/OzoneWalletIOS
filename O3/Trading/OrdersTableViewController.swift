//
//  OrdersTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/21/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import PKHUD

class OrdersTableViewController: UITableViewController {
    
    var orderStatus: SwitcheoOrderStatus?
    var orders: [SwitcheoOrder]?
    
    func loadOrders(status: SwitcheoOrderStatus) {
        O3APIClient(network: AppState.network).loadSwitcheoOrders(address: Authenticated.account!.address, status: status) { result in
            switch result{
            case .failure(let error):
                print(error)
            case .success(let response):
                DispatchQueue.main.async {
                    self.orders = response.switcheo
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-x"), style: .plain, target: self, action: #selector(dismiss(_: )))
        
        //if order status is set we then load the orders from a server
        if orderStatus != nil {
            loadOrders(status: orderStatus!)
        }
    }
    
    @objc func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orders?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? OrderTableViewCell else {
            return UITableViewCell()
        }
        let order = orders![indexPath.row]
        let orderItem: Fill?
        let formatter = NumberFormatter()
        var filled = order.fills.count > 0
        
        if filled {
            orderItem = order.fills.first
        } else {
            orderItem = order.makes.first
        }
        
        let wantAmount = formatter.number(from: orderItem!.wantAmount)?.doubleValue
        var offerAmount = Double(0)
        if filled {
            offerAmount = (formatter.number(from: orderItem!.fillAmount!)?.doubleValue)!
        } else {
            offerAmount = (formatter.number(from: orderItem!.offerAmount!)?.doubleValue)!
        }
        
        let priceDouble = formatter.number(from: orderItem!.price)?.doubleValue
        let v = OrderViewModel(orderID:order.id, orderStatus:order.orderStatus, wantAsset: order.wantAsset, offerAsset: order.offerAsset, price: priceDouble, wantAmount: wantAmount, offerAmount: offerAmount, action: OrderViewModel.Action(rawValue: order.side.rawValue), datetime: order.createdAt.toDate()!)
        cell.configure(viewModel: v)
        cell.delegate = self
        return cell
    }
}

extension OrdersTableViewController: OrderViewModelDelegate {
    func cancelTapped(v: OrderViewModel) {
        let message = String(format: "Confirm cancel your %@ order of %@?", v.action.rawValue, v.wantAsset.symbol.uppercased())
        OzoneAlert.confirmDialog("", message: message, cancelTitle: "Dismiss", confirmTitle: "Confirm", didCancel: {
            
        }) {
            DispatchQueue.main.async {
                HUD.show(.progress)
            }
            let switcheoAccount = SwitcheoAccount(network: AppState.network == Network.main ? Switcheo.Net.Main : Switcheo.Net.Test, account: Authenticated.account!)
            switcheoAccount.cancellation(orderID: v.orderID) { result in
                DispatchQueue.main.async {
                    HUD.hide()
                    switch result{
                    case .failure(let e):
                        print(e)
                    case .success(let response):
                        print(response)
                        let removeIndex = self.orders?.index(where: { order -> Bool in
                            return order.id == v.orderID
                        })
                        self.orders?.remove(at: removeIndex!)
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
}
