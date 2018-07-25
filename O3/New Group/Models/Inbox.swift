//
//  Inbox.swift
//  O3
//
//  Created by Apisit Toompakdee on 6/25/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

struct Inbox: Codable {
    let items: [InboxItem]

    enum CodingKeys: String, CodingKey {
        case items = "data"
    }
}

struct InboxItem: Codable {
    let title: String
    let subtitle: String
    let description: String
    let actionTitle: String
    let actionURL: String
    let readmoreTitle: String
    let readmoreURL: String
    let iconURL: String

    enum CodingKeys: String, CodingKey {
        case title = "title"
        case subtitle = "subtitle"
        case description = "description"
        case actionTitle = "actionTitle"
        case actionURL = "actionURL"
        case readmoreTitle = "readmoreTitle"
        case readmoreURL = "readmoreURL"
        case iconURL = "iconURL"
    }
}
