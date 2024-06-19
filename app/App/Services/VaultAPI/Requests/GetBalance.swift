//
//  GetBalance.swift
//  Vault
//
//  Created by Charles Lanier on 14/06/2024.
//

import Foundation

public struct GetBalance: APIRequest {

    public typealias Response = Balance

    // Notice how we create a composed resourceName
    public var resourceName: String {
        return "get_balance"
    }

    public var httpMethod: HTTPMethod {
        return .GET
    }

    // Parameters
    public let address: String

    public init(address: String) {
        self.address = address
    }
}
