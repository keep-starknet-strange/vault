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
    var groupedPendingTransactions: [Date: [Item]] = [:]
    var days: [Date] = []

    var items: [Item] { transactions }

    private let address: String

    init(address: String) {
        self.address = address
    }

    public func loadNextPage(pageInfo: PageInfo, pageSize: Int?) async throws -> TransactionsPage {
        return try await self.loadPage(request: GetTransactionsHistory(address: self.address, first: pageSize, after: pageInfo.endCursor))
    }

    public func loadPreviousPage(pageInfo: PageInfo, pageSize: Int?) async throws -> TransactionsPage {
        return try await self.loadPage(request: GetTransactionsHistory(address: self.address, first: pageSize, before: pageInfo.startCursor))
    }

    private func loadPage(request: GetTransactionsHistory) async throws -> TransactionsPage {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TransactionsPage, any Error>) in
            VaultService.shared.send(request) { result in
                switch result {
                case .success(let response):
                    let pageInfo = PageInfo(hasNext: response.hasNext, startCursor: response.startCursor, endCursor: response.endCursor)
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
                self.groupedTransactions[day]?.append(item)
            }
        }
        self.updateDays()
    }

    public mutating func addPreviousItems(items: [Transaction]) {
        self.transactions = items + self.transactions

        items.reversed().forEach { item in
            let day = Calendar.current.startOfDay(for: item.date)

            // remove from pending if needed
            self.groupedPendingTransactions[day]?.removeAll { pendingItem in
                return pendingItem.id == item.id
            }

            if self.groupedTransactions[day] == nil {
                self.groupedTransactions[day] = [item]
            } else {
                self.groupedTransactions[day]?.insert(item, at: 0)
            }
        }
        self.updateDays()
    }

    public mutating func addPendingItems(items: [Transaction]) {
        items.reversed().forEach { item in
            let day = Calendar.current.startOfDay(for: item.date)

            if self.groupedPendingTransactions[day] == nil {
                self.groupedPendingTransactions[day] = [item]
            } else {
                self.groupedPendingTransactions[day]?.insert(item, at: 0)
            }
        }
        self.updateDays()
    }

    public mutating func updateDays() {
        let confirmedDays = self.groupedTransactions.keys
        let pendingDays = self.groupedPendingTransactions.keys

        self.days = Array(Set(confirmedDays).union(pendingDays)).sorted(by: >)
    }
}
