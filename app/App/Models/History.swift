//
//  History.swift
//  Vault
//
//  Created by Charles Lanier on 19/06/2024.
//

import Foundation

struct User: Hashable {
    let nickname: String?
    let avatarUrl: String? = nil
    let address: String?
    let phoneNumber: String?

    init(transactionUser: RawTransactionUser) {
        self.nickname = transactionUser.nickname ?? transactionUser.phone_number
        self.address = transactionUser.contract_address
        self.phoneNumber = transactionUser.phone_number
    }
}

struct Transaction: Identifiable, Hashable {

    typealias ID = String

    let from: User
    let to: User
    let amount: Amount
    let date: Date
    let isSending: Bool
    let balance: Amount
    let id: ID

    static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        return lhs.id == rhs.id
    }

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
        self.amount = Amount.usdc(from: transaction.amount)!
        self.date = Self.dateFormatter.date(from: transaction.transaction_timestamp)!
        self.isSending = transaction.from.contract_address == address
        self.balance = Amount.usdc(from: self.isSending ? transaction.from.balance : transaction.to.balance)!
        self.id = transaction.transferId
    }

    init(
        address: String,
        from: RawTransactionUser,
        to: RawTransactionUser,
        amount: Amount,
        date: Date,
        transferId: ID
    ) {
        self.from = User(transactionUser: from)
        self.to = User(transactionUser: to)
        self.amount = amount
        self.date = date
        self.isSending = from.contract_address == address
        self.balance = Amount.usdc(from: 0)!
        self.id = transferId
    }
}
