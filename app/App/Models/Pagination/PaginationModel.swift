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

    private var firstPageInfo: PageInfo = .default
    private var lastPageInfo: PageInfo? = nil

    // polling
    private var pollingTimer: Timer?
    private var pollingAction: (() async -> Void)?

    init(threshold: Int, pageSize: Int) {
        self.threshold = threshold
        self.pageSize = pageSize
        self.source = source
    }

    deinit {
        self.stopPolling()
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

    private var currentPollingTask: Task<Void, Never>? {
        willSet {
            if let task = currentPollingTask {
                if task.isCancelled { return }
                task.cancel()
                // Setting a new task cancelling the current task
            }
        }
    }

    private var canLoadMorePages: Bool { lastPageInfo?.hasNext ?? false }

    public func start(withSource source: TPageable) {
        // prevent double start
        if self.source != nil { return }

        self.source = source

        // start polling
        self.pollingAction = {
            guard let source = self.source else { return }

            do {
                let isFirstFetch = self.lastPageInfo == nil
                let previousPage = try await source.loadPreviousPage(pageInfo: self.firstPageInfo, pageSize: nil)

                // task has been cancelled
                if Task.isCancelled { return }

                // do nothing if no new items have been found
                if previousPage.items.count == 0 { return }

                self.firstPageInfo = previousPage.info

                // set this page as the last one if it's the first time data is fetched
                if isFirstFetch {
                    self.lastPageInfo = previousPage.info
                }

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    // no need to reverse data if we've fetched for the first time
                    self.source?.addPreviousItems(items: isFirstFetch ? previousPage.items : previousPage.items.reversed())
                }
            } catch {
                // Publish our error to SwiftUI
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.state = .error(error: error)
                }
            }
        }

        // first execution
        self.currentPollingTask = Task {
            await self.pollingAction?()
        }

        self.pollingTimer = Timer.scheduledTimer(
            withTimeInterval: 3.0, // 3s
            repeats: true
        ) { _ in
            self.currentPollingTask = Task {
                await self.pollingAction?()
            }
        }
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
        guard
            let source = self.source,
            let lastPageInfo = self.lastPageInfo
        else { return }

        do {
            // (1) Ask the source for a page
            let nextPage = try await source.loadNextPage(pageInfo: lastPageInfo, pageSize: self.pageSize)

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

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        pollingAction = nil
    }
}
