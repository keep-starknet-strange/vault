//
//  FunkitStripeCheckout.swift
//  Vault
//
//  Created by Charles Lanier on 03/07/2024.
//

import Foundation


public struct FunkitStripeCheckout: Decodable {
    public let stripeCheckoutId: String
    public let stripeRedirectUrl: String
    public let funkitDepositAddress: String
}
