//
//  CreateFunkitStripeCheckout.swift
//  Vault
//
//  Created by Charles Lanier on 03/07/2024.
//

import Foundation

public struct CreateFunkitStripeCheckout: APIRequest {

    public typealias Response = FunkitStripeCheckout

    // Notice how we create a composed resourceName
    public var resourceName: String {
        return "create_funkit_stripe_checkout"
    }

    public var httpMethod: HTTPMethod {
        return .POST
    }

    public var headers: [String : String] {
        return ["Content-Type": "application/json"]
    }

    // Parameters
    public let quoteId: String
    public let paymentTokenAmount: Double
    public let estSubtotalUsd: Double
    public let isNy: Bool
    public let isEu: Bool

    public init(quoteId: String, paymentTokenAmount: Double, estSubtotalUsd: Double) {
        self.quoteId = quoteId
        self.paymentTokenAmount = paymentTokenAmount
        self.estSubtotalUsd = estSubtotalUsd
        self.isNy = false
        self.isEu = true
    }
}
