//
//  Events.swift
//  O3
//
//  Created by Apisit Toompakdee on 10/4/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import Amplitude

enum TradingActionSource: String {
    case tradingAccount = "trading_account"
    case asset = "trading_account_menu_item"
    case o3Account = "wallet_account_menu_item"
    case tokenDetail = "token_details"
    case marketplace = "marketplace_card"
}

enum tradingEventName: String {
    case withdrawInitiated = "Withdraw_Initiated"
    case depositInitiated = "Deposit_Initiated"
    case buyInitiated = "Buy_Initiated"
    case sellInitiated = "Sell_Initiated"
    case tokenDetailSelected = "Token_Details_Selected"
    case notEnoughTradingBalance = "Not_enough_trading_balance_error"
    case depositSuccessfully = "Deposit"
    case withdrawSuccessfully = "Withdraw"
    case canceledOrder = "Order Cancelled"
    case viewClosedOrder = "Show Closed Orders"
    case placedOrder = "Native_Order_Placed"
}

enum tradingEventField: String {
    case asset = "asset"
    case source = "source"
    case amount = "amount"
    case orderID = "order_id"
    case datetime = "datetime"
    case side = "side"
    case pair = "pair"
    case baseCurrency = "base_currency"
    case quantity = "quantity"
    case priceSelection = "price_selection"
}

enum multiwalletEventName: String {
    case walletAdded = "wallet_added"
    case watchAddressAdded = "watch_address_added"
    case multiwalletActivated = "multiwallet_activated"
    case walletUnlocked = "wallet_unlocked"
}

enum multiWalletEventField: String {
    case type = "type"
    case method = "method"
    case addressCount = "address_count"
}

class MultiwalletEvent: NSObject {
    private var amplitude: Amplitude! = Amplitude.instance()
    static let shared: MultiwalletEvent! = MultiwalletEvent()
    
    func log(event: String, data: [String: Any]) {
        amplitude.logEvent(event, withEventProperties: data)
    }
    
    func walletAdded(type: String, method: String) {
        log(event: multiwalletEventName.walletAdded.rawValue,
            data: [multiWalletEventField.type.rawValue: type,
                   multiWalletEventField.method.rawValue: method,
                   multiWalletEventField.addressCount.rawValue: NEP6.getFromFileSystem()?.getAccounts().count])
    }
    
    func multiwalletActivated() {
        log(event: multiwalletEventName.multiwalletActivated.rawValue,
            data: [:])
    }
    
    func walletUnlocked() {
        log(event: multiwalletEventName.walletUnlocked.rawValue,
            data: [:])
    }
}

class ClaimEvent: NSObject {
    private var amplitude: Amplitude! = Amplitude.instance()
    static let shared: ClaimEvent! = ClaimEvent()
    
    func log(event: String, data: [String: Any]) {
        amplitude.logEvent(event, withEventProperties: data)
    }
    
    func ongClaimed() {
        log(event: "CLAIM",
            data: ["type": "ONG",
                   "isLedger": false])
    }
    
    func gasClaimed() {
        log(event: "CLAIM",
            data: ["type": "GAS",
                   "isLedger": false])
    }
}


class tradingEvent: NSObject {
    
    private var amplitude: Amplitude! = Amplitude.instance()
    static let shared: tradingEvent! = tradingEvent()
    
    func log(event: String, data: [String: Any]) {
         amplitude.logEvent(event, withEventProperties: data)
    }
    
    func startWithdraw(asset: String, source: TradingActionSource){
        let properties: [String: Any] = [tradingEventField.asset.rawValue: asset,
                                         tradingEventField.source.rawValue: source.rawValue]
        log(event: tradingEventName.withdrawInitiated.rawValue, data: properties)
    }
    
    func successfullyWithdraw(asset: String, amount: Double){
        let properties: [String: Any] = [tradingEventField.asset.rawValue: asset,
                                         tradingEventField.amount.rawValue: amount]
         log(event: tradingEventName.withdrawSuccessfully.rawValue, data: properties)
    }
    
