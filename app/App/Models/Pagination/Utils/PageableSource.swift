//
//  PageableSource.swift
//  Vault
//
//  Created by Charles Lanier on 21/06/2024.
//

import Foundation

public protocol PageableSource {

    associatedtype TPage: Page

    var items: [TPage.Item] { get }

    func loadNextPage(pageInfo: PageInfo, pageSize: Int?) async throws -> TPage
    func loadPreviousPage(pageInfo: PageInfo, pageSize: Int?) async throws -> TPage

    mutating func addItems(items: [TPage.Item])
    mutating func addPreviousItems(items: [TPage.Item])
}
