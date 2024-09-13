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
    public let isEu: Bool

    public init(address: String, amount: String) {
//        self.address = address
        self.address = "0x0171eaf72B36Dd904509297A51c4744Dcaf2E20E327dd1e7b08808DC0283f0A3"
        self.tokenAmount = amount
        self.isNy = false
        self.isEu = true
    }
}