    func startDeposit(asset: String, source: TradingActionSource){
        let properties: [String: Any] = [tradingEventField.asset.rawValue: "NEO",
                                         tradingEventField.source.rawValue: source.rawValue]
         log(event: tradingEventName.depositInitiated.rawValue, data: properties)
    }
    
    func successfullyDeposit(asset: String, amount: Double){
        let properties: [String: Any] = [tradingEventField.asset.rawValue: asset,
                                         tradingEventField.amount.rawValue: amount]
         log(event: tradingEventName.depositSuccessfully.rawValue, data: properties)
    }
    
    func startBuy(asset: String, source: TradingActionSource){
        let properties: [String: Any] = [tradingEventField.asset.rawValue: asset,
                                         tradingEventField.source.rawValue: source.rawValue]
         log(event: tradingEventName.buyInitiated.rawValue, data: properties)
    }
    
    func startSell(asset: String, source: TradingActionSource){
        let properties: [String: Any] = [tradingEventField.asset.rawValue: asset,
                                         tradingEventField.source.rawValue: source.rawValue]
        log(event: tradingEventName.sellInitiated.rawValue, data: properties)
    }
    
    func viewTokenDetail(asset: String, source: TradingActionSource){
        let properties: [String: Any] = [tradingEventField.asset.rawValue: asset,
                                         tradingEventField.source.rawValue: source.rawValue]
        log(event: tradingEventName.tokenDetailSelected.rawValue, data: properties)
    }
    
    func notEnoughTradingBalance() {
        log(event: tradingEventName.notEnoughTradingBalance.rawValue, data: [:])
    }
    
    func canceledOrder(orderID: String) {
        let properties: [String: Any] = [tradingEventField.orderID.rawValue: orderID]
        log(event: tradingEventName.canceledOrder.rawValue, data: properties)
    }
    
    func viewClosedOrder() {
        log(event: tradingEventName.viewClosedOrder.rawValue, data: [:])
    }
    
    func placedOrder(orderID: String, datetime: String, side: String, pair: String, baseCurrency: String, quantity: Double, priceSelection: String) {
        let properties: [String: Any] = [tradingEventField.orderID.rawValue: orderID,
                                         tradingEventField.datetime.rawValue: datetime,
                                         tradingEventField.side.rawValue: side,
                                         tradingEventField.pair.rawValue: pair,
                                         tradingEventField.baseCurrency.rawValue: baseCurrency,
                                         tradingEventField.quantity.rawValue: quantity,
                                         tradingEventField.priceSelection.rawValue: priceSelection]
        log(event: tradingEventName.placedOrder.rawValue, data: properties)
    }
}

class sendEvent: NSObject {
    private var amplitude: Amplitude! = Amplitude.instance()
    static let shared: sendEvent! = sendEvent()
    
    enum sendEventName: String {
        case assetSend = "ASSET SEND"
    }
    
    enum sendEventField: String {
        case blockchain
        case net
        case asset
        case amount
    }
    
    func log(event: String, data: [String: Any]) {
        amplitude.logEvent(event, withEventProperties: data)
    }
    
    func assetSend(blockchain: String, asset: String, amount: Any) {
        let net = UserDefaultsManager.network == .main ? "MainNet" : "TestNet"
        log(event: sendEventName.assetSend.rawValue, data: [sendEventField.blockchain.rawValue: blockchain,
                                                                 sendEventField.net.rawValue: net,
                                                                 sendEventField.asset.rawValue: asset,
                                                                 sendEventField.amount.rawValue: amount])
    }
}

class dapiEvent: NSObject {
    private var amplitude: Amplitude! = Amplitude.instance()
    static let shared: dapiEvent! = dapiEvent()
    
    enum dapiEventName: String {
        case dappOpened = "dAPI_open"
        case dappMethodCall = "dAPI_method_call"
        case dappAccountConnected = "dAPI_account_connected"
        case dappTXAccepted = "dAPI_tx_accepted"
        case dappClosed = "dAPI_closed"
    }
    
