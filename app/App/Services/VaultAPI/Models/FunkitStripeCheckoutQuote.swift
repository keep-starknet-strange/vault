//
//  FunkitStripeCheckoutQuote.swift
//  Vault
//
//  Created by Charles Lanier on 03/07/2024.
//

import Foundation

public struct FunkitStripeCheckoutQuote: Decodable {
    public let quoteId: String
    public let estSubtotalUsd: Double
    public let paymentTokenAmount: String
    public let paymentTokenChain: String
    public let paymentTokenSymbol: String
    public let networkFees: String
    public let cardFees: String
    public let totalUsd: String
}
