//
//  Transactions.swift
//  Vault
//
//  Created by Charles Lanier on 21/06/2024.
//

import Foundation

class TransactionsPage: Page {

    typealias Item = Transaction

    var info: PageInfo
    var items: [Item]

    init(info: PageInfo, items: [Item]) {
        self.info = info
        self.items = items
    }
}

struct TransactionHistory: PageableSource {

    typealias Item = Transaction

    var transactions: [Item] = []
    var groupedTransactions: [Date: [Item]] = [:]

    var items: [Item] { transactions }

    private let address: String

    init(address: String) {
        self.address = address
    }

    public func loadPage(pageInfo: PageInfo, pageSize: Int) async throws -> TransactionsPage {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TransactionsPage, any Error>) in
            VaultService.shared.send(GetTransactionsHistory(address: self.address, first: pageSize, after: pageInfo.endCursor)) { result in
                switch result {
                case .success(let response):
                    let pageInfo = PageInfo(hasNext: response.hasNext, endCursor: response.endCursor)
                    let transactions = response.items.map { Item(address: self.address, transaction: $0) }

                    continuation.resume(returning: TransactionsPage(info: pageInfo, items: transactions))

                case .failure(let error):
                    // TODO: Handle error
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public mutating func addItems(items: [Transaction]) {
        self.transactions += items

        items.forEach { item in
            let day = Calendar.current.startOfDay(for: item.date)

            if self.groupedTransactions[day] == nil {
                self.groupedTransactions[day] = [item]
            } else {
                self.groupedTransactions[day]! += [item]
            }
        }
    }
}
