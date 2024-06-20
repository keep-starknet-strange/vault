//
//  PaginationModel.swift
//  Vault
//
//  Created by Charles Lanier on 20/06/2024.
//

import Foundation
import SwiftUI

public protocol Page {

    associatedtype Item: Identifiable

    var info: PageInfo { get set }
    var items: [Item] { get set }
}

public enum PaginationState: Equatable {
    case loading
    case loaded
    case error(error: Error)

    public static func == (lhs: PaginationState, rhs: PaginationState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.loaded, .loaded):
            return true
        case (.error, .error):
            return true // we don't need associated value equality to be verified here
        default:
            return false
        }
    }
}

public final class PaginationModel<TPageable: PageableSource>: ObservableObject {

    public typealias Item = TPageable.TPage.Item

    @Published private(set) var source: TPageable

    private let pageSize: Int
    private let threshold: Int
    private var state: PaginationState = .loaded

    private var lastPageInfo: PageInfo = .default

    init(threshold: Int, pageSize: Int, source: TPageable) {
        self.threshold = threshold
        self.pageSize = pageSize
        self.source = source
    }

    private var currentTask: Task<Void, Never>? {
        willSet {
            if let task = currentTask {
                if task.isCancelled { return }
                task.cancel()
                // Setting a new task cancelling the current task
            }
        }
    }

    private var canLoadMorePages: Bool { lastPageInfo.hasNext }

    public func loadNext() {
        self.state = .loading
        self.currentTask = Task {
            await loadMoreItems()
        }
    }

    public func onItemAppear(_ item: Item) {
        // (1) appeared: No more pages
        if !self.canLoadMorePages {
            return
        }

        // (2) appeared: Already loading
        if self.state == .loading {
            return
        }

        // (3) No index
        guard let index = self.source.items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        // (4) appeared: Threshold not reached
        let thresholdIndex = self.source.items.index(self.source.items.endIndex, offsetBy: -threshold)
        if index != thresholdIndex {
            return
        }

        // (5) appeared: Load next page
        self.loadNext()
    }

    func loadMoreItems() async {
        do {
            // (1) Ask the source for a page
            let nextPage = try await self.source.loadPage(pageInfo: self.lastPageInfo, pageSize: self.pageSize)

            // (2) Task has been cancelled
            if Task.isCancelled { return }

            // (3) Append the items to the existing set of items
            self.lastPageInfo = nextPage.info

            // (4) Publish our changes to SwiftUI by setting our items and state
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.source.addItems(items: nextPage.items)
                self.state = .loaded
            }
        } catch {

            // (5) Publish our error to SwiftUI
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.state = .error(error: error)
            }
        }
    }
}

public protocol PageableSource {

    associatedtype TPage: Page

    var items: [TPage.Item] { get }

    func loadPage(pageInfo: PageInfo, pageSize: Int) async throws -> TPage

    mutating func addItems(items: [TPage.Item])
}




















struct TransactionHistory: PageableSource {

    typealias Item = Transaction

    var transactions: [Item] = []
    var groupedTransactions: [Date: [Item]] = [:]

    var items: [Item] { transactions }

    private let address: String = "0x039fd69d03e3735490a86925612072c5612cbf7a0223678619a1b7f30f4bdc8f"

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
        self.transactions = items

        print(items)
        print(self.transactions)

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

class TransactionsPage: Page {

    typealias Item = Transaction

    var info: PageInfo
    var items: [Item]

    init(info: PageInfo, items: [Item]) {
        self.info = info
        self.items = items
    }
}
