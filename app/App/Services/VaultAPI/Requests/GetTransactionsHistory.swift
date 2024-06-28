//
//  GetTransactionsHistory.swift
//  Vault
//
//  Created by Charles Lanier on 19/06/2024.
//

import Foundation

public struct GetTransactionsHistory: APIRequest {

    public typealias Response = VaultPage<RawTransaction>

    // Notice how we create a composed resourceName
    public var resourceName: String {
        return "transaction_history"
    }

    public var httpMethod: HTTPMethod {
        return .GET
    }

    // Parameters
    public let address: String
    public let first: Int?
    public let after: String?
    public let before: String?

    public init(address: String, first: Int?, after: String?) {
        self.address = address
        self.first = first
        self.after = after
        self.before = nil
    }

    public init(address: String, first: Int?, before: String?) {
        self.address = address
        self.first = first
        self.before = before
        self.after = nil
    }
}
