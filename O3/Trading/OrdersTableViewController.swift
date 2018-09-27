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
                    
                    if status == SwitcheoOrderStatus.empty { //this is actually all {
                        //so when we show all, meaning any order that is filled even if it's cancelled
                        self.orders = response.switcheo.filter({ o -> Bool in
                            return o.fills.count > 0 || (o.makes.count > 0 && o.orderStatus == SwitcheoOrderStatus.completed)
                        })
                        self.tableView.reloadData()
                        return
                    }
                    self.orders = response.switcheo
                    self.tableView.reloadData()
                }
            }
        }
    }
    
  
    func setupTheme() {
        self.view.theme_backgroundColor = O3Theme.backgroundColorPicker
        self.tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        self.tableView.theme_separatorColor = O3Theme.tableSeparatorColorPicker
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheme()
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
        let order = orders![indexPath.row]
        return  order.orderStatus == .open ? 140.0 : 120.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let order = orders![indexPath.row]
        let cellIdentifier = order.orderStatus == .open ? "cell-open" : "cell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? OrderTableViewCell else {
            return UITableViewCell()
        }
        
        let formatter = NumberFormatter()
        let filled = order.fills.count > 0
        
        var wantAmount = formatter.number(from: order.wantAmount)?.doubleValue
        var offerAmount = (formatter.number(from: order.offerAmount)?.doubleValue)!
        let originalWantAmount = order.side == .sell ? (formatter.number(from: order.offerAmount)?.doubleValue)! : (formatter.number(from: order.wantAmount)?.doubleValue)!
        
        var priceDouble = order.side == .sell ? Double(wantAmount! / offerAmount) : Double(offerAmount / wantAmount!)
        
        let filledAmount = order.totalFilledAmount()
       
        if filled && order.orderStatus != .open {
            
            let sumPriceInFill = order.fills.reduce(0.0, {(result:Double, item:Fill) -> Double in
                return result + (formatter.number(from: item.price)?.doubleValue)!
            })
            
            wantAmount = order.fills.reduce(0.0, {(result:Double, item:Fill) -> Double in
                return result + (formatter.number(from: item.wantAmount)?.doubleValue)!
            })
            
            offerAmount = order.fills.reduce(0.0, {(result:Double, item:Fill) -> Double in
                return result + (formatter.number(from: item.fillAmount!)?.doubleValue)!
            })
            
            priceDouble = sumPriceInFill / Double(order.fills.count)
        }
        
        let v = OrderViewModel(orderID:order.id, orderStatus:order.orderStatus, wantAsset: order.wantAsset, offerAsset: order.offerAsset, price: priceDouble, wantAmount: wantAmount, offerAmount: offerAmount, action: OrderViewModel.Action(rawValue: order.side.rawValue), datetime: order.createdAt.toDate()!,originalWantAmount: originalWantAmount, filled: filled, filledAmount: filledAmount)
        
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
                        #if DEBUG
                        print(response)
                        #endif
                        NotificationCenter.default.post(name: NSNotification.Name("needsReloadOpenOrders"), object: nil)
                         NotificationCenter.default.post(name: NSNotification.Name("needsReloadTradingBalances"), object: nil)
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
