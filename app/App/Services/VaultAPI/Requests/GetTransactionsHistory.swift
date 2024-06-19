//
//  GetTransactionsHistory.swift
//  Vault
//
//  Created by Charles Lanier on 19/06/2024.
//

import Foundation

public struct GetTransactionsHistory: APIRequest {

    public typealias Response = RawTransactions

    // Notice how we create a composed resourceName
    public var resourceName: String {
        return "transaction_history"
    }

    public var httpMethod: HTTPMethod {
        return .GET
    }

    // Parameters
    public let address: String
    public let first: Int

    public init(address: String, first: Int) {
        self.address = address
        self.first = first
    }
}
