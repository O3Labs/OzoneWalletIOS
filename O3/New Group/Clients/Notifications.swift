//
//  Notifications.swift
//  O3
//
//  Created by Andrei Terentiev on 4/22/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import Neoutils

public struct PushUnsignedRequest: Encodable {
    var deviceToken: String
    var platform: String
    var timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case deviceToken
        case platform
        case timestamp
    }
    
    public init(timestamp: String, platform: String, deviceToken: String) {
        self.timestamp = timestamp
        self.platform = platform
        self.deviceToken = deviceToken
    }
}

public struct PushSignedRequest: Encodable {
    var data: PushUnsignedRequest
    var signature: String
    
    enum CodingKeys: String, CodingKey {
        case data
        case signature
    }
    
    public init(data: PushUnsignedRequest, signature: String) {
        self.data = data
        self.signature = signature
    }
}



public struct NotificationSubscriptionUnsignedRequest: Encodable {
    var timestamp: String
    var topic: String
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case topic
    }
    
    public init(timestamp: String, topic: String) {
        self.timestamp = timestamp
        self.topic = topic
    }
}

public struct NotificationSubscriptionSignedRequest: Encodable {
    var data: NotificationSubscriptionUnsignedRequest
    var signature: String
    
    enum CodingKeys: String, CodingKey {
        case data
        case signature
    }
    
    public init(data: NotificationSubscriptionUnsignedRequest, signature: String) {
        self.data = data
        self.signature = signature
    }
}

public struct MessagesUnsignedRequest: Encodable {
    var timestamp: String
    
    enum CodingKeys: String, CodingKey {
       case timestamp
    }
    
    public init(timestamp: String) {
        self.timestamp = timestamp
    }
}

public struct MessagesSignedRequest: Encodable {
    var data: MessagesUnsignedRequest
    var signature: String
    
    enum CodingKeys: String, CodingKey {
        case data
        case signature
    }
    
    public init(data: MessagesUnsignedRequest, signature: String) {
        self.data = data
        self.signature = signature
    }
}

public struct Inbox: Codable {
    var total: Int
    var messages: [Message]
}

public struct Message: Codable {
    var id: String
    var sequence: Int
    var data: MessageData
    var timestamp: Int
    var channel: Channel
    var action: Action?
    var sender: SenderInfo

    
    enum CodingKeys: String, CodingKey {
        case id
        case sequence
        case data
        case timestamp
        case channel
        case action
        case sender
    }
    
    public init(id: String, sequence: Int, data: MessageData, timestamp: Int,
                channel: Channel, action: Action?, sender: SenderInfo) {
        self.id = id
        self.sequence = sequence
        self.data = data
        self.timestamp = timestamp
        self.channel = channel
        self.action = action
        self.sender = sender
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let sequence = try container.decode(Int.self, forKey: .sequence)
        let data = try container.decode(MessageData.self, forKey: .data)
        let timestamp = try container.decode(Int.self, forKey: .timestamp)
        let channel = try container.decode(Channel.self, forKey: .channel)
        let action = try? container.decode(Action.self, forKey: .action)
        let sender = try container.decode(SenderInfo.self, forKey: .sender)
        
        
        self.init(id: id, sequence: sequence, data: data, timestamp: timestamp,
         channel: channel, action: action, sender: sender)
    }

    
    public struct Channel: Codable {
        var topic: String
    
        enum CodingKeys: String, CodingKey {
            case topic
        }
        
        public init(topic: String) {
            self.topic = topic
        }
    }
    
    public struct MessageData: Codable {
        var text: String
        
        enum CodingKeys: String, CodingKey {
            case text
        }
        
        public init(text: String) {
            self.text = text
        }
    }
    
    public struct SenderInfo: Codable {
        var publicKey: String
        var name: String
        var imageURL: String
        
        enum CodingKeys: String, CodingKey {
            case publicKey
            case name
            case imageURL
        }
        
        public init(publicKey: String, name: String, imageURL: String) {
            self.name = name
            self.publicKey = publicKey
            self.imageURL = imageURL
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let pubkey = try container.decode(String.self, forKey: .publicKey)
            var name = try? container.decode(String.self, forKey: .name)
            var imageURL = try? container.decode(String.self, forKey: .imageURL)
            if name == nil {
                name = "Unknown Sender"
            }
            self.init(publicKey: pubkey, name: name!, imageURL: imageURL!)
        }
    }
    
