//
//  History.swift
//  Vault
//
//  Created by Charles Lanier on 19/06/2024.
//

import Foundation

class User {
    let nickname: String
    let avatarUrl: String? = nil
    let address: String?

    init(transactionUser: RawTransactionUser) {
        self.nickname = transactionUser.nickname ?? transactionUser.phone_number ?? "UNKNOWN"
        self.address = transactionUser.contract_address
    }
}

class Transaction: Identifiable {
    let from: User
    let to: User
    let amount: USDCAmount
    let date: Date
    let isSending: Bool

    static let dateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        return dateFormatter
    }()

    init(address: String, transaction: RawTransaction) {
        self.from = User(transactionUser: transaction.from)
        self.to = User(transactionUser: transaction.to)
        self.amount = USDCAmount(from: transaction.amount)!
        self.date = Self.dateFormatter.date(from: transaction.transaction_timestamp)!
        self.isSending = transaction.from.contract_address == address
    }
}

class History {
    let transactions: [Transaction]

    var groupedTransactions: [Date: [Transaction]] {
        get {
            Dictionary(grouping: self.transactions) { (transaction) -> Date in
                return Calendar.current.startOfDay(for: transaction.date)
            }
        }
    }

    init(address: String, transactions: [RawTransaction]) {
        self.transactions = transactions.map { Transaction(address: address, transaction: $0) }
    }
}
