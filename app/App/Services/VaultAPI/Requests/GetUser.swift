//
//  GetUser.swift
//  Vault
//
//  Created by Charles Lanier on 29/06/2024.
//

import Foundation

public struct GetUser: APIRequest {

    public typealias Response = RawUser

    // Notice how we create a composed resourceName
    public var resourceName: String {
        return "get_user"
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