    public struct Action: Codable {
        var type: String
        var title: String
        var url: String
        
        enum CodingKeys: String, CodingKey {
            case type
            case title
            case url
        }
        
        public init(type: String, title: String, url: String) {
            self.type = type
            self.title = title
            self.url = url
        }
    }
}

extension O3APIClient {
    func subscribeToPush(deviceToken: String, completion: @escaping(O3APIClientResult<Bool>) -> Void) {
        let endpoint = "/\(O3KeychainManager.getO3PubKey()!)/devices"
        let fullURL = "https://inbox.o3.network/api/v1" + endpoint
        
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let objectToSign = PushUnsignedRequest(timestamp: timestamp, platform: "iOS", deviceToken: deviceToken)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let dataToSign = try? encoder.encode(objectToSign)
        
        
        var error: NSError?
        let signature = (NeoutilsSign(dataToSign, O3KeychainManager.getO3PrivKey()!, &error)?.fullHexString)!
        
        let signedObject = PushSignedRequest(data: objectToSign, signature: signature)
        let signedData = try! encoder.encode(signedObject)
        
        sendRESTAPIRequest(endpoint, data: signedData, requestType: "POST", overrideURL: fullURL) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let _):
                let success = O3APIClientResult.success(true)
                completion(success)
            }
        }
    }
    
    func subscribeToTopic(topic: String, completion: @escaping(O3APIClientResult<Bool>) -> Void) {
        let endpoint = "/\(O3KeychainManager.getO3PubKey()!)/subscribe"
        let fullURL = "https://inbox.o3.network/api/v1" + endpoint
        
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let objectToSign = NotificationSubscriptionUnsignedRequest(timestamp: timestamp, topic: topic)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let dataToSign = try? encoder.encode(objectToSign)
        
        
        var error: NSError?
        let signature = (NeoutilsSign(dataToSign, O3KeychainManager.getO3PrivKey()!, &error)?.fullHexString)!
        
        let signedObject = NotificationSubscriptionSignedRequest(data: objectToSign, signature: signature)
        let signedData = try! encoder.encode(signedObject)
        
        sendRESTAPIRequest(endpoint, data: signedData, requestType: "POST", overrideURL: fullURL) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let success = O3APIClientResult.success(true)
                completion(success)
            }
        }
    }
    
    func unsubscribeToTopic(topic: String, completion: @escaping(O3APIClientResult<Bool>) -> Void) {
        let endpoint = "/\(O3KeychainManager.getO3PubKey()!)/unsubscribe"
        let fullURL = "https://inbox.o3.network/api/v1" + endpoint
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let objectToSign = NotificationSubscriptionUnsignedRequest(timestamp: timestamp, topic: topic)
        let dataToSign = try? encoder.encode(objectToSign)
        
        var error: NSError?
        let signature = (NeoutilsSign(dataToSign, O3KeychainManager.getO3PrivKey()!, &error)?.fullHexString)!
        
        let signedObject = NotificationSubscriptionSignedRequest(data: objectToSign, signature: signature)
        let signedData = try! encoder.encode(signedObject)
        
        sendRESTAPIRequest(endpoint, data: signedData, requestType: "POST", overrideURL: fullURL) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let success = O3APIClientResult.success(true)
                completion(success)
            }
        }
    }
    
    func getMessages(pubKey: String, sequence: Int? = nil, completion: @escaping(O3APIClientResult<[Message]>) -> Void) {
        let endpoint = "/\(O3KeychainManager.getO3PubKey()!)/notifications"
        
        let fullURL = "https://inbox.o3.network/api/v1" + endpoint
        var params = [String: String]()
        if sequence != nil {
            params = ["sequence": String(sequence!)]
        }
        
        sendRESTAPIRequest(endpoint, data: nil, requestType: "GET", params: params, overrideURL: fullURL) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let decoder = JSONDecoder()
                guard let dictionary = response["result"] as? JSONDictionary,
                    let data = try? JSONSerialization.data(withJSONObject: dictionary["data"], options: .prettyPrinted),
                    let inbox = try? decoder.decode(Inbox.self, from: data) else {
                        completion(.failure(O3APIClientError.invalidData))
                        return
                }
                completion(.success(inbox.messages))
            }
        }
    }
}
