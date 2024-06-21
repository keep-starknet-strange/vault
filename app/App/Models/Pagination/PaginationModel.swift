//
//  PaginationModel.swift
//  Vault
//
//  Created by Charles Lanier on 20/06/2024.
//

import Foundation

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

    @Published private(set) var source: TPageable?

    private let pageSize: Int
    private let threshold: Int
    private var state: PaginationState = .loaded

    private var lastPageInfo: PageInfo = .default

    init(threshold: Int, pageSize: Int) {
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

    public func start(withSource source: TPageable) {
        // prevent double start
        if self.source != nil { return }

        self.source = source
        self.loadNext()
    }

    public func loadNext() {
        self.state = .loading
        self.currentTask = Task {
            await loadMoreItems()
        }
    }

    public func onItemAppear(_ item: Item) {
        guard let source = self.source else { return }

        // (1) appeared: No more pages
        if !self.canLoadMorePages {
            return
        }

        // (2) appeared: Already loading
        if self.state == .loading {
            return
        }

        // (3) No index
        guard let index = source.items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        // (4) appeared: Threshold not reached
        let thresholdIndex = source.items.index(source.items.endIndex, offsetBy: -threshold)
        if index != thresholdIndex {
            return
        }

        // (5) appeared: Load next page
        self.loadNext()
    }

    func loadMoreItems() async {
        guard let source = self.source else { return }

        do {
            // (1) Ask the source for a page
            let nextPage = try await source.loadPage(pageInfo: self.lastPageInfo, pageSize: self.pageSize)

            // (2) Task has been cancelled
            if Task.isCancelled { return }

            // (3) Append the items to the existing set of items
            self.lastPageInfo = nextPage.info

            // (4) Publish our changes to SwiftUI by setting our items and state
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.source?.addItems(items: nextPage.items)
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
