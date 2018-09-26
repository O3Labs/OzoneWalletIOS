//
//  TradingOrder.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/21/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit



struct TradingOrders: Codable {
    let switcheo: [SwitcheoOrder]
    
    enum CodingKeys: String, CodingKey {
        case switcheo = "switcheo"
    }
}

struct SwitcheoOrder: Codable {
    let address: String
    let blockchain: String
    let contractHash: String
    let createdAt: String
    let depositTxn: JSONNull?
    let fills: [Fill]
    let id: String
    let makes: [Fill]
    let nativeFeeTransferAmount: Int
    let offerAsset: TradableAsset
    let offerAmount: String
    let offerAssetID: String
    let priorityGasAmount: String
    let side: Side
    let status: SwitcheoStatus
    let orderStatus: SwitcheoOrderStatus
    let transferAmount: String
    let useNativeToken: Bool
    let wantAsset: TradableAsset
    let wantAmount: String
    let wantAssetID: String
    
    enum CodingKeys: String, CodingKey {
        case address = "address"
        case blockchain = "blockchain"
        case contractHash = "contract_hash"
        case createdAt = "created_at"
        case depositTxn = "deposit_txn"
        case fills = "fills"
        case id = "id"
        case makes = "makes"
        case nativeFeeTransferAmount = "native_fee_transfer_amount"
        case offerAsset = "offerAsset"
        case offerAmount = "offer_amount"
        case offerAssetID = "offer_asset_id"
        case priorityGasAmount = "priority_gas_amount"
        case side = "side"
        case status = "status"
        case orderStatus = "order_status"
        case transferAmount = "transfer_amount"
        case useNativeToken = "use_native_token"
        case wantAsset = "wantAsset"
        case wantAmount = "want_amount"
        case wantAssetID = "want_asset_id"
    }
}


struct Fill: Codable {
    let createdAt: String
    let feeAmount: String?
    let feeAssetID: String?
    let fillAmount: String?
    let filledAmount: String
    let id: String
    let offerAsset: TradableAsset
    let offerAssetID: String
    let offerHash: String
    let price: String
    let status: FillStatus
    let transactionHash: String
    let txn: JSONNull?
    let wantAsset: TradableAsset
    let wantAmount: String
    let wantAssetID: String
    let availableAmount: String?
    let cancelTxn: JSONNull?
    let offerAmount: String?
    let trades: [TradeItem]?
    
    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case feeAmount = "fee_amount"
        case feeAssetID = "fee_asset_id"
        case fillAmount = "fill_amount"
        case filledAmount = "filled_amount"
        case id = "id"
        case offerAsset = "offerAsset"
        case offerAssetID = "offer_asset_id"
        case offerHash = "offer_hash"
        case price = "price"
        case status = "status"
        case transactionHash = "transaction_hash"
        case txn = "txn"
        case wantAsset = "wantAsset"
        case wantAmount = "want_amount"
        case wantAssetID = "want_asset_id"
        case availableAmount = "available_amount"
        case cancelTxn = "cancel_txn"
        case offerAmount = "offer_amount"
        case trades = "trades"
    }
}

enum FillStatus: String, Codable {
    case cancelled = "cancelled"
    case confirming = "confirming"
    case pending = "pending"
    case success = "success"
}

struct TradeItem: Codable {
    let createdAt: String
    let feeAsset: TradableAsset
    let feeAmount: String
    let feeAssetID: String
    let filledAmount: String
    let id: String
    let price: String
    let status: FillStatus
    let wantAmount: String
    
    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case feeAsset = "feeAsset"
        case feeAmount = "fee_amount"
        case feeAssetID = "fee_asset_id"
        case filledAmount = "filled_amount"
        case id = "id"
        case price = "price"
        case status = "status"
        case wantAmount = "want_amount"
    }
}

enum Side: String, Codable {
    case buy = "buy"
    case sell = "sell"
}

enum SwitcheoStatus: String, Codable {
    case pending = "pending"
    case processed = "processed"
}

enum SwitcheoOrderStatus: String, Codable {
    case open = "open"
    case cancelled = "cancelled"
    case completed = "completed"
    case empty = ""
}
