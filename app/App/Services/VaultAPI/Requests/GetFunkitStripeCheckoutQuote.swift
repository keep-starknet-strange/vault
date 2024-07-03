//
//  GetFunkitStripeCheckoutQuote.swift
//  Vault
//
//  Created by Charles Lanier on 03/07/2024.
//

import Foundation

public struct GetFunkitStripeCheckoutQuote: APIRequest {

    public typealias Response = FunkitStripeCheckoutQuote

    // Notice how we create a composed resourceName
    public var resourceName: String {
        return "get_funkit_stripe_checkout_quote"
    }

    public var httpMethod: HTTPMethod {
        return .GET
    }

    // Parameters
    public let address: String
    public let tokenAmount: String
    public let isNy: Bool

    public init(address: String, amount: String) {
        self.address = address
        self.tokenAmount = amount
        self.isNy = false
    }
}
