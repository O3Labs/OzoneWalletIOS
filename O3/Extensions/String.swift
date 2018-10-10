//
//  String.swift
//  O3
//
//  Created by Andrei Terentiev on 9/24/17.
//  Copyright © 2017 drei. All rights reserved.
//

import Foundation

extension String {

    var firstUppercased: String {
        guard let first = first else { return "" }
        return String(first).uppercased() + dropFirst()
    }
    var firstCapitalized: String {
        guard let first = first else { return "" }
        return String(first).capitalized + dropFirst()
    }

    func intervaledDateString(_ interval: PriceInterval) -> String {
        let dateFormatter = DateFormatter()
        let tempLocale = dateFormatter.locale // save locale temporarily
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        guard let date = dateFormatter.date(from: self) else {
            return ""
        }
        if interval.minuteValue() < 60 {
            dateFormatter.dateFormat = "hh:mm"
        } else {
            dateFormatter.dateFormat = "MMM d, hh:mm"
        }
        dateFormatter.locale = tempLocale
        return dateFormatter.string(from: date)
    }

    func toDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter.date(from: self)
    }
    
    func shortDateString() -> String {
        let dateFormatter = DateFormatter()
        let tempLocale = dateFormatter.locale // save locale temporarily
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        guard let date = dateFormatter.date(from: self) else {
            return ""
        }
        dateFormatter.dateFormat = "YYYY-MM-dd"
        dateFormatter.locale = tempLocale
        return dateFormatter.string(from: date)
    }

    static func formattedAmountChange(amount: Double, currency: Currency) -> String {
        let amountNumber = NSNumber(value: amount)
        let formatter = NumberFormatter()
        formatter.negativeFormat = "- #,##0.00"
        formatter.positiveFormat = "+ #,##0.00"
        formatter.minimumFractionDigits = currency == .btc ? Precision.btc : Precision.usd
        formatter.numberStyle = .decimal
        if let formattedTipAmount = formatter.string(from: amountNumber as NSNumber) {
            return formattedTipAmount
        }
        return ""
    }

    static func percentChangeString(latestPrice: PriceData, previousPrice: PriceData, with selectedInterval: PriceInterval, referenceCurrency: Currency) -> String {
        var percentChange = 0.0
        var amountChange = 0.0
        var amountChangeString = ""

        switch referenceCurrency {
        case .btc:
            amountChange = latestPrice.averageBTC - previousPrice.averageBTC
            amountChangeString = String.formattedAmountChange(amount: amountChange, currency: .btc)
            percentChange = 0 < previousPrice.averageBTC ? (amountChange / previousPrice.averageBTC) * 100 : 0
            if amountChange == 0 {
                percentChange = 0
            }
        default:
            amountChange = latestPrice.average - previousPrice.average
            amountChangeString = String.formattedAmountChange(amount: amountChange, currency: .usd)
            percentChange = 0 < previousPrice.average ? (amountChange / previousPrice.average) * 100 : 0
            if amountChange == 0 {
                percentChange = 0
            }
        }
        let posixString = previousPrice.time
        return String(format: NSLocalizedString("PORTFOLIO_Interval", comment: "Portfolio Percentage Change String"),
                      amountChangeString, percentChange, "%", posixString.intervaledDateString(selectedInterval))
    }

    static func percentChangeStringShort(latestPrice: PriceData, previousPrice: PriceData, referenceCurrency: Currency) -> String {
        var percentChange = 0.0
        var amountChange = 0.0

        switch referenceCurrency {
        case .btc:
            amountChange = latestPrice.averageBTC - previousPrice.averageBTC
            percentChange = 0 < previousPrice.averageBTC ? (amountChange / previousPrice.averageBTC) * 100 : 0
        default:
            amountChange = latestPrice.average - previousPrice.average
            percentChange = 0 < previousPrice.average ? (amountChange / previousPrice.average) * 100 : 0
        }
        return String(format: "%.2f%@", percentChange, "%")
    }

    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }
}

extension StringProtocol where Index == String.Index {
    func index<T: StringProtocol>(of string: T, options: String.CompareOptions = []) -> Index? {
        return range(of: string, options: options)?.lowerBound
    }
    func endIndex<T: StringProtocol>(of string: T, options: String.CompareOptions = []) -> Index? {
        return range(of: string, options: options)?.upperBound
    }
    func indexes<T: StringProtocol>(of string: T, options: String.CompareOptions = []) -> [Index] {
        var result: [Index] = []
        var start = startIndex
        while start < endIndex, let range = range(of: string, options: options, range: start..<endIndex) {
            result.append(range.lowerBound)
            start = range.lowerBound < range.upperBound ? range.upperBound : index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
    func ranges<T: StringProtocol>(of string: T, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var start = startIndex
        while start < endIndex, let range = range(of: string, options: options, range: start..<endIndex) {
            result.append(range)
            start = range.lowerBound < range.upperBound  ? range.upperBound : index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}