    enum dapiEventField: String {
        case url
        case domain
        case net
        case method
        case blockchain
    }
        
    func log(event: String, data: [String: Any]) {
        amplitude.logEvent(event, withEventProperties: data)
    }
    
    func methodCall(method: String, url: String, domain: String) {
        let net = UserDefaultsManager.network == .main ? "MainNet" : "TestNet"
        log(event: dapiEventName.dappMethodCall.rawValue, data: [dapiEventField.blockchain.rawValue: "NEO",
                                                                 dapiEventField.net.rawValue: net,
                                                                 dapiEventField.method.rawValue: method,
                                                                 dapiEventField.url.rawValue: url,
                                                                 dapiEventField.domain.rawValue: domain])
    }
    
    func dappOpened(url: String, domain: String) {
        log(event: dapiEventName.dappOpened.rawValue, data: [dapiEventField.url.rawValue: url,
                                                             dapiEventField.domain.rawValue: domain])
    }
    
    func dappClosed(url: String, domain: String) {
        log(event: dapiEventName.dappClosed.rawValue, data: [dapiEventField.url.rawValue: url,
                                                             dapiEventField.domain.rawValue: domain
            ])
    }
    
    func accountConnected(url: String, domain: String) {
        let net = UserDefaultsManager.network == .main ? "MainNet" : "TestNet"
        log(event: dapiEventName.dappAccountConnected.rawValue, data: [dapiEventField.blockchain.rawValue: "NEO",
                                                                 dapiEventField.net.rawValue: net,
                                                                 dapiEventField.url.rawValue: url,
                                                                 dapiEventField.domain.rawValue: domain])
    }
    
    func txAccepted(method: String, url: String, domain: String) {
        let net = UserDefaultsManager.network == .main ? "MainNet" : "TestNet"
        log(event: dapiEventName.dappTXAccepted.rawValue, data: [dapiEventField.blockchain.rawValue: "NEO",
                                                                       dapiEventField.net.rawValue: net,
                                                                       dapiEventField.url.rawValue: url,
                                                                       dapiEventField.domain.rawValue: domain])
    }
}

class RevenueEvent: NSObject {
    private var amplitude: Amplitude! = Amplitude.instance()
    static let shared: RevenueEvent! = RevenueEvent()
    
    enum revenueEventName: String {
        case buyInitiated = "buy_neo_initiated"
        case shareReferral = "share_referral"
    }
    
    enum revenueEventField: String {
        case buyWith
        case source
    }
    
    func log(event: String, data: [String: Any]) {
        amplitude.logEvent(event, withEventProperties: data)
    }
    
    func buyInitiated(buyWith: String, source: String) {
        log(event: revenueEventName.buyInitiated.rawValue, data: [
            revenueEventField.buyWith.rawValue: buyWith,
            revenueEventField.source.rawValue: source])
    }
    
    func shareReferral() {
        log(event: revenueEventName.buyInitiated.rawValue, data: [:])
    }
}

class CoinbaseEvent: NSObject {
    private var amplitude: Amplitude! = Amplitude.instance()
    static let shared: RevenueEvent! = RevenueEvent()
    
    enum coinbaseEventName: String {
        case connectedCoinbase = "connected_coinbase"
        case updatedLimit = "update_limit_tapped"
        case removedCoinbase = "remove_coinbase"
        case transactedCoinbase = "transaction_coinbase"
    }
    
    func log(event: String, data: [String: Any]) {
        amplitude.logEvent(event, withEventProperties: data)
    }
    
    func connectedCoinbase() {
        log(event: coinbaseEventName.connectedCoinbase.rawValue, data:[:])
    }
    
    func updateLimit() {
        log(event: coinbaseEventName.updatedLimit.rawValue, data:[:])
    }
    
    func removedCoinbase() {
        log(event: coinbaseEventName.removedCoinbase.rawValue, data:[:])
    }
    
    func transactedCoinbase() {
        log(event: coinbaseEventName.transactedCoinbase.rawValue, data: [:])
    }
}



